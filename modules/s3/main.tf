###################################
# BUCKET
###################################
resource "aws_s3_bucket" "images" {
  bucket = var.bucket_name
}

###################################
# BLOCK PUBLIC ACCESS
###################################
resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

###################################
# OBJECT OWNERSHIP
###################################
resource "aws_s3_bucket_ownership_controls" "ownership" {

  bucket = aws_s3_bucket.images.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

###################################
# VERSIONING
###################################
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.images.id

  versioning_configuration {
    status = "Enabled"
  }
}

###################################
# ENCRYPTION
###################################
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

###################################
# LIFECYCLE
###################################
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "archive"
    status = "Enabled"
    filter {
      prefix = "images/"
    }
    transition {
      days          = var.transition_days
      storage_class = "STANDARD_IA"
    }
  }
}

###################################
# PREFIX MARKER
###################################
resource "aws_s3_object" "images_prefix" {
  bucket = aws_s3_bucket.images.id
  key    = "images/"
}
