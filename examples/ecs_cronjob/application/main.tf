# ---------------------------------------------------------------------------------------------------------------------
# This is an example showcasing Terra3's capabilities - Implementing ECS Cronjobs
# ---------------------------------------------------------------------------------------------------------------------

locals {
  solution_name = "ecs-cronjob"
}

module "terra3_examples" {
  source = "../../../modules/app_components"

  solution_name = local.solution_name

  app_components = {

    api = {

      instances = 1

      total_cpu    = 256
      total_memory = 512

      container = [
        module.api-container
      ]

      path_mapping = "/api/*"
      service_port = 80

      # for cost savings undeploy outside work hours
      enable_autoscaling = true
    }

    ecscronjob = {

      instances = 1

      total_cpu    = 256
      total_memory = 512

      container = [
        module.alpine_test_image
      ]

      # This entry configures this container to be called every 5 minutes. It is available internally only, is not
      # connected to the load balancer and has a timeout of 5 minutes until the container's execution should be completed
      configure_as_cronjob = "*/5 * * * ? *" # every 5 minutes
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Multi-Container Pod/Task
# - Exposed ports need to be different when used together
# - Names need to be different when used together
# ---------------------------------------------------------------------------------------------------------------------
module "api-container" {
  source = "../../../modules/container"

  name = "my_api_container"

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

# Using alpine as it returns with valid exit code 0 that does not break the step function
module "alpine_test_image" {
  source = "../../../modules/container"

  name = "my_alpine_test_container"

  container_image  = "alpine"
  container_cpu    = 100
  container_memory = 200

  map_environment = {
    "my_var_name1" : "my_var_value1",
    "my_var_name2" : "my_var_value2",
  }
}
