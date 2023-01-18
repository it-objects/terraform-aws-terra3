output "ecs_cluster_id" {
  value = aws_ecs_cluster.cluster.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "solution_kms_key_id" {
  value = var.solution_kms_key_id
}
