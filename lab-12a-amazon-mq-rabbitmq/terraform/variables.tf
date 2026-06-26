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
  description = "Private application subnet IDs available to the broker."
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ECS security group ID allowed to connect to RabbitMQ."
  type        = string
}

variable "broker_username" {
  description = "RabbitMQ lab username."
  type        = string
  default     = "csnplab"
}

variable "broker_password" {
  description = "RabbitMQ lab password. Use a lab-only value and keep terraform.tfvars untracked."
  type        = string
  sensitive   = true
}

variable "host_instance_type" {
  description = "Amazon MQ broker instance type."
  type        = string
  default     = "mq.t3.micro"
}
