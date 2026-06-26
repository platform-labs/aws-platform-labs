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
  description = "Project prefix used for observability resource names and tags."
  type        = string
  default     = "csnp-platform"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name from Lab 5."
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name from Lab 5."
  type        = string
}

variable "alb_arn_suffix" {
  description = "CloudWatch LoadBalancer dimension, e.g. app/name/id."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "CloudWatch TargetGroup dimension, e.g. targetgroup/name/id."
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch Logs group containing application logs."
  type        = string
  default     = "/ecs/csnp-platform-wallet-api"
}

variable "alarm_email" {
  description = "Optional email subscription. Confirmation is required."
  type        = string
  default     = ""
}
