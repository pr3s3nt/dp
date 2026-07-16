# notes-app-config — config repo của notes-app (ArgoCD đọc)

Cùng quy ước với shop-app-config: máy ghi (CI/promote), người chỉ review. Không Secret, không sửa tay.

```
notes-app-config/
├── onprem/{staging,prod}/manifests.yaml
└── cloud/{staging,prod}/manifests.yaml   # Giai đoạn 2
```
