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
      attributes                         = join(",", [for key,value in var.attributes: "${key}=${value}"])
    }
  }
  layers = var.forwarder_logs.forward_enable ? [local.collector_extension_arn] : []
  tags = { service = "aws_logging" }
  depends_on = [module.artefact_bucket, aws_s3_object.log_forwarder, aws_iam_role.this]
}
