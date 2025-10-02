# BrontoBytes AWS Log Forwarder

Terraform module to set up a lambda function and necessary permissions to forward to BrontoBytes
logs delivered to AWS S3 and Cloudwatch.

In particular, it contains a lambda function that gets triggered based on
- S3 notifications when a new object is created in the `logging bucket`
- A Cloudwatch subscription when new data is received in Cloudwatch

This approach should cover many logging needs regarding AWS services. The list of services whose logs
are delivered to S3 or Cloudwatch is provided in the table at https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AWS-logs-and-resource-policy.html#AWS-logs-infrastructure-S3.
In some cases, the log entries processed by this integration are parsed by the lambda function and sent in Json format to 
BrontoBytes.

## How it works

### Forwarding logs delivered to AWS S3

This Terraform module sets up the necessary infrastructure to forward to Bronto, logs delivered to S3 buckets. It relies 
on AWS S3 Notifications or AWS EventBridge so that an AWS Lambda function gets triggered when a new object is uploaded to an S3 bucket 
(called the Logging Bucket).
The Lambda function gets notification of the new objects being added to the Logging Bucket, then downloads the object so 
as to parse its content and send it to Bronto for ingestion.

### Forwarding logs delivered to AWS Cloudwatch

This follows the same principle as for forwarding logs from S3, except that Cloudwatch Subscription Filters are used in order 
to trigger the forwarding lambda function, rather than S3 notifications. It is recommended to use an account level 
subscription filter rather than individual subscriptions per log group.


## Usage

Here is a sample usage of this Terraform module, where lambda logs, S3 access logs and CloudFront standard access logs 
are forwarded to Bronto. 
```hcl
module "bronto_aws_log_forwarding" {
  source = "git::https://github.com/brontoio/brontobytes-aws-ingestion-terraform.git//aws_log_forwarder"
  # Forwarder Lambda
  name             = "bronto_aws_log_forwarder"
  tags             = { Name = "bronto_aws_log_forwarding" }
  timeout_sec      = 30
  storage_size_mb  = 1000
  bronto_api_key   = data.aws_kms_secrets.secrets.plaintext["bronto_api_key"]
  uncompressed_max_batch_size = 5000000  # 5Mb
  attributes = { region = "us-east-1", account_id = "12345678"}
  destination_config   = {
    "/aws/lambda/my-function-name" = {
      dataset    = "<BRONTO DESTINATION DATASET>"
      collection = "<BRONTO DESTINATION COLLECTION>"
      log_type   = "cloudwatch_log"
    }
    "<BUCKET_WHOSE_ACCESS_LOGS_ARE_COLLECTED>" = {
      dataset    = "<BRONTO DESTINATION DATASET>"
      collection = "<BRONTO DESTINATION COLLECTION>"
      log_type   = "s3_access_log"
    }
    "<CLOUDFRONT_DISTRIBUBTION_ID>" = {
      dataset    = "<BRONTO DESTINATION DATASET>"
      collection = "<BRONTO DESTINATION COLLECTION>"
      log_type   = "cf_standard_access_log"
    }
    "my_config_id" = {
      dataset    = "<BRONTO DESTINATION DATASET>"
      collection = "<BRONTO DESTINATION COLLECTION>"
      log_type   = "default"  # this sets the types of parser to be applied. `default` means no parser and is typically suitable for JSON structured logs
    }
  },
  artifact_bucket  = {name="LAMBDA_ARTIFACT_BUCKET_NAME", id="LAMBDA_ARTIFACT_BUCKET_NAME", arn="arn:aws:s3:::LAMBDA_ARTIFACT_BUCKET_NAME"}
  artifact_version = "latest"
  # Forwarding data from S3
  with_s3_notification = false
  logging_bucket   = {name="<LOGGING_BUCKET_NAME>", prefix="<LOGGING_BUCKET_PREFIX>"}
  # Forwarding data from Cloudwatch
  cloudwatch_default_collection = "Cloudwatch"
  account_level_cloudwatch_subscription = {
    enable = true
    excluded_log_groups = ["log_group1", "log_group2"]
  }
  bronto_tags = {environment = "production", region="eu-west-1"}
}
```

