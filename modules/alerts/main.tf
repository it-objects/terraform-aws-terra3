# ---------------------------------------------------------------------------------------------------------------------
# AWS CloudWatch alarm
# to send a notification when the alarm reaches the desired alarm state
# ---------------------------------------------------------------------------------------------------------------------
locals {
  metric_name = var.metric_type == "CPU_UTILISATION" ? "CPUUtilization" : "MemoryUtilization"

  high_evaluation_periods = var.metric_type == "CPU_UTILISATION" ? var.cpu_utilization_high_evaluation_periods : var.memory_utilization_high_evaluation_periods
  high_period             = var.metric_type == "CPU_UTILISATION" ? var.cpu_utilization_high_period : var.memory_utilization_high_period
  high_threshold          = var.metric_type == "CPU_UTILISATION" ? var.cpu_utilization_high_threshold : var.memory_utilization_high_threshold

  low_evaluation_periods = var.metric_type == "CPU_UTILISATION" ? var.cpu_utilization_low_evaluation_periods : var.memory_utilization_low_evaluation_periods
  low_period             = var.metric_type == "CPU_UTILISATION" ? var.cpu_utilization_low_period : var.memory_utilization_low_period
  low_threshold          = var.metric_type == "CPU_UTILISATION" ? var.cpu_utilization_low_threshold : var.memory_utilization_low_threshold
}

resource "aws_cloudwatch_metric_alarm" "ECS_Service_Usage_High" {
  alarm_name          = "ECS_${var.metric_type}_High_Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.high_evaluation_periods
  metric_name         = local.metric_name
  namespace           = "AWS/ECS"
  period              = local.high_period
  statistic           = "Average"
  threshold           = local.high_threshold
  alarm_description   = "This metric monitors ecs service ${var.metric_type} exceeding ${local.high_threshold}%."
  alarm_actions       = [aws_sns_topic.ECS_service_CPU_and_Memory_Utilization_topic.arn]

  dimensions = {
    #ServiceName = var.ecs_service_name
    ClusterName = var.container_runtime
  }
}

resource "aws_cloudwatch_metric_alarm" "ECS_Service_Usage_Low" {
  alarm_name          = "ECS_${var.metric_type}_Low_Alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = local.low_evaluation_periods
  metric_name         = local.metric_name
  namespace           = "AWS/ECS"
  period              = local.low_period
  statistic           = "Average"
  threshold           = local.low_threshold
  alarm_description   = "This metric monitors ecs service ${var.metric_type} less than ${local.low_threshold}%."
  alarm_actions       = [aws_sns_topic.ECS_service_CPU_and_Memory_Utilization_topic.arn]

  dimensions = {
    #ServiceName = var.ecs_service_name
    ClusterName = var.container_runtime
  }
}

#tfsec:ignore:aws-sns-enable-topic-encryption
resource "aws_sns_topic" "ECS_service_CPU_and_Memory_Utilization_topic" {
  name = "ECS_service_CPU_and_Memory_Utilization_SNS_topic"
}

resource "aws_sns_topic_subscription" "ECS_service_CPU_and_Memory_Utilization_SNS_Subscription" {
  topic_arn = aws_sns_topic.ECS_service_CPU_and_Memory_Utilization_topic.arn
  protocol  = "email"
  endpoint  = var.endpoint_email
}
