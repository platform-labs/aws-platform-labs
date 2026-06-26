variable "aws_region" {
  description = "AWS region for this lab. Lab 1 was originally run in us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used for the lab S3 bucket and RDS identifier, matching the manual walkthrough."
  type        = string
  default     = "csnp-wallet-dev"
}

variable "vpc_id" {
  description = "VPC to deploy into. The original manual lab used the account's default VPC."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EC2 instance and the RDS subnet group (at least 2 subnets in different AZs for RDS)."
  type        = list(string)
}

variable "ec2_instance_type" {
  description = "EC2 instance type. t3.micro is Free Tier eligible."
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of an EXISTING EC2 key pair. Do not create a new key pair via Terraform for this lab - generate it manually in the console and keep the .pem file out of git (see SECURITY note in the lab README)."
  type        = string
}

variable "my_ip_cidr" {
  description = "Your current public IP in CIDR form (e.g. 203.0.113.10/32), used to restrict SSH access on csnp-ec2-sg."
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class. db.t3.micro is Free Tier eligible."
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version used in the manual walkthrough."
  type        = string
  default     = "16"
}

variable "db_allocated_storage" {
  description = "RDS storage in GB. Storage autoscaling stays disabled to avoid surprise cost."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name created by RDS."
  type        = string
  default     = "wallet"
}

variable "db_username" {
  description = "RDS master username used in the manual walkthrough."
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "db_password" {
  description = "Set via TF_VAR_db_password env var or terraform.tfvars (gitignored) - never hardcode."
  type        = string
  sensitive   = true
}