Here is another example where only Cloudwatch logs are forwarded to Bronto:
```hcl
module "bronto_aws_log_forwarding" {
  source = "git::https://github.com/brontoio/brontobytes-aws-ingestion-terraform.git//aws_log_forwarder"
  # Forwarder Lambda
  name             = "bronto_aws_log_forwarder"
  tags             = { Name = "bronto_aws_log_forwarding" }
  timeout_sec      = 30
  storage_size_mb  = 1000
  bronto_api_key   = data.aws_kms_secrets.secrets.plaintext["bronto_api_key"]
  uncompressed_max_batch_size = 5000000  # 5Mb
  destination_config   = {
    "/aws/lambda/my-function-name" = {
      dataset    = "<BRONTO DESTINATION LOG_NAME>"
      collection = "<BRONTO DESTINATION COLLECTION>"
      log_type   = "cloudwatch_log"
      set_individual_subscription = true
      subscription_filter_pattern = "<FILTER_PATTERN>"  # only relevant if set_individual_subscription = true. Filter pattern syntax is described at https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html
    }
  },
  artifact_bucket  = {name="LAMBDA_ARTIFACT_BUCKET_NAME", id="LAMBDA_ARTIFACT_BUCKET_NAME", arn="arn:aws:s3:::LAMBDA_ARTIFACT_BUCKET_NAME"}
  artifact_version = "latest"
  # Forwarding data from Cloudwatch
  cloudwatch_default_collection = "Cloudwatch"
  account_level_cloudwatch_subscription = {
    enable = true
    excluded_log_groups = ["log_group1", "log_group2"]
  }
  bronto_tags = {environment = "production", region="eu-west-1"}
  default_subscription_filter_pattern = "<MY_DEFAULT_FILTER_PATTERN>"  # filter pattern syntax is described at https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html
}
```
Note: It is recommended to use account level subscription filters rather than log group level ones. Therefore, when 
following this recommendation, it should not be necessary to include Cloudwatch logs in the `destination_config` section 
of the configuration unless:
- you wish to not rely on the default `collection` and `dataset` names
- you wish to overwrite the default subscription filter pattern for specific log groups.


And here is an example where only S3 logs are forwarded to Bronto:
```hcl
module "bronto_aws_log_forwarding" {
  source = "git::https://github.com/brontoio/brontobytes-aws-ingestion-terraform.git//aws_log_forwarder"
  # Forwarder Lambda
  name             = "bronto_aws_log_forwarder"
  tags             = { Name = "bronto_aws_log_forwarding" }
  timeout_sec      = 30
  storage_size_mb  = 1000
  bronto_api_key   = data.aws_kms_secrets.secrets.plaintext["bronto_api_key"]
  uncompressed_max_batch_size = 5000000  # 5Mb
  destination_config   = {
    "<BUCKET_WHOSE_ACCESS_LOGS_ARE_COLLECTED>" = {
      dataset    = "<BRONTO DESTINATION LOG_NAME>"
      collection = "<BRONTO DESTINATION COLLECTION>"
      log_type   = "s3_access_log"
    }
    "<CLOUDFRONT_DISTRIBUBTION_ID>" = {
      dataset    = "<BRONTO DESTINATION LOG_NAME>"
      collection = "<BRONTO DESTINATION COLLECTION>"
      log_type   = "cf_standard_access_log"
    }
  }
  artifact_bucket  = {name="LAMBDA_ARTIFACT_BUCKET_NAME", id="LAMBDA_ARTIFACT_BUCKET_NAME", arn="arn:aws:s3:::LAMBDA_ARTIFACT_BUCKET_NAME"}
  artifact_version = "latest"
  # Forwarding data from S3
  with_s3_notification = false
  logging_bucket = {name="<LOGGING_BUCKET_NAME>", prefix="<LOGGING_BUCKET_PREFIX>"}
  bronto_tags = {environment = "production", region="eu-west-1"}
}
```

Below is a list of fields that can be used to configure this module.

### Forwarder Lambda

Lambda related configuration:
- `name`: the name to use for the lambda function
- `tags`: key-value pairs defining AWS tags to be applied to the resources created by the module
- `timeout_sec`: the lambda function timeout value
- `storage_size_mb`: the lambda function storage size

Bronto related configuration, these are provided to the Lambda function as environment variables:
- `bronto_api_key`: the Bronto API key
- `bronto_ingestion_endpoint`: the Bronto ingestion endpoint, e.g. https://ingestion.eu.bronto.io/. This endpoint must
point to the Bronto system where the API key was created.  
- `bronto_tags`: map of key-value pairs representing tags that are applied to destination Bronto datasets, e.g. `{environment="production", region="eu-west-1"}`.
- `aggregator`: the name of an aggregator to use: either `java_stack_trace` or `default`. This property defaults to `default` if not set. 
Aggregators aggregate multiline log entries into a single entry. The `default` aggregator is a
 noop (no entries get aggregated), while the `java_stack_trace` aggregator aggregates Java stack trace entries into a single one. 
- `uncompressed_max_batch_size`: the max size of the batches of data to be forwarded to Bronto
- `destination_config`: map of configurations indicating the type of data to be forwarded as well as the destination
  in Bronto where to send the data to. When forwarding data from Cloudwatch log groups, it is recommended to use account 
