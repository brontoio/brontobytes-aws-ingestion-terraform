# IAM
data "aws_iam_policy_document" "s3_access" {
  count = local.enable_s3_forwarding ? 1 : 0

  statement {
    effect = "Allow"
    resources = [
      "${local.logging_bucket_prefix_arn}*",
      "${local.artefact_bucket["arn"]}/${var.name}/*",
      "${local.artefact_bucket["arn"]}/${local.otel_config_s3_key}",
      "${local.artefact_bucket["arn"]}/${local.destination_config_s3_key}",
      "${local.artefact_bucket["arn"]}/${local.paths_regex_config_s3_key}"
    ]
    actions   = ["s3:Get*", "s3:List*"]
  }

  statement {
    effect    = "Allow"
    resources = [local.artefact_bucket.arn]
    actions   = ["s3:ListBucket"]
  }
}

resource "aws_iam_policy" "s3_access" {
  count  = local.enable_s3_forwarding ? 1 : 0
  policy = data.aws_iam_policy_document.s3_access[0].json
}

resource "aws_iam_policy_attachment" "s3_access" {
  count      = local.enable_s3_forwarding ? 1 : 0
  name       = "S3AccessLoggingBucketRO"
  policy_arn = aws_iam_policy.s3_access[0].arn
  roles      = [local.role_name]
  depends_on = [aws_iam_role.this]
}

# Lambda permissions
resource "aws_lambda_permission" "allow_bucket" {
  count         = local.enable_s3_forwarding ? 1 : 0
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.arn
  principal     = "s3.amazonaws.com"
  source_arn    = local.logging_bucket_arn
}

# S3 Notifications and EventBridge
resource "aws_s3_bucket_notification" "bucket_notification" {
  count  = local.enable_s3_forwarding && (var.with_s3_notification || var.enable_eventbridge_notification) ? 1 : 0
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
  count  = local.enable_s3_forwarding && var.with_eventbridge_rule ? 1 : 0
  source = "./notifications/"
  lambda_function_arn = aws_lambda_function.this.arn
  logging_bucket      = var.logging_bucket
  name                = var.name
  tags                = { Name = "bronto-log-forwarder" }
}
