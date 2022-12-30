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
  create_alter_nat              = (var.nat == "ALTER_NAT") ? true : false

  domain_name = length(module.dns_and_certificates) == 0 ? "" : module.dns_and_certificates[0].domain_name
}

# ---------------------------------------------------------------------------------------------------------------------
# Public/Private cross-AZ VPC setup. Default CIDR use /20 allowing up to 4094 IPs per subnet
# ---------------------------------------------------------------------------------------------------------------------
# Public IP assignment is enabled for NAT instance option
# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs tfsec:ignore:aws-ec2-no-public-ip-subnet
module "vpc" {
  source  = "registry.terraform.io/terraform-aws-modules/vpc/aws"
  version = "3.16.0"

  name = "${var.solution_name}-vpc"
  cidr = var.cidr

  azs             = var.azs
  public_subnets  = var.public_subnets_cidr_blocks
  private_subnets = var.private_subnets_cidr_blocks

  public_subnet_tags = {
    "Tier" : "public"
  }

  private_subnet_tags = {
    "Tier" : "private"
  }

  create_database_subnet_group = true
  database_subnets             = var.database_cidr_blocks

  create_elasticache_subnet_group = true
  elasticache_subnets             = var.elasticache_cidr_blocks

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = local.create_nat_gateway
  single_nat_gateway     = local.create_single_nat_gateway
  one_nat_gateway_per_az = local.create_one_nat_gateway_per_az
}

resource "aws_ssm_parameter" "vpc_id" {
  name  = "/${var.solution_name}/vpc_id"
  type  = "String"
  value = module.vpc.vpc_id
}

# ---------------------------------------------------------------------------------------------------------------------
# Enable S3 gateway endpoint. Best practice to keep S3 traffic internal
# ---------------------------------------------------------------------------------------------------------------------
module "vpc_endpoints" {
  source = "registry.terraform.io/terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      tags            = { Name = "s3-vpc-endpoint" }
      route_table_ids = module.vpc.private_route_table_ids
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

  private_route_table_ids = module.vpc.private_route_table_ids
  public_subnets          = module.vpc.public_subnets
  private_subnets         = module.vpc.private_subnets
  vpc_id                  = module.vpc.vpc_id
}

# ---------------------------------------------------------------------------------------------------------------------
# Use of alterNAT instances instead of NAT instances to reduce costs on the basis of hourly usage.
# ---------------------------------------------------------------------------------------------------------------------
module "alternat_instances" {
  count = local.create_alter_nat ? 1 : 0

  source = "git::https://github.com/1debit/alternat.git//modules/terraform-aws-alternat?ref=v0.1.0"

  alternat_image_uri = "531874807515.dkr.ecr.eu-central-1.amazonaws.com/alternat"
  alternat_image_tag = "latest"

  ingress_security_group_ids = var.ingress_security_group_ids

  subnet_suffix     = var.nat_subnet_suffix
  nat_instance_type = "t4g.nano"

  private_route_table_ids = module.vpc.private_route_table_ids

  tags = var.tags

  vpc_id                 = module.vpc.vpc_id
  vpc_private_subnet_ids = module.vpc.private_subnets
  vpc_public_subnet_ids  = module.vpc.public_subnets
}

module "l7_loadbalancer" {
  count = var.create_load_balancer ? 1 : 0

  source        = "./modules/loadbalancer"
  solution_name = var.solution_name

  public_subnets  = module.vpc.public_subnets
  security_groups = [module.security_groups.loadbalancer_sg]

  enable_alb_logs = false
}

module "security_groups" {
  source = "./modules/securitygroups"

  name   = var.solution_name
  vpc_id = module.vpc.vpc_id

  create_dns_and_certificates = var.create_dns_and_certificates
}

# ---------------------------------------------------------------------------------------------------------------------
# Use cases:
# - hosted zone within route53 with required privileges available
# - hosted zone to be created within account
# ---------------------------------------------------------------------------------------------------------------------
module "dns_and_certificates" {
  count = var.create_dns_and_certificates ? 1 : 0

  source = "./modules/dns_and_certificates"

  environment = var.solution_name

  route53_subdomain = var.solution_name
  route53_zone_id   = var.route53_zone_id
  domain            = var.domain_name

  create_load_balancer = var.create_load_balancer
  lb_dns_name          = length(module.l7_loadbalancer) == 0 ? "" : module.l7_loadbalancer[0].lb_dns_name

  providers = {
    aws.useast1 = aws.useast1
  }
}

module "cloudfront_cdn" {
  source        = "./modules/cloudfront_cdn"
  solution_name = var.solution_name

  origin_alb_url  = length(module.l7_loadbalancer) == 0 ? null : module.l7_loadbalancer[0].lb_dns_name
  domain          = length(module.dns_and_certificates) == 0 ? null : module.dns_and_certificates[0].domain_name
  certificate_arn = length(module.dns_and_certificates) == 0 ? null : module.dns_and_certificates[0].cloudfront_certificate_arn

