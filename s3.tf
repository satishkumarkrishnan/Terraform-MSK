# S3 bucket to store App
resource "aws_s3_bucket" "kms_encrypted" {
  bucket = "tokyo-tf-kms"
  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = false
  }
}

# Enable versioning so you can see the full revision history of your
# state files
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.kms_encrypted.id  
  versioning_configuration {
    status = "Enabled"
  }
}
# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.kms_encrypted.id

  rule {
    apply_server_side_encryption_by_default {
      #kms_master_key_id = aws_kms_key.
      sse_algorithm = "AES256"
    }
  }
}
# Explicitly block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.kms_encrypted.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# Upload TF state file to S3 bucket
resource "aws_s3_object" "object" {
  bucket = "tokyo-tf-kms"
  key    = "terraform.tfstate" # Object name
  source = "./README.md"
  lifecycle {
    prevent_destroy = false
  }
  depends_on = [module.asg]
}
