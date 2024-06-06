# ---------------------------------------------------------------------------------------------------------------------
# This is example 2 showcasing Terra3's capabilities.
#
# Outcome: Like example 1 + a container runtime and no custom domain
# ---------------------------------------------------------------------------------------------------------------------

locals {
  solution_name = "terra3-example2"
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

    my_app_component = {

      instances = 1

      total_cpu    = 256
      total_memory = 512

      container = [
        module.container_my_main
      ]

      path_mapping = "/api/*"
      service_port = 80

      # for cost savings undeploy outside work hours
      enable_autoscaling = false

      attach_ebs_to_ecs_container = true
      #attach_ebs_volume = true
    }

    my_app_component_2 = {

      instances = 1

      total_cpu    = 256
      total_memory = 512

      container = [
        module.container_my_sidecar
      ]

      path_mapping = "/apiii/*"
      service_port = 1090

      # for cost savings undeploy outside work hours
      enable_autoscaling = false

      attach_ebs_to_ecs_container = true
      #attach_ebs_volume = true
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

  solution_name                 = local.solution_name

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

  attach_ebs_volume = true
  ebs_volume_names = [ "my_app_component-Service-Volume" ]
  container_path = "/data"

  mount_points = [{
    "sourceVolume" : "my_app_component-Service-Volume", #"${var.name}-Service-Volume"
    "containerPath" : "/data",
    "readOnly" : false
  }]

  readonlyRootFilesystem = false # disable because of entrypoint script
}

module "container_my_sidecar" {
  source = "../../modules/container"

  name = "my_sidecar"

  solution_name     = local.solution_name
  attach_ebs_volume = true

  mount_points = [{
    "sourceVolume" : "my_app_component_2-Service-Volume", #"${var.name}-Service-Volume"
    "containerPath" : "/data",
    "readOnly" : false
  }]
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

  readonlyRootFilesystem = true
}
