# RDS PostgreSQL for the Wallet API
#
# This is the database tier (Private Data Subnet) - same role as the RDS instance
# from Lab 1, but now created via Terraform as part of the platform stack (not
# as a separate manual operation).
#
# Key differences from Lab 1:
#   - Placed explicitly in Private Data Subnet (multi-AZ via DB Subnet Group)
#   - Security Group only allows inbound from ECS SG on port 5432
#   - No public IP assignment
#   - KMS encryption at rest (best practice even for labs)

# --- DB Subnet Group ---
#
# RDS requires a DB Subnet Group to specify which subnets it can be deployed to.
# AWS creates the subnet group from the private data subnets passed in from Lab 4.

resource "aws_db_subnet_group" "wallet" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_data_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# --- RDS Instance ---

resource "aws_db_instance" "wallet_db" {
  identifier            = "${var.project_name}-wallet-db"
  engine                = "postgres"
  engine_version        = "16.14" # match Lab 1 baseline
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 100 # auto-scaling if needed
  storage_encrypted     = true
  storage_type          = "gp3"

  # Database & credentials
  db_name  = var.db_name
  username = var.db_user
  password = var.db_password # Known gap: plain variable, not Secrets Manager
  # Moving to Secrets Manager is Lab 6/7 work

  # Networking
  db_subnet_group_name   = aws_db_subnet_group.wallet.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false

  # Backups & maintenance (lab defaults)
  backup_retention_period = 0
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"
  skip_final_snapshot     = true # lab only - remove for production

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Name = "${var.project_name}-wallet-db"
  }

  depends_on = [aws_db_subnet_group.wallet]
}

# --- Output RDS endpoint for reference ---
#
# The task definition will use `aws_db_instance.wallet_db.address` directly
# via interpolation - no need for a separate output here, but we export it
# for reference and for logging to show what was created.
