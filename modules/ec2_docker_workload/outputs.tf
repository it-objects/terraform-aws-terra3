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

output "backup_vault_arn" {
  description = "ARN of the AWS Backup vault (if backups enabled)"
  value       = try(aws_backup_vault.docker_workload[0].arn, null)
}

output "backup_plan_arn" {
  description = "ARN of the AWS Backup plan (if backups enabled)"
  value       = try(aws_backup_plan.docker_workload[0].arn, null)
}

output "backup_enabled" {
  description = "Whether automated backups are enabled"
  value       = var.enable_backup
}

output "internal_dns_fqdn" {
  description = "Fully qualified domain name for accessing this workload internally"
  value       = try(aws_route53_record.workload[0].fqdn, null)
}

output "internal_dns_hostname" {
  description = "Internal hostname for this workload (without FQDN)"
  value       = try(aws_route53_record.workload[0].name, null)
}

output "route53_updater_lambda_arn" {
  description = "ARN of the Lambda function that updates Route53 DNS records on instance launch (if internal DNS enabled)"
  value       = try(aws_lambda_function.route53_updater[0].arn, null)
}

output "route53_updater_lambda_name" {
  description = "Name of the Lambda function that updates Route53 DNS records (if internal DNS enabled)"
  value       = try(aws_lambda_function.route53_updater[0].function_name, null)
}

output "persistent_volume_ids" {
  description = "IDs of persistent EBS volumes (persisted across instance termination/restart)"
  value       = [for vol in aws_ebs_volume.persistent : vol.id]
}

output "persistent_volume_devices" {
  description = "Device names and volume IDs for persistent EBS volumes"
  value = {
    for idx, vol in aws_ebs_volume.persistent :
    local.persistent_volumes[idx].device_name => vol.id
  }
}

output "target_group_arn" {
  description = "ARN of the ALB target group (if ALB enabled)"
  value       = try(aws_lb_target_group.alb[0].arn, null)
}

output "target_group_name" {
  description = "Name of the ALB target group (if ALB enabled)"
  value       = try(aws_lb_target_group.alb[0].name, null)
}

output "listener_rule_arn" {
  description = "ARN of the ALB listener rule (if ALB enabled)"
  value       = try(aws_lb_listener_rule.alb[0].arn, null)
}

output "alb_listener_arn_used" {
  description = "Which ALB listener ARN is being used for the rule (for debugging)"
  value       = local.alb_listener_arn
}

output "use_https_listener" {
  description = "Whether HTTPS listener is being used (for debugging)"
  value       = local.use_https_listener
}

output "path_mapping_configured" {
  description = "Path mapping pattern being used"
  value       = var.path_mapping
}

output "listener_rule_created" {
  description = "Whether listener rule resource was created"
  value       = length(aws_lb_listener_rule.alb) > 0
}

output "target_group_created" {
  description = "Whether ALB target group resource was created"
  value       = length(aws_lb_target_group.alb) > 0
}
