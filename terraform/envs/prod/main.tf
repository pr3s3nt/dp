# =============================================================================
# ENV: PROD (cloud) — cùng module với staging, KHÁC sizing/độ bền:
#   NAT mỗi AZ, node to hơn & nhiều hơn, RDS multi-AZ + deletion protection.
# =============================================================================

terraform {
  required_version = ">= 1.6"

  backend "s3" {
    bucket         = "your-org-tfstate"        # TODO
    key            = "idp/prod/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "your-org-tflock"         # TODO
    encrypt        = true
  }

  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.30" }
    random     = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

locals {
  env    = "prod"
  region = "ap-southeast-1" # TODO
  tags = {
    env       = local.env
    managedby = "terraform"
    project   = "idp"
  }
}

provider "aws" {
  region = local.region
}

module "vpc" {
  source = "../../modules/vpc"

  name            = "idp-${local.env}"
  cidr            = "10.20.0.0/16"
  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
  public_subnets  = ["10.20.101.0/24", "10.20.102.0/24", "10.20.103.0/24"]

  single_nat_gateway = false # prod: NAT mỗi AZ (HA)
  tags               = local.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name = "idp-${local.env}"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets

  instance_types = ["m5.large"]
  min_size       = 3
  desired_size   = 3
  max_size       = 6

  tags = local.tags
}

module "shop_app_db" {
  source = "../../modules/rds"

  identifier                 = "shop-app-${local.env}"
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnets
  eks_node_security_group_id = module.eks.node_security_group_id

  instance_class      = "db.t4g.medium"
  allocated_storage   = 100
  multi_az            = true
  skip_final_snapshot = false
  deletion_protection = true

  tags = local.tags
}

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

locals {
  shop_app_db_workloads = ["order-service", "payment-service"]
}

resource "kubernetes_secret" "shop_app_db" {
  for_each = toset(local.shop_app_db_workloads)

  metadata {
    name      = "${each.key}-db-credentials"
    namespace = kubernetes_namespace.shop_app.metadata[0].name
  }

  data = {
    host     = module.shop_app_db.host
    port     = tostring(module.shop_app_db.port)
    dbname   = module.shop_app_db.dbname
    username = module.shop_app_db.username
    password = module.shop_app_db.password
    # Xem ghi chú ở envs/staging/main.tf — key `url` là hợp đồng với provisioner cloud.
    url = "postgresql://${module.shop_app_db.username}:${module.shop_app_db.password}@${module.shop_app_db.host}:${module.shop_app_db.port}/${module.shop_app_db.dbname}"
  }
}

output "eks_cluster_name" { value = module.eks.cluster_name }
output "rds_endpoint" { value = module.shop_app_db.host }
