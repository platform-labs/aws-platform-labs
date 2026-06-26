terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

}

provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Project     = "csnp-platform"
      Environment = "lab"
      ManagedBy   = "terraform"
      Lab         = "20"
    }
  }
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region

  default_tags {
    tags = {
      Project     = "csnp-platform"
      Environment = "lab"
      ManagedBy   = "terraform"
      Lab         = "20"
    }
  }
}

