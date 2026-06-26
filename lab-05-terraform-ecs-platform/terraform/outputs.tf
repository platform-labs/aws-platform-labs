output "ecr_repository_url" {
  description = "ECR repository URL for the Wallet API image."
  value       = aws_ecr_repository.wallet_api.repository_url
}

output "alb_dns_name" {
  description = "Public DNS of the ALB - use this to test the API, e.g. http://<alb_dns_name>/health"
  value       = aws_lb.main.dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.wallet_api.name
}

output "task_execution_role_arn" {
  description = "IAM role ARN used by ECS to pull images and publish logs."
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "IAM role ARN assumed by the Wallet API application."
  value       = aws_iam_role.task_role.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch Logs group used by the ECS task."
  value       = aws_cloudwatch_log_group.wallet_api.name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint address."
  value       = aws_db_instance.wallet_db.address
}

output "rds_port" {
  description = "RDS PostgreSQL port."
  value       = aws_db_instance.wallet_db.port
}

output "s3_bucket_name" {
  description = "S3 bucket name for wallet uploads."
  value       = aws_s3_bucket.wallet_uploads.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN."
  value       = aws_s3_bucket.wallet_uploads.arn
}
