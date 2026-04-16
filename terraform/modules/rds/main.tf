resource "random_password" "db_password" {
    length = 24
    special = true
    override_special = "!#$%^&*()-_=+"
}

resource "aws_db_subnet_group" "this" {
    name = "${var.name}-subnet-group"
    subnet_ids = var.subnet_ids

    tags = { Name = var.name }
}

resource "aws_security_group" "this" {
    name = "${var.name}-sg"
    vpc_id = var.vpc_id

    ingress {
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        security_groups = [var.allowed_security_group_id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["10.0.0.0/16"] #VPC only
    }

    tags = { Name = var.name }
}

resource "aws_db_instance" "this" {
    identifier = var.name
    engine = "postgres"
    engine_version = "15.7"

    instance_class = "db.t3.micro"
    allocated_storage = 20
    max_allocated_storage = 20

    db_name = "weather_db"
    username = "app_user"
    password = random_password.db_password.result

    db_subnet_group_name = aws_db_subnet_group.this.name
    vpc_security_group_ids = [aws_security_group.this.id]
    publicly_accessible = false

    skip_final_snapshot       = true  # no snapshot on delete (dev only!)
    backup_retention_period   = 0     # no backups (dev only!)
    deletion_protection       = false # allow easy cleanup

    storage_encrypted = true

    tags = {
    Name        = var.name
    Environment = var.environment
  }
}

