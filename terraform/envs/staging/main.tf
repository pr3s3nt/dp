# =============================================================================
# ENV: STAGING (cloud) — sizing nhỏ, tối ưu chi phí.
# Terraform dừng ở: VPC + EKS + RDS + ghi Secret DB vào cụm.
# KHÔNG deploy app — app đi đường Score + GitOps (xem appset-cloud.yaml).
# Sau khi apply: `argocd cluster add --name eks-staging` (xem ../../README.md).
# =============================================================================

terraform {
  required_version = ">= 1.6"

  backend "s3" {
    bucket         = "your-org-tfstate"        # TODO: bucket S3 có versioning + encrypt
    key            = "idp/staging/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "your-org-tflock"         # TODO: bảng lock
    encrypt        = true
  }

  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.30" }
    random     = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

locals {
  env    = "staging"
  region = "ap-southeast-1" # TODO: region của bạn
  tags = {
    env       = local.env
    managedby = "terraform"
    project   = "idp"
  }
}

provider "aws" {
  region = local.region
}

# ---------------------------------------------------------------------------
# Lớp platform: VPC + EKS
# ---------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  name            = "idp-${local.env}"
  cidr            = "10.10.0.0/16"
  azs             = ["${local.region}a", "${local.region}b"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
  public_subnets  = ["10.10.101.0/24", "10.10.102.0/24"]

  single_nat_gateway = true # staging: 1 NAT cho rẻ
  tags               = local.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name = "idp-${local.env}"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets

  instance_types = ["t3.medium"]
  min_size       = 1
  desired_size   = 2
  max_size       = 3

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Lớp per-app: RDS cho shop-app.
# Thêm app mới cần DB = thêm 1 block module "rds" + 1 block secret tương ứng.
# ---------------------------------------------------------------------------
module "shop_app_db" {
  source = "../../modules/rds"

  identifier                 = "shop-app-${local.env}"
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnets
  eks_node_security_group_id = module.eks.node_security_group_id

  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  multi_az          = false

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Ghi Secret DB vào cụm — ĐIỂM NỐI giữa Terraform và Score:
# provisioner cloud (type: postgres) đọc Secret <workload>-db-credentials.
# staging dùng chung 1 instance RDS cho các service của app (tiết kiệm);
# cần tách thì thêm module rds + đổi secret tương ứng.
# ---------------------------------------------------------------------------
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

resource "kubernetes_namespace" "shop_app" {
  metadata {
    name = "shop-app-${local.env}"
  }
}

# Các workload của shop-app có `db: {type: postgres}`:
locals {
  shop_app_db_workloads = ["order-service", "payment-service"]
}

resource "kubernetes_secret" "shop_app_db" {
  for_each = toset(local.shop_app_db_workloads)

  metadata {
    name      = "${each.key}-db-credentials" # convention của provisioner cloud
    namespace = kubernetes_namespace.shop_app.metadata[0].name
  }

  data = {
    host     = module.shop_app_db.host
    port     = tostring(module.shop_app_db.port)
    dbname   = module.shop_app_db.dbname
    username = module.shop_app_db.username
    password = module.shop_app_db.password
    # Connection string ghép sẵn — provisioner cloud (type: postgres) xuất ra
    # ${resources.db.url} từ key này. App một-biến (Prisma...) chỉ đọc DATABASE_URL;
    # onprem/do tự ghép trong provisioner, cloud thì Terraform ghép vì Secret do TF sở hữu.
    url = "postgresql://${module.shop_app_db.username}:${module.shop_app_db.password}@${module.shop_app_db.host}:${module.shop_app_db.port}/${module.shop_app_db.dbname}"
  }
}

output "eks_cluster_name" { value = module.eks.cluster_name }
output "rds_endpoint" { value = module.shop_app_db.host }
