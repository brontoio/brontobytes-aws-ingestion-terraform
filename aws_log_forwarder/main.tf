data "http" "package" {
  url = local.artefact_url
}

data "http" "package_b64sha256" {
  url = local.artefact_url_b64sha256
}

module "artefact_bucket" {
  count  = var.artifact_bucket.create ? 1 : 0
  source = "./s3_bucket"
  name   = local.artefact_bucket["name"]
  tags   = var.tags
}

resource "aws_s3_object" "log_forwarder" {
  bucket         = local.artefact_bucket["name"]
  key            = "${var.name}/${local.filename}"
  content_base64 = data.http.package.response_body_base64
  depends_on     = [module.artefact_bucket]
}

resource "aws_s3_object" "otel_collector_config" {
  count          = var.forwarder_logs.forward_enable ? 1 : 0
  bucket         = local.artefact_bucket["name"]
  key            = local.otel_config_s3_key
  content_base64 = base64encode(templatefile("${path.module}/resources/collector.yaml.tmpl",
    {service_name = var.forwarder_logs.service_name, cloudwatch_default_collection = var.cloudwatch_default_collection}))
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.function_log_retention_in_days
  tags              = var.tags
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
      destination_config        = base64encode(jsonencode(local.fct_destination_properties))
      bronto_api_key            = var.bronto_api_key
      bronto_endpoint           = var.bronto_ingestion_endpoint
      bronto_otel_logs_endpoint = var.bronto_otel_logs_endpoint
      max_batch_size            = var.uncompressed_max_batch_size
      cloudwatch_default_collection      = var.cloudwatch_default_collection
      OPENTELEMETRY_COLLECTOR_CONFIG_URI = var.forwarder_logs.forward_enable ? local.otel_config_s3_uri : null
    }
  }
  layers = var.forwarder_logs.forward_enable ? [local.collector_extension_arn] : []
  tags = { service = "aws_logging" }
  depends_on = [module.artefact_bucket, aws_s3_object.log_forwarder, aws_iam_role.this]
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.arn
  principal     = "s3.amazonaws.com"
  source_arn    = local.logging_bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count  = var.with_s3_notification || var.enable_eventbridge_notification ? 1 : 0
  bucket = var.logging_bucket.name
  eventbridge = var.enable_eventbridge_notification


  dynamic lambda_function {
    for_each = var.with_s3_notification ? { (var.name) = "1" } : {}
    content {
      lambda_function_arn = aws_lambda_function.this.arn
      events              = ["s3:ObjectCreated:*"]
      filter_prefix       = var.logging_bucket.prefix
    }
  }
}

module "event_bridge" {
  count  = var.with_eventbridge_rule ? 1 : 0
  source = "./notifications/"
  lambda_function_arn = aws_lambda_function.this.arn
  logging_bucket      = var.logging_bucket
  name                = var.name
  tags                = { Name = "bronto-log-forwarder" }
}
