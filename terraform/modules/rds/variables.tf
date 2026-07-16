variable "identifier" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "eks_node_security_group_id" { type = string }

variable "engine_version" {
  type    = string
  default = "16"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "username" {
  type    = string
  default = "app"
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
