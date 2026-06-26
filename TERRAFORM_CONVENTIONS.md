# Terraform Conventions for AWS Labs

These conventions apply to every Terraform-based lab under `platforms/aws/labs/`.

## File responsibilities

| File | Responsibility |
| --- | --- |
| `backend.tf` | Backend only |
| `versions.tf` | Terraform version, required providers, provider configuration, provider-level default tags |
| `variables.tf` | Input variables only |
| `outputs.tf` | Outputs only |
| `main.tf` | Primary resources for small labs |
| `<concern>.tf` | Resources split by concern when `main.tf` becomes difficult to navigate |

Terraform loads all `.tf` files in a directory as one module. Splitting files does not create a module or change resource addresses.

## `versions.tf` pattern

```hcl
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
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "csnp-platform"
      Environment = "lab"
      ManagedBy   = "terraform"
      Lab         = "NN"
    }
  }
}
```

## `backend.tf` pattern

```hcl
terraform {
  backend "s3" {
    bucket         = "csnp-labs-tfstate-289069331511"
    key            = "aws/lab-NN/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "csnp-labs-tfstate-lock"
    encrypt        = true
  }
}
```

Exceptions:

- `bootstrap/` uses a local backend because it creates the shared S3 bucket and lock table.
- A lab may declare additional required providers, such as `tls`.
- A multi-region lab may declare AWS provider aliases after the primary provider.
- Provider profiles are not configured in HCL. Select a local profile with `AWS_PROFILE`.

## Variables and outputs

- Use multi-line blocks.
- Every variable and output has a description.
- Order variable attributes as `description`, `type`, `default`, `sensitive`, then `validation`.
- Put global inputs first, cross-lab inputs second, and service-specific settings last.
- Mark credentials and other secret inputs as `sensitive = true`.
- Do not commit real `terraform.tfvars`.

## Naming and tags

- Resource labels use `snake_case`.
- AWS names use the lab/project prefix already defined by that lab.
- Provider `default_tags` supplies `Project`, `Environment`, `ManagedBy`, and `Lab`.
- Resource-level tags are allowed for `Name` or intentional overrides.

## Formatting and verification

Run before committing:

```powershell
terraform fmt -recursive
terraform validate
```

Changing file layout alone must not rename resource addresses. Any deliberate resource rename requires a `moved` block or explicit state migration.
