locals {
  environment_name = "${var.solution_name}-env"
}

# ---------------------------------------------------------------------------------------------------------------------
# Initialize environment
# ---------------------------------------------------------------------------------------------------------------------
module "environment" {
  source = "./modules/environment"

  solution_name = var.solution_name

  add_default_index_html      = var.add_default_index_html
  create_dns_and_certificates = var.create_dns_and_certificates
  route53_zone_id             = var.route53_zone_id
  create_load_balancer        = var.create_load_balancer
  nat                         = var.nat
  create_bastion_host         = var.create_bastion_host
  create_database             = var.create_database

  providers = {
    aws.useast1 = aws.useast1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Required in case a certificate is created for Cloudfront which needs to reside in the N. Virgina region (us-east-1)
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}

module "account" {
  count = var.enable_account_best_practices ? 1 : 0

  source = "./modules/account"
}

module "cluster" {
  source = "./modules/container_runtime"

  environment_name       = local.environment_name
  container_runtime_name = "${local.environment_name}-cluster"
  ecs_cluster_type       = var.ecs_cluster_type
  launch_type            = var.launch_type

  cluster_ec2_min_nodes           = var.cluster_ec2_min_nodes
  cluster_ec2_max_nodes           = var.cluster_ec2_max_nodes
  cluster_ec2_instance_type       = var.cluster_ec2_instance_type
  cluster_ec2_desired_capacity    = var.cluster_ec2_desired_capacity
  cluster_ec2_detailed_monitoring = var.cluster_ec2_detailed_monitoring
  cluster_ec2_volume_size         = var.cluster_ec2_volume_size

  enable_container_insights = var.enable_container_insights
  enable_ecs_exec           = var.enable_ecs_exec
  depends_on                = [module.environment]
}

module "app_components" {
  for_each = var.app_components

  source = "./modules/app_component"

  name              = each.key
  environment       = local.environment_name
  container_runtime = module.cluster.ecs_cluster_name
  ecs_cluster_type  = var.ecs_cluster_type
  launch_type       = var.launch_type
  metric_type       = var.metric_type

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

  instances = each.value["instances"]

  total_cpu    = each.value["total_cpu"]
  total_memory = each.value["total_memory"]

  container = each.value["container"]

  listener_rule_prio = each.value["listener_rule_prio"]
  path_mapping       = each.value["path_mapping"]
  service_port       = each.value["service_port"]

  # for cost savings undeploy outside work hours
  enable_autoscaling = lookup(each.value, "enable_autoscaling", false)

  lb_domain_name = var.create_dns_and_certificates ? "lb.${module.environment.domain_name}" : ""

  depends_on = [module.environment, module.cluster]
}
