output "json_map" {
  value = local.json_map
}

output "ecs_service_name" {
  value = try(aws_ecs_service.ecs_service[0].name, null)
}

output "ecs_desire_task_count" {
  value = try(aws_ecs_service.ecs_service[0].desired_count, null)
}

output "ecs_service_arn" {
  value = try(aws_ecs_service.ecs_service[0].id, null)
}
