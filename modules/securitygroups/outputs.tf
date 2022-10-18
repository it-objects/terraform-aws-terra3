output "loadbalancer_sg" {
  value = aws_security_group.loadbalancer_sg.id
}

output "ecs_task_sg" {
  value = aws_security_group.ecs_task_sg.id
}

output "mysql_access_marker_sg" {
  value = aws_security_group.mysql_access_marker_sg.id
}

output "mysql_db_sg" {
  value = aws_security_group.mysql_db_sg.id
}
