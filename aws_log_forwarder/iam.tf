# Lambda
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

data "aws_iam_policy_document" "s3_artefact_access" {

  statement {
    effect = "Allow"
    resources = [
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

resource "aws_iam_policy" "s3_artefact_access" {
  policy = data.aws_iam_policy_document.s3_artefact_access.json
}

resource "aws_iam_role" "this" {
  count              = local.create_role ? 1 : 0
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = local.role_name
  depends_on = [aws_iam_role.this]
}

resource "aws_iam_role_policy_attachment" "s3_artefact_access" {
  policy_arn = aws_iam_policy.s3_artefact_access.arn
  role       = local.role_name
  depends_on = [aws_iam_role.this]
}
