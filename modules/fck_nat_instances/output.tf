output "nat_instance_security_group" {
  value = aws_security_group.main.id
}

output "nat_instances_autoscaling_group_names" {
  value = aws_autoscaling_group.main[*].name
}

output "nat_instances_autoscaling_group_max_capacity" {
  value = aws_autoscaling_group.main[*].max_size
}

output "nat_instances_autoscaling_group_min_capacity" {
  value = aws_autoscaling_group.main[*].min_size
}

output "nat_instances_autoscaling_group_desired_capacity" {
  value = aws_autoscaling_group.main[*].desired_capacity
}

output "nat_instances_autoscaling_group_arn" {
  value = aws_autoscaling_group.main[*].arn
}
