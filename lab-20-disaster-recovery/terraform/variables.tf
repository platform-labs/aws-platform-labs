variable "primary_region" {
  description = "Primary AWS region containing the protected workloads."
  type        = string
  default     = "us-east-1"
}

variable "dr_region" {
  description = "Secondary AWS region receiving backup copies."
  type        = string
  default     = "us-west-2"
}

variable "backup_tag_key" {
  description = "Resource tag key used by the AWS Backup selection."
  type        = string
  default     = "Backup"
}

variable "backup_tag_value" {
  description = "Resource tag value used by the AWS Backup selection."
  type        = string
  default     = "lab20"
}
