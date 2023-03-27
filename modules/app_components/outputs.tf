output "app_components" {
  value = module.app_components
}

output "ecs_task_definition_name" {
  value = "my_app_component"
}

output "ecs_desire_task_count" {
  value = 0
}
