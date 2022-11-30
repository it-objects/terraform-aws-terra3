locals {
  environment_name = var.environment_name == "" ? "${var.solution_name}-env" : var.environment_name
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

  create_database_subnet_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  # this switch would spawn NAT gateways per AZ; we use NAT instances instead (see below)
  enable_nat_gateway = local.create_nat_gateway
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

locals {
  # local variables declaration
  create_nat_instances = var.nat == "NAT_INSTANCES" ? true : false
  create_nat_gateway   = var.nat == "NAT_GATEWAY" ? true : false
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

locals {
  # local variables declaration
  create_alter_nat = var.nat == "ALTER_NAT" ? true : false
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

  subnet_suffix = var.nat_subnet_suffix

  private_route_table_ids = module.vpc.private_route_table_ids

  tags = var.tags

  vpc_id                 = module.vpc.vpc_id
  vpc_private_subnet_ids = module.vpc.private_subnets
  vpc_public_subnet_ids  = module.vpc.public_subnets
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

module "database" {
  count = var.create_database ? 1 : 0

  source        = "../database"
  solution_name = var.solution_name

  db_subnet_group_subnet_ids = module.vpc.private_subnets

  rds_cluster_database_name  = "${replace(var.solution_name, "-", "")}db" # alphanumeric and lower case
  rds_cluster_identifier     = "${lower(var.solution_name)}_db"
  rds_cluster_engine         = "MySQL"
  rds_cluster_engine_version = "8.0.30"

  rds_cluster_security_group_ids = [module.security_groups.mysql_db_sg]

  # adapt these for prod! Now optimized for for testing and low costs
  rds_cluster_allocated_storage       = 20
  rds_cluster_max_allocated_storage   = 25
  rds_cluster_backup_retention_period = "1"           # at least 7 days for prod
  rds_cluster_deletion_protection     = false         # true for prod env
  rds_cluster_multi_az                = false         # true for ha prod envs
  rds_cluster_instance_instance_class = "db.t3.micro" # db.t3.* for prod env
  rds_cluster_storage_encrypted       = true          # true for prod env or non-db.t2x.micro free tier instance
}

module "ecr" {
  count = var.create_ecr ? 1 : 0

  source        = "../ecr"
  solution_name = var.solution_name

  ecr_name              = "${var.solution_name}-api"
  access_for_account_id = var.ecr_access_for_account_id # allow production account
}

# ---------------------------------------------------------------------------------------------------------------------
# S3 bucket used for storing images
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

# ---------------------------------------------------------------------------------------------------------------------
# VARIANT 2: OIDC
# ---------------------------------------------------------------------------------------------------------------------
# data "tls_certificate" "gitlab" {
#   url = var.gitlab_url
# }

# resource "aws_iam_openid_connect_provider" "gitlab" {
#   url            = var.gitlab_url
#   client_id_list = [var.gitlab_url] # aud_value = gitlab_url

#   # picks intermediate's certificate;
#   # in case of ITO's wildcard cert (AlphaSSL) it is valid until 20.2.2024
#   # in case of Amazon cert it is valid until 19.10.2025
#   # in case of LetsEncrypt cert (R3) it is valid until 15.9.2025
#   thumbprint_list = [data.tls_certificate.gitlab.certificates.0.sha1_fingerprint]
# }

# module "deployment-infra-role-oidc" {
#   source = "../gitlab-aws-oidc"

#   app_name          = "infra"
#   oidc_gitlab_arn   = aws_iam_openid_connect_provider.gitlab.arn
#   oidc_gitlab_url   = aws_iam_openid_connect_provider.gitlab.url
#   match_value       = ["project_path:other/project_name/repo_name:ref_type:branch:ref:main"]
#   policy_statements = [
#     {
#       "Sid" : "deploymentpolicy",
#       "Effect" : "Allow",
#       "Action" : [
#         "states:*",
#         "application-autoscaling:*",
#         "autoscaling:*",
#         "rds:*",
#         "s3:*",
#         "logs:*",
#         "elasticloadbalancing:*",
#         "iam:*",
#         "cloudfront:*",
#         "secretsmanager:*",
#         "cloudwatch:*",
#         "ssm:*",
#         "route53:*",
#         "ecs:*",
#         "ecr:*",
#         "ec2:*",
#         "ebs:*",
#         "events:*",
#         "acm:*",
#         "kms:*",
#       ],
#       "Resource" : "*"
#     }
#   ]
# }

# module "deployment-cf-website-role-oidc" {
#   source = "../gitlab-aws-oidc"

#   app_name          = "cfwebsite"
#   oidc_gitlab_arn   = aws_iam_openid_connect_provider.gitlab.arn
#   oidc_gitlab_url   = aws_iam_openid_connect_provider.gitlab.url
#   match_value       = ["project_path:other/project_name/*:ref_type:branch:ref:*"]
#   policy_statements = [
#     {
#       "Sid" : "cloudfrontinvalidationpolicy",
#       "Effect" : "Allow",
#       "Action" : [
#         "cloudfront:CreateInvalidation",
#         "cloudfront:GetInvalidation",
#         "cloudfront:ListInvalidations",
#       ],
#       "Resource" : [module.cloudfront_cdn.cloudfront_arn]
#     },
#     {
#       "Sid": "ListObjectsInBucket",
#       "Effect": "Allow",
#       "Action": "s3:ListBucket",
#       "Resource": [module.cloudfront_cdn.s3_static_website_arn]
#     },
#     {
#       "Sid": "AllObjectActions",
#       "Effect": "Allow",
#       "Action": "s3:*Object",
#       "Resource": ["${module.cloudfront_cdn.s3_static_website_arn}/*"]
#     },
#     {
#       "Sid": "ECRImagePush",
#       "Effect": "Allow",
#       "Action": [
#         "ecr:CompleteLayerUpload",
#         "ecr:UploadLayerPart",
#         "ecr:InitiateLayerUpload",
#         "ecr:BatchCheckLayerAvailability",
#         "ecr:PutImage"
#       ],
#       "Resource": module.ecr[0].ecr_arn
#     },
#     {
#       "Sid": "ECRRetrieveCredentials",
#       "Effect": "Allow",
#       "Action": "ecr:GetAuthorizationToken",
#       "Resource": "*"
#     }
#   ]
# }


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
