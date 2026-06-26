output "bucket_name" {
  description = "S3 bucket name for labs Terraform state"
  value       = aws_s3_bucket.tfstate.id
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for labs state locking"
  value       = aws_dynamodb_table.tfstate_lock.name
}

output "state_keys" {
  description = "Canonical state key registry for every Terraform-based lab."
  value = {
    lab_01  = "aws/lab-01/terraform.tfstate"
    lab_02  = "aws/lab-02/terraform.tfstate"
    lab_04  = "aws/lab-04/terraform.tfstate"
    lab_05  = "aws/lab-05/terraform.tfstate"
    lab_06  = "aws/lab-06/terraform.tfstate"
    lab_07  = "aws/lab-07/terraform.tfstate"
    lab_08  = "aws/lab-08/terraform.tfstate"
    lab_09  = "aws/lab-09/terraform.tfstate"
    lab_10  = "aws/lab-10/terraform.tfstate"
    lab_11  = "aws/lab-11/terraform.tfstate"
    lab_12a = "aws/lab-12a/terraform.tfstate"
    lab_12b = "aws/lab-12b/terraform.tfstate"
    lab_13  = "aws/lab-13/terraform.tfstate"
    lab_14  = "aws/lab-14/terraform.tfstate"
    lab_15  = "aws/lab-15/terraform.tfstate"
    lab_17  = "aws/lab-17/terraform.tfstate"
    lab_20  = "aws/lab-20/terraform.tfstate"
  }
}

output "backend_example" {
  description = "Canonical backend template. Replace LAB_KEY with one value from state_keys."
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.tfstate.id}"
        key            = "LAB_KEY"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.tfstate_lock.name}"
        encrypt        = true
      }
    }
  EOT
}

output "backend_config_lab01" {
  description = "Copy this into lab-01-ec2-rds-s3-cloudwatch/terraform/backend.tf"
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.tfstate.id}"
        key            = "aws/lab-01/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.tfstate_lock.name}"
        encrypt        = true
      }
    }
  EOT
}

output "backend_config_lab02" {
  description = "Copy this into lab-02-ecr-ecs-fargate/terraform/backend.tf"
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.tfstate.id}"
        key            = "aws/lab-02/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.tfstate_lock.name}"
        encrypt        = true
      }
    }
  EOT
}

output "backend_config_lab04" {
  description = "Copy this into lab-04-terraform-platform-foundation/terraform/backend.tf"
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.tfstate.id}"
        key            = "aws/lab-04/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.tfstate_lock.name}"
        encrypt        = true
      }
    }
  EOT
}

output "backend_config_lab05" {
  description = "Copy this into lab-05-terraform-ecs-platform/terraform/backend.tf"
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.tfstate.id}"
        key            = "aws/lab-05/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.tfstate_lock.name}"
        encrypt        = true
      }
    }
  EOT
}
