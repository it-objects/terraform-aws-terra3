locals {
  zone_id      = var.route53_zone_id == "" ? aws_route53_zone.hostedzone[0].zone_id : var.route53_zone_id
  name_servers = var.route53_zone_id == "" ? aws_route53_zone.hostedzone[0].name_servers : []
  domain_name  = var.route53_zone_id == "" ? var.domain : data.aws_route53_zone.imported_hostedzone[0].name

  loadbalancer_available = var.create_load_balancer
}

# ---------------------------------------------------------------------------------------------------------------------
# Hosted Zone; Is only created if var.route53_zone_id is not given by solution
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route53_zone" "hostedzone" {
  count = var.route53_zone_id == "" ? 1 : 0
  name  = var.domain
}

data "aws_route53_zone" "imported_hostedzone" {
  count   = var.route53_zone_id == "" ? 0 : 1
  zone_id = var.route53_zone_id
}



# ---------------------------------------------------------------------------------------------------------------------
# cert for root domain in Virgina required by CloudFront
# If alias domain is set, make alias domain first and domain_name second, as domain_name is usually the internal
# auto-generated domain name and alias domain the final one.
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_acm_certificate" "domain_certificate" {
  domain_name               = length(var.alias_domain_name) == 0 ? var.create_subdomain ? "${var.solution_name}.${local.domain_name}" : local.domain_name : var.alias_domain_name
  validation_method         = "DNS"
  subject_alternative_names = length(var.alias_domain_name) == 0 ? [] : var.create_subdomain ? ["${var.solution_name}.${local.domain_name}"] : [local.domain_name]

  # It's recommended to specify create_before_destroy = true in a lifecycle block to
  # replace a certificate which is currently in use (eg, by aws_lb_listener).
  lifecycle {
    create_before_destroy = true
  }

  provider = aws.useast1
}

# ---------------------------------------------------------------------------------------------------------------------
# Required for DNS validation: adds a record to the DNS zone to show that we own the DNS zone
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route53_record" "route53_validation_record_domain" {
  for_each = {
    for dvo in aws_acm_certificate.domain_certificate.domain_validation_options : dvo.domain_name => {
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
  zone_id         = local.zone_id
}
