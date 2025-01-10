variable "name" {
  description = "The bucket name"
}

variable "tags" {
  description = "Bucket tags. The name tag is inferred from the name variable if not overwritten here."
  default     = {}
}

variable "versioning_configuration" {
  description = "Bucket versioning configuration"
  type        = object({
    status: string
    non_current_versions_ttl_days: number
  })
  default     = { status = "Disabled", non_current_versions_ttl_days = null }
}

variable "object_ownership" {
  description = "Ownership type to apply to objects"
  default     = "BucketOwnerEnforced"
}

variable "expiration_rules" {
  description = "Lifecycle expiration rules configuration"
  type        = map(object({
    status: string
    ttl_days: optional(number)
    filter: optional(object({
      prefix: string
    }))
    incomplete_multipart_upload_ttl_days: optional(number)
  }))
  default = {}
}

variable "bucket_policy_json" {
  description = "JSON representation of the bucket policy"
  default     = null
}

variable "extra_metrics" {
  description = "Whether to enable extra metrics on the bucket, e.g. Request metrics"
  type        = object({
    enabled: bool
    filter_id: string
  })
  default     = { enabled = false, filter_id = null }
}
