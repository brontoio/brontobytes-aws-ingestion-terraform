#
# EventBridge
#
resource "aws_lambda_permission" "allow_event_bridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.bucket_notification.arn
}

resource "aws_cloudwatch_event_rule" "bucket_notification" {
  name        = "s3-notification-${var.name}"
  description = "Rules to notify on log data delivered to S3"
  event_pattern = jsonencode({
    detail-type = ["Object Created"]
    source = ["aws.s3"]
    detail = {
      bucket = {
        name = [var.logging_bucket.name]
      }
    }
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.bucket_notification.name
  target_id = "${ var.name }-lambda"
  arn       = var.lambda_function_arn
}
