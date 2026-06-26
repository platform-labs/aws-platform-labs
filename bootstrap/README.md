# Labs Bootstrap Setup Guide

This bootstrap directory creates shared AWS infrastructure for all Terraform-based labs from Lab 01 through Lab 20:
- **S3 bucket**: Centralized Terraform state storage for all labs
- **DynamoDB table**: State locking to prevent concurrent modifications

The bucket is dedicated to `platforms/aws/labs/`. Never reuse a production backend or a state key from `platforms/aws/terraform/envs/*`.

## Why Bootstrap Uses Local State

Bootstrap creates the S3 bucket and DynamoDB table used by the labs, so its first apply cannot depend on that backend. Bootstrap is the only intentional local backend. Keep and back up `bootstrap/terraform.tfstate`.

## Prerequisites

- AWS CLI configured with `default` profile
- Terraform >= 1.6.0

## Setup Steps

### 1. Initialize and Apply Bootstrap

```bash
cd bootstrap
terraform init
terraform apply
```

Verify the outputs:

```bash
terraform output bucket_name
terraform output dynamodb_table_name
terraform output state_keys
```

### 2. Backend Convention

Every lab backend is already configured with the shared bucket and its own key. The canonical template is available from:

```bash
terraform output backend_example
```

Existing convenience outputs for Labs 01, 02, 04 and 05 are retained below for backward compatibility.

#### Lab-01 (EC2 + RDS + S3 + CloudWatch)
```bash
terraform output backend_config_lab01
# Copy the output into: lab-01-ec2-rds-s3-cloudwatch/terraform/backend.tf
```

#### Lab-02 (ECR + ECS + Fargate)
```bash
terraform output backend_config_lab02
# Copy the output into: lab-02-ecr-ecs-fargate/terraform/backend.tf
```

#### Lab-04 (Terraform Platform Foundation)
```bash
terraform output backend_config_lab04
# Copy the output into: lab-04-terraform-platform-foundation/terraform/backend.tf
```

#### Lab-05 (Terraform ECS Platform)
```bash
terraform output backend_config_lab05
# Copy the output into: lab-05-terraform-ecs-platform/terraform/backend.tf
```

### 3. Initialize Each Lab

After updating backend config:

```bash
cd ../lab-XX-*/terraform
terraform init
terraform plan
terraform apply
```

If the lab already has a real local `terraform.tfstate`, migrate it explicitly:

```bash
cp terraform.tfstate terraform.tfstate.pre-s3-migration.bak
terraform init -migrate-state
terraform state list
terraform plan
```

Do not substitute `terraform init -reconfigure` when preserving an existing local state. `-reconfigure` can make Terraform start against an empty remote state instead of copying the old state.

## Backend Configuration

Each lab has its own state file in the shared bucket:
- Lab-01: `s3://csnp-labs-tfstate-289069331511/aws/lab-01/terraform.tfstate`
- Lab-02: `s3://csnp-labs-tfstate-289069331511/aws/lab-02/terraform.tfstate`
- Lab-04: `s3://csnp-labs-tfstate-289069331511/aws/lab-04/terraform.tfstate`
- Lab-05: `s3://csnp-labs-tfstate-289069331511/aws/lab-05/terraform.tfstate`

Additional state keys:

```text
Lab-06  aws/lab-06/terraform.tfstate
Lab-07  aws/lab-07/terraform.tfstate
Lab-08  aws/lab-08/terraform.tfstate
Lab-09  aws/lab-09/terraform.tfstate
Lab-10  aws/lab-10/terraform.tfstate
Lab-11  aws/lab-11/terraform.tfstate
Lab-12A aws/lab-12a/terraform.tfstate
Lab-12B aws/lab-12b/terraform.tfstate
Lab-13  aws/lab-13/terraform.tfstate
Lab-14  aws/lab-14/terraform.tfstate
Lab-15  aws/lab-15/terraform.tfstate
Lab-17  aws/lab-17/terraform.tfstate
Lab-20  aws/lab-20/terraform.tfstate
```

Labs 00, 03A, 03B, 9.5, 16, 18 and 19 have no Terraform configuration and therefore no state key. State locking is enabled via DynamoDB for every Terraform-based lab.

## Cleanup

To destroy the bootstrap infrastructure (only do this when all labs are destroyed):

```bash
terraform destroy
```

Do not destroy bootstrap while any lab state remains. Destroy every lab first, verify resources are gone, then remove all S3 object versions and delete markers before destroying the versioned bucket and DynamoDB table.

⚠️ **WARNING**: This will remove the S3 bucket and DynamoDB table. Ensure all lab state files have been destroyed first.
