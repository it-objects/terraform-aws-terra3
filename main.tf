# ---------------------------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------------
# Terra3 - Your hyperdrive module for 3-tier applications
# ---------------------------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # "nat" variable defines how nat should be configured
  create_nat_instances          = (var.nat == "NAT_INSTANCES") ? true : false
  create_nat_gateway            = (var.nat != "NO_NAT" && var.nat != "NAT_INSTANCES") ? true : false
  create_single_nat_gateway     = (var.nat == "NAT_GATEWAY_SINGLE") ? true : false
  create_one_nat_gateway_per_az = (var.nat == "NAT_GATEWAY_PER_AZ") ? true : false

  domain_name = var.enable_custom_domain ? module.dns_and_certificates[0].internal_domain_name : ""

  created_db_subnet_group_name = var.create_database && var.use_an_existing_vpc && var.external_db_subnet_group_name == "" ? join(", ", aws_db_subnet_group.external_db_subnet_group[*].name) : var.external_db_subnet_group_name

  # Variable definitions of using existing VPC or create VPC
  vpc_id                  = var.use_an_existing_vpc ? var.external_vpc_id : module.vpc[0].vpc_id
  public_subnets          = var.use_an_existing_vpc ? var.external_public_subnets : module.vpc[0].public_subnets
  private_subnets         = var.use_an_existing_vpc ? var.external_private_subnets : module.vpc[0].private_subnets
  private_route_table_ids = var.use_an_existing_vpc ? var.external_vpc_private_route_table_ids : module.vpc[0].private_route_table_ids
  public_route_table_ids  = var.use_an_existing_vpc ? var.external_vpc_private_route_table_ids : module.vpc[0].public_route_table_ids
  db_subnet_group_name    = var.use_an_existing_vpc ? local.created_db_subnet_group_name : module.vpc[0].database_subnet_group_name
  elasticache_subnet_ids  = var.use_an_existing_vpc ? var.external_elasticache_subnet_ids : module.vpc[0].elasticache_subnets

  # calculate app_components' path
  app_component_paths = length(var.app_components) == 0 ? ["/api/*"] : [for component in values(var.app_components) : (contains(keys(component), "path_mapping") ? component.path_mapping : "/api/*")]
}

resource "aws_ssm_parameter" "domain_name" {
  name  = "/${var.solution_name}/domain_name"
  type  = "String"
  value = var.enable_custom_domain ? local.domain_name : "-"
}

# ---------------------------------------------------------------------------------------------------------------------
# Added resources for database subnet group while using existing VPC.
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_subnet" "database_subnet" {
  count = var.create_database && var.use_an_existing_vpc && var.external_db_subnet_group_name == "" && length(var.external_database_cidr) > 0 ? length(var.azs) : 0

  vpc_id            = local.vpc_id
  cidr_block        = var.external_database_cidr[count.index]
  availability_zone = element(var.azs, count.index)

  tags = merge(
    {
      "Name" = format(
        "${var.solution_name}-%s", element(var.azs, count.index),
      )
    }
  )
}

resource "aws_route_table_association" "database" {
  count = var.create_database && var.use_an_existing_vpc && var.external_db_subnet_group_name == "" && length(var.external_database_cidr) > 0 ? length(var.azs) : 0

  subnet_id      = element(aws_subnet.database_subnet[*].id, count.index)
  route_table_id = element(local.private_route_table_ids[*], count.index)
}

resource "aws_db_subnet_group" "external_db_subnet_group" {
  count = var.create_database && var.use_an_existing_vpc && var.external_db_subnet_group_name == "" && length(var.external_database_cidr) > 0 ? 1 : 0

  name        = "${var.solution_name}-db-subnet-group"
  description = "Database subnet group."
  subnet_ids  = aws_subnet.database_subnet[*].id
}

