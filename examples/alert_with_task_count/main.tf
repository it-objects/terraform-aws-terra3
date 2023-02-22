# ---------------------------------------------------------------------------------------------------------------------
# This is an example showcasing Terra3's alerting feature.
#
# Outcome: Like example 1 + a container runtime and no custom domain + alerting
# ---------------------------------------------------------------------------------------------------------------------

locals {
  solution_name = "task-count-alert"
}

module "terra3_examples" {
  source = "../.."

  solution_name                 = local.solution_name
  enable_account_best_practices = true

  # configure your environment here
  create_load_balancer = true

  # dependency: required for downloading container images
  nat = "NAT_INSTANCES"

  # enable CPU utilization alerts;
  alert_receivers_email = ["test@example.com.fake"] # an SNS confirmation mail needs to be confirmed before receiving alerts
  cpu_utilization_alert = true                      # minimal setup to enable alerts with defaults

  # enable alerting based on the task count.
  #task_count_alert       = true # false = default
  #task_count_lower_limit = 1    # 1 = default

  # disable memory utilization alerts but show possible settings; the same are available for cpu_utilization
  memory_utilization_alert                   = false # false disables all follow-up settings for this specific alert
  memory_utilization_high_evaluation_periods = 3     # how many times before switching state
  memory_utilization_high_period             = 300   # seconds before re-evaluation
  memory_utilization_high_threshold          = 90    # 90% of total amount of memory threshold
  memory_utilization_low_evaluation_periods  = 3     # how many times before switching state
  memory_utilization_low_period              = 300   # seconds before re-evaluation
  memory_utilization_low_threshold           = 0     # threshold of 0 disables alarm completely

  app_components = {

    my_app_component = {

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

    my_app_component2 = {

      instances = 1

      total_cpu    = 256
      total_memory = 512

      container = [
        module.container_my_main,
        module.container_my_sidecar
      ]

      listener_rule_prio = 300
      path_mapping       = "/api2/*"
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
