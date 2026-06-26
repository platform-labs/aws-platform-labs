resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-aurora"
  subnet_ids = var.private_data_subnet_ids
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier              = "${var.project_name}-aurora"
  engine                          = "aurora-postgresql"
  database_name                   = var.database_name
  master_username                 = var.master_username
  manage_master_user_password     = true
  db_subnet_group_name            = aws_db_subnet_group.aurora.name
  vpc_security_group_ids          = [var.rds_security_group_id]
  storage_encrypted               = true
  backup_retention_period         = 1
  preferred_backup_window         = "03:00-04:00"
  preferred_maintenance_window    = "sun:04:00-sun:05:00"
  enabled_cloudwatch_logs_exports = ["postgresql"]
  deletion_protection             = false
  skip_final_snapshot             = true
  apply_immediately               = true

}

resource "aws_rds_cluster_instance" "nodes" {
  count                = 2
  identifier           = "${var.project_name}-aurora-${count.index + 1}"
  cluster_identifier   = aws_rds_cluster.aurora.id
  instance_class       = var.instance_class
  engine               = aws_rds_cluster.aurora.engine
  engine_version       = aws_rds_cluster.aurora.engine_version
  db_subnet_group_name = aws_db_subnet_group.aurora.name

}
