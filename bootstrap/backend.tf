terraform {
  # Bootstrap is the only intentional local backend. It creates the S3 bucket
  # and DynamoDB table used by every Terraform-based lab.
  backend "local" {
    path = "terraform.tfstate"
  }
}

