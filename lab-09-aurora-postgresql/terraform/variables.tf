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
  description = "Prefix used for Aurora resource names and tags."
  type        = string
  default     = "csnp-lab09"
}

variable "private_data_subnet_ids" {
  description = "Private data subnet IDs spanning at least two Availability Zones."
  type        = list(string)
  validation {
    condition     = length(var.private_data_subnet_ids) >= 2
    error_message = "Aurora subnet group must span at least two AZs."
  }
}

variable "rds_security_group_id" {
  description = "RDS security group ID from Lab 4."
  type        = string
}

variable "database_name" {
  description = "Initial Aurora PostgreSQL database name."
  type        = string
  default     = "wallet"
}

variable "master_username" {
  description = "Aurora master username; the password is managed by Secrets Manager."
  type        = string
  default     = "clusteradmin"
}

variable "instance_class" {
  description = "Aurora cluster instance class."
  type        = string
  default     = "db.t4g.medium"
}
