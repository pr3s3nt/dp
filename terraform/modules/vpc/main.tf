# Module VPC — bọc module chính thức terraform-aws-modules/vpc.
# Mỗi env (staging/prod) gọi module này với sizing riêng.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway # staging: true (rẻ), prod: false (HA)

  enable_dns_hostnames = true

  # Tags bắt buộc để EKS/ALB controller tìm được subnet:
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = var.tags
}
