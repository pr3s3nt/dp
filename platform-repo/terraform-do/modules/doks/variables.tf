# Module doks — dựng 1 cụm DOKS (+ VPC) cho MỘT app trên DigitalOcean.
variable "name" {
  description = "Tên cụm (đồng thời prefix cho VPC). Vd idp-notes-app."
  type        = string
}

variable "region" {
  description = "Region DO (vd sgp1)."
  type        = string
  default     = "sgp1"
}

variable "k8s_version" {
  description = "Prefix phiên bản k8s (vd 1.36.). Lấy bản mới nhất khớp prefix."
  type        = string
  default     = "1.36."
}

variable "node_size" {
  description = "Slug node pool (vd s-2vcpu-4gb — nhỏ nhất chạy được stack)."
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Số node cố định (auto_scale=false cho rẻ/đơn giản)."
  type        = number
  default     = 1
}

variable "vpc_ip_range" {
  description = "CIDR cho VPC riêng của cụm."
  type        = string
  default     = "10.20.0.0/16"
}

variable "create_cluster" {
  description = "false -> chỉ tạo VPC (bỏ cụm). Dùng khi droplet quota hết mà vẫn muốn apply phần không tốn quota."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tag gắn cho cụm."
  type        = list(string)
  default     = []
}
