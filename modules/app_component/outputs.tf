output "json_map" {
  value = local.json_map
}

output "ecs_service_name" {
  value = aws_ecs_service.ecs_service.name
}

output "ecs_desire_task_count" {
  value = aws_ecs_service.ecs_service.desired_count
}

output "ecs_service_arn" {
  value = aws_ecs_service.ecs_service.id
}
