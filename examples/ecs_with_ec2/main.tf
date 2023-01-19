# ---------------------------------------------------------------------------------------------------------------------
# This is an example with Cluster type options.
# Here, cluster_type can be selected as "ECS_FARGATE" or "ECS_EC2".
# Default cluster_type is "ECS_FARGATE".
# ---------------------------------------------------------------------------------------------------------------------

locals {
  solution_name = "terra3-ecs"
}

module "terra3_examples" {
  source = "../.."

  solution_name                 = local.solution_name
  enable_account_best_practices = true

  # configure your environment here
  create_load_balancer = true

  # dependency: required for downloading container images
  nat = "NAT_INSTANCES"

  # Cluster type options
  #cluster_type = "FARGATE"
  cluster_type = "FARGATE_SPOT"
  #cluster_type = "EC2"

  #EC2 cluster configurations
  cluster_ec2_min_nodes           = 1
  cluster_ec2_max_nodes           = 2
  cluster_ec2_instance_type       = "t3a.small"
  cluster_ec2_desired_capacity    = 1
  cluster_ec2_detailed_monitoring = false
  cluster_ec2_volume_size         = 30

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
