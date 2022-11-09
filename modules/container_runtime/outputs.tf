output "ecs_cluster_id" {
  value = local.create_ecs_with_fargate == true ? aws_ecs_cluster.fargate_cluster[0].id : aws_ecs_cluster.ec2_cluster[0].id
}

output "ecs_cluster_name" {
  value = local.create_ecs_with_fargate == true ? aws_ecs_cluster.fargate_cluster[0].name : aws_ecs_cluster.ec2_cluster[0].name
}

output "solution_kms_key_id" {
  value = var.solution_kms_key_id
}
