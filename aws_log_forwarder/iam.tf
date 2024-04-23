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
  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "s3_access" {

  statement {
    effect = "Allow"
    resources = [
      "${local.logging_bucket_prefix_arn}*",
      "${var.artifact_bucket.arn}/${var.name}/*"
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
  roles      = [aws_iam_role.this.name]
}

resource "aws_iam_role_policy_attachment" "basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.this.name
}
