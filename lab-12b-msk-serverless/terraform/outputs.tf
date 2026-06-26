output "cluster_arn" {
  description = "MSK Serverless cluster ARN."
  value       = aws_msk_serverless_cluster.main.arn
}
