# Hướng dẫn cài đặt app mẫu (notes-app) lên cụm công ty — môi trường KHÔNG có internet

Bối cảnh: cụm K8s nội bộ (Rook Ceph), Harbor nội bộ, GitHub Enterprise Server (GHES) chạy trong cụm, **không kết nối internet**. Nguyên tắc xuyên suốt: *mọi image đi qua Harbor, mọi binary chép tay một lần*.

> **ĐƯỜNG TẮT nếu đã có runner self-hosted build được image** (GHES dispatch vào runner, runner build + push Harbor + kubectl vào cụm được): bỏ qua Bước 0–2 phần chuẩn bị offline. Chỉ cần: (1) cài `score-k8s` + `yq` lên runner (Bước 3.3), (2) kiểm tra node cụm pull được `postgres:16-alpine` không — không được thì mirror vào Harbor từ runner và sửa 1 dòng image trong provisioner (Bước 2, dòng cuối), (3) SSH vào runner chạy Bước 4. Các workflow đổi `runs-on: self-hosted` là xong đường CI.

Ký hiệu dùng trong tài liệu (thay bằng giá trị thật của bạn):

| Placeholder | Ý nghĩa | Ví dụ |
|---|---|---|
| `HARBOR` | domain Harbor | `harbor.congty.local` |
| `NODE_IP` | IP một node chạy Traefik | `10.0.0.11` |

---

## Bước 0 — Chuẩn bị trên MÁY CÓ INTERNET (làm ở nhà, trước khi mang lên công ty)

Cần một máy có internet + docker để gom artifact, rồi chuyển vào mạng công ty (USB/file share).

### 0.1. Tải binary

```bash
mkdir -p idp-offline/bin && cd idp-offline/bin
# score-k8s 0.15.0
wget https://github.com/score-spec/score-k8s/releases/download/0.15.0/score-k8s_0.15.0_linux_amd64.tar.gz
# yq v4
wget -O yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
# helm (nếu cụm chưa có Traefik)
wget https://get.helm.sh/helm-v3.15.4-linux-amd64.tar.gz
```

### 0.2. Tải Helm chart Traefik (nếu cụm chưa có Traefik)

```bash
cd .. && mkdir charts && cd charts
helm repo add traefik https://traefik.github.io/charts && helm repo update
helm pull traefik/traefik        # ra file traefik-<version>.tgz
```

### 0.3. Kéo và đóng gói image nền

```bash
cd .. && mkdir images
docker pull node:20-alpine
docker pull nginx:1.27-alpine
docker pull postgres:16-alpine
docker pull traefik:v3.1        # khớp appVersion của chart vừa pull (xem `helm show chart`)
docker save -o images/base-images.tar \
  node:20-alpine nginx:1.27-alpine postgres:16-alpine traefik:v3.1
```

### 0.4. Gom source

Chép toàn bộ thư mục `v2/` (ít nhất phải có `platform-repo/` và `app-repos/notes-app/`) vào `idp-offline/`. Mang cả thư mục `idp-offline/` vào mạng công ty.

---

## Bước 1 — Nạp image nền vào Harbor (máy trong mạng công ty, có docker)

### 1.1. Tạo 2 project trong Harbor UI

- **`dockerhub`** — chứa image nền mirror từ Docker Hub. Đặt **public** để khỏi cần pull secret cho image nền.
- **`idp`** — chứa image app. Để **private**.

Tạo thêm 1 **robot account** cho project `idp` (quyền push + pull), ghi lại username (`robot$idp+ci`) và password.

### 1.2. Load và push

```bash
docker load -i idp-offline/images/base-images.tar
docker login HARBOR   # tài khoản có quyền push vào cả 2 project

for img in node:20-alpine nginx:1.27-alpine postgres:16-alpine traefik:v3.1; do
  docker tag "$img" "HARBOR/dockerhub/library/$img"
  docker push "HARBOR/dockerhub/library/$img"
done
```

---