# ---------------------------------------------------------------------------------------------------------------------
# Public/Private cross-AZ VPC setup. Default CIDR use /20 allowing up to 4094 IPs per subnet
# ---------------------------------------------------------------------------------------------------------------------
# Public IP assignment is enabled for NAT instance option
# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs tfsec:ignore:aws-ec2-no-public-ip-subnet
module "vpc" {
  count = !var.use_an_existing_vpc ? 1 : 0

  source  = "registry.terraform.io/terraform-aws-modules/vpc/aws"
  version = "5.7.0"

  name = "${var.solution_name}-vpc"
  cidr = var.cidr

  azs             = var.azs
  public_subnets  = var.public_subnets_cidr_blocks
  private_subnets = var.private_subnets_cidr_blocks

  # to stay backwards compatible
  map_public_ip_on_launch       = true
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  public_subnet_tags = var.set_cluster_name_for_k8s_subnet_tagging == "" ? {
    Tier = "public"
    } : {
    "kubernetes.io/role/elb"                                               = "1"      # required annotations for ALB controller
    "kubernetes.io/cluster/${var.set_cluster_name_for_k8s_subnet_tagging}" = "shared" # required annotations for ALB controller
    Tier                                                                   = "public"
  }

  private_subnet_tags = var.set_cluster_name_for_k8s_subnet_tagging == "" ? {
    Tier = "private"
    } : {
    "kubernetes.io/role/internal-elb"                                      = "1"      # required annotations for ALB controller
    "kubernetes.io/cluster/${var.set_cluster_name_for_k8s_subnet_tagging}" = "shared" # required annotations for ALB controller
    Tier                                                                   = "private"
  }

  create_database_subnet_group = var.create_database
  database_subnets             = var.create_database ? var.database_cidr_blocks : []

  create_elasticache_subnet_group = var.create_elasticache_redis
  elasticache_subnets             = var.create_elasticache_redis ? var.elasticache_cidr_blocks : []

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = local.create_nat_gateway
  single_nat_gateway     = local.create_single_nat_gateway
  one_nat_gateway_per_az = local.create_one_nat_gateway_per_az
}

resource "aws_ssm_parameter" "vpc_id" {
  name  = "/${var.solution_name}/vpc_id"
  type  = "String"
  value = local.vpc_id
}

resource "aws_ssm_parameter" "private_subnets" {
  name  = "/${var.solution_name}/private_subnets"
  type  = "StringList"
  value = join(",", local.private_subnets)
}

# ---------------------------------------------------------------------------------------------------------------------
# Enable S3 gateway endpoint. Best practice to keep S3 traffic internal
# ---------------------------------------------------------------------------------------------------------------------
module "vpc_endpoints" {
  count = var.enable_vpc_s3_endpoint ? 1 : 0

  source  = "registry.terraform.io/terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.7.0"

  vpc_id = local.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      tags            = { Name = "s3-vpc-endpoint" }
      route_table_ids = concat(local.private_route_table_ids, local.public_route_table_ids)
      service_type    = "Gateway"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Use of NAT instances instead of NAT gateways to reduce costs
# ---------------------------------------------------------------------------------------------------------------------
module "nat_instances" {
  count = local.create_nat_instances ? 1 : 0

  source        = "./modules/nat_instances"
  solution_name = var.solution_name

  public_subnets_cidr_blocks  = var.public_subnets_cidr_blocks
  private_subnets_cidr_blocks = var.private_subnets_cidr_blocks

  azs                   = var.azs
  nat_use_spot_instance = false
  nat_instance_types    = var.nat_instance_types

  private_route_table_ids = local.private_route_table_ids
  public_subnets          = local.public_subnets
  private_subnets         = local.private_subnets
  vpc_id                  = local.vpc_id
}

module "l7_loadbalancer" {
  count = var.create_load_balancer ? 1 : 0

  source        = "./modules/loadbalancer"
  solution_name = var.solution_name

  public_subnets  = local.public_subnets
  security_groups = [module.security_groups.loadbalancer_sg]

