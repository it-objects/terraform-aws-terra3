# ---------------------------------------------------------------------------------------------------------------------
# This is example to showcase Terra3's capabilities of enabling global scale down.mjs/up option.
#
# Outcome: Environment can be put to hibernation state (sleep/wake up).
# ---------------------------------------------------------------------------------------------------------------------

locals {
  solution_name = "scale-down"
}

module "terra3_examples" {
  source = "../.."

  solution_name                 = local.solution_name
  enable_account_best_practices = true

  # configure your environment here
  create_load_balancer = true
  create_bastion_host  = true
  #create_database          = true
  #database                 = "postgres"
  #create_elasticache_redis = true

  # dependency: required for downloading container images
  nat = "NAT_INSTANCES"

  # Please make sure to enable only one feature at a time.
  # Either enable_environment_hibernation_sleep_schedule OR enable_autoscaling in app_components.
  enable_environment_hibernation_sleep_schedule = true
  environment_hibernation_sleep_schedule        = "cron(00 18 ? * MON-FRI *)" #Down
  environment_hibernation_wakeup_schedule       = "cron(00 04 ? * MON-FRI *)" #Up

  app_components = {

    global_scale_down_app_component = {

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
