# terraform — Giai đoạn 2: hạ tầng cloud (VPC + EKS + RDS)

Terraform chỉ dựng hạ tầng và nối nó vào platform. **Không deploy app** — app vẫn đi Score + GitOps y như onprem.

```
terraform/
├── modules/
│   ├── vpc/    # bọc terraform-aws-modules/vpc (tag sẵn cho EKS/ALB)
│   ├── eks/    # bọc terraform-aws-modules/eks (managed node group)
│   └── rds/    # 1 instance Postgres / app / env + SG chỉ mở cho node EKS
└── envs/
    ├── staging/  # 2 AZ, 1 NAT, t3.medium ×2, db.t4g.micro
    └── prod/     # 3 AZ, NAT/AZ, m5.large ×3, db.t4g.medium multi-AZ + deletion protection
```

## Điểm nối Terraform ↔ platform Score

Env ghi output RDS thành K8s Secret `<workload>-db-credentials` trong namespace `<app>-<env>` (resource `kubernetes_secret` trong `envs/*/main.tf`). Provisioner `cloud.provisioners.yaml` (type `postgres`) cho app đọc đúng Secret đó qua `secretKeyRef`. App không đổi một dòng nào so với onprem.

## Trình tự chạy (mỗi env)

```bash
cd envs/staging
terraform init      # TODO trước đó: tạo bucket S3 + bảng DynamoDB lock, sửa backend
terraform plan
terraform apply

# Nối cụm mới vào ArgoCD (chạy ở cụm onprem):
aws eks update-kubeconfig --name idp-staging --alias eks-staging
argocd cluster add eks-staging --name eks-staging   # tên phải khớp appset-cloud.yaml

# Bật nhánh cloud:
kubectl apply -f ../../platform-repo/argocd/appset-cloud.yaml
# và trong app repo: đổi TARGETS="onprem cloud" trong ci.yaml
```

## Việc còn phải làm trước khi lên thật

- Cài **AWS Load Balancer Controller** lên EKS (provisioner `route` cloud sinh Ingress class `alb`) — cài bằng Helm hoặc thêm module terraform (aws-ia/eks-blueprints-addons).
- Thay `your-org`, region, CIDR theo thực tế.
- Thêm app mới có DB: thêm block `module "<app>_db"` + `kubernetes_secret` tương ứng trong từng env.
- Cân nhắc RDS riêng cho từng service khi tải tăng (hiện các service của 1 app dùng chung 1 instance, khác Secret).
- Password RDS nằm trong tfstate → bucket S3 bắt buộc private + encrypt + versioning.
