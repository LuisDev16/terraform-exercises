data "aws_caller_identity" "current" {}
resource "aws_s3_bucket" "lab" {
  bucket = "gha-tf-lab-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  tags = {
    environment = "lab"
    managed_by = "terraform"
  }
}
resource "aws_s3_bucket_public_access_block" "lab" {
  bucket = aws_s3_bucket.lab.id
  block_public_acls = true
  ignore_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "lab" {
  bucket = aws_s3_bucket.lab.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}