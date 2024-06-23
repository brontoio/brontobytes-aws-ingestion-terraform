# BrontoBytes AWS Log Forwarder

Terraform module to set up a lambda function and necessary permissions to forward to BrontoBytes
logs delivered to AWS S3 and Cloudwatch.

In particular, it contains a lambda function that gets triggered based on
- S3 notifications when a new object is created in the `logging bucket`
- A Cloudwatch subscription when new data is received in Cloudwatch

This approach should cover most if not all the logging needs regarding AWS services. The list of services whose logs
are delivered to S3 or Cloudwatch is provided in the table at https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AWS-logs-and-resource-policy.html#AWS-logs-infrastructure-S3.
In some cases (when we found an available parser/regex), the log entries are parsed by the lambda function in order to
forward these entries in Json format to BrontoBytes, so that the structured is preserved there.

**Note:** The `with_s3_notification` variable makes it possible to control whether S3 notifications get set up as part of 
instantiating this module. In one hand, it is necessary to set an S3 notification on the bucket containing the log data in
order to trigger the lambda function created by this module. On the other hand, the S3 API does not support for S3 
notifications to be added but rather for all of them to be set together. Therefore, setting S3 notification with this 
module is only relevant if no other notifications are set on the bucket. In order to handle the case of other 
notifications being present on the bucket, best is to set `with_s3_notification` to false and create the needed 
notifications the same was as the other ones are.