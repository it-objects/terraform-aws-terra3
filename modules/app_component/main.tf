# ---------------------------------------------------------------------------------------------------------------------
# App Component (AWS)
# Features (pre-configured)
# - debug: ECS Connect
# - costs: scale down on non-working hours (can save costs for non-prod environments)
# - security: default read-only root filesystem for containers (complies with Basic Sec rules)
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# Service definition, auto heals if task shuts down
# ---------------------------------------------------------------------------------------------------------------------
locals {
  launch_type = var.cluster_type == "FARGATE" || var.cluster_type == "FARGATE_SPOT" ? "FARGATE" : "EC2"

  security_groups = length(var.service_sg) == 0 ? [
    data.aws_security_group.ecs_default_sg.id,
    data.aws_security_group.mysql_marker_sg.id,
    data.aws_security_group.redis_marker_sg.id,
    data.aws_security_group.postgres_marker_sg.id
  ] : var.service_sg
  security_groups_as_string = jsonencode(local.security_groups)

  # convert string to list
  private_subnets           = split(",", data.aws_ssm_parameter.private_subnets.value)
  private_subnets_as_string = jsonencode(local.private_subnets)

  # configure dependent options in case of cronjob mode
  enable_autoscaling       = length(var.configure_as_cronjob) >= 1 ? false : var.enable_autoscaling
  internal_service         = length(var.configure_as_cronjob) >= 1 ? true : var.internal_service
  cpu_utilization_alert    = length(var.configure_as_cronjob) >= 1 ? false : var.cpu_utilization_alert
  memory_utilization_alert = length(var.configure_as_cronjob) >= 1 ? false : var.memory_utilization_alert
  task_count_alert         = length(var.configure_as_cronjob) >= 1 ? false : var.task_count_alert

  timeout_in_seconds = 300 # the time in seconds after the cronjob should be terminated
}

