resource "aws_security_group" "msk" {
  name   = "csnp-lab12b-msk"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 9098
    to_port         = 9098
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

resource "aws_msk_serverless_cluster" "main" {
  cluster_name = "csnp-lab12b-msk-serverless"

  vpc_config {
    subnet_ids         = var.private_app_subnet_ids
    security_group_ids = [aws_security_group.msk.id]
  }

  client_authentication {
    sasl {
      iam {
        enabled = true
      }
    }
  }
}
