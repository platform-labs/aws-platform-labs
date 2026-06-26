terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Local state for this lab on purpose - same approach as lab-01/lab-02.
  # Switch to an S3 + DynamoDB remote backend once you reach the
  # Terraform-for-real-team-workflows stage, not needed for a solo lab.
}
provider "aws" {
  region = var.aws_region
}

