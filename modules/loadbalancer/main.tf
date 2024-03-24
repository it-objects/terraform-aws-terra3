# ---------------------------------------------------------------------------------------------------------------------
# Application Loadbalancer
# ---------------------------------------------------------------------------------------------------------------------
#tfsec:ignore:aws-elb-alb-not-public
#tfsec:ignore:aws-s3-enable-versioning
resource "aws_lb" "this" {
  name               = "${var.solution_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = var.security_groups

  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true

  access_logs {
    bucket  = try(module.log_bucket[0].s3_bucket_id, "")
    prefix  = "${var.solution_name}-alb"
    enabled = var.enable_alb_logs
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# HTTPS (Port 443) listener
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lb_listener" "port_443" {
  count = var.enable_custom_domain ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.subdomain_certificate[0].arn
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2020-10"

  # if no attached rule matches, do this
  default_action {
    type = "redirect"
    redirect {
      host        = var.default_redirect_url
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_302"
    }
  }
}

resource "aws_ssm_parameter" "alb_listener_443_arn" {
  name  = "/${var.solution_name}/alb_listener_443_arn"
  type  = "String"
  value = var.enable_custom_domain ? aws_lb_listener.port_443[0].arn : "-"
}

# ---------------------------------------------------------------------------------------------------------------------
# HTTP (Port 80) listener
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lb_listener" "port_80" {
  count = !var.enable_custom_domain ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      host        = var.default_redirect_url
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_302"
    }
  }
}

resource "aws_ssm_parameter" "alb_listener_arn" {
  name  = "/${var.solution_name}/alb_listener_80_arn"
  type  = "String"
  value = !var.enable_custom_domain ? aws_lb_listener.port_80[0].arn : "-"
}

# ---------------------------------------------------------------------------------------------------------------------
# ALB Log S3 bucket
# ---------------------------------------------------------------------------------------------------------------------
# tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
module "log_bucket" {
  count = var.enable_alb_logs ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.1"

  bucket = "${var.solution_name}-alb-logs-s3-bucket-${random_string.random_s3_alb_logs_postfix.result}"
  acl    = "log-delivery-write"

  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_elb_log_delivery_policy = true # Required for ALB logs
  #attach_lb_log_delivery_policy  = true # Required for ALB/NLB logs

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
}

resource "random_string" "random_s3_alb_logs_postfix" {
  length    = 4
  special   = false
  min_lower = 4
}

# ---------------------------------------------------------------------------------------------------------------------
# Write Loadbalancer config to SSM
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ssm_parameter" "environment_alb_arn" {
  name  = "/${var.solution_name}/alb_arn"
  type  = "String"
  value = aws_lb.this.arn
}

resource "aws_ssm_parameter" "environment_alb_url" {
  name  = "/${var.solution_name}/alb_url"
  type  = "String"
  value = aws_lb.this.dns_name
}

# ---------------------------------------------------------------------------------------------------------------------
# Loadbalancer subdomain
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route53_record" "subdomain" {
  count = var.enable_custom_domain ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = "lb.${var.domain_name}"
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.this.dns_name]
}

# ---------------------------------------------------------------------------------------------------------------------
# Certificate
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_acm_certificate" "subdomain_certificate" {
  count = var.enable_custom_domain ? 1 : 0

  domain_name       = "lb.${var.domain_name}"
  validation_method = "DNS"

  # It's recommended to specify create_before_destroy = true in a lifecycle block to
  # replace a certificate which is currently in use (eg, by aws_lb_listener).
  lifecycle {
    create_before_destroy = true
  }
}

locals {
  domain_validation_options = length(aws_acm_certificate.subdomain_certificate) > 0 ? aws_acm_certificate.subdomain_certificate[0].domain_validation_options : []
}

# ---------------------------------------------------------------------------------------------------------------------
# Required for DNS validation: adds a record to the DNS zone to show that we own the DNS zone
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route53_record" "route53_validation_record" {
  for_each = {
    for dvo in local.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}
