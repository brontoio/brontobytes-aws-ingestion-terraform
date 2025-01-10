output "lambda_arn" {
  value = aws_lambda_function.this.arn
}

output "artefact_bucket" {
  description = "The artefact bucket name, ARN and id"
  value = local.artefact_bucket
}
