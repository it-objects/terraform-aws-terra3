# ---------------------------------------------------------------------------------------------------------------------
# Application Loadbalancer
# ---------------------------------------------------------------------------------------------------------------------
#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "this" {
  name               = "${var.solution_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = var.security_groups

  enable_deletion_protection = false
  drop_invalid_header_fields = true
}

# default redirect of http to https
#resource "aws_lb_listener" "default_redirect_to_443" {
#  load_balancer_arn = aws_lb.this.arn
#  port              = "80"
#  protocol          = "HTTP"
#
#  default_action {
#    type = "redirect"
#    redirect {
#      host        = "#{host}"
#      path        = "/#{path}"
#      query       = "#{query}"
#      protocol    = "HTTPS"
#      port        = "443"
#      status_code = "HTTP_301"
#    }
#  }
#}
