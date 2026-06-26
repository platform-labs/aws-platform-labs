resource "aws_security_group" "redis" {
  name        = "csnp-lab11-redis"
  description = "Redis from ECS only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "csnp-lab11-redis"
  subnet_ids = var.private_data_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "csnp-lab11-redis"
  description                = "CSNP Lab 11 Redis"
  engine                     = "redis"
  node_type                  = var.node_type
  port                       = 6379
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  snapshot_retention_limit   = 0
  apply_immediately          = true
}
