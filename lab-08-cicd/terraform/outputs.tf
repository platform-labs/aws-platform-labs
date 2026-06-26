output "github_actions_role_arn" {
  description = "IAM role ARN assumed by GitHub Actions through OIDC."
  value       = aws_iam_role.github_deploy.arn
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions IAM OIDC provider ARN."
  value       = local.oidc_provider_arn
}

output "github_actions_subject" {
  description = "GitHub OIDC subject allowed to assume the deploy role."
  value       = local.github_actions_subjects
}

output "github_actions_variables" {
  description = "Repository variables to create in GitHub Actions."
  value = {
    AWS_ROLE_ARN        = aws_iam_role.github_deploy.arn
    AWS_REGION          = var.aws_region
    ECR_REPOSITORY      = element(split(":repository/", var.ecr_repository_arn), 1)
    ECS_CLUSTER         = element(split(":cluster/", var.ecs_cluster_arn), 1)
    ECS_SERVICE         = element(split("/", var.ecs_service_arn), 2)
    ECS_TASK_DEFINITION = "lab-08-cicd/task-definition.json"
    CONTAINER_NAME      = "wallet-api"
  }
}
