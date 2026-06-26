# Lab 5 - Terraform ECS Platform
#
# Builds on the network foundation from Lab 4 (Custom VPC, Public/Private
# App/Private Data subnets, NAT, Security Groups). This lab does NOT create
# any VPC/Subnet/NAT/Route Table resources - everything network-related is
# passed in as a variable (see variables.tf), copied from Lab 4's outputs.
#
# Architecture:
#
#   Internet
#       |
#       v
#   ALB (Public Subnet, both AZs)
#       |
#       v
#   ECS Fargate Service (Private App Subnet, both AZs)
#       |
#       v
#   RDS (Private Data Subnet - created in Lab 4, referenced here via db_host)
#
# Compare with Lab 2: same ECR + ECS Fargate + ALB shape, but now correctly
# placed in private subnets instead of the default VPC with
# assign_public_ip = true.

# --- ECR repository (same role as Lab 2) ---

resource "aws_ecr_repository" "wallet_api" {
  name                 = "${var.project_name}-wallet-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-wallet-api-ecr"
  }
}

# --- ECS Cluster ---

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled" # Container Insights is a Lab 6 (Observability) topic, not in scope here
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}
