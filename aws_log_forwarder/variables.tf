variable "name" {
  description = "A name of the component"
}

variable "logging_bucket" {
  description = "Config representing the bucket containing logs. The bucket may contain logs from different sources under the provided prefix"
  type        = object({
    name: string
    prefix: optional(string, "")
  })
  default = null
}

variable "destination_config" {
  description = "Config mapping prefixes/logs to BrontoBytes logname and logset. Even though not recommended, set_individual_subscription allows to create an individual subscription filter for cloudwatch log groups"
  type        = map(object({
    logname: string
    logset: string
    log_type: string
    set_individual_subscription: optional(bool, false)
  }))
}

variable "paths_regex" {
  description = "List of regex patterns to match against S3 key, e.g. [{\"pattern\": \"regex1\"}, {\"pattern\": \"regex2\"}]. Note that the regex pattern must include a capture group named dest_config_id"
  type        = list(object({
    pattern: string
  }))
  default = []
}

variable "storage_size_mb" {
  description = "The storage size in MB for the lambda function"
  default     = 512
}

variable "timeout_sec" {
  description = "The lambda function timeout in seconds"
  default     = 3
}

variable "memory_size_mb" {
  description = "The lambda function memory size in MB"
  default     = 128
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "bronto_api_key" {
  description = "Encrypted BrontoBytes API key. Used to ingest data"
}

variable "bronto_ingestion_endpoint" {
  description = "Bronto ingestion endpoint"
  default     = "https://ingestion.eu.bronto.io/"
}

variable "bronto_otel_logs_endpoint" {
  description = "Bronto OTEL ingestion endpoint, e.g. https://ingestion.eu.bronto.io/v1/logs"
  default     = null
}

variable "uncompressed_max_batch_size" {
  description = "The max size of a payload, before compression"
}

variable "artifact_bucket" {
  description = "Config object representing the artifact bucket (a.k.a. codedeploy bucket). When create = false and name is null, default name is bronto-aws-forwarder-<ACCOUNT_ID>-<REGION>"
  type        = object({
    create: optional(bool, false)
    arn: optional(string)
    id: optional(string)
    name: optional(string)
  })
  validation {
    condition = var.artifact_bucket.create || var.artifact_bucket.name != null
    error_message = "The artefact bucket name must be specified when using an existing artefact bucket"
  }
}

variable "artifact_version" {
  description = "The version of the log forwarder"
  default     = "latest"
}

variable "role_name" {
  description = "The name of an existing role to be used. No role is created if this property is set."
  default     = null
}

variable "with_s3_notification" {
  description = "Whether to set S3 notifications (See README file for details)"
  type        = bool
  default     = true
}

variable "with_eventbridge_rule" {
  description = "Whether to create EventBridge rule"
  type        = bool
  default     = false
}

variable "enable_eventbridge_notification" {
  description = "Whether to get notifications via EventBridge"
  type        = bool
  default     = false
}

variable "account_level_cloudwatch_subscription" {
  description = "Account level subscription. The log group matching "
  type        = object({
    enable: optional(bool, true)
    excluded_log_groups: optional(list(string), [])
  })
  default = null
}

variable "cloudwatch_default_collection" {
  description = "The default Bronto Collection where to forward Cloudwatch logs to"
  default     = null
}

variable "function_log_retention_in_days" {
  description = "The Cloudwatch retention of the lambda forwarder logs"
  default     = 365
}

variable "forwarder_logs" {
  description = "Config to forward the forwarder fct logs"
  type        = object({
    forward_enable: optional(bool, true)
    service_name: optional(string, "bronto-aws-forwarder")
    collector_extension_arn: optional(string)
  })
  default = {
    forward_enable = false
  }
}

variable "attributes" {
  description = "Attributes that apply to all data forwarded, e.g. region=us-east-1"
  type        = map(string)
  default     = {}
}

variable "aggregator" {
  description = "The name of the aggregator to be applied in order to aggregate multiple log lines into a single one. Currently only `java_stack_trace` and null are supported. No aggregator applies when this property is set to null."
  default     = null
}

variable "bronto_tags" {
  description = "Tags that apply to all data forwarded, e.g. environment=production,region=us-east-1"
  type        = map(string)
  default     = {}
}
