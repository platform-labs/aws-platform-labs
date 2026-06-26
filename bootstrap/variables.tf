variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name for labs Terraform state (must be globally unique)"
  type        = string
  default     = "csnp-labs-tfstate-289069331511" # accountId suffix để unique
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for labs state locking"
  type        = string
  default     = "csnp-labs-tfstate-lock"
}
