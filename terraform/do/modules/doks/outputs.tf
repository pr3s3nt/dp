output "vpc_id" {
  value = digitalocean_vpc.this.id
}

output "cluster_id" {
  description = "ID cụm (rỗng nếu create_cluster=false)."
  value       = try(digitalocean_kubernetes_cluster.this[0].id, "")
}

output "cluster_name" {
  value = var.name
}

output "endpoint" {
  value = try(digitalocean_kubernetes_cluster.this[0].endpoint, "")
}

output "k8s_version" {
  value = data.digitalocean_kubernetes_versions.this.latest_version
}
