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

variable "min_capacity" {
  description = "Minimum ECS desired count managed by Application Auto Scaling."
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum ECS desired count managed by Application Auto Scaling."
  type        = number
  default     = 4
}

variable "cpu_target" {
  description = "Target average ECS CPU utilization percentage."
  type        = number
  default     = 60
}

variable "memory_target" {
  description = "Target average ECS memory utilization percentage."
  type        = number
  default     = 70
}
