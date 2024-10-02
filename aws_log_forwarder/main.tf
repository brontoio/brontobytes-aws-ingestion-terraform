data "http" "package" {
  url = local.artefact_url
}

data "http" "package_b64sha256" {
  url = local.artefact_url_b64sha256
}

resource "aws_s3_object" "log_forwarder" {
  bucket         = var.artifact_bucket.name
  key            = "${var.name}/${local.filename}"
  content_base64 = data.http.package.response_body_base64
}

resource "aws_lambda_function" "this" {
  s3_bucket        = aws_s3_object.log_forwarder.bucket
  s3_key           = aws_s3_object.log_forwarder.key
  source_code_hash = chomp(data.http.package_b64sha256.body)
  architectures    = ["arm64"]

  function_name = var.name
  role          = local.role_arn
  handler       = "forward.forward_logs"

  logging_config {
    log_format = "JSON"
    application_log_level = "INFO"
    system_log_level      = "INFO"
  }

  runtime     = "python3.12"
  timeout     = var.timeout_sec
  memory_size = var.memory_size_mb

  ephemeral_storage {
    size = var.storage_size_mb
  }

  environment {
    variables = {
      destination_config = base64encode(jsonencode(var.destination_config))
      bronto_api_key     = var.bronto_api_key
      bronto_endpoint    = var.bronto_ingestion_endpoint
      max_batch_size     = var.uncompressed_max_batch_size
    }
  }

  tags = { service = "aws_logging" }

}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.arn
  principal     = "s3.amazonaws.com"
  source_arn    = local.logging_bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count  = var.with_s3_notification ? 1 : 0
  bucket = var.logging_bucket.name

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.logging_bucket.prefix
  }
}
