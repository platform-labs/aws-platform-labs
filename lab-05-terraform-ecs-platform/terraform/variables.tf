variable "aws_region" {
  description = "AWS region for this lab."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod) - used for naming and tagging."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Prefix used for resource names."
  type        = string
  default     = "csnp-platform"
}

# --- Network inputs from Lab 4 ---
#
# Lab 5 does NOT create its own VPC/Subnet/NAT/SG for network - it consumes
# the platform foundation built in Lab 4. Two ways to wire this up:
#
#   A) Manual (default): copy the actual output values from `terraform output`
#      in lab-04-terraform-platform-foundation/terraform/ into terraform.tfvars
#      here. This keeps the lab boundary and dependency explicit.
#
#   B) Remote state data source: since Lab 4 uses the labs S3 backend, these
#      variables can later be replaced with `data "terraform_remote_state"`.
#      This is optional and intentionally deferred until the state interface
#      and cross-lab coupling trade-offs have been discussed.
#
# This lab ships with (A).

variable "vpc_id" {
  description = "VPC ID - copy from `terraform output vpc_id` in Lab 4."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs - copy from `terraform output public_subnet_ids` in Lab 4. Used by the ALB."
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "Private app subnet IDs - copy from `terraform output private_app_subnet_ids` in Lab 4. Used by ECS tasks."
  type        = list(string)
}

variable "private_data_subnet_ids" {
  description = "Private data subnet IDs - copy from `terraform output private_data_subnet_ids` in Lab 4. Used by RDS."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB Security Group ID - copy from `terraform output alb_security_group_id` in Lab 4. Already scoped to port 80 from 0.0.0.0/0."
  type        = string
}

variable "ecs_security_group_id" {
  description = "ECS Security Group ID - copy from `terraform output ecs_security_group_id` in Lab 4. Already scoped to accept only from the ALB SG."
  type        = string
}

variable "rds_security_group_id" {
  description = "RDS Security Group ID - copy from `terraform output rds_security_group_id` in Lab 4. Already configured to allow ingress from ECS SG on port 5432."
  type        = string
}

# --- RDS configuration ---

variable "db_name" {
  description = "PostgreSQL database name created when RDS instance initializes."
  type        = string
  default     = "wallet"
}

variable "db_user" {
  description = "PostgreSQL master username."
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "PostgreSQL master password. Known gap: still a plain Terraform variable, not Secrets Manager. Moving this to Secrets Manager is explicitly deferred to Lab 6/7 per the platform roadmap - do not try to fix this here."
  type        = string
  sensitive   = true
}

variable "s3_bucket" {
  description = "S3 bucket name created by Lab 5 Terraform."
  type        = string
  default     = "csnp-platform-wallet-uploads"
}

# --- ECS / container settings ---

variable "container_image" {
  description = "Full ECR image URI, e.g. <account-id>.dkr.ecr.us-east-1.amazonaws.com/csnp-wallet-api:latest. Build/push manually before apply, same as Lab 2."
  type        = string
}

variable "container_port" {
  description = "Container port exposed by the Wallet API."
  type        = number
  default     = 5000
}

variable "task_cpu" {
  description = "Fargate task CPU units. 256 = 0.25 vCPU."
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Fargate task memory in MB. 512 = 0.5 GB."
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Number of ECS tasks to run. 2 for self-healing / no single point of failure, same reasoning as Lab 2."
  type        = number
  default     = 2
}
