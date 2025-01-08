## Migrations

### From 0.x to 1.x

Version 1.0.0 introduces the lambda forwarder Cloudwatch log group definition. For forwarder that are already setup 
and running, this log group already exists. This will lead to an error when applying this module with Terraform. To 
overcome, this issue:

- either delete the Bronto Forwarder log group in the corresponding AWS account,
- or import the log group resource via a command similar to:

```
terraform import 'module.bronto_forwarder.aws_cloudwatch_log_group.this' '/aws/lambda/bronto_forwarder'
```
