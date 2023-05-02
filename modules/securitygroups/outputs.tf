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

output "postgres_access_marker_sg" {
  value = aws_security_group.postgres_access_marker_sg.id
}

output "postgres_db_sg" {
  value = aws_security_group.postgres_db_sg.id
}

output "redis_access_marker_sg" {
  value = aws_security_group.redis_access_marker_sg.id
}

output "redis_sg" {
  value = aws_security_group.redis_sg.id
}

output "redis_sg_arn" {
  value = aws_security_group.redis_sg.arn
}