  enable_alb_logs            = var.enable_alb_logs
  enable_deletion_protection = var.enable_alb_deletion_protection

  enable_custom_domain = var.enable_custom_domain
  default_redirect_url = var.default_redirect_url
  hosted_zone_id       = var.enable_custom_domain ? module.dns_and_certificates[0].hosted_zone_id : ""
  domain_name          = var.enable_custom_domain ? module.dns_and_certificates[0].internal_domain_name : ""
}

resource "aws_ssm_parameter" "environment_alb_arn" {
  count = !var.create_load_balancer ? 1 : 0

  name  = "/${var.solution_name}/alb_arn"
  type  = "String"
  value = "-"
}

module "security_groups" {
  source = "./modules/securitygroups"

  name   = var.solution_name
  vpc_id = local.vpc_id

  create_dns_and_certificates = var.enable_custom_domain
}

# ---------------------------------------------------------------------------------------------------------------------
# Use cases:
# - hosted zone within route53 with required privileges available
# - hosted zone to be created within account
# ---------------------------------------------------------------------------------------------------------------------
module "dns_and_certificates" {
  count = var.enable_custom_domain ? 1 : 0

  source = "./modules/dns_and_certificates"

  solution_name = var.solution_name

  route53_subdomain = var.solution_name
  route53_zone_id   = var.route53_zone_id
  domain            = var.domain_name
  alias_domain_name = var.alias_domain_name

  create_subdomain = var.create_subdomain

  providers = {
    aws.useast1 = aws.useast1
  }
}

resource "aws_ssm_parameter" "enable_custom_domain" {
  name  = "/${var.solution_name}/enable_custom_domain"
  type  = "String"
  value = var.enable_custom_domain
}

module "cloudfront_cdn" {
  source        = "./modules/cloudfront_cdn"
  solution_name = var.solution_name

  origin_alb_url    = length(module.l7_loadbalancer) == 0 ? null : module.l7_loadbalancer[0].lb_dns_name
  domain            = length(module.dns_and_certificates) == 0 ? null : module.dns_and_certificates[0].internal_domain_name
  alias_domain_name = length(module.dns_and_certificates) == 0 ? null : var.alias_domain_name
  certificate_arn   = length(module.dns_and_certificates) == 0 ? null : module.dns_and_certificates[0].cloudfront_certificate_arn

  calculated_zone_id = var.enable_custom_domain ? module.dns_and_certificates[0].hosted_zone_id : ""

  enable_s3_for_static_website                                   = var.enable_s3_for_static_website
  s3_static_website_bucket_cf_function_arn                       = var.s3_static_website_bucket_cf_function_arn
  s3_static_website_bucket_cf_lambda_at_edge_origin_request_arn  = var.s3_static_website_bucket_cf_lambda_at_edge_origin_request_arn
  s3_static_website_bucket_cf_lambda_at_edge_viewer_request_arn  = var.s3_static_website_bucket_cf_lambda_at_edge_viewer_request_arn
  s3_static_website_bucket_cf_lambda_at_edge_origin_response_arn = var.s3_static_website_bucket_cf_lambda_at_edge_origin_response_arn
  s3_static_website_bucket_cf_lambda_at_edge_viewer_response_arn = var.s3_static_website_bucket_cf_lambda_at_edge_viewer_response_arn

  s3_solution_bucket_cf_behaviours = var.s3_solution_bucket_cf_behaviours
  disable_custom_error_response    = var.disable_custom_error_response

  # when custom_elb_cf_path_patterns is not given by developer, it is being calculated (calculation only works in single state setups)
  custom_elb_cf_path_patterns = length(var.custom_elb_cf_path_patterns) == 0 ? local.app_component_paths : var.custom_elb_cf_path_patterns

