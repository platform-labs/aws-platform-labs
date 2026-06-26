output "dashboard_name" {
  description = "CloudWatch dashboard name."
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "alerts_topic_arn" {
  description = "SNS topic ARN receiving CloudWatch alarm notifications."
  value       = aws_sns_topic.alerts.arn
}

output "application_secret_arn" {
  description = "Secrets Manager secret ARN for application database credentials."
  value       = aws_secretsmanager_secret.application.arn
}

output "secrets_kms_key_arn" {
  description = "KMS key ARN encrypting the application secret."
  value       = aws_kms_key.secrets.arn
}
