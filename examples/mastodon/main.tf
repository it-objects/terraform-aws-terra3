# ---------------------------------------------------------------------------------------------------------------------
# This is a Mastodon AWS setup using Terra3.
# ---------------------------------------------------------------------------------------------------------------------
module "mastodon-on-aws" {
  source = "../.."

  solution_name = var.solution_name
  # enable_account_best_practices = true # disabled because Mastodon requires a public bucket
  enable_s3_for_static_website = false # there's no static website, Mastodon is served from web app container

  # if set to true, domain_name or domain of zone is required
  enable_custom_domain = true

  # domain name of hosted zone to which we have full access
  # domain_name = var.custom_domain_name
  route53_zone_id = var.route53_zone_id

  # configure your environment here
  create_load_balancer = true

  # provision redis
  create_elasticache_redis = true

  # provision postgres db
  create_database = true
  database        = "postgres"

  # provision an S3 solution bucket to store uploaded media
  create_s3_solution_bucket = true

  # Mastodon specialty 1:
  # although ACL for S3 are deprecated, it's still needed for Mastodon as of v4.1.x
  # there is an open PR that will make the option below obsolete
  # PR: https://github.com/mastodon/mastodon/pull/17979
  s3_solution_bucket_enable_acl = true

  # Mastodon specialty 2:
  # Configure Cloudfront to forward URL paths to S3 solution bucket.
  s3_solution_bucket_cf_behaviours = [
    {
      s3_solution_bucket_cloudfront_path = "/media_attachments/*"
    },
    {
      # Mastodon provides the image under /system/media_attachments immediately after the upload. Only after a page
      # reload, the image is served from /media_attachments. Thus, this Cloudfront function rewrites requests from
      # /system/* => /*
      s3_solution_bucket_cloudfront_path     = "/system/media_attachments/*"
      s3_solution_bucket_cloudfront_function = aws_cloudfront_function.cf_function_rewrite_system_dir_request.arn
    }
  ]

  # prepare cluster to allow enabling ECS exec; each component requires enable_ecs_exec for which it should be activated
  enable_ecs_exec = true

  # dependency: required for downloading container images
  nat = "NAT_INSTANCES"

