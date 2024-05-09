variable "name" {
  description = "A name of the component"
}

variable "logging_bucket" {
  description = "Config representing the bucket containing logs. The bucket may contain logs from different sources under the provided prefix"
  type        = object({
    name: string
    prefix: string
  })
}

variable "destination_config" {
  description = "Config mapping prefixes/logs to BrontoBytes logname and logset"
  type        = map(object({
    logname: string
    logset: string
    log_type: string
  }))
}

variable "storage_size_mb" {
  description = "The storage size in MB for the lambda function"
  default     = 512
}

variable "timeout_sec" {
  description = "The lambda function timeout in seconds"
  default     = 3
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "bronto_api_key" {
  description = "Encrypted BrontoBytes API key. Used to ingest data"
}

variable "bronto_ingestion_endpoint" {
  description = "Brontobytes ingestion endpoint"
  default     = "https://ingestion.brontobytes.io/"
}

variable "uncompressed_max_batch_size" {
  description = "The max size of a payload, before compression"
}

variable "artifact_bucket" {
  description = "Config object representing the artifact bucket (a.k.a. codedeploy bucket)"
  type        = object({
    arn: string
    id: string
    name: string
  })
}

variable "artifact_version" {
  description = "The version of the log forwarder"
  default     = "latest"
}

variable "role_name" {
  description = "The name of an existing role to be used. No role is created if this property is set."
  default     = null
}
