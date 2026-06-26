variable "aws_region" {
  description = "AWS provider region used by this lab."
  type        = string
  default     = "us-east-1"
}

variable "origin_domain_name" {
  description = "HTTPS origin domain name, normally the Lab 13 API domain."
  type        = string
}

variable "origin_id" {
  description = "Stable identifier for the CloudFront origin."
  type        = string
  default     = "csnp-alb-origin"
}