## Bước 2 — Trỏ code về Harbor (sửa 4 dòng, một lần)

Vì không có internet, mọi `FROM`/`image:` phải trỏ Harbor:

| File | Dòng cũ | Đổi thành |
|---|---|---|
| `app-repos/notes-app/backend/Dockerfile` | `FROM node:20-alpine` | `FROM HARBOR/dockerhub/library/node:20-alpine` |
| `app-repos/notes-app/frontend/Dockerfile` | `FROM node:20-alpine AS build` | `FROM HARBOR/dockerhub/library/node:20-alpine AS build` |
| `app-repos/notes-app/frontend/Dockerfile` | `FROM nginx:1.27-alpine` | `FROM HARBOR/dockerhub/library/nginx:1.27-alpine` |
| `platform-repo/score/provisioners/onprem.provisioners.yaml` | `image: postgres:16-alpine` | `image: HARBOR/dockerhub/library/postgres:16-alpine` |

Lưu ý thêm: frontend chạy `npm install` lúc build — máy build docker phải với được **npm registry nội bộ** (Nexus/Verdaccio) nếu có; nếu không, build image frontend/backend ngay trên máy có internet ở Bước 0 rồi `docker save` mang vào luôn (bỏ qua build ở Bước 5, chỉ tag + push).

```bash
# Phương án build sẵn từ nhà (khuyên dùng nếu công ty không có npm mirror):
cd v2/app-repos/notes-app
docker build -t notes-app-frontend:v1 frontend/
docker build -t notes-app-backend:v1  backend/
docker save -o ../../..//idp-offline/images/notes-app.tar notes-app-frontend:v1 notes-app-backend:v1
```

---

## Bước 3 — Chuẩn bị cụm K8s

### 3.1. Kiểm tra storageclass Rook Ceph

```bash
kubectl get storageclass
```

Provisioner đang khai `rook-ceph-block`. Nếu cụm đặt tên khác → sửa `storageClassName` trong `platform-repo/score/provisioners/onprem.provisioners.yaml` (một dòng).

### 3.2. Cài Traefik (bỏ qua nếu đã có)

```bash
tar xzf idp-offline/bin/helm-v3.15.4-linux-amd64.tar.gz && sudo mv linux-amd64/helm /usr/local/bin/

helm install traefik idp-offline/charts/traefik-<version>.tgz \
  --namespace traefik --create-namespace \
  --set image.registry=HARBOR/dockerhub \
  --set image.repository=library/traefik \
  --set image.tag=v3.1 \
  --set service.type=NodePort \
  --set ports.web.nodePort=30080

kubectl get pods -n traefik   # chờ Running
```

### 3.3. Cài công cụ lên máy thao tác (máy có kubectl trỏ vào cụm)

```bash
cd idp-offline/bin
tar xzf score-k8s_0.15.0_linux_amd64.tar.gz score-k8s && sudo mv score-k8s /usr/local/bin/
sudo install -m 0755 yq /usr/local/bin/yq
score-k8s --version && yq --version
```

---

## Bước 4 — Deploy notes-app

### 4.1. Nếu build tại chỗ (công ty có npm mirror)

```bash
cd v2/app-repos/notes-app
REGISTRY=HARBOR/idp \
HARBOR_USERNAME='robot$idp+ci' \
HARBOR_PASSWORD='<password-robot>' \
bash scripts/deploy-local.sh
```

### 4.2. Nếu dùng image build sẵn từ nhà (Bước 2)

```bash
# đẩy image app vào Harbor
docker load -i idp-offline/images/notes-app.tar
docker login HARBOR -u 'robot$idp+ci'
docker tag notes-app-frontend:v1 HARBOR/idp/notes-app-frontend:v1
docker tag notes-app-backend:v1  HARBOR/idp/notes-app-backend:v1
docker push HARBOR/idp/notes-app-frontend:v1
docker push HARBOR/idp/notes-app-backend:v1

# chạy script nhưng BỎ bước build (script build lại sẽ fail vì không có npm):
# cách nhanh: comment vòng lặp docker build/push trong scripts/deploy-local.sh,
# rồi chạy với TAG=v1 để render trỏ đúng image đã push:
cd v2/app-repos/notes-app
REGISTRY=HARBOR/idp TAG=v1 \
HARBOR_USERNAME='robot$idp+ci' HARBOR_PASSWORD='<password>' \
bash scripts/deploy-local.sh
```

