variable "aws_region" {
  description = "AWS region for the ALB and ACM certificate."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Fully qualified API domain name."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 public hosted zone ID."
  type        = string
}

variable "alb_arn" {
  description = "Application Load Balancer ARN from Lab 5."
  type        = string
}

variable "alb_dns_name" {
  description = "Application Load Balancer DNS name."
  type        = string
}

variable "alb_zone_id" {
  description = "Canonical hosted zone ID of the ALB."
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN receiving HTTPS traffic."
  type        = string
}
