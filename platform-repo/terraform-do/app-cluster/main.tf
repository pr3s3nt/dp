# =============================================================================
# ROOT app-cluster — dựng hạ tầng cho MỘT app: VPC + cụm DOKS "idp-<app>".
# Tái dùng cho mọi app: truyền -var app_name=<app>. Mô hình "mỗi app một cụm
# riêng" (khớp platform-repo/clusters/placement/<app>.yaml).
#
# Token DO: biến môi trường DIGITALOCEAN_TOKEN (KHÔNG commit token).
#
# STATE: mặc định local (đủ cho demo). Production nên dùng DO Spaces (S3-compat) —
# xem backend.tf.example. Trong pipeline, state được guard bằng existence-check
# (workflow bỏ qua apply nếu cụm đã tồn tại) nên mất state local không tạo trùng.
# =============================================================================
terraform {
  required_version = ">= 1.6"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.40"
    }
  }
}

provider "digitalocean" {
  # token đọc từ env DIGITALOCEAN_TOKEN
}

variable "app_name" {
  description = "Tên app (dùng đặt tên cụm idp-<app>)."
  type        = string
}

variable "region" {
  type    = string
  default = "sgp1"
}

variable "node_size" {
  type    = string
  default = "s-2vcpu-4gb"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "create_cluster" {
  description = "false -> chỉ VPC (khi droplet quota hết). true -> tạo cả cụm."
  type        = bool
  default     = true
}

module "cluster" {
  source = "../modules/doks"

  name           = "idp-${var.app_name}"
  region         = var.region
  node_size      = var.node_size
  node_count     = var.node_count
  create_cluster = var.create_cluster
  tags           = ["idp", "app:${var.app_name}"]
}

output "cluster_name" { value = module.cluster.cluster_name }
output "cluster_id" { value = module.cluster.cluster_id }
output "vpc_id" { value = module.cluster.vpc_id }
output "k8s_version" { value = module.cluster.k8s_version }
