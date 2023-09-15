locals {
  create_sns_topic = var.cpu_utilization_alert || var.memory_utilization_alert ? true : false
}

module "app_components" {
  for_each = var.app_components

  source = "../app_component"

  name              = each.key
  solution_name     = var.solution_name
  container_runtime = data.aws_ecs_cluster.selected.cluster_name
  cluster_type      = data.aws_ssm_parameter.cluster_type.value

  instances = each.value["instances"]

  total_cpu    = each.value["total_cpu"]
  total_memory = each.value["total_memory"]

  # CloudWatch alert based on cpu and memory utilization
  cpu_utilization_alert    = var.cpu_utilization_alert
  memory_utilization_alert = var.memory_utilization_alert
  sns_topic_arn            = local.create_sns_topic ? [data.aws_ssm_parameter.sns_alerts_topic_arn.value] : null

  cpu_utilization_high_evaluation_periods = var.cpu_utilization_high_evaluation_periods
  cpu_utilization_high_period             = var.cpu_utilization_high_period
  cpu_utilization_high_threshold          = var.cpu_utilization_high_threshold
  cpu_utilization_low_evaluation_periods  = var.cpu_utilization_low_evaluation_periods
  cpu_utilization_low_period              = var.cpu_utilization_low_period
  cpu_utilization_low_threshold           = var.cpu_utilization_low_threshold

  memory_utilization_high_evaluation_periods = var.memory_utilization_high_evaluation_periods
  memory_utilization_high_period             = var.memory_utilization_high_period
  memory_utilization_high_threshold          = var.memory_utilization_high_threshold
  memory_utilization_low_evaluation_periods  = var.memory_utilization_low_evaluation_periods
  memory_utilization_low_period              = var.memory_utilization_low_period
  memory_utilization_low_threshold           = var.memory_utilization_low_threshold

  task_count_alert              = var.task_count_alert
  task_count_threshold          = var.task_count_threshold
  task_count_evaluation_periods = var.task_count_evaluation_periods
  task_count_period             = var.task_count_period
  enable_container_insights     = var.enable_container_insights

  enable_ecs_autoscaling       = var.enable_ecs_autoscaling
  ecs_autoscaling_metric_type  = var.ecs_autoscaling_metric_type
  ecs_autoscaling_max_capacity = var.ecs_autoscaling_max_capacity
  ecs_autoscaling_min_capacity = var.ecs_autoscaling_min_capacity
  ecs_autoscaling_target_value = var.ecs_autoscaling_target_value

  container = each.value["container"]

  enable_firelens_container = lookup(each.value, "enable_firelens_container", false)

  execution_iam_access = lookup(each.value, "execution_iam_access", null)

  # if true the next block's variables are ignored internally
  internal_service = lookup(each.value, "internal_service", false)

  // generate listener_rule_prios according to sequence from app_components' map; using index function to calculate the next increment
  listener_rule_prio = lookup(each.value, "listener_rule_prio", null) == null ? ((index(keys(var.app_components), each.key) + 1) * 200) : lookup(each.value, "listener_rule_prio", null)

  path_mapping = lookup(each.value, "path_mapping", null)
  service_port = lookup(each.value, "service_port", null)

  lb_healthcheck_url                = lookup(each.value, "lb_healthcheck_url", null)
  health_check_grace_period_seconds = lookup(each.value, "lb_healthcheck_grace_period", null)
  lb_healthcheck_port               = lookup(each.value, "lb_healthcheck_port", null)

  enable_ecs_exec = lookup(each.value, "enable_ecs_exec", false)

  configure_as_cronjob = lookup(each.value, "configure_as_cronjob", "")

  # for cost savings undeploy outside work hours
  enable_autoscaling                = lookup(each.value, "enable_autoscaling", false)
  autoscale_task_weekday_scale_down = lookup(each.value, "autoscale_task_weekday_scale_down", 0)
  autoscale_up_event                = lookup(each.value, "autoscale_up_event", "cron(0 8 ? * MON-FRI *)")
  autoscale_down_event              = lookup(each.value, "autoscale_down_event", "cron(0 18 ? * * *)")

  s3_solution_bucket_access = lookup(each.value, "s3_solution_bucket_access", false)

  # get custom_domain setting from parameter store in case of a two_states_approach
  enable_custom_domain = var.two_states_approach ? data.aws_ssm_parameter.enable_custom_domain.value : var.enable_custom_domain
}
