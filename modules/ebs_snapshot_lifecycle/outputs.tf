# -----------------------------------------------
# EBS Snapshot Lifecycle - Outputs
# -----------------------------------------------

output "ssm_parameter_name" {
  description = "SSM parameter name storing the latest snapshot ID"
  value       = local.ssm_param_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name used for idempotency tracking"
  value       = aws_dynamodb_table.lifecycle.name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for snapshot failure alerts"
  value       = local.sns_topic_arn
}
