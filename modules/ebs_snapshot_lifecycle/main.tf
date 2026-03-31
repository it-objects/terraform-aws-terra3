# -----------------------------------------------
# EBS Snapshot Lifecycle - Main
# -----------------------------------------------
# Automatically snapshots EBS volumes when ECS Fargate tasks stop
# and stores the latest snapshot ID in SSM for restore on next launch.
#
# Safety features:
# - DynamoDB idempotency table prevents concurrent processing
# - Loop prevention via task tagging
# - Blocks restart on failure (desiredCount=0) with SNS alerting
# - Waits for snapshot completion before updating service
# -----------------------------------------------

locals {
  ssm_param_name = "/${var.solution_name}/ebs_snapshot/${var.app_component_name}/latest_snapshot_id"
  create_sns     = var.alarm_sns_topic_arn == null
  sns_topic_arn  = local.create_sns ? aws_sns_topic.snapshot_failed[0].arn : var.alarm_sns_topic_arn
}

# -----------------------------------------------
# DynamoDB table for idempotency
# -----------------------------------------------

#tfsec:ignore:aws-dynamodb-table-customer-key -- AWS managed key is sufficient for idempotency tracking
resource "aws_dynamodb_table" "lifecycle" {
  name         = "${var.solution_name}-${var.app_component_name}-ebs-lifecycle"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "volumeId"
  range_key    = "taskArn"

  attribute {
    name = "volumeId"
    type = "S"
  }

  attribute {
    name = "taskArn"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = var.tags
}

# -----------------------------------------------
# SNS topic for failure alerts (created only if not provided)
# -----------------------------------------------

#tfsec:ignore:aws-sns-topic-encryption-use-cmk -- AWS managed key is sufficient for failure alerts
resource "aws_sns_topic" "snapshot_failed" {
  count = local.create_sns ? 1 : 0

  name              = "${var.solution_name}-${var.app_component_name}-ebs-snapshot-failed"
  kms_master_key_id = "alias/aws/sns"
  tags              = var.tags
}

# -----------------------------------------------
# CloudWatch metric filter + alarm for snapshot failures
# -----------------------------------------------

resource "aws_cloudwatch_log_metric_filter" "snapshot_failed" {
  name           = "${var.solution_name}-${var.app_component_name}-snapshot-failed"
  log_group_name = module.snapshot_lambda.lambda_cloudwatch_log_group_name
  pattern        = "SNAPSHOT_FAILED"

  metric_transformation {
    name          = "SnapshotFailureCount"
    namespace     = "${var.solution_name}/EBSSnapshotLifecycle"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "snapshot_failed" {
  alarm_name          = "${var.solution_name}-${var.app_component_name}-ebs-snapshot-failed"
  alarm_description   = "EBS snapshot failed for ${var.solution_name}/${var.app_component_name}. Service restart blocked. Manual intervention required."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "SnapshotFailureCount"
  namespace           = "${var.solution_name}/EBSSnapshotLifecycle"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [local.sns_topic_arn]
  ok_actions    = [local.sns_topic_arn]

  tags = var.tags
}

# -----------------------------------------------
# Lambda function for snapshotting EBS volumes
# -----------------------------------------------

module "snapshot_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.20.1"

  function_name = "${var.solution_name}-${var.app_component_name}-ebs-snap"
  description   = "Snapshots EBS volumes on ECS task stop for ${var.solution_name}/${var.app_component_name}"
  handler       = "snapshot.handler"
  runtime       = "nodejs22.x"
  timeout       = 600

  source_path = "${path.module}/snapshot.mjs"

  tracing_mode = "Active"

  environment_variables = {
    SSM_PARAM_NAME         = local.ssm_param_name
    SOLUTION_NAME          = var.solution_name
    APP_COMPONENT_NAME     = var.app_component_name
    RETENTION_COUNT        = tostring(var.snapshot_retention_count)
    ECS_CLUSTER_ARN        = var.cluster_arn
    ECS_SERVICE_NAME       = var.ecs_service_name
    VOLUME_NAME            = var.volume_name
    DYNAMODB_TABLE_NAME    = aws_dynamodb_table.lifecycle.name
    SNS_TOPIC_ARN          = local.sns_topic_arn
    FILE_SYSTEM_TYPE       = var.file_system_type
    BACKUP_RETENTION_COUNT = tostring(var.backup_retention_count)
  }

  attach_policies    = true
  number_of_policies = 1
  policies           = [aws_iam_policy.lambda_ebs_snapshot.arn]

  cloudwatch_logs_retention_in_days = 30

  trigger_on_package_timestamp = false

  tags = var.tags
}

# -----------------------------------------------
# EventBridge rule: ECS task stopping
# -----------------------------------------------

resource "aws_cloudwatch_event_rule" "ecs_task_stopped" {
  name        = "${var.solution_name}-${var.app_component_name}-ebs-snap"
  description = "Trigger EBS snapshot when ECS task is stopping for ${var.app_component_name}"

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Task State Change"]
    detail = {
      clusterArn    = [var.cluster_arn]
      lastStatus    = ["STOPPING"]
      desiredStatus = ["STOPPED"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "snapshot_lambda" {
  rule = aws_cloudwatch_event_rule.ecs_task_stopped.name
  arn  = module.snapshot_lambda.lambda_function_arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.snapshot_lambda.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_task_stopped.arn
}

# -----------------------------------------------
# Scheduled Backup (optional cron-based snapshots)
# -----------------------------------------------

resource "aws_cloudwatch_event_rule" "scheduled_backup" {
  count               = var.enable_scheduled_backup ? 1 : 0
  name                = "${var.solution_name}-${var.app_component_name}-ebs-backup"
  description         = "Scheduled EBS backup for ${var.app_component_name}"
  schedule_expression = var.backup_schedule
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "scheduled_backup" {
  count = var.enable_scheduled_backup ? 1 : 0
  rule  = aws_cloudwatch_event_rule.scheduled_backup[0].name
  arn   = module.snapshot_lambda.lambda_function_arn
}

resource "aws_lambda_permission" "scheduled_backup" {
  count         = var.enable_scheduled_backup ? 1 : 0
  statement_id  = "AllowScheduledBackupInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.snapshot_lambda.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduled_backup[0].arn
}
