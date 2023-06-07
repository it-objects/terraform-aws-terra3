output "ecs_cluster_id" {
  value = aws_ecs_cluster.cluster.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.cluster.arn
}

output "solution_kms_key_id" {
  value = var.solution_kms_key_id
}

output "ecs_ec2_instances_autoscaling_group_name" {
  value = aws_autoscaling_group.ecs_ec2_asg[*].name
}

output "ecs_ec2_instances_autoscaling_group_max_capacity" {
  value = aws_autoscaling_group.ecs_ec2_asg[*].max_size
}

output "ecs_ec2_instances_autoscaling_group_min_capacity" {
  value = aws_autoscaling_group.ecs_ec2_asg[*].min_size
}

output "ecs_ec2_instances_autoscaling_group_desired_capacity" {
  value = aws_autoscaling_group.ecs_ec2_asg[*].desired_capacity
}

output "ecs_ec2_instances_autoscaling_group_arn" {
  value = aws_autoscaling_group.ecs_ec2_asg[*].arn
}