  s3_solution_bucket_name        = try(module.s3_solution_bucket[0].s3_solution_bucket_name, "")
  s3_solution_bucket_arn         = try(module.s3_solution_bucket[0].s3_bucket_arn, "")
  s3_solution_bucket_domain_name = try(module.s3_solution_bucket[0].s3_bucket_domain_name, "")

  # ignored if static web page is deactivated
  add_default_index_html = var.enable_s3_for_static_website && var.add_default_index_html

  enable_cloudfront_url_signing_for_solution_bucket = var.enable_cloudfront_url_signing_for_solution_bucket

  s3_admin_website_url                         = module.global_scale_down.s3_admin_website_url
  enable_environment_hibernation_admin_website = var.enable_environment_hibernation_sleep_schedule
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

  solution_name          = var.solution_name
  container_runtime_name = "${var.solution_name}-cluster"
  cluster_type           = var.cluster_type

  public_subnets         = local.public_subnets
  vpc_security_group_ids = [module.security_groups.ecs_task_sg]

  cluster_ec2_min_nodes           = var.cluster_ec2_min_nodes
  cluster_ec2_max_nodes           = var.cluster_ec2_max_nodes
  cluster_ec2_instance_type       = var.cluster_ec2_instance_type
  cluster_ec2_desired_capacity    = var.cluster_ec2_desired_capacity
  cluster_ec2_detailed_monitoring = var.cluster_ec2_detailed_monitoring
  cluster_ec2_volume_size         = var.cluster_ec2_volume_size

  enable_container_insights = var.enable_container_insights
  enable_ecs_exec           = var.enable_ecs_exec
}

resource "aws_ssm_parameter" "cluster_type" {
  name  = "/${var.solution_name}/cluster_type"
  type  = "String"
  value = var.cluster_type
}

locals {
  create_sns_topic = var.cpu_utilization_alert || var.memory_utilization_alert == true ? true : false
}

# Disable for now. In a further iteration to be added and cw needs access to KMS key.
# tfsec:ignore:aws-sns-enable-topic-encryption
resource "aws_sns_topic" "ecs_service_cpu_and_memory_utilization_topic" {
  count = local.create_sns_topic ? 1 : 0
  name  = "ecs_service_cpu_and_memory_utilization_topic"
}

resource "aws_ssm_parameter" "sns_alerts_topic_arn" {
  name  = "/${var.solution_name}/sns_alerts_topic_arn"
  type  = "String"
  value = local.create_sns_topic ? aws_sns_topic.ecs_service_cpu_and_memory_utilization_topic[0].arn : "-"
}

resource "aws_sns_topic_subscription" "ecs_service_cpu_and_memory_utilization_sns_subscription" {
  count     = local.create_sns_topic ? length(var.alert_receivers_email) : 0
  topic_arn = aws_sns_topic.ecs_service_cpu_and_memory_utilization_topic[0].arn
  protocol  = "email"
  endpoint  = var.alert_receivers_email[count.index]
}

module "bastion_host_ssm" {
  count = var.create_bastion_host ? 1 : 0

  source = "./modules/bastion_host_ssm"

  solution_name    = var.solution_name
  environment_name = var.solution_name
  vpc_id           = local.vpc_id
  private_subnets  = local.private_subnets

  depends_on = [module.security_groups]
}

locals {
  rds_cluster_engine_version                = var.database == "mysql" ? var.database_mysql_engine_version : var.database_postgres_engine_version
  rds_cluster_security_group_ids            = var.database == "mysql" ? [module.security_groups.mysql_db_sg] : [module.security_groups.postgres_db_sg]
  rds_cluster_enable_cloudwatch_logs_export = var.database == "mysql" ? ["audit"] : ["postgresql"]
}

module "database" {
  count = var.create_database ? 1 : 0

  database = var.database

  source        = "./modules/database"
  solution_name = var.solution_name

  db_subnet_group_name = local.db_subnet_group_name

