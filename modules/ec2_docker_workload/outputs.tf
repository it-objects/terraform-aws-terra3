# -----------------------------------------------
# EC2 Docker Workload Module - Outputs
# -----------------------------------------------

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.docker_workload.name
}

output "asg_arn" {
  description = "Auto Scaling Group ARN"
  value       = aws_autoscaling_group.docker_workload.arn
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.docker_workload.id
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = aws_launch_template.docker_workload.latest_version
}

output "security_group_id" {
  description = "Security Group ID for the workload (if created by module)"
  value       = length(aws_security_group.default) > 0 ? aws_security_group.default[0].id : null
}

output "iam_role_arn" {
  description = "ARN of the IAM role for the EC2 instance"
  value       = aws_iam_role.docker_workload_role.arn
}

output "iam_role_name" {
  description = "Name of the IAM role for the EC2 instance"
  value       = aws_iam_role.docker_workload_role.name
}

output "log_group_name" {
  description = "CloudWatch log group name for Docker container logs"
  value       = aws_cloudwatch_log_group.docker_logs.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.docker_logs.arn
}

output "ssm_security_group_parameter" {
  description = "SSM Parameter path for the security group ID"
  value       = aws_ssm_parameter.security_group_id.name
}

output "ssm_log_group_parameter" {
  description = "SSM Parameter path for the log group name"
  value       = aws_ssm_parameter.log_group_name.name
}

output "docker_image_uri" {
  description = "Docker image URI being run"
  value       = var.docker_image_uri
}

output "instance_name" {
  description = "Instance/workload name"
  value       = var.instance_name
}

output "solution_name" {
  description = "Solution name"
  value       = var.solution_name
}
