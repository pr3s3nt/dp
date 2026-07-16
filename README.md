# IDP v2 — Score → score-k8s (render + patch) → config repo → ArgoCD

Internal Developer Platform cho app microservices trên Kubernetes. Dev chỉ viết `score.yaml` cho mỗi service; platform sinh toàn bộ manifest và deploy qua GitOps. Hai môi trường (staging/prod), hai nền tảng (onprem trước, EKS sau) — **cùng một giao diện Score**.

Khác v1 (idp-scaffold): **bỏ Kustomize**. CI render manifest hoàn chỉnh theo từng env bằng `score-k8s` + patch template, đẩy vào config repo; ArgoCD sync nguyên thư mục, không render gì thêm.

## Luồng end-to-end (mô hình orchestrator — CI tách khỏi deploy)

```
dev push main (app repo)
  → CI CHỈ build image lên Harbor (tag = git SHA)
  → gọi platform: repository_dispatch "deploy-request" sang platform-repo
  → ORCHESTRATOR (platform-repo/.github/workflows/orchestrator.yaml):
      - tự phát hiện mọi */score.yaml của app
      - score-k8s generate
          + provisioners (onprem|cloud)   ← postgres/route/service -> manifest thật
          + patch template (staging|prod) ← replicas/resources + imagePullSecrets Harbor
      - tách Secret (apply thẳng lên cụm, create-if-missing — KHÔNG vào git)
      - commit manifest sang <app>-config/onprem/staging/
  → ArgoCD auto-sync staging

pass staging → bấm nút promote (Actions → promote trong app repo, nhập SHA)
  → dispatch "promote-request" → orchestrator tạo commit đổi tag prod
  → ArgoCD (prod = manual sync) hiện diff → bấm Sync
```

CI của app chỉ biết "build"; mọi credential hạ tầng và logic render nằm một chỗ ở platform-repo. Đây cũng là chỗ cắm tự động hóa Terraform về sau (stage "infra" trong orchestrator).

## Cấu trúc (mỗi thư mục con = một git repo riêng khi triển khai thật)

```
v2/
├── platform-repo/                    # team hạ tầng sở hữu
│   ├── score/provisioners/           #   postgres / route / service (onprem + cloud)
│   ├── score/patches/                #   staging.tpl / prod.tpl — khác biệt env
│   ├── argocd/                       #   project + 2 ApplicationSet (tự quét repo *-config)
│   └── bootstrap/onprem.md           #   dựng tay Traefik + ArgoCD (Giai đoạn 1)
├── app-repos/shop-app/               # app mẫu: 4 service × (score.yaml + code + Dockerfile)
│   └── .github/workflows/            #   ci.yaml (staging) + promote.yaml (nút lên prod)
├── config-repos/shop-app-config/     # 1 app = 1 config repo — ArgoCD đọc, máy ghi
│   ├── onprem/{staging,prod}/manifests.yaml
│   └── cloud/{staging,prod}/manifests.yaml
└── terraform/                        # Giai đoạn 2: VPC + EKS + RDS + Secret DB vào cụm
```

## Các quyết định đã chốt

| Chủ đề | Quyết định |
|---|---|
| Giao diện dev | Chỉ `score.yaml` (3 loại resource: `postgres`, `route`, `service`) |
| Render | score-k8s + catalog provisioner + patch template theo env — không Kustomize/Helm |
| Config repo | 1 app = 1 repo `<app>-config`, manifest render sẵn, máy ghi người review |
| Phát hiện app | ApplicationSet SCM provider quét org tìm `*-config` → thêm app = tạo repo |
| Namespace | `<app>-<env>` (mọi service của app chung namespace) |
| Sync | staging auto (prune+selfHeal); prod manual |
| Secret | Provisioner tự sinh password → Secret; CI tách khỏi git, `kubectl create` (giữ nguyên nếu đã có); app đọc qua `secretKeyRef`; convention `<workload>-db-credentials` |
| Promotion | Nút bấm (workflow_dispatch) → orchestrator tạo commit đổi tag prod; mode `re-render` khi score.yaml đổi cấu trúc; không build lại image |
| CI vs Platform | CI app chỉ build + dispatch; orchestrator (platform-repo) render/secret/commit — credential tập trung 1 chỗ |
| Ghim hạ tầng | `platform.lock` mỗi app ghim tag catalog (provisioners+patches); sửa platform không lan sang app đang chạy; catalog-ci render-diff khi PR — xem CHIEN-LUOC-MIGRATION-VA-CAP-NHAT.md |
| Registry | Harbor on-prem: image `harbor.<domain>/<project>/<app>-<svc>:<sha>`, robot account cho CI, patch tự tiêm `imagePullSecrets: harbor-pull` |
| Cloud | Terraform dựng VPC/EKS/RDS + ghi Secret DB; deploy app y luồng onprem |

## Thứ tự triển khai

1. **Giai đoạn 1 — onprem:** làm theo `platform-repo/bootstrap/onprem.md` (Traefik, ArgoCD, token, appset). Tạo 3 repo từ 3 thư mục: `platform-repo`, `shop-app`, `shop-app-config`. Cấu hình secrets cho CI (xem `app-repos/shop-app/README.md`). Push shop-app → xem staging lên.
2. **Giai đoạn 2 — cloud:** `terraform/README.md` (apply staging → prod, argocd cluster add, bật `TARGETS="onprem cloud"` trong ci.yaml, apply appset-cloud).

## TODO trước khi dùng thật

- Thay toàn bộ `your-org`, domain `shop.example.com`, region/CIDR.
- Cú pháp provisioner (`encodeSecretRef`, `.WorkloadServices`) và patch template đã đối chiếu với score-k8s 0.15.0 (bản pin trong workflow). Vẫn nên chạy `score-k8s init/generate` local một lần trước khi bật CI để soi output thực tế.
- `storageClassName` trong provisioner postgres onprem cho khớp cụm.
- TLS cho Traefik (entryPoint `websecure`) và cài AWS Load Balancer Controller trên EKS.
- Về sau: thay bước CI apply secret bằng Sealed Secrets hoặc External Secrets Operator (convention tên Secret giữ nguyên nên app không đổi).
