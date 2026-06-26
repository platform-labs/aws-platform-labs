resource "aws_security_group" "mq" {
  name   = "csnp-lab12a-mq"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5671
    to_port         = 5671
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_mq_broker" "rabbitmq" {
  broker_name                = "csnp-lab12a-rabbitmq"
  engine_type                = "RABBITMQ"
  engine_version             = "3.13"
  host_instance_type         = var.host_instance_type
  deployment_mode            = "SINGLE_INSTANCE"
  publicly_accessible        = false
  auto_minor_version_upgrade = true
  subnet_ids                 = [var.private_app_subnet_ids[0]]
  security_groups            = [aws_security_group.mq.id]

  logs {
    general = true
  }

  user {
    username = var.broker_username
    password = var.broker_password
  }
}
