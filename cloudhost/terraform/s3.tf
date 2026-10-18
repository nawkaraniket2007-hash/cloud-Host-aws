# ==============================================================================
# Amazon S3 Bucket Configuration (Hardened Security Baseline)
# ==============================================================================

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 1. Dedicated S3 Bucket
resource "aws_s3_bucket" "storage" {
  bucket        = "${var.s3_bucket_prefix}-${var.environment}-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-s3-bucket-${var.environment}"
  }
}

# 2. Block All Public Access (Strict Defense-in-Depth)
resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Bucket Versioning for Audit Trail and Recovery
resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 4. Server-Side Encryption (SSE-S3 AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 5. Security Parameter: Enforce TLS/HTTPS In-Transit
resource "aws_s3_bucket_policy" "enforce_tls" {
  bucket     = aws_s3_bucket.storage.id
  depends_on = [aws_s3_bucket_public_access_block.storage]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.storage.arn,
          "${aws_s3_bucket.storage.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# 6. Lifecycle Configuration: Abort Incomplete Multipart Uploads
resource "aws_s3_bucket_lifecycle_configuration" "storage" {
  bucket     = aws_s3_bucket.storage.id
  depends_on = [aws_s3_bucket_versioning.storage]

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# 7. Upload Application Deployment Package to S3
resource "aws_s3_object" "app_package" {
  bucket = aws_s3_bucket.storage.id
  key    = "deploy/app.tar.gz"
  source = "${path.module}/../app.tar.gz"
  etag   = filemd5("${path.module}/../app.tar.gz")
}
