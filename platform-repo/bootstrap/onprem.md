# Bootstrap cụm ONPREM (Lớp 1 + Lớp 2 — dựng tay, một lần)

Giai đoạn 1: hạ tầng dựng tay. Chuỗi lệnh dưới chạy trên máy có `kubectl` trỏ vào cụm nội bộ.

## 0. Điều kiện

- Cụm K8s đã có (kubeadm / k3s / RKE2...), có StorageClass (sửa `storageClassName` trong
  `score/provisioners/onprem.provisioners.yaml` cho khớp — mặc định `standard`).
- DNS wildcard (vd `*.shop.example.com`) trỏ vào node chạy ingress-nginx, hoặc sửa `/etc/hosts` khi thử.

## 1. ingress-nginx (gateway — khuôn công ty đang dùng trên Rancher)

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443
# hoặc service.type=LoadBalancer nếu có MetalLB
# air-gap: mirror image ingress-nginx qua Harbor rồi --set controller.image.registry=...
```

Provisioner `route` sinh Ingress chuẩn `networking.k8s.io/v1` với `ingressClassName: nginx`
(đổi qua `params.ingressClass` nếu cụm dùng class khác). TLS: tạo secret cert trong
namespace app rồi khai `params.tlsSecret` ở resource route — không cần sửa provisioner.

## 2. ArgoCD (CD/GitOps)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Lấy mật khẩu admin:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## 3. Token để ApplicationSet quét org GitHub

ApplicationSet dùng SCM Provider generator quét các repo `*-config`:

```bash
kubectl -n argocd create secret generic github-token \
  --from-literal=token=<GITHUB_PAT_READ_ONLY>
```

(Nếu không muốn cấp token quét org: mở `argocd/appset-*.yaml`, thay generator `scmProvider` bằng `list` — có sẵn mẫu comment.)

## 4. Apply project + ApplicationSet

```bash
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/appset-onprem.yaml
# appset-cloud.yaml apply ở Giai đoạn 2, sau khi có EKS
```

Từ đây trở đi platform chạy tự động: repo `<app>-config` nào xuất hiện trong org là ArgoCD tự tạo Application `<app>-staging-onprem` + `<app>-prod-onprem`.

## 5. Secrets cho orchestrator + app repo

Mô hình orchestrator: credential tập trung ở **platform-repo**, app repo chỉ giữ tối thiểu.

| Ở đâu | Secret | Dùng cho |
|---|---|---|
| platform-repo | `APP_REPOS_TOKEN`, `CONFIG_REPO_TOKEN` | đọc app repo, push config repo |
| platform-repo | `KUBECONFIG_ONPREM_STAGING` / `..._PROD` | apply Secret DB + harbor-pull |
| platform-repo | `HARBOR_HOST`, `HARBOR_ROBOT_USER`, `HARBOR_ROBOT_PASS` | pull secret cho namespace |
| app repo | `HARBOR_USERNAME` / `HARBOR_PASSWORD` | push image lên Harbor |
| app repo | `PLATFORM_DISPATCH_TOKEN` | gọi orchestrator (repository_dispatch) |

## 6. Giai đoạn 2 — nối EKS

Sau khi `terraform apply` (xem `terraform/README.md`):

```bash
aws eks update-kubeconfig --name idp-staging --alias eks-staging
argocd cluster add eks-staging --name eks-staging
kubectl apply -f argocd/appset-cloud.yaml
```
