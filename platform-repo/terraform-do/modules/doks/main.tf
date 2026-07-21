# =============================================================================
# Module doks — VPC + cụm DOKS cho một app. Terraform CHỈ dựng hạ tầng;
# app vẫn deploy qua Score + GitOps (do-orchestrator + ArgoCD). Cùng triết lý
# với terraform/ (AWS) nhưng cho DigitalOcean.
# =============================================================================
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.40"
    }
  }
}

# Bản k8s mới nhất khớp prefix (vd "1.36.") — tránh hardcode patch version.
data "digitalocean_kubernetes_versions" "this" {
  version_prefix = var.k8s_version
}

resource "digitalocean_vpc" "this" {
  name     = "${var.name}-vpc"
  region   = var.region
  ip_range = var.vpc_ip_range
}

resource "digitalocean_kubernetes_cluster" "this" {
  count = var.create_cluster ? 1 : 0

  name         = var.name
  region       = var.region
  version      = data.digitalocean_kubernetes_versions.this.latest_version
  vpc_uuid     = digitalocean_vpc.this.id
  auto_upgrade = false
  tags         = var.tags

  # ha=false (control plane không HA) cho rẻ — cụm test.
  node_pool {
    name       = "pool-default"
    size       = var.node_size
    node_count = var.node_count
    auto_scale = false
  }

  # DOKS đôi khi provision node rất chậm (đã gặp ~30–60 phút) -> nới timeout
  # để terraform không bỏ cuộc giữa chừng.
  timeouts {
    create = "60m"
  }
}