  rds_cluster_database_name  = "${replace(var.solution_name, "-", "")}db" # alphanumeric and lower case
  rds_cluster_identifier     = "${lower(var.solution_name)}_db"
  rds_cluster_engine         = var.database
  rds_cluster_engine_version = local.rds_cluster_engine_version

  rds_cluster_security_group_ids = local.rds_cluster_security_group_ids

  # adapt these for prod! Now optimized for for testing and low costs
  rds_cluster_allocated_storage       = var.database_allocated_storage
  rds_cluster_max_allocated_storage   = var.database_max_allocated_storage
  rds_cluster_backup_retention_period = var.database_backup_retention_period # at least 7 days or more for prod
  rds_cluster_deletion_protection     = var.database_deletion_protection     # true for prod env
  rds_cluster_multi_az                = var.database_multi_az                # true for ha prod envs
  rds_cluster_instance_instance_class = var.database_instance_instance_class # db.t3.* for prod env
  rds_cluster_storage_encrypted       = true                                 # true for prod env or non-db.t2x.micro free tier instance

  rds_cluster_enable_cloudwatch_logs_export = local.rds_cluster_enable_cloudwatch_logs_export

  ca_cert_identifier                    = var.database_ca_cert_identifier
  iam_database_authentication_enabled   = var.database_iam_database_authentication_enabled
  monitoring_interval                   = var.database_enhanced_monitoring
  performance_insights_enabled          = var.database_performance_insights_enabled
  performance_insights_retention_period = var.database_performance_insights_retention_period
}

# ---------------------------------------------------------------------------------------------------------------------
# Redis Cluster
# ---------------------------------------------------------------------------------------------------------------------
# tfsec:ignore:aws-elasticache-enable-backup-retention

locals {
  redis_cluster_id      = "${var.solution_name}-redis"
  redis_engine          = "redis"
  redis_node_type       = "cache.t4g.micro"
  redis_num_cache_nodes = 1
  redis_engine_version  = "5.0.6"
}

# tfsec:ignore:aws-elasticache-enable-backup-retention
resource "aws_elasticache_cluster" "redis" {
  count = var.create_elasticache_redis ? 1 : 0

  cluster_id         = local.redis_cluster_id
  engine             = local.redis_engine
  node_type          = local.redis_node_type
  num_cache_nodes    = local.redis_num_cache_nodes
  engine_version     = local.redis_engine_version
  subnet_group_name  = aws_elasticache_subnet_group.db_elastic_subnetgroup[0].name
  security_group_ids = [module.security_groups.redis_sg]
}

resource "aws_elasticache_subnet_group" "db_elastic_subnetgroup" {
  count = var.create_elasticache_redis ? 1 : 0

  name       = "${var.solution_name}-elasticache-subnet-group"
  subnet_ids = local.elasticache_subnet_ids
}

# ---------------------------------------------------------------------------------------------------------------------
# ECR repo used for storing container images
# ---------------------------------------------------------------------------------------------------------------------
module "ecr" {
  count = length(var.create_ecr_with_names) > 0 ? 1 : 0

  source = "./modules/ecr"

  create_ecr_with_names  = var.create_ecr_with_names
  ecr_name               = length(var.ecr_custom_name) > 3 ? var.ecr_custom_name : var.solution_name
  access_for_account_id  = var.ecr_access_for_account_id  # allow production account
  access_for_account_ids = var.ecr_access_for_account_ids # allow production accounts
}

# ---------------------------------------------------------------------------------------------------------------------
# S3 bucket used for solution specific purposes
# ---------------------------------------------------------------------------------------------------------------------
module "s3_solution_bucket" {
  count = var.create_s3_solution_bucket ? 1 : 0

  source                        = "./modules/s3_bucket"
  solution_name                 = var.solution_name
  s3_solution_bucket_enable_acl = var.s3_solution_bucket_enable_acl
}

# ---------------------------------------------------------------------------------------------------------------------
# User for CI/CD deployment
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# VARIANT 1: ACCESS_KEYS
# ---------------------------------------------------------------------------------------------------------------------
module "deployment_user" {
  count = var.create_deployment_user ? 1 : 0

