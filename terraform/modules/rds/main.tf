# Module RDS — một instance Postgres cho MỘT app trong MỘT env.
# Password sinh ngẫu nhiên, giữ trong tfstate (backend S3 phải bật encrypt).
# Env sẽ lấy output của module này ghi thành K8s Secret <workload>-db-credentials
# để provisioner cloud của Score nối app vào (xem envs/*/main.tf).

resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnets"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "db" {
  name   = "${var.identifier}-db"
  vpc_id = var.vpc_id

  # Chỉ cho node EKS nói chuyện với DB:
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_db_instance" "this" {
  identifier     = var.identifier
  engine         = "postgres"
  engine_version = var.engine_version

  instance_class    = var.instance_class # staging: db.t4g.micro, prod: to hơn
  allocated_storage = var.allocated_storage
  multi_az          = var.multi_az       # prod: true

  db_name  = var.db_name
  username = var.username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  skip_final_snapshot = var.skip_final_snapshot # prod: false
  deletion_protection = var.deletion_protection # prod: true

  tags = var.tags
}
