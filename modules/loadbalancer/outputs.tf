output "lb_arn" {
  value = aws_lb.this.arn
}

output "lb_dns_name" {
  value = aws_lb.this.dns_name
}