  source = "./modules/deployment_user"
}

module "aws_ses" {
  count = var.create_ses ? 1 : 0

  source           = "./modules/ses"
  create_ses       = var.create_ses
  ses_domain_name  = var.ses_domain_name
  mail_from_domain = var.ses_mail_from_domain

}

# ---------------------------------------------------------------------------------------------------------------------
# scheduled HTTPS API call
# ---------------------------------------------------------------------------------------------------------------------
module "scheduled_api_call" {
  count = var.enable_scheduled_https_api_call ? 1 : 0

  source        = "./modules/scheduled_api_call"
  solution_name = var.solution_name

  # Scheduled https api call
  enable_scheduled_https_api_call  = var.enable_scheduled_https_api_call
  scheduled_https_api_call_crontab = var.scheduled_https_api_call_crontab
  scheduled_https_api_call_url     = var.scheduled_https_api_call_url
}

# ---------------------------------------------------------------------------------------------------------------------
# app components called from within the same module (can also be used externally, see separate_state_example)
# ---------------------------------------------------------------------------------------------------------------------
module "app_components" {
  source = "./modules/app_components"

  app_components = var.app_components

  solution_name = var.solution_name

  two_states_approach = false # overwriting default to indicate one state approach

  enable_custom_domain = var.enable_custom_domain

  # CloudWatch alert based on cpu and memory utilization
  cpu_utilization_alert    = var.cpu_utilization_alert
  memory_utilization_alert = var.memory_utilization_alert
  sns_topic_arn            = local.create_sns_topic ? [aws_sns_topic.ecs_service_cpu_and_memory_utilization_topic[0].arn] : null

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

  # needed because for the ability to run separately, this module relies on querying information via data fields
  depends_on = [module.l7_loadbalancer, module.security_groups, module.cluster, aws_ssm_parameter.enable_custom_domain, aws_ssm_parameter.environment_alb_arn]
}

locals {
  ecs_services_json = jsonencode([
    for i in range(length(local.ecs_service_names)) : {
      name         = local.ecs_service_names[i],
      desiredCount = local.ecs_desire_task_counts[i]
    }
  ])

  ecs_service_names = [
    for ecs_service_names in module.app_components.app_components : ecs_service_names.ecs_service_name if ecs_service_names.ecs_service_name != null
  ]

  ecs_desire_task_counts = [
    for ecs_desire_task_counts in module.app_components.app_components : ecs_desire_task_counts.ecs_desire_task_count if ecs_desire_task_counts.ecs_desire_task_count != null
  ]

  ecs_service_arn = [
    for ecs_service_arn in module.app_components.app_components : ecs_service_arn.ecs_service_arn if ecs_service_arn.ecs_service_arn != null
  ]

  db_instance_name = var.create_database ? split(",", module.database[0].db_instance_name) : []

  cluster_name = split(",", module.cluster.ecs_cluster_name)

  redis = {
    cluster_id         = var.create_elasticache_redis ? split(",", local.redis_cluster_id) : []
    engine             = var.create_elasticache_redis ? split(",", local.redis_engine) : []
    node_type          = var.create_elasticache_redis ? split(",", local.redis_node_type) : []
    num_cache_nodes    = var.create_elasticache_redis ? local.redis_num_cache_nodes : 0
    engine_version     = var.create_elasticache_redis ? split(",", local.redis_engine_version) : []
    subnet_group_name  = aws_elasticache_subnet_group.db_elastic_subnetgroup[*].name
    security_group_ids = var.create_elasticache_redis ? [module.security_groups.redis_sg] : []
    cluster_arn        = aws_elasticache_cluster.redis[*].arn
    subnet_group_arn   = aws_elasticache_subnet_group.db_elastic_subnetgroup[*].arn
    security_group_arn = module.security_groups.redis_sg_arn
  }
}

resource "aws_ssm_parameter" "ecs_service_name" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  name  = "/${var.solution_name}/global_scale_down/ecs_service_data"
  value = local.ecs_services_json
  type  = "String"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "scale_up_parameters" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  name  = "/${var.solution_name}/global_scale_down/scale_up_parameters"
  value = local.global_scale_data
  type  = "String"
}

