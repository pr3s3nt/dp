# Platform DigitalOcean — scaffold app + hạ tầng trước, deploy sau

Tài liệu cho luồng "một app mới = tự sinh code + git + **tự dựng hạ tầng** rồi CI/CD".
Mô hình **mỗi app một cụm DOKS riêng** (`idp-<app>`), tự chứa ArgoCD + ingress.

## Thành phần

| File | Vai trò |
|---|---|
| `scripts/new-app.sh` | Scaffold app: sinh code (backend Express+PG, frontend nginx), score.yaml, Dockerfile, `do-ci.yaml`, `platform.lock`; tạo repo `<app>` + `<app>-config`; thêm `clusters/placement/<app>.yaml`; đặt secrets; đẩy placement lên platform-repo |
| `terraform/do/modules/doks` | Module: VPC + cụm DOKS (+ version tự lấy mới nhất) |
| `terraform/do/app-cluster` | Root tái dùng: `-var app_name=<app>` → cụm `idp-<app>`. State local (demo) / DO Spaces (prod, xem `backend.tf.example`) |
| `.github/workflows/do-platform.yaml` | **infra → deploy** trong 1 workflow (dispatch `provision-and-deploy`) |
| `argocd/do-app.tpl.yaml` | 2 Application (staging auto / prod manual) cho riêng 1 app |

## Luồng đầy đủ

```
scripts/new-app.sh <app>            # tạo code + 2 repo + placement + secrets
   │
   └─(push app repo)→ do-ci: build+push DOCR (tag <svc>-<sha>) → dispatch provision-and-deploy
        │
        └→ do-platform.yaml
             job infra:  terraform ensure cụm idp-<app> (idempotent: bỏ qua nếu đã có)
                         → bootstrap ingress-nginx (1 LB) + ArgoCD + 2 Application của app
             job deploy: score-k8s render (do provisioner + do-<env>.tpl, image DOCR, host nip.io)
                         → apply secret + pull secret → commit <app>-config/do/<env>/manifests.yaml
        │
        └→ ArgoCD (trên cụm idp-<app>): staging auto-sync, prod bấm Sync
```

**Thứ tự đúng như yêu cầu: hạ tầng (terraform) TRƯỚC, triển khai (CI/CD) SAU** — job `deploy` khai báo `needs: infra`.

## Cách chạy

```bash
# 1. Scaffold (cần GH_TOKEN=PAT; DO_TOKEN tự đọc từ doctl)
export GH_TOKEN=<pat>
platform-repo/scripts/new-app.sh myapp
# (hoặc thử offline không đụng GitHub:)
platform-repo/scripts/new-app.sh myapp --local-only

# 2. Push app repo -> luồng tự chạy. Theo dõi Actions của platform-repo.
```

## Ghi chú vận hành

- **Droplet quota**: mỗi cụm mới tốn ≥1 droplet. Tài khoản limit mặc định 3 → hết quota thì
  `terraform apply` cụm sẽ lỗi `not enough droplet limit`. Xin tăng limit ở DO, hoặc đặt
  `-var create_cluster=false` (chỉ tạo VPC) để thử luồng. `terraform plan` không tốn quota.
- **State terraform**: pipeline dùng existence-check (`doctl cluster get`) nên mất state local
  không tạo trùng. Production nên bật DO Spaces backend (`backend.tf.example`).
- **DOCR**: starter tier chỉ 1 repository. Nhiều app → nâng basic ($5/mo) hoặc mỗi app một tag
  trong chung 1 repo. `--registry` đổi được prefix.
- **Registry pull secret** tên `registry-<registry>` phải khớp `$pullSecret` trong `do-*.tpl`.
```