Script sẽ: render manifest (score-k8s + provisioner onprem + patch staging, tự tiêm `imagePullSecrets`) → tạo namespace `notes-app-staging`, secret `harbor-pull`, secret DB (create-if-missing) → `kubectl apply`.

### 4.3. Kiểm tra

```bash
kubectl get pods,pvc -n notes-app-staging
# Mong đợi: frontend, backend Running; backend-db-0 Running; PVC Bound (rook-ceph-block)
kubectl get ingressroute -n notes-app-staging
```

### 4.4. Truy cập

```bash
# Máy của bạn: thêm vào /etc/hosts
#   NODE_IP  notes.local
# Mở trình duyệt: http://notes.local:30080/
# Hoặc test API không cần /etc/hosts:
curl -H 'Host: notes.local' http://NODE_IP:30080/api/health   # {"ok":true}
```

Demo hay: tạo vài note → `kubectl delete pod backend-db-0 -n notes-app-staging` → pod tự lên lại, note còn nguyên (dữ liệu trên PVC Ceph).

### 4.5. Gỡ

```bash
kubectl delete namespace notes-app-staging
```

---

## Xử lý sự cố nhanh

| Triệu chứng | Nguyên nhân thường gặp | Cách xử |
|---|---|---|
| `ImagePullBackOff` (frontend/backend) | thiếu secret `harbor-pull`, robot sai quyền | `kubectl get secret harbor-pull -n notes-app-staging`; kiểm tra robot pull được project `idp` |
| `ImagePullBackOff` (backend-db-0) | chưa đổi image postgres sang Harbor (Bước 2) | sửa provisioner rồi chạy lại script |
| PVC `Pending` | tên storageclass không phải `rook-ceph-block` | Bước 3.1 |
| `404` khi curl | Traefik chưa có entryPoint web / sai nodePort | `kubectl get svc -n traefik`, xem port thật |
| backend `CrashLoopBackOff` | DB chưa lên kịp (backend có retry 60s) hoặc secret DB sai | `kubectl logs backend-... -n notes-app-staging` |

---

## Bước 5 (làm sau) — Chuyển sang đường GHES Actions + ArgoCD

Không cần cho buổi test, nhưng cần khi vận hành thật. Điểm khác biệt với GitHub cloud:

1. **Runner**: GHES không có runner của GitHub — cài self-hosted runner (một VM/container trong mạng) cho platform-repo (bắt buộc, vì orchestrator cần với tới API cụm) và cho app repo (build). Đổi `runs-on: ubuntu-latest` → `runs-on: self-hosted` trong các workflow.
2. **Action bên thứ 3** (`docker/login-action`, `docker/build-push-action`) không tự tải được trên GHES air-gap — thay bằng lệnh `docker login/build/push` thuần trong `run:` (hoặc sync action vào GHES). `actions/checkout` có sẵn (bundled).
3. **score-k8s trong orchestrator**: không tải từ github.com được — cài sẵn binary lên runner (orchestrator đã sửa: chỉ tải khi máy chưa có, có sẵn thì dùng luôn).
4. **URL dispatch**: các workflow đã dùng `${{ github.api_url }}` nên tự đúng trên GHES (`https://<ghes>/api/v3`) — không phải sửa.
5. **ArgoCD**: mirror image ArgoCD vào Harbor rồi cài theo `platform-repo/bootstrap/onprem.md` (manifest install cần sửa image về Harbor), apply `argocd/project.yaml` + `appset-onprem.yaml`, tạo secret `github-token` trỏ GHES.
