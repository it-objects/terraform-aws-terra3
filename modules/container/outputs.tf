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

output "map_environment" {
  value = var.map_environment
}

output "environment" {
  value = local.environment
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
