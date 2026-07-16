# shop-app — app microservices mẫu chạy trên IDP

4 service, mỗi service một thư mục + một `score.yaml`. Dev chỉ viết code + `score.yaml`; không viết Deployment/IngressRoute/Secret nào cả.

```
shop-app/
├── frontend/          # nginx tĩnh, route /            (type: route)
├── api-gateway/       # /api -> gọi orders + payments  (type: service ×2, route)
├── order-service/     # Postgres riêng + gọi payments  (type: postgres, service)
├── payment-service/   # Postgres riêng, chỉ nội bộ     (type: postgres)
└── .github/workflows/
    ├── ci.yaml        # push main -> build + render + commit sang shop-app-config (staging)
    └── promote.yaml   # NÚT promote: đổi tag prod trong config repo (không build lại)
```

## Vòng đời một thay đổi (mô hình orchestrator)

1. Sửa code / `score.yaml`, push `main`.
2. CI **chỉ build** 4 image lên Harbor (tag = git SHA) rồi gọi platform (repository_dispatch).
3. **Orchestrator** ở platform-repo nhận yêu cầu: render manifest (provisioner + patch), apply Secret lên cụm, commit sang `shop-app-config/onprem/staging/` → ArgoCD tự sync staging.
4. Test trên staging.
5. Bấm **Actions → promote**, nhập SHA → orchestrator tạo commit đổi tag trong `onprem/prod/manifests.yaml` → vào ArgoCD bấm Sync app `shop-app-prod-onprem`.
   - Nếu thay đổi có sửa `score.yaml` (thêm env/service/resource): chọn mode `re-render`.
6. Rollback: promote lại tag cũ.

## Secrets cần cấu hình cho repo này (Settings → Secrets → Actions)

| Secret | Dùng cho |
|---|---|
| `HARBOR_USERNAME` / `HARBOR_PASSWORD` | robot account Harbor có quyền push vào project |
| `PLATFORM_DISPATCH_TOKEN` | PAT bắn repository_dispatch sang platform-repo |

(Kubeconfig, token config repo... nằm hết ở platform-repo — repo app không giữ credential hạ tầng.)

## Thêm service thứ 5?

Tạo thư mục mới + `score.yaml`, thêm tên vào matrix build trong `ci.yaml`. Orchestrator tự phát hiện mọi thư mục có `score.yaml` — không phải khai báo gì thêm phía platform.

## Cần DB/route/gọi service khác?

Khai trong `resources:` của `score.yaml` — xem 4 file có sẵn làm mẫu. Danh sách `type` platform hỗ trợ: `postgres`, `route`, `service` (hỏi team hạ tầng khi cần thêm loại mới).
