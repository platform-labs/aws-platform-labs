output "primary_vault_arn" {
  description = "AWS Backup vault ARN in the primary region."
  value       = aws_backup_vault.primary.arn
}

output "dr_vault_arn" {
  description = "AWS Backup vault ARN in the disaster recovery region."
  value       = aws_backup_vault.dr.arn
}

output "backup_plan_id" {
  description = "AWS Backup plan ID."
  value       = aws_backup_plan.main.id
}
