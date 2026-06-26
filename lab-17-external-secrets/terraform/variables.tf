variable "aws_region" {
  description = "AWS region containing the EKS cluster and source secret."
  type        = string
  default     = "us-east-1"
}

variable "oidc_provider_arn" {
  description = "IAM OIDC provider ARN for the EKS cluster."
  type        = string
}

variable "oidc_issuer_without_scheme" {
  description = "EKS OIDC issuer hostname and path without the https:// prefix."
  type        = string
}

variable "secret_arn" {
  description = "Secrets Manager secret ARN that External Secrets may read."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt the source secret."
  type        = string
}

variable "namespace" {
  description = "Namespace containing the External Secrets service account."
  type        = string
  default     = "external-secrets"
}

variable "service_account_name" {
  description = "Service account allowed to assume the IAM role."
  type        = string
  default     = "external-secrets"
}
