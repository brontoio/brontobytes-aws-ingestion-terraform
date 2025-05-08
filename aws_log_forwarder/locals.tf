data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  # Lambda
  create_role                             = var.role_name == null
  role_name                               = var.role_name == null ? "${var.name}-role" : var.role_name
  role_arn                                = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.role_name}"
  fct_destination_properties              = {
    for key, value in var.destination_config : key =>
    {for prop in keys(value) : prop => value[prop] if prop != "set_individual_subscription"}
  }
  collector_extension_arn = var.forwarder_logs.collector_extension_arn != null ? var.forwarder_logs.collector_extension_arn : "arn:aws:lambda:${data.aws_region.current.name}:184161586896:layer:opentelemetry-collector-arm64-0_12_0:1"
  otel_config_s3_key        = "config/collector.yaml"
  destination_config_s3_key = "config/destination_config.json"
  otel_config_s3_uri = "s3://${local.artefact_bucket["name"]}.s3.${data.aws_region.current.name}.amazonaws.com/${local.otel_config_s3_key}"

  # s3 forwarding
  enable_s3_forwarding                    = var.logging_bucket != null
  logging_bucket_arn                      = local.enable_s3_forwarding ? "arn:aws:s3:::${var.logging_bucket.name}" : null
  logging_bucket_prefix_arn               = local.enable_s3_forwarding ? "${local.logging_bucket_arn}/${var.logging_bucket.prefix}" : null

  # Artefact
  filename                                = "lambda_${var.name}.zip"
  artefact_url_suffix                     = var.artifact_version == "latest" ? "latest/download/brontobytes-aws-ingestion-python.zip" : "download/${var.artifact_version}/brontobytes-aws-ingestion-python.zip"
  artefact_url                            = "https://github.com/brontoio/brontobytes-aws-ingestion-python/releases/${local.artefact_url_suffix}"
  artefact_url_b64sha256                  = "${local.artefact_url}.b64sha256"
  artefact_bucket_default_name            = "bronto-aws-forwarder-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  artefact_bucket                         = var.artifact_bucket.name == null ? {
      id   = local.artefact_bucket_default_name
      arn  = "arn:aws:s3:::${local.artefact_bucket_default_name}"
      name = local.artefact_bucket_default_name
    } : {
      id   = var.artifact_bucket.id != null ? var.artifact_bucket.id : var.artifact_bucket.name
      arn  = var.artifact_bucket.arn != null ? var.artifact_bucket.arn : "arn:aws:s3:::${var.artifact_bucket.name}"
      name = var.artifact_bucket.name
    }

  # Cloudwatch forwarding
  log_groups_with_individual_subscription = [
    for key in keys(var.destination_config) : key
    if lookup(var.destination_config[key], "log_type", "") == "cloudwatch_log" && var.destination_config[key].set_individual_subscription
  ]
  excluded_log_groups = var.account_level_cloudwatch_subscription == null ? [] : concat(var.account_level_cloudwatch_subscription.excluded_log_groups, [aws_cloudwatch_log_group.this.name], local.log_groups_with_individual_subscription)
  enable_account_level_subscription_filter = var.account_level_cloudwatch_subscription != null ? var.account_level_cloudwatch_subscription.enable : false
  enable_cloudwatch_forwarding = local.enable_account_level_subscription_filter || length(local.log_groups_with_individual_subscription) > 0
}
