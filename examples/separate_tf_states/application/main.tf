# ---------------------------------------------------------------------------------------------------------------------
# This is an example showcasing Terra3's capabilities.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  solution_name = "t3-two-states"
}

module "terra3_examples" {
  source = "../../../modules/app_components"

  solution_name = local.solution_name

  app_components = {

    t3-two-states-component = {

      instances = 1

      total_cpu    = 256
      total_memory = 512

      container = [
        module.container_my_main
      ]

      path_mapping = "/api/*"
      service_port = 80

      # for cost savings undeploy outside work hours
      enable_autoscaling = true
    }

    t3-two-states-component-2 = {

      instances = 1

      total_cpu    = 256
      total_memory = 512

      container = [
        module.container_my_main
      ]

      path_mapping = "/custom/*"
      service_port = 80

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
  source = "../../../modules/container"

  name = "my_main_container"

  container_image  = "nginxdemos/hello"
  container_cpu    = 100
  container_memory = 200

  port_mappings = [{ # container reachable by load balancer must have the same name and port
    protocol      = "tcp"
    containerPort = 80
  }]

  map_environment = {
    "my_var_name1" : "my_var_value1",
    "my_var_name2" : "my_var_value2",
  }

  readonlyRootFilesystem = false # disable because of entrypoint script
}
