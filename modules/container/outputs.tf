output "name" {
  value = var.name
}

output "container_image" {
  value = var.container_image
}

output "container_cpu" {
  value = var.container_cpu
}

output "container_memory" {
  value = var.container_memory
}

output "container_memory_reservation" {
  value = var.container_memory_reservation
}

output "port_mappings" {
  value = var.port_mappings
}

output "mount_points" {
  value = var.mount_points
}

output "ebs_volume_namess" {
  value = var.ebs_volume_names
}

output "attach_ebs_volume" {
  value = var.attach_ebs_volume
}

output "source_volume" {
  value = var.source_volume
}

output "container_path" {
  value = var.container_path
}

output "read_only" {
  value = var.read_only
}

output "environment" {
  value = local.environment
}

output "secrets" {
  value = local.secrets
}

output "command" {
  value = var.command
}

output "essential" {
  value = var.essential
}

output "readonlyRootFilesystem" {
  value = var.readonlyRootFilesystem
}

output "log_configuration" {
  value = var.log_configuration
}
