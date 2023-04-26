output "nat_instance_security_group" {
  value = aws_security_group.nat.id
}

output "nat_instances_autoscaling_group_names" {
  value = aws_autoscaling_group.this[*].name
}

output "nat_instances_autoscaling_group_max_capacity" {
  value = aws_autoscaling_group.this[*].max_size
}

output "nat_instances_autoscaling_group_min_capacity" {
  value = aws_autoscaling_group.this[*].min_size
}

output "nat_instances_autoscaling_group_desired_capacity" {
  value = aws_autoscaling_group.this[*].desired_capacity
}

output "nat_instances_autoscaling_group_arn" {
  value = aws_autoscaling_group.this[*].arn
}
