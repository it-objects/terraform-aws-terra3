output "json_map" {
  value = local.json_map
}

output "ecs_service_name" {
  value = aws_ecs_service.ecs_service.name
}
