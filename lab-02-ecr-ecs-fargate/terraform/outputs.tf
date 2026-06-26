output "alb_dns_name" {
  description = "Public DNS name of the ALB - test with curl <this>/health"
  value       = aws_lb.wallet.dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for the Wallet API image."
  value       = aws_ecr_repository.wallet_api.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.wallet.name
}

output "rds_endpoint" {
  description = "RDS endpoint used by the ECS task"
  value       = local.effective_db_host
}

output "s3_bucket_name" {
  description = "S3 bucket used by the app"
  value       = local.effective_s3_bucket
}
