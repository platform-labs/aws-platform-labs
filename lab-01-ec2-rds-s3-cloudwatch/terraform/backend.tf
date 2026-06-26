terraform {

  backend "s3" {
    bucket         = "csnp-labs-tfstate-289069331511"
    key            = "aws/lab-01/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "csnp-labs-tfstate-lock"
    encrypt        = true
  }
}

