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

  enable_container_insights = var.enable_container_insights
  enable_ecs_exec           = var.enable_ecs_exec
}

module "app_components" {
  for_each = var.app_components

  source = "./modules/app_component"

  name              = each.key
  environment       = local.environment_name
  container_runtime = module.cluster.ecs_cluster_name

  instances = each.value["instances"]

  total_cpu    = each.value["total_cpu"]
  total_memory = each.value["total_memory"]

  container = each.value["container"]

  listener_rule_prio = each.value["listener_rule_prio"]
  path_mapping       = each.value["path_mapping"]
  service_port       = each.value["service_port"]

  # for cost savings undeploy outside work hours
  enable_autoscaling = each.value["enable_autoscaling"]

  lb_domain_name = var.create_dns_and_certificates ? "lb.${module.environment.domain_name}" : ""

  depends_on = [module.environment]
}
