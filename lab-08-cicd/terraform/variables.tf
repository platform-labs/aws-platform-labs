variable "aws_region" {
  description = "AWS region containing ECR and ECS."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod) - used for naming and tagging."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project prefix used for observability resource names and tags."
  type        = string
  default     = "csnp-platform"
}

variable "github_owner" {
  description = "GitHub organization or user that owns the application repository."
  type        = string

  validation {
    condition     = length(trimspace(var.github_owner)) > 0 && var.github_owner != "REPLACE_OWNER"
    error_message = "github_owner must be the real GitHub owner or organization."
  }
}

variable "github_repository" {
  description = "GitHub application repository name."
  type        = string

  validation {
    condition     = length(trimspace(var.github_repository)) > 0 && var.github_repository != "REPLACE_APP_REPOSITORY"
    error_message = "github_repository must be the real GitHub repository name."
  }
}

variable "github_branch" {
  description = "Branch allowed to assume the AWS deployment role."
  type        = string
  default     = "main"
}

variable "github_environment" {
  description = "GitHub Actions environment used by the deploy job. When a job references an environment, GitHub OIDC uses an environment subject instead of a branch ref subject."
  type        = string
  default     = "dev"
}

variable "create_oidc_provider" {
  description = "Whether this lab should create the GitHub Actions OIDC provider."
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "Existing GitHub Actions OIDC provider ARN when creation is disabled."
  type        = string
  default     = ""
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN receiving pipeline images."
  type        = string
}

variable "ecs_cluster_arn" {
  description = "ECS cluster ARN targeted by the deployment workflow."
  type        = string
}

variable "ecs_service_arn" {
  description = "ECS service ARN targeted by the deployment workflow."
  type        = string
}

variable "task_execution_role_arn" {
  description = "ECS task execution role ARN the workflow may pass."
  type        = string
}

variable "task_role_arn" {
  description = "ECS application task role ARN the workflow may pass."
  type        = string
}
