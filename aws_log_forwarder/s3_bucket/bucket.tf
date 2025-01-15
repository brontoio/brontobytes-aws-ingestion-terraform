resource "aws_s3_bucket" "this" {
    bucket        = var.name
    force_destroy = false  // Prevent accidental deletion of the bucket
    tags          = local.tags
  lifecycle {
    prevent_destroy = true
    ignore_changes = [versioning, server_side_encryption_configuration]
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
    bucket = aws_s3_bucket.this.id
    rule {
        bucket_key_enabled = true
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

resource "aws_s3_bucket_versioning" "this" {
    bucket = aws_s3_bucket.this.id
    versioning_configuration {
        status     = var.versioning_configuration.status
    }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count      = var.versioning_configuration.non_current_versions_ttl_days != null || length(keys(var.expiration_rules)) > 0 ? 1 : 0
  depends_on = [aws_s3_bucket_versioning.this]

  bucket = aws_s3_bucket.this.id

  dynamic rule {
    for_each = var.versioning_configuration.non_current_versions_ttl_days == null ? [] : ["versions"]
    content {
      id       = "expireNonCurrentVersions"

      noncurrent_version_expiration {
        noncurrent_days = var.versioning_configuration.non_current_versions_ttl_days
      }

      expiration {
        expired_object_delete_marker = true
      }

      status = "Enabled"
    }
  }

  dynamic rule {
    for_each = var.expiration_rules
    content {
      id       = rule.key

      dynamic expiration {
        for_each = rule.value.ttl_days == null ? {} : { expiration = rule.value.ttl_days }
        content {
          days = expiration.value
        }
      }

      dynamic abort_incomplete_multipart_upload {
        for_each = rule.value.incomplete_multipart_upload_ttl_days == null ? {} : { incomplete_multipart_upload_ttl_days = rule.value.incomplete_multipart_upload_ttl_days }
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }

      dynamic filter {
        for_each = rule.value.filter == null ? {} : { filter = rule.value.filter }
        content {
          prefix = filter.value.prefix
        }
      }

      status = rule.value.status
    }
  }
}

# Extra bucket metrics
resource "aws_s3_bucket_metric" "this" {
  count  = var.extra_metrics.enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id
  name   = var.extra_metrics.filter_id
}