resource "aws_ssm_parameter" "hibernation_state" {
  count = var.enable_environment_hibernation_sleep_schedule ? 1 : 0

  name  = "/${var.solution_name}/global_scale_down/hibernation_state"
  value = "initial"
  type  = "String"
}

locals {
  global_scale_data = jsonencode({
    "asg_name" : flatten([module.bastion_host_ssm[*].bastion_host_autoscaling_group_name, module.nat_instances[*].nat_instances_autoscaling_group_names, module.cluster.ecs_ec2_instances_autoscaling_group_name]),
    "asg_max_capacity" : flatten([module.bastion_host_ssm[*].bastion_host_autoscaling_group_max_capacity, module.nat_instances[*].nat_instances_autoscaling_group_max_capacity, module.cluster.ecs_ec2_instances_autoscaling_group_max_capacity]),
    "asg_min_capacity" : flatten([module.bastion_host_ssm[*].bastion_host_autoscaling_group_min_capacity, module.nat_instances[*].nat_instances_autoscaling_group_min_capacity, module.cluster.ecs_ec2_instances_autoscaling_group_min_capacity]),
    "asg_desired_capacity" : flatten([module.bastion_host_ssm[*].bastion_host_autoscaling_group_desired_capacity, module.nat_instances[*].nat_instances_autoscaling_group_desired_capacity, module.cluster.ecs_ec2_instances_autoscaling_group_desired_capacity]),
    "db_instance_name" : local.db_instance_name,
    "redis_cluster_id" : local.redis.cluster_id,
    "redis_engine" : local.redis.engine,
    "redis_node_type" : local.redis.node_type,
    "redis_num_cache_nodes" : local.redis.num_cache_nodes,
    "redis_engine_version" : local.redis.engine_version,
    "redis_subnet_group_name" : local.redis.subnet_group_name,
    "redis_security_group_ids" : [local.redis.security_group_ids],
    "cluster_name" : local.cluster_name,
  })
}

module "global_scale_down" {

  source = "./modules/global_scale_down"

  enable_environment_hibernation_sleep_schedule = var.enable_environment_hibernation_sleep_schedule
  environment_hibernation_sleep_schedule        = var.environment_hibernation_sleep_schedule
  environment_hibernation_wakeup_schedule       = var.environment_hibernation_wakeup_schedule

  solution_name  = var.solution_name
  cloudfront_arn = module.cloudfront_cdn.cloudfront_arn

  ecs_ec2_instances_autoscaling_group_arn = module.cluster.ecs_ec2_instances_autoscaling_group_arn
  nat_instances_autoscaling_group_arn     = flatten(module.nat_instances[*].nat_instances_autoscaling_group_arn)
  bastion_host_autoscaling_group_arn      = module.bastion_host_ssm[*].bastion_host_autoscaling_group_arn
  cluster_name                            = local.cluster_name
  cluster_arn                             = module.cluster.ecs_cluster_arn
  db_instance_arn                         = module.database[*].db_instance_arn
  redis_cluster_arn                       = local.redis.cluster_arn
  redis_subnet_group_arn                  = local.redis.subnet_group_arn
  redis_security_group_arn                = local.redis.security_group_arn
}

# ---------------------------------------------------------------------------------------------------------------------
# scheduled HTTPS API call
# ---------------------------------------------------------------------------------------------------------------------
module "enable_kms" {
  count = var.enable_kms_key ? 1 : 0

  source = "./modules/kms"
  name   = var.kms_key_alias
}
