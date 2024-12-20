data "aws_caller_identity" "current" {}

locals {
  role_name                  = var.role_name == null ? "${var.name}-role" : var.role_name
  role_arn                   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.role_name}"
  logging_bucket_arn         = "arn:aws:s3:::${var.logging_bucket.name}"
  logging_bucket_prefix_arn  = "${local.logging_bucket_arn}/${var.logging_bucket.prefix}"
  filename                   = "lambda_${var.name}.zip"
  artefact_url_suffix        = var.artifact_version == "latest" ? "latest/download/brontobytes-aws-ingestion-python.zip" : "download/${var.artifact_version}/brontobytes-aws-ingestion-python.zip"
  artefact_url               = "https://github.com/brontoio/brontobytes-aws-ingestion-python/releases/${local.artefact_url_suffix}"
  artefact_url_b64sha256     = "${local.artefact_url}.b64sha256"
}
