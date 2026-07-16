# Module EKS — bọc terraform-aws-modules/eks. Dừng ở: cụm chạy được + node group.
# Terraform KHÔNG deploy app — app đi đường Score + GitOps y như onprem.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Cho phép ArgoCD (chạy ở cụm onprem) gọi API server:
  cluster_endpoint_public_access = true

  # Người chạy terraform có quyền admin cụm (tiện bootstrap; siết lại sau):
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      instance_types = var.instance_types
      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.desired_size
    }
  }

  tags = var.tags
}
