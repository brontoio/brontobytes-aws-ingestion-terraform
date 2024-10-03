variable "name" {
  description = "A name of the component"
}

variable "logging_bucket" {
  description = "Config representing the bucket containing logs. The bucket may contain logs from different sources under the provided prefix"
  type        = object({
    name: string
    prefix: optional(string, "")
  })
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "with_s3_notification" {
  description = "Whether to set S3 notifications (See README file for details)"
  type        = bool
  default     = true
}

variable "lambda_function_arn" {
  description = "The ARN of the forwarding lambda function"
}
