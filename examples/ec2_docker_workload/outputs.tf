# -----------------------------------------------
# EC2 Docker Workload Example - Outputs
# -----------------------------------------------

output "postgres_asg_name" {
  description = "Auto Scaling Group name for PostgreSQL workload"
  value       = module.postgres_docker.asg_name
}

output "postgres_asg_arn" {
  description = "Auto Scaling Group ARN for PostgreSQL workload"
  value       = module.postgres_docker.asg_arn
}

output "postgres_security_group_id" {
  description = "Security group ID for PostgreSQL EC2 workload"
  value       = module.postgres_docker.security_group_id
}

output "postgres_log_group" {
  description = "CloudWatch log group for PostgreSQL Docker logs"
  value       = module.postgres_docker.log_group_name
}

output "postgres_iam_role_arn" {
  description = "IAM role ARN for PostgreSQL EC2 instance"
  value       = module.postgres_docker.iam_role_arn
}

# -----------------------------------------------
# ECS Testing Service Outputs
# -----------------------------------------------

output "ecs_psql_test_service" {
  description = "ECS service reference for PostgreSQL testing"
  value       = "The psql_test service runs in the ECS cluster created by Terra3"
}

output "postgres_endpoint_ssm_parameter" {
  description = "SSM parameter path for PostgreSQL endpoint discovery"
  value       = aws_ssm_parameter.postgres_endpoint.name
}