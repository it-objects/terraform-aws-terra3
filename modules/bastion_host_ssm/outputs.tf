output "bastion_host_autoscaling_group_name" {
  value = aws_autoscaling_group.my_autoscaling_group.name
}

output "bastion_host_autoscaling_group_max_capacity" {
  value = aws_autoscaling_group.my_autoscaling_group.max_size
}

output "bastion_host_autoscaling_group_min_capacity" {
  value = aws_autoscaling_group.my_autoscaling_group.min_size
}

output "bastion_host_autoscaling_group_desired_capacity" {
  value = aws_autoscaling_group.my_autoscaling_group.desired_capacity
}

output "bastion_host_autoscaling_group_arn" {
  value = aws_autoscaling_group.my_autoscaling_group.arn
}
