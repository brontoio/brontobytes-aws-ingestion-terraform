# brontobytes-aws-ingestion-terraform

Terraform module to set up a lambda function and necessary permissions to forward to BrontoBytes
logs delivered to AWS S3 and Cloudwatch.

In particular, it contains a lambda function that gets triggered based on
- S3 notifications when a new object is created in the `logging bucket`
- A Cloudwatch subscription when new data is received in Cloudwatch

This approach should cover most if not all the logging needs regarding AWS services. The list of services whose logs
are delivered to S3 or Cloudwatch is provided in the table at https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AWS-logs-and-resource-policy.html#AWS-logs-infrastructure-S3.
In some cases (when we found an available parser/regex), the log entries are parsed by the lambda function in order to
forward these entries in Json format to BrontoBytes, so that the structured is preserved there.
