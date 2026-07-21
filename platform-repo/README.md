# platform-repo — bộ máy phía sau IDP (team hạ tầng sở hữu)

Dev không cần đọc repo này. Mọi thứ ở đây tồn tại để `score.yaml` của dev đơn giản nhất có thể.

```
platform-repo/
├── .github/workflows/
│   ├── orchestrator.yaml              # BỘ NÃO DEPLOY: nhận dispatch từ CI app,
│   │                                  #   render (theo catalog app ghim) + secret + commit
│   └── catalog-ci.yaml                # PR sửa score/** -> render-diff bộ mẫu để review
├── score/
│   ├── provisioners/
│   │   ├── onprem.provisioners.yaml   # postgres/mysql/mongodb->StatefulSet(rook-ceph-block), redis->Deployment,
│   │   │                              #   app-config->Secret khai key, route->Ingress nginx, service->DNS
│   │   └── cloud.provisioners.yaml    # datastore->RDS/DocumentDB/ElastiCache (Secret của Terraform), route->Ingress ALB
│   ├── patches/
│   │   ├── staging.tpl                # khác biệt env: replicas, resources (bỏ qua datastore) + pull secret ($pullSecret)
│   │   └── prod.tpl
│   └── examples/                      # bộ score mẫu làm input chuẩn cho catalog-ci
│       └── migration/                 #   3 app đại diện migrate 1.19->1.35 (feedback360, okr, shift-handover)
├── scripts/
│   └── test-local.sh                  # render + dry-run server-side vào ns sandbox (xem HUONG-DAN-THUC-THI.md)
├── docs/
│   ├── them-provisioner-moi.md        # checklist thêm datastore mới (<1h)
│   └── mapping-k8s-cu-sang-score.md   # mapping manifest cũ -> Score + đánh giá keycloak/svms/arangodb
├── argocd/
│   ├── project.yaml
│   ├── appset-onprem.yaml             # đa cụm: đọc clusters/placement/*.yaml -> destination theo từng app
│   └── appset-cloud.yaml
├── clusters/
│   ├── README.md                      # mô hình mỗi app một cụm: onboard cụm, đặt tên, secret
│   └── placement/<app>.yaml           # NGUỒN SỰ THẬT: app nào chạy cụm nào (staging/prod)
└── bootstrap/
    └── onprem.md                      # dựng tay ingress-nginx + ArgoCD (Giai đoạn 1)
```

## Mô hình orchestrator (CI tách khỏi deploy)

```
app repo CI:  build image (Harbor) ──repository_dispatch──> platform-repo orchestrator:
                                                              1. checkout app @ sha
                                                              2. tự phát hiện */score.yaml
                                                              3. score-k8s render (provisioner + patch env)
                                                              4. tách Secret -> apply cụm (create-if-missing)
                                                              5. commit manifest -> <app>-config
                                                            ArgoCD: sync như bình thường
```

Lợi ích: credential (kubeconfig, token config repo, robot Harbor) chỉ nằm ở repo này; logic render viết 1 lần cho mọi app; và đây là chỗ cắm tự động hóa Terraform về sau (stage "infra" đã đánh dấu sẵn trong orchestrator.yaml).

## Secrets cấu hình

| Ở đâu | Secret | Dùng cho |
|---|---|---|
| **platform-repo** | `APP_REPOS_TOKEN` | đọc app repo trong org |
| | `CONFIG_REPO_TOKEN` | push vào các repo `<app>-config` |
| | `KUBECONFIG_ONPREM_STAGING` / `..._PROD` | apply Secret DB + harbor-pull (cụm quản lý / app đặt `in-cluster`) |
| | `KUBECONFIG_<TÊN_CỤM>` | đa cụm: kubeconfig từng cụm app riêng (vd `KUBECONFIG_OKR_STAGING`) — xem `clusters/README.md` |
| | `HARBOR_HOST`, `HARBOR_ROBOT_USER`, `HARBOR_ROBOT_PASS` | tạo pull secret trong namespace |
| **mỗi app repo** | `HARBOR_USERNAME` / `HARBOR_PASSWORD` | push image |
| | `PLATFORM_DISPATCH_TOKEN` | bắn repository_dispatch sang repo này |

## Harbor

- Image nằm ở `harbor.<domain>/<project>/<app>-<service>:<sha>` — tạo project (vd `idp`) và robot account trước.
- Registry private → patch template tự tiêm `imagePullSecrets: harbor-pull` vào mọi Deployment/StatefulSet; orchestrator tạo secret đó trong từng namespace (create-if-missing).
- Nên bật proxy-cache project cho Docker Hub nếu cụm không ra internet (ảnh hưởng image `postgres:16-alpine` của provisioner — xem comment trong file).

## Phiên bản catalog & ghim (platform.lock)

Mỗi app repo có file `platform.lock` ghim ref (tag `catalog/vX`) của repo này — orchestrator render app bằng đúng catalog đó. Sửa provisioner/patch trên `main` **không ảnh hưởng app nào** cho tới khi app tự nâng lock. Quy trình: PR (catalog-ci hiện render-diff) → merge + tag → canary 1 app → rollout wave. Chi tiết: `CHIEN-LUOC-MIGRATION-VA-CAP-NHAT.md` ở repo tổng.

## Nhiều người dùng đồng thời — mô hình tuần tự hóa

| Tình huống | Cơ chế bảo vệ |
|---|---|
| 2 dev sửa score.yaml, push cùng lúc | git từ chối push sau (non-fast-forward) — dev phải pull/rebase; không bao giờ có 2 trạng thái song song trong repo |
| 2 commit liên tiếp cùng app → 2 lần orchestrator | `concurrency.group: app-<app>` — deploy/promote CÙNG app xếp hàng tuần tự, KHÁC app chạy song song; kèm push retry+rebase vào config repo |
| 2 tiến trình cùng tạo Secret trên cụm | create-if-missing: một bên thắng, bên kia AlreadyExists → giữ nguyên |
| Deploy chen promote cùng app | chung concurrency group → không chen được |
| 2 maintainer sửa catalog | PR + catalog-ci render-diff + tag; app ghim `platform.lock` nên không ai bị ăn catalog dở dang |
| 2 người test-local cùng app trên cùng cụm | namespace sandbox trùng nhau → mỗi người truyền `--namespace <app>-sandbox-<tên mình>` |

## Mô hình đa cụm (mỗi app một cụm k8s riêng)

ArgoCD chạy trên **cụm quản lý**, deploy chéo sang **cụm app** theo
`clusters/placement/<app>.yaml`. Thêm app = tạo repo `<app>-config` + 1 file placement.
Orchestrator cũng đọc placement để apply Secret đúng cụm (secret `KUBECONFIG_<TÊN_CỤM>`).
Chi tiết + checklist onboard cụm mới: `clusters/README.md`.

## Mở rộng platform

- Thêm loại hạ tầng (s3, queue...): thêm 1 block provisioner vào cả 2 file onprem/cloud theo checklist `docs/them-provisioner-moi.md`. Dev dùng ngay bằng `type: <tên>`.
- Đổi cách làm secret (Sealed Secrets, ESO+Vault): giữ convention tên Secret `<workload>-db-credentials` thì app không đổi.
- Tự động hóa hạ tầng cloud: viết vào stage "infra" của orchestrator (terraform module rds theo app), CI app không đổi.
