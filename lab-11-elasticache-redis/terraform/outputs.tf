output "primary_endpoint" {
  description = "Primary Redis endpoint for write traffic."
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Redis reader endpoint for read traffic."
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "redis_security_group_id" {
  description = "Security group ID attached to the Redis replication group."
  value       = aws_security_group.redis.id
}