resource "aws_ecs_service" "ecs_service" {
  count = length(var.configure_as_cronjob) == 0 ? 1 : 0

  name            = "${var.name}Service"
  cluster         = data.aws_ecs_cluster.selected.arn
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = var.instances
  launch_type     = local.launch_type # FARGATE | EC2

  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  # for ECS exec
  enable_execute_command = var.enable_ecs_exec

  network_configuration {
    subnets = local.private_subnets
    # if security groups are given, then overwrite default, otherwise take default (ecs_default + mysql_marker)
    security_groups = local.security_groups
  }

  dynamic "load_balancer" {
    for_each = local.internal_service ? [] : [true]
    content {
      target_group_arn = aws_lb_target_group.target_group[0].arn
      container_name   = var.container[0].name
      container_port   = var.service_port
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Ignored desired count changes live, permitting schedulers to update this value without terraform reverting
  lifecycle {
    ignore_changes = [desired_count]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Task definition
# Will be relaunched by service frequently
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = var.name
  execution_role_arn       = aws_iam_role.ExecutionRole.arn
  task_role_arn            = aws_iam_role.task.arn
  network_mode             = "awsvpc"
  requires_compatibilities = [local.launch_type]

  # Fargate cpu/mem must match available options: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
  cpu    = var.total_cpu
  memory = var.total_memory

  container_definitions = local.json_map

  tags = {
    Name = "${var.name}-task-def"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Link to loadbalancer: target group and lb listener
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lb_target_group" "target_group" {
  count = local.internal_service ? 0 : 1

  name_prefix          = substr(replace(var.name, "_", "-"), 0, 6)
  port                 = var.service_port
  protocol             = "HTTP"
  vpc_id               = data.aws_ssm_parameter.vpc_id.value
  target_type          = "ip"
  deregistration_delay = var.deregistration_delay

  health_check {
    healthy_threshold   = "3"
    port                = var.lb_healthcheck_port
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.lb_healthcheck_url
    unhealthy_threshold = "2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## HTTPS (Port 443) listener rules
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_lb_listener_rule" "https_listener_rule" {
  count = var.enable_custom_domain && !local.internal_service ? 1 : 0

  listener_arn = data.aws_ssm_parameter.alb_listener_443_arn.value
  priority     = var.listener_rule_prio

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[0].arn
  }

  # Exactly one of host_header, http_header, http_request_method, path_pattern, query_string or source_ip must be set per condition.
  # Multiple conditions declare an AND operation
  condition {
    path_pattern {
      values = [var.path_mapping]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# attaches trailing slash in case it recognizes one
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lb_listener_rule" "https_trailing_slash_redirect" {
  count = var.enable_custom_domain && !local.internal_service ? 1 : 0

  listener_arn = data.aws_ssm_parameter.alb_listener_443_arn.value
  priority     = var.listener_rule_prio + 1 # make rule appear after the default rule

  action {
    type = "redirect"
    redirect {
      host        = "#{host}"
      path        = "/#{path}/" # trailing slash is added here
      query       = "#{query}"
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }

  # Exactly one of host_header, http_header, http_request_method, path_pattern, query_string or source_ip must be set per condition.
  # Multiple conditions declare an AND operation
  condition {
    path_pattern {
      values = [(length(var.path_mapping) > 2) ? trimsuffix(var.path_mapping, "/*") : var.path_mapping]
    }
  }
}

resource "aws_lb_listener_rule" "http_listener_rule" {
  count = !var.enable_custom_domain && !local.internal_service ? 1 : 0

  listener_arn = data.aws_ssm_parameter.alb_listener_80_arn.value
  priority     = var.listener_rule_prio

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[0].arn
  }

  # Exactly one of host_header, http_header, http_request_method, path_pattern, query_string or source_ip must be set per condition.
  # Multiple conditions declare an AND operation
  condition {
    path_pattern {
      values = [var.path_mapping]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# attaches trailing slash in case it recognizes one
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lb_listener_rule" "http_trailing_slash_redirect" {
  count = !var.enable_custom_domain && !local.internal_service ? 1 : 0

  listener_arn = data.aws_ssm_parameter.alb_listener_80_arn.value
  priority     = var.listener_rule_prio + 1 # make rule appear after the default rule

  action {
    type = "redirect"
    redirect {
      host        = "#{host}"
      path        = "/#{path}/" # trailing slash is added here
      query       = "#{query}"
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }

  # Exactly one of host_header, http_header, http_request_method, path_pattern, query_string or source_ip must be set per condition.
  # Multiple conditions declare an AND operation
  condition {
    path_pattern {
      values = [(length(var.path_mapping) > 2) ? trimsuffix(var.path_mapping, "/*") : var.path_mapping]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Cloudwatch to store logs
# ---------------------------------------------------------------------------------------------------------------------
#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "CloudWatchLogGroup" {
  name = "${var.name}LogGroup"

  retention_in_days = 7

  tags = {
    Name = "${var.name}LogGroup"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AWS CloudWatch alarm
# to send a notification when the alarm reaches the desired alarm state
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ecs_service_cpu_utilization_high" {
  count               = local.cpu_utilization_alert && var.cpu_utilization_high_threshold != 0 ? 1 : 0
  alarm_name          = "ecs_svc_cpu_high_${var.name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_utilization_high_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.cpu_utilization_high_period
  statistic           = "Average"
  threshold           = var.cpu_utilization_high_threshold
  alarm_description   = "This metric monitors ecs service cpu utilization exceeding ${var.cpu_utilization_high_threshold}%."
  alarm_actions       = var.sns_topic_arn
  ok_actions          = var.sns_topic_arn

  dimensions = {
    ServiceName = aws_ecs_service.ecs_service[0].name
    ClusterName = var.container_runtime
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_cpu_utilization_low" {
  count               = local.cpu_utilization_alert && var.cpu_utilization_low_threshold != 0 ? 1 : 0
  alarm_name          = "ecs_svc_cpu_low_${var.name}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.cpu_utilization_low_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.cpu_utilization_low_period
  statistic           = "Average"
  threshold           = var.cpu_utilization_low_threshold
  alarm_description   = "This metric monitors ecs service cpu utilization less than ${var.cpu_utilization_low_threshold}%."
  alarm_actions       = var.sns_topic_arn
  ok_actions          = var.sns_topic_arn

  dimensions = {
    ServiceName = aws_ecs_service.ecs_service[0].name
    ClusterName = var.container_runtime
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_memory_utilization_high" {
  count               = local.memory_utilization_alert && var.memory_utilization_high_threshold != 0 ? 1 : 0
  alarm_name          = "ecs_svc_mem_high_${var.name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.memory_utilization_high_evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.memory_utilization_high_period
  statistic           = "Average"
  threshold           = var.memory_utilization_high_threshold
  alarm_description   = "This metric monitors ecs service cpu utilization exceeding ${var.memory_utilization_high_threshold}%."
  alarm_actions       = var.sns_topic_arn
  ok_actions          = var.sns_topic_arn

  dimensions = {
    ServiceName = aws_ecs_service.ecs_service[0].name
    ClusterName = var.container_runtime
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_memory_utilization_low" {
  count               = local.memory_utilization_alert && var.memory_utilization_low_threshold != 0 ? 1 : 0
  alarm_name          = "ecs_svc_mem_low_${var.name}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.memory_utilization_low_evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.memory_utilization_low_period
  statistic           = "Average"
  threshold           = var.memory_utilization_low_threshold
  alarm_description   = "This metric monitors ecs service cpu utilization less than ${var.memory_utilization_low_threshold}%."
  alarm_actions       = var.sns_topic_arn
  ok_actions          = var.sns_topic_arn

  dimensions = {
    ServiceName = aws_ecs_service.ecs_service[0].name
    ClusterName = var.container_runtime
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# Autoscaling based on CPU and MEMORY Utilisation for scaling up and down to save costs.
# ---------------------------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------------
# Create autoscaling target linked to ECS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.enable_ecs_autoscaling ? 1 : 0
  max_capacity       = var.ecs_autoscaling_max_capacity
  min_capacity       = var.ecs_autoscaling_min_capacity
  resource_id        = "service/${var.container_runtime}/${aws_ecs_service.ecs_service[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# ---------------------------------------------------------------------------------------------------------------------
# Scale up based on CPU and MEMORY Utilisation
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_appautoscaling_policy" "ecs_target_cpu" {
  count              = var.enable_ecs_autoscaling && var.ecs_autoscaling_metric_type == "CPU_UTILISATION" ? 1 : 0
  name               = "${var.name}-auto-scaling-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.ecs_autoscaling_target_value
  }
  depends_on = [aws_appautoscaling_target.ecs_target]
}

resource "aws_appautoscaling_policy" "ecs_target_memory" {
  count              = var.enable_ecs_autoscaling && var.ecs_autoscaling_metric_type == "MEMORY_UTILISATION" ? 1 : 0
  name               = "${var.name}-auto-scaling-policy-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.ecs_autoscaling_target_value
  }
  depends_on = [aws_appautoscaling_target.ecs_target]
}

locals {
  metric_name        = !var.enable_container_insights ? "CPUUtilization" : "RunningTaskCount"
  namespace          = !var.enable_container_insights ? "AWS/ECS" : "ECS/ContainerInsights"
  statistics         = !var.enable_container_insights ? "SampleCount" : "Average"
  treat_missing_data = !var.enable_container_insights ? "breaching" : "missing"
}

resource "aws_cloudwatch_metric_alarm" "ecs_running_task_count" {
  count               = local.task_count_alert ? 1 : 0
  alarm_name          = "ecs_running_task_count_${var.name}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.task_count_evaluation_periods
  metric_name         = local.metric_name
  namespace           = local.namespace
  period              = var.task_count_period
  statistic           = local.statistics
  threshold           = var.task_count_threshold
  alarm_description   = "This metric send alert when running ecs task count is less than ${var.task_count_threshold} for ${var.task_count_period} seconds."
  alarm_actions       = var.sns_topic_arn
  ok_actions          = var.sns_topic_arn
  treat_missing_data  = local.treat_missing_data

  dimensions = {
    ServiceName = aws_ecs_service.ecs_service[0].name
    ClusterName = var.container_runtime
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Autoscaling logic for scaling up and down to save costs and for resets
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# Create autoscaling target linked to ECS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_appautoscaling_target" "ServiceAutoScalingTarget" {
  count              = local.enable_autoscaling ? 1 : 0
  min_capacity       = var.autoscale_task_weekday_scale_down
  max_capacity       = var.desired_count
  resource_id        = "service/${var.container_runtime}/${aws_ecs_service.ecs_service[0].name}" # service/(clusterName)/(serviceName)
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  lifecycle {
    ignore_changes = [
      min_capacity,
      max_capacity,
    ]
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# Scale down on weekdays logic to save costs
# Scale up weekdays at beginning of day
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_appautoscaling_scheduled_action" "WeekdayScaleUp" {
  count              = local.enable_autoscaling ? 1 : 0
  name               = "${var.name}ScaleUp"
  service_namespace  = aws_appautoscaling_target.ServiceAutoScalingTarget[0].service_namespace
  resource_id        = aws_appautoscaling_target.ServiceAutoScalingTarget[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ServiceAutoScalingTarget[0].scalable_dimension
  schedule           = var.autoscale_up_event
  timezone           = "Europe/Berlin"

  scalable_target_action {
    min_capacity = var.desired_count
    max_capacity = var.desired_count
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Scale down weekdays at end of day
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_appautoscaling_scheduled_action" "WeekdayScaleDown" {
  count              = local.enable_autoscaling ? 1 : 0
  name               = "${var.name}ScaleDown"
  service_namespace  = aws_appautoscaling_target.ServiceAutoScalingTarget[0].service_namespace
  resource_id        = aws_appautoscaling_target.ServiceAutoScalingTarget[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ServiceAutoScalingTarget[0].scalable_dimension
  schedule           = var.autoscale_down_event
  timezone           = "Europe/Berlin"

  scalable_target_action {
    min_capacity = var.autoscale_task_weekday_scale_down
    max_capacity = var.autoscale_task_weekday_scale_down
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ECS Exec specific
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# IAM Role Definitions
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "ExecutionRole" {
  name = "${var.name}-ExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "${var.name}ExecutionRole"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Link to AWS-managed policy - AmazonECSTaskExecutionRolePolicy
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ExecutionRole_to_ecsTaskExecutionRole" {
  role       = aws_iam_role.ExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------------------------------------------------------------------------------------------------------------------
# required task role to access cf private key
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "ssm_parameter_cloudfront_private_key" {
  #count = var.enable_ecs_exec ? 1 : 0

  name   = "cf-private-key-access-permissions"
  role   = aws_iam_role.ExecutionRole.id
  policy = data.aws_iam_policy_document.ssm_parameter_cloudfront_private_key.json
}

data "aws_iam_policy_document" "ssm_parameter_cloudfront_private_key" {
  #count = var.enable_ecs_exec ? 1 : 0
  statement {
    sid       = "cfPrivatekeyAccessPermissions"
    effect    = "Allow"
    resources = ["arn:aws:ssm:${data.aws_region.current_region.name}:${data.aws_caller_identity.this.account_id}:parameter/${var.solution_name}/cloudfront/*"]
    actions = [
      "ssm:GetParameters"
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Construct IAM policies
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Find all secret ARNs and output as a list
  execution_iam_secrets = try(
    flatten([
      for permission_type, permission_targets in var.execution_iam_access : [
        for secret in permission_targets : "${secret}*"
      ]
      if permission_type == "secrets"
    ]),
    # If nothing provided, default to empty set
    [],
  )

  # Final all S3 bucket ARNs and output as list
  execution_iam_s3_buckets = try(
    flatten([
      for permission_type, permission_targets in var.execution_iam_access : permission_targets if permission_type == "s3_buckets"
    ]),
    # If nothing provided, default to empty set
    [],
  )

  # Find all S3 bucket ARNs and output as list for object access
  execution_iam_s3_buckets_object_access = try(
    flatten(
      [
        for buckets in local.execution_iam_s3_buckets : "${buckets}/*"
      ]
    ),
    # If nothing provided, default to empty set
    [],
  )

  # Find all KMS CMK ARNs passed to module and output as a list
  execution_iam_kms_cmk = try(
    flatten([
      for permission_type, permission_targets in var.execution_iam_access : [
        for kms_cmk in permission_targets : kms_cmk
      ]
      if permission_type == "kms_cmk"
    ]),
    # If nothing provided, default to empty set
    [],
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# Construct the secrets policy
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "ecs_secrets_access" {
  count = local.execution_iam_secrets == [] ? 0 : 1
  statement {
    sid = "EcsSecretAccess"
    #effect = "Allow"
    resources = local.execution_iam_secrets
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Build role policy using data, link to role
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "ecs_secrets_access_role_policy" {
  count  = local.execution_iam_secrets == [] ? 0 : 1
  name   = "EcsSecretExecutionRolePolicy"
  role   = aws_iam_role.ExecutionRole.id
  policy = data.aws_iam_policy_document.ecs_secrets_access[0].json
}

# ---------------------------------------------------------------------------------------------------------------------
# Construct the S3 bucket list policy
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "s3_bucket_list_access" {
  count = local.execution_iam_s3_buckets == [] ? 0 : 1
  statement {
    sid       = "S3ListBucketAccess"
    effect    = "Allow"
    resources = local.execution_iam_s3_buckets
    actions = [
      "s3:ListBucket",
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Build role policy using data, link to role
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "ecs_s3_bucket_list_access_role_policy" {
  count  = local.execution_iam_s3_buckets == [] ? 0 : 1
  name   = "EcsS3BucketListExecutionRolePolicy"
  role   = aws_iam_role.ExecutionRole.id
  policy = data.aws_iam_policy_document.s3_bucket_list_access[0].json
}

# ---------------------------------------------------------------------------------------------------------------------
# Construct the S3 bucket object policy
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "s3_bucket_object_access" {
  count = local.execution_iam_s3_buckets_object_access == [] ? 0 : 1
  statement {
    sid       = "S3BucketObjectAccess"
    effect    = "Allow"
    resources = local.execution_iam_s3_buckets_object_access
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Build role policy using data, link to role
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "ecs_s3_bucket_object_access_role_policy" {
  count  = local.execution_iam_s3_buckets_object_access == [] ? 0 : 1
  name   = "EcsS3BucketObjectAccessExecutionRolePolicy"
  role   = aws_iam_role.ExecutionRole.id
  policy = data.aws_iam_policy_document.s3_bucket_object_access[0].json
}

# ---------------------------------------------------------------------------------------------------------------------
# Construct the S3 bucket object policy
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "kms_cmk_access" {
  count = local.execution_iam_kms_cmk == [] ? 0 : 1
  statement {
    sid       = "KmsCmkAccess"
    effect    = "Allow"
    resources = local.execution_iam_kms_cmk
    actions = [
      "kms:Decrypt"
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Build role policy using data, link to role
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "ecs_kms_cmk_access_role_policy" {
  count  = local.execution_iam_kms_cmk == [] ? 0 : 1
  name   = "EcsKmsCmkAccessExecutionRolePolicy"
  role   = aws_iam_role.ExecutionRole.id
  policy = data.aws_iam_policy_document.kms_cmk_access[0].json
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM - Task role, basic. Append policies to this role for S3, DynamoDB etc.
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# Task role assume policy
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Task logging privileges
# ---------------------------------------------------------------------------------------------------------------------
#tfsec:ignore:aws-iam-no-policy-wildcards # can be more restrictive
data "aws_iam_policy_document" "task_permissions" {
  statement {
    effect = "Allow"

    resources = [
      aws_cloudwatch_log_group.CloudWatchLogGroup.arn,
      "${aws_cloudwatch_log_group.CloudWatchLogGroup.arn}:*"
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Task permissions to allow ECS Exec command
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "task_ecs_exec_policy" {
  count = var.enable_ecs_exec ? 1 : 0

  statement {
    effect = "Allow"

    resources = ["*"]

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Task Role
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "task" {
  name               = "${var.name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
}

resource "aws_iam_role_policy" "log_agent" {
  name   = "log-permissions"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_permissions.json
}

# ---------------------------------------------------------------------------------------------------------------------
# required task role access for ecs exec
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "ecs_exec_inline_policy" {
  count = var.enable_ecs_exec ? 1 : 0

  name   = "ecs-exec-permissions"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_ecs_exec_policy[0].json
}

data "aws_iam_policy_document" "kms_cmk_access_for_ecs_exec" {
  count = var.enable_ecs_exec ? 1 : 0
  statement {
    sid       = "KmsCmkAccess"
    effect    = "Allow"
    resources = [data.aws_kms_key.solution_key[0].arn]
    actions = [
      "kms:Decrypt"
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Build role policy using data, link to role
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy" "ecs_kms_cmk_access_task_role_policy" {
  count  = var.enable_ecs_exec ? 1 : 0
  name   = "EcsKmsCmkAccessTaskRolePolicy"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.kms_cmk_access_for_ecs_exec[0].json
}

###############
# Access to S3
###############

data "aws_iam_policy" "s3_bucket_accesss_policy" {
  count = var.s3_solution_bucket_access ? 1 : 0

  name = "${var.solution_name}-s3-access-policy"
}

# Attaches a managed IAM policy to an IAM role
# TF: https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html
# AWS: http://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_managed-vs-inline.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/iam/attach-role-policy.html
resource "aws_iam_role_policy_attachment" "ecs_role_s3_data_bucket_policy_attach" {
  count = var.s3_solution_bucket_access ? 1 : 0

  role       = aws_iam_role.task.name
  policy_arn = data.aws_iam_policy.s3_bucket_accesss_policy[0].arn
}


# ---------------------------------------------------------------------------------------------------------------------
# If configure_as_cronjob is set to true, build up this state machine which creates a container based on the given
# task def.
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "state_machine_role" {
  count = length(var.configure_as_cronjob) > 0 ? 1 : 0

  name = "${var.name}-ecs-cronjob-sfn"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        },
      },
    ],
  })

  inline_policy {
    name = "StateMachine"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action   = "iam:PassRole",
          Effect   = "Allow",
          Resource = [aws_iam_role.ExecutionRole.arn, aws_iam_role.task.arn],
        },
        {
          Action   = "ecs:RunTask",
          Effect   = "Allow",
          Resource = aws_ecs_task_definition.ecs_task_definition.arn,
          Condition = {
            ArnEquals = {
              "ecs:cluster" = data.aws_ecs_cluster.selected.arn,
            },
          },
        },
        {
          Action   = ["ecs:StopTask", "ecs:DescribeTasks"],
          Effect   = "Allow",
          Resource = "*",
          Condition = {
            ArnEquals = {
              "ecs:cluster" = data.aws_ecs_cluster.selected.arn,
            },
          },
        },
        {
          Action   = ["events:PutTargets", "events:PutRule", "events:DescribeRule"],
          Effect   = "Allow",
          Resource = "arn:aws:events:${data.aws_region.current_region.id}:${data.aws_caller_identity.this.account_id}:rule/StepFunctionsGetEventsForECSTaskRule",
        },
      ],
    })
  }
}

resource "aws_cloudwatch_event_rule" "rule" {
  count = length(var.configure_as_cronjob) > 0 ? 1 : 0

  name                = "${var.name}-events-rule"
  schedule_expression = "cron(${var.configure_as_cronjob})"
}

resource "aws_cloudwatch_event_target" "target" {
  count = length(var.configure_as_cronjob) > 0 ? 1 : 0

  rule      = aws_cloudwatch_event_rule.rule[0].name
  target_id = "poller-cronjob-statemachine"
  arn       = aws_sfn_state_machine.state_machine[0].arn
  role_arn  = aws_iam_role.rule_role[0].arn
}

resource "aws_iam_role" "rule_role" {
  count = length(var.configure_as_cronjob) > 0 ? 1 : 0

  name = "${var.name}-rule-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
      },
    ],
  })

  inline_policy {
    name = "EventRulePolicy"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action   = "states:StartExecution",
          Effect   = "Allow",
          Resource = aws_sfn_state_machine.state_machine[0].arn,
        },
      ],
    })
  }
}

resource "aws_sfn_state_machine" "state_machine" {
  count = length(var.configure_as_cronjob) > 0 ? 1 : 0

  name       = "${var.name}-statemachine"
  definition = <<EOF
{
  "Version": "1.0",
  "Comment": "Run ECS/Fargate enplug Poller cronjob.",
  "TimeoutSeconds": ${local.timeout_in_seconds},
  "StartAt": "RunTask",
  "States": {
    "RunTask": {
      "Parameters": {
        "LaunchType": "FARGATE",
        "Cluster": "${data.aws_ecs_cluster.selected.arn}",
        "TaskDefinition": "${aws_ecs_task_definition.ecs_task_definition.arn}",
        "NetworkConfiguration": {
          "AwsvpcConfiguration": {
            "Subnets": ${local.private_subnets_as_string},
            "AssignPublicIp": "DISABLED",
            "SecurityGroups": ${local.security_groups_as_string}
          }
        }
      },
      "Type": "Task",
      "Resource": "arn:aws:states:::ecs:runTask.sync",
      "Retry": [
        {
          "ErrorEquals": [
            "States.TaskFailed"
          ],
          "IntervalSeconds": 10,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ],
      "End": true
    }
  }
}
EOF

  role_arn = aws_iam_role.state_machine_role[0].arn
}
