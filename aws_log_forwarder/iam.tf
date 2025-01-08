data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  count              = var.role_name == null ? 1 : 0
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "s3_access" {

  statement {
    effect = "Allow"
    resources = [
      "${local.logging_bucket_prefix_arn}*",
      "${var.artifact_bucket.arn}/${var.name}/*",
      "${var.artifact_bucket.arn}/${local.otel_config_s3_key}"
    ]
    actions   = ["s3:Get*", "s3:List*"]
  }
}

resource "aws_iam_policy" "s3_access" {
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_policy_attachment" "s3_access" {
  name       = "S3AccessLoggingBucketRO"
  policy_arn = aws_iam_policy.s3_access.arn
  roles      = [local.role_name]
  depends_on = [aws_iam_role.this]
}

resource "aws_iam_role_policy_attachment" "basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = local.role_name
  depends_on = [aws_iam_role.this]
}
