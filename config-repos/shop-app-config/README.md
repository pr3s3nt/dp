# shop-app-config — config repo của app shop-app (ArgoCD đọc repo này)

**Quy ước platform: 1 app = 1 config repo, tên `<app>-config`.**
ApplicationSet của ArgoCD tự quét org tìm repo `*-config` → tạo repo này xong là ArgoCD tự nhận, không phải khai báo gì thêm.

```
shop-app-config/
├── onprem/
│   ├── staging/manifests.yaml   # CI ghi mỗi lần push main (ArgoCD auto-sync)
│   └── prod/manifests.yaml     # chỉ thay đổi qua nút promote (ArgoCD manual sync)
└── cloud/
    ├── staging/manifests.yaml   # Giai đoạn 2
    └── prod/manifests.yaml
```

## Quy tắc

- **Không sửa tay file trong repo này.** Toàn bộ manifest do `score-k8s` render từ `score.yaml` + provisioner + patch env. Người chỉ đọc/review, máy ghi.
- **Không bao giờ có Secret trong repo này** — CI đã tách Secret ra và apply thẳng lên cụm.
- Lịch sử git của repo này = lịch sử deploy. Rollback = revert commit (hoặc promote tag cũ).
- Manifest là bản render sẵn hoàn chỉnh — ArgoCD sync nguyên thư mục, không Kustomize/Helm.
