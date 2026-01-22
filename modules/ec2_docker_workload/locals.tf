# -----------------------------------------------
# EC2 Docker Workload Module - Locals
# -----------------------------------------------

locals {
  # Security groups: use provided or create default
  security_groups = length(var.security_group_ids) > 0 ? var.security_group_ids : [aws_security_group.default[0].id]

  # Docker volume mount string for user data
  # Converts ebs_volumes list to Docker -v bind mount arguments
  docker_volume_mounts = join(" ", [
    for vol in var.ebs_volumes :
    "-v /mnt/${trimprefix(vol.device_name, "/dev/")}:${vol.mount_path}"
  ])

  # Environment variables for Docker run command
  # Converts map to Docker -e arguments
  docker_env_vars = join(" ", [
    for key, value in var.environment_variables :
    "-e ${key}=\"${replace(value, "\"", "\\\\")}\"" # Escape quotes in values
  ])

  # Port mappings for Docker run command
  docker_port_args = join(" ", [
    for pm in var.port_mappings :
    "-p ${pm.hostPort}:${pm.containerPort}/${pm.protocol}"
  ])

  # Common tags for all resources
  common_tags = merge(
    var.tags,
    {
      Name             = "${var.solution_name}-${var.instance_name}"
      ManagedBy        = "Terraform"
      Solution         = var.solution_name
      WorkloadInstance = var.instance_name
    }
  )

  # Parameter paths for SSM discovery
  ssm_param_prefix = "/${var.solution_name}/ec2_docker_workload/${var.instance_name}"
}
