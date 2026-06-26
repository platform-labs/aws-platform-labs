# Lab 1 - EC2 + RDS PostgreSQL + S3 + IAM Role + CloudWatch
#
# This was originally done by hand in the AWS Console (see docs/lab-01-hands-on.md).
# This file recreates the Console walkthrough in Terraform - flat resources on
# purpose, no module reuse from platforms/aws/terraform/modules/. The point of
# this lab is to understand each resource directly, not to abstract it yet.
#
# TODO before first apply:
#   - fill terraform.tfvars (copy from terraform.tfvars.example, never commit it)
#   - confirm vpc_id / subnet_ids for the default VPC in your account
#   - generate an EC2 key pair manually and reference it via key_pair_name

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# --- IAM Role for EC2 (no static access keys, per lab-01-interview-notes.md) ---

resource "aws_iam_role" "ec2_wallet_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Lab uses the AWS-managed policies for simplicity. Production should replace
# this with a custom least-privilege policy scoped to the exact bucket/actions.
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.ec2_wallet_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_wallet_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_wallet_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_wallet_role.name
}

# --- Security Groups ---

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "SG for the Wallet API EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = "HTTP public for later reverse proxy labs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS public for later reverse proxy labs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kestrel direct test from my IP only"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "SG for RDS - only reachable from the EC2 SG, not from the internet"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EC2 SG only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- S3 Bucket ---

resource "aws_s3_bucket" "wallet_dev" {
  bucket = var.project_name
}

resource "aws_s3_bucket_public_access_block" "wallet_dev" {
  bucket = aws_s3_bucket.wallet_dev.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "wallet_dev" {
  bucket = aws_s3_bucket.wallet_dev.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "wallet_dev" {
  bucket = aws_s3_bucket.wallet_dev.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --- RDS PostgreSQL ---

resource "aws_db_subnet_group" "wallet" {
  name       = "${var.project_name}-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "wallet_dev" {
  identifier                   = var.project_name
  engine                       = "postgres"
  engine_version               = var.db_engine_version
  instance_class               = var.db_instance_class
  allocated_storage            = var.db_allocated_storage
  max_allocated_storage        = 0 # storage autoscaling disabled
  db_name                      = var.db_name
  username                     = var.db_username
  password                     = var.db_password
  db_subnet_group_name         = aws_db_subnet_group.wallet.name
  vpc_security_group_ids       = [aws_security_group.rds_sg.id]
  publicly_accessible          = false
  multi_az                     = false
  backup_retention_period      = 0
  performance_insights_enabled = false
  monitoring_interval          = 0
  auto_minor_version_upgrade   = true
  skip_final_snapshot          = true # lab only - never do this for production RDS
}

# --- CloudWatch Log Group ---

resource "aws_cloudwatch_log_group" "wallet_api" {
  name              = "${var.project_name}-api"
  retention_in_days = 7
}

# --- EC2 Instance ---

resource "aws_instance" "wallet_api" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = var.subnet_ids[0]
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_wallet_profile.name
  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    dnf update -y
    dnf install -y amazon-cloudwatch-agent postgresql16 aspnetcore-runtime-10.0

    mkdir -p /var/log/app /home/ec2-user/wallet-api
    chown ec2-user:ec2-user /var/log/app /home/ec2-user/wallet-api

    cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/app/application.log",
                "log_group_name": "${aws_cloudwatch_log_group.wallet_api.name}",
                "log_stream_name": "{instance_id}",
                "timezone": "UTC"
              }
            ]
          }
        }
      }
    }
    CWCONFIG

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
      -s

    cat >/home/ec2-user/wallet-api/env.example <<'APPENV'
    export DB_HOST=${aws_db_instance.wallet_dev.address}
    export DB_PORT=5432
    export DB_NAME=${var.db_name}
    export DB_USER=${var.db_username}
    export DB_PASSWORD=<your-password>
    export S3_BUCKET=${aws_s3_bucket.wallet_dev.bucket}
    export ASPNETCORE_URLS=http://+:5000
    APPENV
    chown ec2-user:ec2-user /home/ec2-user/wallet-api/env.example
  EOF

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "${var.project_name}-ec2"
  }
}
