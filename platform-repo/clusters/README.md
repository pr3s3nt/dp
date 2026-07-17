# clusters/ — placement: app nào chạy trên cụm k8s nào

Mô hình: **một cụm quản lý** chạy ArgoCD + nhiều **cụm app** (mỗi app — hoặc nhóm app —
một cụm riêng). ArgoCD ở cụm quản lý deploy chéo sang cụm app qua cluster đã đăng ký.

**Nguồn sự thật duy nhất**: `clusters/placement/<app>.yaml` — cả ArgoCD (ApplicationSet
đọc để chọn `destination`) lẫn orchestrator (chọn kubeconfig để apply Secret) đều đọc
từ đây. Đổi cụm của app = sửa 1 file này qua PR (placement đọc từ `main`, KHÔNG theo
`platform.lock` — đây là dữ liệu vận hành, không phải template render).

## Khuôn file placement

```yaml
# clusters/placement/okr.yaml
app: okr                  # == tên repo bỏ hậu tố -config
clusters:
  staging: okr-staging    # tên cluster ĐÃ đăng ký trong ArgoCD (xem dưới)
  prod: okr-prod
```

`in-cluster` = chính cụm quản lý (tên mặc định ArgoCD tự có) — dùng cho app chưa tách cụm.

## Onboard một CỤM mới (một lần cho mỗi cụm)

1. Dựng cụm + ingress-nginx (theo `bootstrap/onprem.md` — controller cần cho `type: route`;
   không cần cài lại ArgoCD trên cụm app).
2. Đăng ký với ArgoCD từ máy quản trị:
   `argocd cluster add <context-cụm> --name <tên-cụm>` (tên ngắn, chữ thường, gạch nối).
3. Thêm secret cho orchestrator trong platform-repo (Settings → Secrets → Actions):
   `KUBECONFIG_<TÊN_CỤM viết hoa, gạch nối → gạch dưới>` = base64 kubeconfig cụm đó
   (vd cụm `okr-staging` → secret `KUBECONFIG_OKR_STAGING`).
   Riêng `in-cluster` dùng secret cũ `KUBECONFIG_ONPREM_STAGING` / `KUBECONFIG_ONPREM_PROD`.
4. (Nếu cụm không có ceph) kiểm tra `kubectl get storageclass` — datastore provisioner
   mặc định `rook-ceph-block`.

## Onboard một APP

1. Tạo repo `<app>` + `<app>-config` như cũ.
2. Thêm `clusters/placement/<app>.yaml` (PR vào repo này) — **không có file này thì
   ApplicationSet không deploy app** và orchestrator rơi về cụm mặc định (in-cluster) kèm cảnh báo.
3. Test trước bằng harness, trỏ đúng kubeconfig CỦA CỤM APP ĐÓ:
   `./scripts/test-local.sh <app-dir> --kubeconfig ~/.kube/<cụm-app>.yaml [--insecure-skip-tls-verify]`

Ghi chú: placement hiện áp cho **onprem** (`appset-onprem.yaml`). `appset-cloud.yaml` vẫn
là 1 cụm EKS chung — khi cloud cần đa cụm, áp cùng khuôn (đổi generator sang placement).
