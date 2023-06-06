resource "aws_db_subnet_group" "rds" {
  name       = var.name
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "rds" {
  name   = var.name
  vpc_id = var.vpc_id

  ingress {
    description = "postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage         = var.allocated_storage
  identifier                = var.name
  snapshot_identifier       = var.snapshot_arn
  engine                    = var.engine
  engine_version            = var.engine_version
  instance_class            = var.instance_class
  db_subnet_group_name      = var.name
  skip_final_snapshot       = false
  final_snapshot_identifier = var.name
  vpc_security_group_ids    = [aws_security_group.rds.id]
  depends_on                = [aws_db_subnet_group.rds]
}
