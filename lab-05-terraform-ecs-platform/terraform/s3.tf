# S3 Bucket for file uploads
#
# Same role as the S3 bucket from Lab 1 (csnp-wallet-dev), but now
# created via Terraform as part of the platform stack instead of manually.
#
# The bucket is accessed by the ECS task via IAM Task Role
# (aws_iam_role_policy.task_role_s3 in iam.tf) - no static Access Keys.

# --- S3 Bucket ---

resource "aws_s3_bucket" "wallet_uploads" {
  bucket = "${var.project_name}-wallet-uploads-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  tags = {
    Name = "${var.project_name}-wallet-uploads"
  }
}

# --- Versioning (optional, good practice) ---

resource "aws_s3_bucket_versioning" "wallet_uploads" {
  bucket = aws_s3_bucket.wallet_uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --- Server-side Encryption (best practice even for labs) ---

resource "aws_s3_bucket_server_side_encryption_configuration" "wallet_uploads" {
  bucket = aws_s3_bucket.wallet_uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Block Public Access (strict, best practice) ---

resource "aws_s3_bucket_public_access_block" "wallet_uploads" {
  bucket = aws_s3_bucket.wallet_uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