level subscription filters and therefore not to add entries for log groups to this map. For data forwarded from S3, only 
data matching entries in this map is forwarded and adding entries is therefore required in that case. `destination_config` takes the following attributes:
  - logname: the Bronto dataset where to send the log data to
  - logset: the Bronto collection that the dataset belongs to
  - log_type: the type of logs, e.g. cloudwatch, s3_access_log
  - set_individual_subscription: if set to true, then a log group subscription filter is set. Otherwise, the forwarder 
  relies on an account level subscription filter. 
  - subscription_filter_pattern: the subscription filter pattern to apply to the log group level subscription filter. 
  This overwrites the default level subscription filter pattern. 
- `paths_regex`: list of regex patterns to match against S3 key, e.g.
- `default_subscription_filter_pattern`: the default filter pattern to apply to cloudwatch log group subscriptions. The 
`subscription_filter_pattern` attribute of entries in `destination_config` takes precedence over 
`default_subscription_filter_pattern`.

```json
[{"pattern": "regex1 with dest_config_id capture group"}, {"pattern": "regex2 with dest_config_id capture group"}]
``` 

Regex expressions follow the [Python syntax](https://docs.python.org/3/library/re.html#regular-expression-syntax). This 
variable defaults to `[]` when not specified. It only needs to be set for cases where AWS
service logs are delivered to custom S3 keys, e.g. objects containing log data are not delivered directly by the AWS 
service and the S3 key of the destination is custom. Note that the regex pattern must include a capture group named 
`dest_config_id`. The value of this group is then matched to entries in the `destination_config` map. For instance,
if `paths_regex` is set to `[{"pattern": ".*/prefix-(?P(dest_config_id)my_config_id)-some-suffix"}` and s3 keys of 
objects delivered to S3 are of the form such as `s3/key/pref/prefix-my_config_id-some-suffix/some/more/suffix`, then the 
entry with key `my_config_id` in the destination configuration above will apply to this log data.
- `attributes`: map of keys and values added to log data as log attributes, e.g. `{ region = "us-east-1", account_id = "12345678"}` 

Lambda artefact:

The lambda code artifact is automatically downloaded from Bronto's Github repository and uploaded to S3. The following 
attributes specify the bucket where to upload the artifact to so that is can be used to define the forwarding lambda. 
- `artifact_bucket`: an object representing the S3 bucket where the lambda code artifact should be stored. If the 
`create` attribute is set to `true`, then a bucket is created with either the specified `name` or with a default name 
(currently `bronto-aws-forwarder-<ACCOUNT_ID>-<REGION>`).
- `artifact_version`: the version of the lambda artifact to be used, e.g. `latest`

### Forwarding from S3:
- `with_s3_notification`: boolean value indicating whether S3 notification should be created with this module (see note below)
- `with_eventbridge_rule`: boolean value indicating whether an EventBridge rule should be created with this module
- `enable_eventbridge_notification`: boolean value indicating whether EventBridge should be used in order to send notifications
- `logging_bucket`: an object defining the name of the bucket and prefix where the data to be forwarded is located 

**Note:** The `with_s3_notification` variable makes it possible to control whether S3 notifications get set up as part of
instantiating this module. In one hand, it is necessary to set an S3 notification on the bucket containing the log data in
order to trigger the lambda function created by this module. On the other hand, the S3 API does not support for S3
notifications to be added but rather for all of them to be set together. Therefore, setting S3 notification with this
module is only relevant if no other notifications are set on the bucket. In order to handle the case of other
notifications being present on the bucket, best is to set `with_s3_notification` to false and create the needed
notifications with already existing Terraform definition for the S3 notification resource.

### Forwarding from Cloudwatch:

The following variables can be used to configure the forwarder when forwarding data from Cloudwatch.
 
- `account_level_cloudwatch_subscription`: configuration to create an account level subscription filter and exclude specific Cloudwatch log groups 
(the Bronto forwarder log group is automatically excluded and does not need to be specified), e.g. `account_level_cloudwatch_subscription = { create = true }`. 
When enabled, data of all log groups will be received and forwarded by the Bronto Lambda forwarder. This is the recommended approach.
Note: AWS currently only support a single account level subscription. So this approach is only suitable if no other account level subscription are already in place. 
- `cloudwatch_default_collection`: the Bronto Collection where Cloudwatch data is sent to. The destination dataset is represented by the log group 
name. More details can be found in the [forwarding Lambda function repository](https://github.com/brontoio/brontobytes-aws-ingestion-python). Destination collections 
and datasets can be overwritten via the `destination_config` parameter described above if required. 
