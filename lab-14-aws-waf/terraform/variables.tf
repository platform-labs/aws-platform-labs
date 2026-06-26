variable "aws_region" {
  description = "AWS region for the regional WAF and ALB."
  type        = string
  default     = "us-east-1"
}

variable "alb_arn" {
  description = "Application Load Balancer ARN protected by the Web ACL."
  type        = string
}

variable "rate_limit" {
  description = "Maximum requests per source IP in the WAF evaluation window."
  type        = number
  default     = 300
}
