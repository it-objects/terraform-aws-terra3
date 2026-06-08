output "lambda_function_arn" {
  description = "ARN of the AMI updater Lambda function"
  value       = module.lambda.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the AMI updater Lambda function"
  value       = module.lambda.lambda_function_name
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule that triggers AMI checks"
  value       = module.eventbridge.eventbridge_rule_arns["ami_check"]
}

output "lambda_log_group_name" {
  description = "CloudWatch log group for the AMI updater Lambda"
  value       = module.lambda.lambda_cloudwatch_log_group_name
}
