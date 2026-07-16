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
│   │   ├── onprem.provisioners.yaml   # postgres->StatefulSet(rook-ceph-block), route->Traefik, service->DNS
│   │   └── cloud.provisioners.yaml    # postgres->RDS(Secret của Terraform), route->Ingress ALB
│   ├── patches/
│   │   ├── staging.tpl                # khác biệt env: replicas, resources + tiêm imagePullSecrets (Harbor)
│   │   └── prod.tpl
│   └── examples/                      # bộ score mẫu làm input chuẩn cho catalog-ci
├── argocd/
│   ├── project.yaml
│   ├── appset-onprem.yaml             # tự quét repo *-config trong org
│   └── appset-cloud.yaml
└── bootstrap/
    └── onprem.md                      # dựng tay Traefik + ArgoCD (Giai đoạn 1)
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
| | `KUBECONFIG_ONPREM_STAGING` / `..._PROD` | apply Secret DB + harbor-pull |
| | `HARBOR_HOST`, `HARBOR_ROBOT_USER`, `HARBOR_ROBOT_PASS` | tạo pull secret trong namespace |
| **mỗi app repo** | `HARBOR_USERNAME` / `HARBOR_PASSWORD` | push image |
| | `PLATFORM_DISPATCH_TOKEN` | bắn repository_dispatch sang repo này |

## Harbor

- Image nằm ở `harbor.<domain>/<project>/<app>-<service>:<sha>` — tạo project (vd `idp`) và robot account trước.
- Registry private → patch template tự tiêm `imagePullSecrets: harbor-pull` vào mọi Deployment/StatefulSet; orchestrator tạo secret đó trong từng namespace (create-if-missing).
- Nên bật proxy-cache project cho Docker Hub nếu cụm không ra internet (ảnh hưởng image `postgres:16-alpine` của provisioner — xem comment trong file).

## Phiên bản catalog & ghim (platform.lock)

Mỗi app repo có file `platform.lock` ghim ref (tag `catalog/vX`) của repo này — orchestrator render app bằng đúng catalog đó. Sửa provisioner/patch trên `main` **không ảnh hưởng app nào** cho tới khi app tự nâng lock. Quy trình: PR (catalog-ci hiện render-diff) → merge + tag → canary 1 app → rollout wave. Chi tiết: `CHIEN-LUOC-MIGRATION-VA-CAP-NHAT.md` ở repo tổng.

## Mở rộng platform

- Thêm loại hạ tầng (redis, s3...): thêm 1 block provisioner vào cả 2 file onprem/cloud. Dev dùng ngay bằng `type: redis`.
- Đổi cách làm secret (Sealed Secrets, ESO+Vault): giữ convention tên Secret `<workload>-db-credentials` thì app không đổi.
- Tự động hóa hạ tầng cloud: viết vào stage "infra" của orchestrator (terraform module rds theo app), CI app không đổi.
