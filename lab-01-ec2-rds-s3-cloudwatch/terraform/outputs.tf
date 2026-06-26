output "ec2_public_ip" {
  description = "Public IP of the Wallet API EC2 instance"
  value       = aws_instance.wallet_api.public_ip
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint - use this as DB_HOST for the app"
  value       = aws_db_instance.wallet_dev.address
}

output "s3_bucket_name" {
  description = "S3 bucket used by the Wallet API."
  value       = aws_s3_bucket.wallet_dev.bucket
}

output "cloudwatch_log_group" {
  description = "CloudWatch Logs group used by the Wallet API."
  value       = aws_cloudwatch_log_group.wallet_api.name
}