  calculated_zone_id = var.create_dns_and_certificates ? module.dns_and_certificates[0].hosted_zone_id : ""

  enable_s3_for_static_website = var.enable_s3_for_static_website

  s3_solution_bucket_cf_behaviours = var.s3_solution_bucket_cf_behaviours

  s3_solution_bucket_name        = try(module.s3_solution_bucket[0].s3_solution_bucket_name, "")
  s3_solution_bucket_arn         = try(module.s3_solution_bucket[0].s3_bucket_arn, "")
  s3_solution_bucket_domain_name = try(module.s3_solution_bucket[0].s3_bucket_domain_name, "")

  # ignored if static web page is deactivated
  add_default_index_html = var.enable_s3_for_static_website && var.add_default_index_html
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

  public_subnets         = module.vpc.public_subnets
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

module "app_components" {
  for_each = var.app_components

  source = "./modules/app_component"

  name              = each.key
  solution_name     = var.solution_name
  container_runtime = module.cluster.ecs_cluster_name
  cluster_type      = var.cluster_type

  instances = each.value["instances"]

  total_cpu    = each.value["total_cpu"]
  total_memory = each.value["total_memory"]

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

  lb_domain_name = var.create_dns_and_certificates ? "lb.${local.domain_name}" : ""

  depends_on = [module.l7_loadbalancer, module.security_groups]
}

module "bastion_host_ssm" {
  count = var.create_bastion_host ? 1 : 0

  source = "./modules/bastion_host_ssm"

  solution_name    = var.solution_name
  environment_name = var.solution_name

  depends_on = [module.vpc, module.security_groups]
}

locals {
  rds_cluster_engine_version                = var.database == "mysql" ? "8.0.30" : "14.5"
  rds_cluster_security_group_ids            = var.database == "mysql" ? [module.security_groups.mysql_db_sg] : [module.security_groups.postgres_db_sg]
  rds_cluster_enable_cloudwatch_logs_export = var.database == "mysql" ? ["audit"] : ["postgresql"]
}

module "database" {
  count = var.create_database ? 1 : 0

  database = var.database

  source        = "./modules/database"
  solution_name = var.solution_name

  db_subnet_group_name = module.vpc.database_subnet_group

  rds_cluster_database_name  = "${replace(var.solution_name, "-", "")}db" # alphanumeric and lower case
  rds_cluster_identifier     = "${lower(var.solution_name)}_db"
  rds_cluster_engine         = var.database
  rds_cluster_engine_version = local.rds_cluster_engine_version

  rds_cluster_security_group_ids = local.rds_cluster_security_group_ids

  # adapt these for prod! Now optimized for for testing and low costs
  rds_cluster_allocated_storage       = 20
  rds_cluster_max_allocated_storage   = 25
  rds_cluster_backup_retention_period = "7"            # at least 7 days or more for prod
  rds_cluster_deletion_protection     = false          # true for prod env
  rds_cluster_multi_az                = false          # true for ha prod envs
  rds_cluster_instance_instance_class = "db.t4g.micro" # db.t3.* for prod env
  rds_cluster_storage_encrypted       = true           # true for prod env or non-db.t2x.micro free tier instance

  rds_cluster_enable_cloudwatch_logs_export = local.rds_cluster_enable_cloudwatch_logs_export
}

# ---------------------------------------------------------------------------------------------------------------------
# Redis Cluster
# ---------------------------------------------------------------------------------------------------------------------
# tfsec:ignore:aws-elasticache-enable-backup-retention
resource "aws_elasticache_cluster" "redis" {
  count = var.create_elasticache_redis ? 1 : 0

  cluster_id         = "${var.solution_name}-redis"
  engine             = "redis"
  node_type          = "cache.t4g.micro"
  num_cache_nodes    = 1
  engine_version     = "5.0.6"
  subnet_group_name  = aws_elasticache_subnet_group.db_elastic_subnetgroup[0].name
  security_group_ids = [module.security_groups.redis_sg]
}

resource "aws_elasticache_subnet_group" "db_elastic_subnetgroup" {
  count = var.create_elasticache_redis ? 1 : 0

  name       = "${var.solution_name}-elasticache-subnet-group"
  subnet_ids = module.vpc.elasticache_subnets
}

# ---------------------------------------------------------------------------------------------------------------------
# ECR repo used for storing container images
# ---------------------------------------------------------------------------------------------------------------------
module "ecr" {
  count = var.create_ecr ? 1 : 0

  source        = "./modules/ecr"
  solution_name = var.solution_name

  ecr_name              = "${var.solution_name}-api"
  access_for_account_id = var.ecr_access_for_account_id # allow production account
}

# ---------------------------------------------------------------------------------------------------------------------
# S3 bucket used for solution specific purposes
# ---------------------------------------------------------------------------------------------------------------------
module "s3_solution_bucket" {
  count = var.create_s3_solution_bucket ? 1 : 0

  source                    = "./modules/s3_bucket"
  solution_name             = var.solution_name
  s3_solution_bucket_policy = var.s3_solution_bucket_policy
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
