output "json_map" {
  value = local.json_map
}

output "ecs_service_name" {
  value = aws_ecs_service.ecs_service.name
}

output "ecs_task_definition_name" {
  value = aws_ecs_task_definition.ecs_task_definition.family
}

output "ecs_desire_task_count" {
  value = aws_ecs_service.ecs_service.desired_count
}
