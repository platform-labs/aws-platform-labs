variable "aws_region" {
  description = "AWS region for this lab."
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID from Lab 4."
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Private application subnet IDs used by MSK Serverless."
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ECS security group ID allowed to connect to MSK."
  type        = string
}
