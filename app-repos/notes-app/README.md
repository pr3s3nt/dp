# notes-app — React (Vite) + Express + PostgreSQL trên IDP

App demo để test platform trên cụm onprem (Rook Ceph). 2 service + 1 DB:

```
notes-app/
├── frontend/    # React (Vite) build tĩnh, nginx serve — route /      (type: route)
├── backend/     # Express CRUD /api/notes — route /api               (type: route)
│                #   + db: {type: postgres} -> StatefulSet trên rook-ceph-block
├── scripts/deploy-local.sh   # TEST NHANH không cần CI/ArgoCD (xem dưới)
└── .github/workflows/        # ci.yaml + promote.yaml (đường GitOps đầy đủ)
```

Cùng host `notes.local`, Traefik tách theo path: `/` → frontend, `/api` → backend. Backend tự serve dưới prefix `/api` (Traefik PathPrefix không strip).

## Test nhanh ngày mai (không cần GitHub/ArgoCD)

Chuẩn bị trên máy: `docker`, `kubectl` (context trỏ đúng cụm), `score-k8s` 0.15.0, `yq` v4, và một registry mà cụm pull được.

```bash
cd notes-app
REGISTRY=<registry-cụm-pull-được> bash scripts/deploy-local.sh
```

Script làm đúng trình tự CI sẽ làm: build 2 image → `score-k8s generate` (provisioner onprem + patch staging) → tách Secret apply riêng (create-if-missing) → `kubectl apply` vào namespace `notes-app-staging`.

Kiểm tra kết quả:

```bash
kubectl get pods,pvc -n notes-app-staging        # PVC phải Bound (rook-ceph-block)
kubectl get ingressroute -n notes-app-staging

# Truy cập: thêm vào /etc/hosts của máy bạn
#   <IP-node-chạy-Traefik>  notes.local
# rồi mở http://notes.local:<nodePort web của Traefik>/
# Test API nhanh không cần /etc/hosts:
curl -H 'Host: notes.local' http://<IP-node>:<port>/api/health
```

Bài test đáng làm: tạo vài note → `kubectl delete pod backend-db-0 -n notes-app-staging` → pod tự lên lại, note vẫn còn (dữ liệu nằm trên PVC Ceph, không theo pod).

Gỡ sạch: `kubectl delete namespace notes-app-staging` (PVC sẽ bị xóa theo namespace).

## Nếu tên storageclass khác `rook-ceph-block`

```bash
kubectl get storageclass
```

Sửa `storageClassName` trong `platform-repo/score/provisioners/onprem.provisioners.yaml` (một chỗ duy nhất, mọi app hưởng). Script cũng tự cảnh báo nếu không thấy.

## Dev local (không cần cụm)

```bash
# DB tạm
docker run -d --name notes-db -e POSTGRES_PASSWORD=dev -e POSTGRES_DB=appdb -p 5432:5432 postgres:16-alpine
# backend
cd backend && npm install
DB_HOST=localhost DB_PORT=5432 DB_NAME=appdb DB_USER=postgres DB_PASSWORD=dev npm start
# frontend (vite proxy /api -> localhost:8080)
cd frontend && npm install && npm run dev
```

## Đường GitOps đầy đủ (sau khi test tay OK)

Mô hình orchestrator: CI repo này **chỉ build image lên Harbor + gọi platform**; render/secret/commit do `platform-repo/.github/workflows/orchestrator.yaml` làm. Cần: tạo repo `notes-app` + `notes-app-config`, secrets cho repo app (`HARBOR_USERNAME/PASSWORD`, `PLATFORM_DISPATCH_TOKEN`), secrets cho platform-repo (xem `platform-repo/README.md`), sửa `your-org`/`harbor.example.com` trong workflows. Push main là staging tự lên; promote bằng nút Actions → promote.
