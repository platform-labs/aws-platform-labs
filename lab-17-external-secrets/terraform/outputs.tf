output "external_secrets_role_arn" {
  description = "IAM role ARN assumed by the External Secrets service account."
  value       = aws_iam_role.external_secrets.arn
}
