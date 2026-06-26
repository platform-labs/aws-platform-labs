output "cluster_endpoint" {
  description = "Aurora writer endpoint."
  value       = aws_rds_cluster.aurora.endpoint
}

output "reader_endpoint" {
  description = "Aurora reader endpoint."
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN containing the managed master credential."
  value       = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
}

output "cluster_members" {
  description = "Aurora cluster instance identifiers."
  value       = aws_rds_cluster_instance.nodes[*].identifier
}
