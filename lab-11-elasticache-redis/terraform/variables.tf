variable "aws_region" {
  description = "AWS region for this lab."
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID from Lab 4."
  type        = string
}

variable "private_data_subnet_ids" {
  description = "Private data subnet IDs from Lab 4."
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ECS security group ID allowed to connect to Redis."
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type used by the replication group."
  type        = string
  default     = "cache.t4g.micro"
}
