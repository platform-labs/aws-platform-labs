variable "aws_region" {
  description = "AWS region for this lab."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for Lab 2 resource names."
  type        = string
  default     = "csnp-wallet"
}

variable "vpc_id" {
  description = "VPC ID used by the ALB, ECS tasks, and optional data dependencies."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the ALB and the Fargate tasks (needs at least 2 AZs for the ALB)."
  type        = list(string)
}

variable "create_data_dependencies" {
  description = "Create the RDS PostgreSQL instance and S3 bucket needed by the app. Set false only when reusing existing Lab 1 resources."
  type        = bool
  default     = true
}

variable "rds_security_group_id" {
  description = "Existing RDS security group ID. Used only when create_data_dependencies=false."
  type        = string
  default     = ""
}

variable "container_image" {
  description = "Full ECR image URI including tag, e.g. <account-id>.dkr.ecr.us-east-1.amazonaws.com/csnp-wallet-api:v1. Push the image first (see docs/lab-02-hands-on.md Step 2-3), Terraform does not build/push images."
  type        = string
}

variable "container_port" {
  description = "Container port exposed by the Wallet API."
  type        = number
  default     = 5000
}

variable "task_cpu" {
  description = "0.25 vCPU, matches the manual Task Definition."
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "0.5 GB, matches the manual Task Definition."
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Desired number of ECS service tasks."
  type        = number
  default     = 2
}

variable "assign_public_ip" {
  description = "Enable when running Fargate tasks in public subnets. Disable only when the subnets have NAT/private egress."
  type        = bool
  default     = true
}

variable "db_host" {
  description = "Existing RDS endpoint. Used only when create_data_dependencies=false."
  type        = string
  default     = ""
}

variable "rds_identifier" {
  description = "RDS identifier to create when create_data_dependencies=true."
  type        = string
  default     = "csnp-wallet-dev"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16"
}

variable "db_instance_class" {
  description = "RDS instance class for the lab."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS storage in GB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "PostgreSQL database name."
  type        = string
  default     = "wallet"
}

variable "db_username" {
  description = "PostgreSQL master username."
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL master password. Supply through a gitignored tfvars file or TF_VAR_db_password."
  type        = string
  sensitive   = true
}

variable "s3_bucket" {
  description = "S3 bucket name to create or reuse."
  type        = string
  default     = "csnp-wallet-dev"
}
