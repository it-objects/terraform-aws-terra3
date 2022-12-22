# ---------------------------------------------------------------------------------------------------------------------
# AWS CloudWatch alarm
# to send a notification when the alarm reaches the desired alarm state
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ECS_Service_CPU_Usage_High" {
  count               = var.cpu_utilization_alert ? 1 : 0
  alarm_name          = "ECS_CPU_UTILISATION_High_Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_utilization_high_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.cpu_utilization_high_period
  statistic           = "Average"
  threshold           = var.cpu_utilization_high_threshold
  alarm_description   = "This metric monitors ecs service cpu utilization exceeding ${var.cpu_utilization_high_threshold}%."
  alarm_actions       = [aws_sns_topic.ECS_service_CPU_and_Memory_Utilization_topic.arn]

  dimensions = {
    ServiceName = "my_app_componentService"
    ClusterName = var.container_runtime
  }
}

resource "aws_cloudwatch_metric_alarm" "ECS_Service_CPU_Usage_Low" {
  count               = var.cpu_utilization_alert ? 1 : 0
  alarm_name          = "ECS_CPU_UTILISATION_Low_Alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.cpu_utilization_low_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.cpu_utilization_low_period
  statistic           = "Average"
  threshold           = var.cpu_utilization_low_threshold
  alarm_description   = "This metric monitors ecs service cpu utilization less than ${var.cpu_utilization_low_threshold}%."
  alarm_actions       = [aws_sns_topic.ECS_service_CPU_and_Memory_Utilization_topic.arn]

  dimensions = {
    ServiceName = "my_app_componentService"
    ClusterName = var.container_runtime
  }
}

resource "aws_cloudwatch_metric_alarm" "ECS_Service_MEMORY_Usage_High" {
  count               = var.memory_utilization_alert ? 1 : 0
  alarm_name          = "ECS_Memory_Utilization_High_Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.memory_utilization_high_evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.memory_utilization_high_period
  statistic           = "Average"
  threshold           = var.memory_utilization_high_threshold
  alarm_description   = "This metric monitors ecs service cpu utilization exceeding ${var.memory_utilization_high_threshold}%."
  alarm_actions       = [aws_sns_topic.ECS_service_CPU_and_Memory_Utilization_topic.arn]

  dimensions = {
    ServiceName = "my_app_componentService"
    ClusterName = var.container_runtime
  }
}

resource "aws_cloudwatch_metric_alarm" "ECS_Service_MEMORY_Usage_Low" {
  count               = var.memory_utilization_alert ? 1 : 0
  alarm_name          = "ECS_Memory_Utilization_Low_Alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.memory_utilization_low_evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.memory_utilization_low_period
  statistic           = "Average"
  threshold           = var.memory_utilization_low_threshold
  alarm_description   = "This metric monitors ecs service cpu utilization less than ${var.memory_utilization_low_threshold}%."
  alarm_actions       = [aws_sns_topic.ECS_service_CPU_and_Memory_Utilization_topic.arn]

  dimensions = {
    ServiceName = "my_app_componentService"
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
