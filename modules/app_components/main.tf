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

  container = each.value["container"]

  # if true the next block's variables are ignored internally
  internal_service = lookup(each.value, "internal_service", false)

  listener_rule_prio = lookup(each.value, "listener_rule_prio", null)
  path_mapping       = lookup(each.value, "path_mapping", null)
  service_port       = lookup(each.value, "service_port", null)

  lb_healthcheck_url                = lookup(each.value, "lb_healthcheck_url", null)
  health_check_grace_period_seconds = lookup(each.value, "lb_healthcheck_grace_period", null)
  lb_healthcheck_port               = lookup(each.value, "lb_healthcheck_port", null)

  enable_ecs_exec = lookup(each.value, "enable_ecs_exec", false)

  # for cost savings undeploy outside work hours
  enable_autoscaling = lookup(each.value, "enable_autoscaling", false)

  s3_solution_bucket_access = lookup(each.value, "s3_solution_bucket_access", false)

  # get custom_domain setting from parameter store in case of a two_states_approach
  enable_custom_domain = var.two_states_approach ? data.aws_ssm_parameter.enable_custom_domain.value : var.enable_custom_domain
}
