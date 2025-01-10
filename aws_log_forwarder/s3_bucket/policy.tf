resource "aws_s3_bucket_policy" "this" {
  count  = var.bucket_policy_json == null ? 0 : 1
  bucket = var.name
  policy = var.bucket_policy_json
}
