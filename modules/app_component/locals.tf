locals {
  # loop through all container definitions (and merge with default)
  # later entries overwrite former entries
  json_map = jsonencode([for single_container in var.container : merge(
    local.default_container_definition,
    {
      name   = single_container.name
      image  = single_container.container_image
      cpu    = single_container.container_cpu
      memory = single_container.container_memory

      memoryReservation = single_container.container_memory_reservation

      portMappings = single_container.port_mappings
      environment  = single_container.environment
      secrets      = single_container.secrets

      command = single_container.command

      essential = single_container.essential

      readonlyRootFilesystem = single_container.readonlyRootFilesystem
    }
  )])

  default_container_definition = {
    name   = "default_name"
    image  = "nginx:latest"
    cpu    = 512
    memory = 256

    portMappings = [{ # container reachable by load balancer must have the same name and port
      protocol      = "tcp"
      containerPort = 80
    }]

    environment = []
    secrets     = []

    command = null

    essential   = true
    mountPoints = []
    volumesFrom = []

    readonlyRootFilesystem = false

    linuxParameters = {
      initProcessEnabled : true
    }

    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        awslogs-group : "${var.name}LogGroup",
        awslogs-region : data.aws_region.current_region.name,
        awslogs-stream-prefix : var.solution_name
      }
    }
  }
}