  # define the three Mastodon application components (web, streaming api and sidekiq)
  app_components = {

    mastodon_streaming_api = {
      path_mapping = "/api/v1/streaming/*"

      instances    = 1
      total_cpu    = 256
      total_memory = 512

      container = [
        module.mastodon_streaming_api
      ]

      service_port       = 4000
      lb_healthcheck_url = "/api/v1/streaming/health"
      enable_ecs_exec    = true

      # for cost savings undeploy outside work hours
      enable_autoscaling = true
    }

    mastodon_web = {
      path_mapping = "/*"

      instances    = 1
      total_cpu    = 512
      total_memory = 1024

      container = [
        module.mastodon_web
      ]

      service_port = 3000

      lb_healthcheck_url          = "/health"
      lb_healthcheck_grace_period = 60 # in seconds

      enable_ecs_exec = true

      s3_solution_bucket_access = true

      # for cost savings undeploy outside work hours
      enable_autoscaling = true
    }

    mastodon_sidekiq = {
      instances    = 1
      total_cpu    = 256
      total_memory = 512 # optimal size is 1024

      container = [
        module.mastodon_sidekiq
      ]

      internal_service = true
      enable_ecs_exec  = true

      # for cost savings undeploy outside work hours
      enable_autoscaling = true
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Read generated db_credentials from Terra3 module and add these as parameter to the container's env vars
# ---------------------------------------------------------------------------------------------------------------------
locals {
  db_user     = try(jsondecode(module.mastodon-on-aws.db_credentials)["DB_USER"], "")
  db_password = try(jsondecode(module.mastodon-on-aws.db_credentials)["DB_PASSWORD"], "")
  db_name     = try(jsondecode(module.mastodon-on-aws.db_credentials)["DB_NAME"], "")
  db_host     = try(jsondecode(module.mastodon-on-aws.db_credentials)["DB_HOST"], "")
}

# ---------------------------------------------------------------------------------------------------------------------
# Multi-Container Pod/Task
# - Exposed ports need to be different when used together
# - Names need to be different when used together
# ---------------------------------------------------------------------------------------------------------------------
module "mastodon_web" {
  source = "../../modules/container"

  name = "mastodon_web"

  container_image  = var.mastodon_image
  container_cpu    = 512
  container_memory = 1024

  command = ["bash", "-c", "bundle exec rails db:migrate && bundle exec rails s -p 3000"]

  port_mappings = [{ # container reachable by load balancer must have the same name and port
    protocol      = "tcp"
    containerPort = 3000
  }]

  map_environment = {
    "LOCAL_DOMAIN" : module.mastodon-on-aws.domain_name,
    "REDIS_HOST" : module.mastodon-on-aws.redis_endpoint,
    "DB_PASS" : local.db_password,
    "ES_ENABLED" : "false", # elasticsearch disabled for now
    "SECRET_KEY_BASE" : var.secret_key_base,
    "OTP_SECRET" : var.otp_secret,
    "VAPID_PRIVATE_KEY" : var.vapid_private_key,
    "VAPID_PUBLIC_KEY" : var.vapid_public_key,
    "S3_ENABLED" : "true",
    "S3_BUCKET" : module.mastodon-on-aws.s3_solution_bucket_name,
    "S3_REGION" : data.aws_region.current_region.id,
    "S3_PROTOCOL" : "https"
    "S3_HOSTNAME" : "s3-${data.aws_region.current_region.id}.amazonaws.com"
    "S3_ALIAS_HOST" : module.mastodon-on-aws.domain_name
    # "S3_ACL_DISABLED" : "true", # mastodon PR still pending; until then, solution buckets needs to have ACL enabled with s3_solution_bucket_enable_acl = true
    "DB_NAME" : local.db_name,
    "DB_USER" : local.db_user,
    "DB_HOST" : local.db_host
    "RAILS_ENV" : "production",
    "SMTP_SERVER" : var.smtp_server,
    "SMTP_PORT" : "587",
    "SMTP_LOGIN" : var.smtp_login,
    "SMTP_PASSWORD" : var.smtp_password,
    "SMTP_FROM_ADDRESS" : var.smtp_from_address
  }

  log_configuration = {
    "logDriver" : "awslogs",
    "options" : {
      awslogs-group : "mastodon_webLogGroup",
      awslogs-region : "eu-central-1",
      awslogs-stream-prefix : var.solution_name
    }
  }

  readonlyRootFilesystem = false # disable because of entrypoint script
}

module "mastodon_streaming_api" {
  source = "../../modules/container"

  name = "mastodon_streaming_api"

  container_image  = var.mastodon_image
  container_cpu    = 256
  container_memory = 512

  command = ["bash", "-c", "node ./streaming"]

  port_mappings = [{ # container reachable by load balancer must have the same name and port
    protocol      = "tcp"
    containerPort = 4000
  }]

  map_environment = {
    "LOCAL_DOMAIN" : module.mastodon-on-aws.domain_name,
    "REDIS_HOST" : module.mastodon-on-aws.redis_endpoint,
    "DB_PASS" : local.db_password,
    "ES_ENABLED" : "false", # elasticsearch disabled for now
    "SECRET_KEY_BASE" : var.secret_key_base,
    "OTP_SECRET" : var.otp_secret,
    "VAPID_PRIVATE_KEY" : var.vapid_private_key,
    "VAPID_PUBLIC_KEY" : var.vapid_public_key,
    "DB_NAME" : local.db_name,
    "DB_USER" : local.db_user,
    "DB_HOST" : local.db_host
    "RAILS_ENV" : "production",
  }

  log_configuration = {
    "logDriver" : "awslogs",
    "options" : {
      awslogs-group : "mastodon_streaming_apiLogGroup",
      awslogs-region : "eu-central-1",
      awslogs-stream-prefix : var.solution_name
    }
  }

  readonlyRootFilesystem = false # disable because of entrypoint script
}

module "mastodon_sidekiq" {
  source = "../../modules/container"

  name = "mastodon_sidekiq"

  container_image  = var.mastodon_image
  container_cpu    = 256
  container_memory = 512

  command = ["bash", "-c", "bundle exec sidekiq"]

  port_mappings = [{ # container reachable by load balancer must have the same name and port
    protocol      = "tcp"
    containerPort = 6000
  }]

  map_environment = {
    "LOCAL_DOMAIN" : module.mastodon-on-aws.domain_name,
    "REDIS_HOST" : module.mastodon-on-aws.redis_endpoint,
    "DB_PASS" : local.db_password,
    "ES_ENABLED" : "false", # elasticsearch disabled for now
    "SECRET_KEY_BASE" : var.secret_key_base,
    "OTP_SECRET" : var.otp_secret,
    "VAPID_PRIVATE_KEY" : var.vapid_private_key,
    "VAPID_PUBLIC_KEY" : var.vapid_public_key,
    "DB_NAME" : local.db_name,
    "DB_USER" : local.db_user,
    "DB_HOST" : local.db_host
    "RAILS_ENV" : "production",
    "SMTP_SERVER" : var.smtp_server,
    "SMTP_PORT" : "587",
    "SMTP_LOGIN" : var.smtp_login,
    "SMTP_PASSWORD" : var.smtp_password,
    "SMTP_FROM_ADDRESS" : var.smtp_from_address
  }

  log_configuration = {
    "logDriver" : "awslogs",
    "options" : {
      awslogs-group : "mastodon_sidekiqLogGroup",
      awslogs-region : "eu-central-1",
      awslogs-stream-prefix : var.solution_name
    }
  }

  readonlyRootFilesystem = false # disable because of entrypoint script
}

# Mastodon requires a URL rewrite rule from /system to / in order to properly show media assets correctly immediately after uploading it
resource "aws_cloudfront_function" "cf_function_rewrite_system_dir_request" {
  name    = "${var.solution_name}-RewriteSystemDirRequest"
  runtime = "cloudfront-js-1.0"
  comment = "CloudFront Function rewrite /system dir."
  publish = true
  code    = file("${path.module}/cloudfront_functions/rewritesystemdir.js")
}
