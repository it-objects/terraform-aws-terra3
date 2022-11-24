locals {
  environment_name = var.environment_name == "" ? "${var.solution_name}-env" : var.environment_name

  # "nat" variable defines how nat should be configured
  create_nat_instances          = (var.nat == "NAT_INSTANCES") ? true : false
  create_nat_gateway            = (var.nat != "NO_NAT" && var.nat != "NAT_INSTANCES") ? true : false
  create_single_nat_gateway     = (var.nat == "NAT_GATEWAY_SINGLE") ? true : false
  create_one_nat_gateway_per_az = (var.nat == "NAT_GATEWAY_PER_AZ") ? true : false
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

  source        = "../nat_instances"
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

module "l7_loadbalancer" {
  count = var.create_load_balancer ? 1 : 0

  source        = "../loadbalancer"
  solution_name = var.solution_name

  public_subnets  = module.vpc.public_subnets
  security_groups = [module.security_groups.loadbalancer_sg]
}

module "security_groups" {
  source = "../securitygroups"

  name   = local.environment_name
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

  source = "../dns_and_certificates"

  environment = local.environment_name

  route53_subdomain = local.environment_name
  route53_zone_id   = var.route53_zone_id
  domain            = var.domain_name

  create_load_balancer = var.create_load_balancer
  lb_dns_name          = length(module.l7_loadbalancer) == 0 ? "" : module.l7_loadbalancer[0].lb_dns_name

  providers = {
    aws.useast1 = aws.useast1
  }
}

module "cloudfront_cdn" {
  source        = "../cloudfront_cdn"
  solution_name = var.solution_name

  origin_alb_url  = length(module.l7_loadbalancer) == 0 ? null : module.l7_loadbalancer[0].lb_dns_name
  domain          = length(module.dns_and_certificates) == 0 ? null : module.dns_and_certificates[0].domain_name
  certificate_arn = length(module.dns_and_certificates) == 0 ? null : module.dns_and_certificates[0].cloudfront_certificate_arn

  calculated_zone_id = var.create_dns_and_certificates ? module.dns_and_certificates[0].hosted_zone_id : ""

  add_default_index_html = var.add_default_index_html
}

module "bastion_host_ssm" {
  count = var.create_bastion_host ? 1 : 0

  source = "../bastion_host_ssm"

  solution_name    = var.solution_name
  environment_name = local.environment_name

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

  source        = "../database"
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

#module "database_postgres" {
#  count = var.create_database ? 1 : 0
#
#  source        = "../database"
#  solution_name = var.solution_name
#
#  db_subnet_group_subnet_ids = module.vpc.database_subnets
#
#  rds_cluster_database_name  = "${replace(var.solution_name, "-", "")}db" # alphanumeric and lower case
#  rds_cluster_identifier     = "${lower(var.solution_name)}_db"
#  rds_cluster_engine         = "MySQL"
#  rds_cluster_engine_version = "8.0.30"
#
#  rds_cluster_security_group_ids = [module.security_groups.mysql_db_sg]
#
#  # adapt these for prod! Now optimized for for testing and low costs
#  rds_cluster_allocated_storage       = 20
#  rds_cluster_max_allocated_storage   = 25
#  rds_cluster_backup_retention_period = "7"           # at least 7 days or more for prod
#  rds_cluster_deletion_protection     = false         # true for prod env
#  rds_cluster_multi_az                = false         # true for ha prod envs
#  rds_cluster_instance_instance_class = "db.t4g.micro" # db.t3.* for prod env
#  rds_cluster_storage_encrypted       = true          # true for prod env or non-db.t2x.micro free tier instance
#}

# ---------------------------------------------------------------------------------------------------------------------
# ECR repo used for storing container images
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_elasticache_cluster" "redis" {
  cluster_id         = "${var.solution_name}-redis"
  engine             = "redis"
  node_type          = "cache.t4g.micro"
  num_cache_nodes    = 1
  engine_version     = "5.0.6"
  subnet_group_name  = aws_elasticache_subnet_group.db_elastic_subnetgroup.name
  security_group_ids = [module.security_groups.redis_sg]
}

resource "aws_elasticache_subnet_group" "db_elastic_subnetgroup" {
  name       = "mastodonsubnetgroup"
  subnet_ids = module.vpc.elasticache_subnets
}

# ---------------------------------------------------------------------------------------------------------------------
# ECR repo used for storing container images
# ---------------------------------------------------------------------------------------------------------------------
module "ecr" {
  count = var.create_ecr ? 1 : 0

  source        = "../ecr"
  solution_name = var.solution_name

  ecr_name              = "${var.solution_name}-api"
  access_for_account_id = var.ecr_access_for_account_id # allow production account
}

# ---------------------------------------------------------------------------------------------------------------------
# S3 bucket used for solution specific purposes
# ---------------------------------------------------------------------------------------------------------------------
module "s3_bucket" {
  count = var.create_s3_bucket ? 1 : 0

  source        = "../s3_bucket"
  solution_name = var.solution_name
}

module "newrelic_account_integration" {
  count               = var.create_newrelic_integration ? 1 : 0
  source              = "../newrelic_integration"
  newrelic_account_id = var.newrelic_account_id
}

# ---------------------------------------------------------------------------------------------------------------------
# User for CI/CD deployment
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# VARIANT 1: ACCESS_KEYS
# ---------------------------------------------------------------------------------------------------------------------
module "deployment_user" {
  count = var.create_deployment_user ? 1 : 0

  source = "../deployment_user"
}

resource "aws_ssm_parameter" "vpc_id" {
  name  = "/${local.environment_name}/vpc_id"
  type  = "String"
  value = module.vpc.vpc_id
}

resource "aws_ssm_parameter" "environment_alb_arn" {
  count = var.create_load_balancer ? 1 : 0

  name  = "/${local.environment_name}/alb_arn"
  type  = "String"
  value = length(module.l7_loadbalancer) == 0 ? "" : module.l7_loadbalancer[0].lb_arn
}

resource "aws_ssm_parameter" "environment_alb_url" {
  count = var.create_load_balancer ? 1 : 0

  name  = "/${local.environment_name}/alb_url"
  type  = "String"
  value = length(module.l7_loadbalancer) == 0 ? "" : module.l7_loadbalancer[0].lb_dns_name
}
