locals {
  logging_bucket_arn         = "arn:aws:s3:::${var.logging_bucket.name}"
  prefix_with_trailing_slash = endswith(var.logging_bucket.prefix, "/") ? var.logging_bucket.prefix : format("%s/", var.logging_bucket.prefix)
  logging_bucket_prefix_arn  = "${local.logging_bucket_arn}/${local.prefix_with_trailing_slash}"
  filename                   = "lambda_${var.name}.zip"
  artefact_url_suffix        = var.artifact_version == "latest" ? "latest/download/brontobytes-aws-ingestion-python.zip" : "download/${var.artifact_version}/brontobytes-aws-ingestion-python.zip"
  artefact_url               = "https://github.com/logchatio/brontobytes-aws-ingestion-python/releases/${local.artefact_url_suffix}"
  artefact_url_b64sha256     = "${local.artefact_url}.b64sha256"
}
