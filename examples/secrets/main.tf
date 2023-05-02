# ---------------------------------------------------------------------------------------------------------------------
# This is example is showcasing Terra3's secrets injection.
#
# Outcome: Like example 1 + a container runtime and no custom domain + secret injection
# ---------------------------------------------------------------------------------------------------------------------

locals {
  solution_name = "terra3-secrets"

  # define the ARN of the secret; NOTE: replace ACCOUNT_NUMBER placeholder
  secret_arn = "arn:aws:secretsmanager:eu-central-1:<ACCOUNT_NUMBER>:secret:test/secret-oghXUn"
}

module "terra3_examples" {
  source = "../.."

  solution_name                 = local.solution_name
  enable_account_best_practices = true

  # configure your environment here
  create_load_balancer = true

  # dependency: required for downloading container images
  nat = "NAT_INSTANCES"

  app_components = {

    my_app_w_secrets = {

      instances = 1

      total_cpu    = 256
      total_memory = 512

      container = [
        module.container_my_main,
        module.container_my_sidecar
      ]

      listener_rule_prio = 200
      path_mapping       = "/api/*"
      service_port       = 80

      # adding IAM privilege to allow app_component to access secret
      execution_iam_access = {
        secrets = [
          local.secret_arn
        ]
      }

      # for cost savings undeploy outside work hours
      enable_autoscaling = true
    }

  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Multi-Container Pod/Task
# - Exposed ports need to be different when used together
# - Names need to be different when used together
# ---------------------------------------------------------------------------------------------------------------------
module "container_my_main" {
  source = "../../modules/container"

  name = "my_main_container"

  container_image  = "nginxdemos/hello"
  container_cpu    = 100
  container_memory = 200

  port_mappings = [{ # container reachable by load balancer must have the same name and port
    protocol      = "tcp"
    containerPort = 80
  }]

  map_environment = {
    "my_var_name" : "my_var_value",
    "my_var_name2" : "my_var_value2",
  }

  # add ARN of the secret to be injected. Add a reference ":<JSON_KEY>::" to JSON key of which the value should be added.
  # for more info go to https://docs.aws.amazon.com/AmazonECS/latest/developerguide/specifying-sensitive-data-secrets.html
  map_secrets = {
    "my_secret_name1" : "${local.secret_arn}:secret_key::"
  }

  readonlyRootFilesystem = false # disable because of entrypoint script
}

module "container_my_sidecar" {
  source = "../../modules/container"

  name = "my_sidecar"

  container_image  = "mockserver/mockserver"
  container_cpu    = 100
  container_memory = 200

  port_mappings = [{ # container reachable by load balancer must have the same name and port
    protocol      = "tcp"
    containerPort = 1090
  }]

  map_environment = {
    "my_var_name_sidecar" : "my_var_value",
    "MOCKSERVER_SERVER_PORT" : "1090"
  }

  essential = false

  readonlyRootFilesystem = true
}
