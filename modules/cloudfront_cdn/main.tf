locals {
  # -------------------------------------------------------------------------------------------------------------------
  # Define origins either with or without ALB
  # -------------------------------------------------------------------------------------------------------------------
  alb_origins = var.origin_alb_url == null ? {} : var.certificate_arn == null ? {
    # HTTP
    elb = {
      domain_name = var.origin_alb_url
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
    } : {
    # HTTPS
    elb = {
      domain_name = "lb.${var.domain}"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  s3_static_website_origins = !var.enable_s3_for_static_website ? {} : {
    s3_static_website = {
      domain_name = aws_s3_bucket.s3_static_website[0].bucket_regional_domain_name
      origin_path = ""

      s3_origin_config = {
        origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity[0].cloudfront_access_identity_path
      }
    }
  }

  s3_solution_bucket_origins = length(var.s3_solution_bucket_cf_behaviours) == 0 ? {} : {
    s3_solution_bucket = {
      domain_name = var.s3_solution_bucket_domain_name
      origin_path = ""

      s3_origin_config = {
        origin_access_identity = aws_cloudfront_origin_access_identity.oai_s3_solution_bucket[0].cloudfront_access_identity_path
      }
    }
  }

  all_origins = merge(local.alb_origins, local.s3_static_website_origins, local.s3_solution_bucket_origins)

  # -------------------------------------------------------------------------------------------------------------------
  # Define behaviours either with or without ALB
  # -------------------------------------------------------------------------------------------------------------------
  all_behaviors = flatten([
    length(var.s3_solution_bucket_cf_behaviours) == 0 ? [] : [
      for behaviour in var.s3_solution_bucket_cf_behaviours :
      {
        path_pattern           = behaviour.s3_solution_bucket_cloudfront_path
        target_origin_id       = "s3_solution_bucket"
        viewer_protocol_policy = "https-only"

        allowed_methods = ["GET", "HEAD", "OPTIONS"]
        cached_methods  = ["GET", "HEAD"]
        compress        = true

        min_ttl     = 0
        default_ttl = 0
        max_ttl     = 0

        use_forwarded_values     = false
        origin_request_policy_id = data.aws_cloudfront_origin_request_policy.ManagedCORSS3Origin.id
        cache_policy_id          = data.aws_cloudfront_cache_policy.ManagedCachingDisabled.id

        function_association = lookup(behaviour, "s3_solution_bucket_cloudfront_function", null) == null ? {} : {
          viewer-request : { function_arn : behaviour.s3_solution_bucket_cloudfront_function }
        }
      }
    ],
    var.origin_alb_url == null ? [] : [{
      path_pattern           = var.enable_s3_for_static_website ? "/api/*" : "/*"
      target_origin_id       = "elb"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true

      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0

      use_forwarded_values     = false
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.ManagedAllViewer.id
      cache_policy_id          = data.aws_cloudfront_cache_policy.ManagedCachingDisabled.id
    }],
    !var.enable_s3_for_static_website ? [] : [{
      path_pattern           = "/*"
      target_origin_id       = "s3_static_website"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true

      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0

      use_forwarded_values     = false
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.ManagedCORSS3Origin.id
      cache_policy_id          = data.aws_cloudfront_cache_policy.ManagedCachingDisabled.id

      function_association = var.s3_static_website_bucket_cf_function_arn == "" ? {} : {
        viewer-request : { function_arn : var.s3_static_website_bucket_cf_function_arn }
      }
    }]
  ])

  all_certificates = flatten([var.certificate_arn == null ? [
    {
      cloudfront_default_certificate = true
      acm_certificate_arn            = null
      minimum_protocol_version       = null
      ssl_support_method             = null
    }
    ] : [
    {
      cloudfront_default_certificate = false
      acm_certificate_arn            = var.certificate_arn
      minimum_protocol_version       = "TLSv1.2_2021"
      ssl_support_method             = "sni-only"
    }
  ]])
}

# for testing purposes WAF is disabled. TLS is disabled for the non-custom-domain examples.
# tfsec:ignore:aws-cloudfront-enable-waf tfsec:ignore:aws-cloudfront-use-secure-tls-policy
resource "aws_cloudfront_distribution" "general_distribution" {
  enabled         = true
  is_ipv6_enabled = true

  aliases = var.domain == null ? null : length(var.domain) == 0 ? null : [var.domain] # compact([var.domain, var.alias_domain_name, var.alias_domain_name_2])

  comment             = "General Cloudfront distribution."
  http_version        = "http2and3"      # enable QUIC
  price_class         = "PriceClass_All" #"PriceClass_100" # Use only North America and Europe
  retain_on_delete    = false
  wait_for_deployment = false

  default_root_object = var.enable_s3_for_static_website ? "index.html" : ""

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "cf-logs/"
  }

  dynamic "origin" {
    for_each = local.all_origins

    content {
      domain_name         = origin.value.domain_name
      origin_id           = lookup(origin.value, "origin_id", origin.key)
      origin_path         = lookup(origin.value, "origin_path", "")
      connection_attempts = lookup(origin.value, "connection_attempts", null)
      connection_timeout  = lookup(origin.value, "connection_timeout", null)

      dynamic "s3_origin_config" {
        for_each = length(keys(lookup(origin.value, "s3_origin_config", {}))) == 0 ? [] : [lookup(origin.value, "s3_origin_config", {})]

        content {
          origin_access_identity = lookup(s3_origin_config.value, "origin_access_identity", "")
        }
      }

      dynamic "custom_origin_config" {
        for_each = length(lookup(origin.value, "custom_origin_config", "")) == 0 ? [] : [lookup(origin.value, "custom_origin_config", "")]

        content {
          http_port                = custom_origin_config.value.http_port
          https_port               = custom_origin_config.value.https_port
          origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols     = custom_origin_config.value.origin_ssl_protocols
          origin_keepalive_timeout = lookup(custom_origin_config.value, "origin_keepalive_timeout", null)
          origin_read_timeout      = lookup(custom_origin_config.value, "origin_read_timeout", null)
        }
      }

      dynamic "custom_header" {
        for_each = lookup(origin.value, "custom_header", [])

        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      dynamic "origin_shield" {
        for_each = length(keys(lookup(origin.value, "origin_shield", {}))) == 0 ? [] : [lookup(origin.value, "origin_shield", {})]

        content {
          enabled              = origin_shield.value.enabled
          origin_shield_region = origin_shield.value.origin_shield_region
        }
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.all_behaviors
    iterator = i

    content {
      path_pattern           = i.value["path_pattern"]
      target_origin_id       = i.value["target_origin_id"]
      viewer_protocol_policy = i.value["viewer_protocol_policy"]

      allowed_methods           = lookup(i.value, "allowed_methods", ["GET", "HEAD", "OPTIONS"])
      cached_methods            = lookup(i.value, "cached_methods", ["GET", "HEAD"])
      compress                  = lookup(i.value, "compress", null)
      field_level_encryption_id = lookup(i.value, "field_level_encryption_id", null)
      smooth_streaming          = lookup(i.value, "smooth_streaming", null)
      trusted_signers           = lookup(i.value, "trusted_signers", null)
      trusted_key_groups        = lookup(i.value, "trusted_key_groups", null)

      cache_policy_id            = lookup(i.value, "cache_policy_id", null)
      origin_request_policy_id   = lookup(i.value, "origin_request_policy_id", null)
      response_headers_policy_id = lookup(i.value, "response_headers_policy_id", null)
      realtime_log_config_arn    = lookup(i.value, "realtime_log_config_arn", null)

      min_ttl     = lookup(i.value, "min_ttl", null)
      default_ttl = lookup(i.value, "default_ttl", null)
      max_ttl     = lookup(i.value, "max_ttl", null)

      dynamic "forwarded_values" {
        for_each = lookup(i.value, "use_forwarded_values", true) ? [true] : []

        content {
          query_string            = lookup(i.value, "query_string", false)
          query_string_cache_keys = lookup(i.value, "query_string_cache_keys", [])
          headers                 = lookup(i.value, "headers", [])

          cookies {
            forward           = lookup(i.value, "cookies_forward", "none")
            whitelisted_names = lookup(i.value, "cookies_whitelisted_names", null)
          }
        }
      }

      dynamic "lambda_function_association" {
        for_each = lookup(i.value, "lambda_function_association", [])
        iterator = l

        content {
          event_type   = l.key
          lambda_arn   = l.value.lambda_arn
          include_body = lookup(l.value, "include_body", null)
        }
      }

      dynamic "function_association" {
        for_each = lookup(i.value, "function_association", [])
        iterator = f

        content {
          event_type   = f.key
          function_arn = f.value.function_arn
        }
      }
    }
  }

  default_cache_behavior {
    allowed_methods  = var.enable_s3_for_static_website ? ["GET", "HEAD", "OPTIONS"] : ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = var.enable_s3_for_static_website ? "s3_static_website" : "elb"

    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    origin_request_policy_id = var.enable_s3_for_static_website ? data.aws_cloudfront_origin_request_policy.ManagedCORSS3Origin.id : data.aws_cloudfront_origin_request_policy.ManagedAllViewer.id
    cache_policy_id          = data.aws_cloudfront_cache_policy.ManagedCachingDisabled.id
  }

  dynamic "viewer_certificate" {
    for_each = local.all_certificates

    content {
      cloudfront_default_certificate = lookup(viewer_certificate.value, "cloudfront_default_certificate", "")
      acm_certificate_arn            = lookup(viewer_certificate.value, "acm_certificate_arn", "")
      minimum_protocol_version       = lookup(viewer_certificate.value, "minimum_protocol_version", "")
      ssl_support_method             = lookup(viewer_certificate.value, "ssl_support_method", "")
    }
  }

  # -------------------------------------------------------------------------------------------------------------------
  # needs to be added for SPA's
  # source: https://stackoverflow.com/questions/44318922/receive-accessdenied-when-trying-to-access-a-page-via-the-full-url-on-my-website
  # -------------------------------------------------------------------------------------------------------------------
  dynamic "custom_error_response" {
    for_each = var.disable_custom_error_response ? [] : [true]

    content {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    }
  }
}

resource "random_string" "random_s3_postfix" {
  length    = 4
  special   = false
  min_lower = 4
}

# ---------------------------------------------------------------------------------------------------------------------
# AWS S3 bucket
# TF: https://www.terraform.io/docs/providers/aws/r/s3_bucket.html
# AWS: http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html
# AWS CLI: http://docs.aws.amazon.com/cli/latest/reference/s3api/create-bucket.html
# ---------------------------------------------------------------------------------------------------------------------
#tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${var.solution_name}-cloudfront-logs-${random_string.random_s3_postfix.result}"

  force_destroy = true
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_enc_config" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Block all public access
# TF: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.cloudfront_logs.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Give access to account and log front cloud delivery
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  access_control_policy {
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
    grant {
      grantee {
        id   = data.aws_cloudfront_log_delivery_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Alias record for cloudfront distribution
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_route53_record" "domain" {
  count = var.calculated_zone_id == "" ? 0 : 1

  zone_id = var.calculated_zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.general_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.general_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Static Website
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# AWS S3 bucket for static website
# ---------------------------------------------------------------------------------------------------------------------
#tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "s3_static_website" {
  count = var.enable_s3_for_static_website ? 1 : 0

  bucket = "${var.solution_name}-static-website-s3-bucket-${random_string.random_s3_postfix.result}"

  force_destroy = true
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_static_website_enc_config" {
  count = var.enable_s3_for_static_website ? 1 : 0

  bucket = aws_s3_bucket.s3_static_website[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "s3_static_website_bucket_acl" {
  count = var.enable_s3_for_static_website ? 1 : 0

  bucket = aws_s3_bucket.s3_static_website[0].id
  acl    = "private"
}

resource "aws_s3_bucket_cors_configuration" "example" {
  count = var.enable_s3_for_static_website ? 1 : 0

  bucket = aws_s3_bucket.s3_static_website[0].id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = [aws_cloudfront_distribution.general_distribution.domain_name]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "random_string" "random_s3_static_website_postfix" {
  count = var.enable_s3_for_static_website ? 1 : 0

  length    = 4
  special   = false
  min_lower = 4
}

# ---------------------------------------------------------------------------------------------------------------------
# Block public access per-se
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "block_static_website_bucket" {
  count = var.enable_s3_for_static_website ? 1 : 0

  bucket = aws_s3_bucket.s3_static_website[0].bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------------------------------------------------
# store s3-static-website-bucket name in parameter store to be retrieved later
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ssm_parameter" "s3_static_website_bucket" {
  count = var.enable_s3_for_static_website ? 1 : 0

  name  = "/${var.solution_name}/s3-static-website-bucket"
  type  = "String"
  value = aws_s3_bucket.s3_static_website[0].bucket
}

resource "aws_ssm_parameter" "s3_static_website_bucket_arn" {
  count = var.enable_s3_for_static_website ? 1 : 0

  name  = "/${var.solution_name}/s3-static-website-bucket-arn"
  type  = "String"
  value = aws_s3_bucket.s3_static_website[0].arn
}

# ---------------------------------------------------------------------------------------------------------------------
# OAI for S3 static website
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  count = var.enable_s3_for_static_website ? 1 : 0

  comment = "OAI for static website."
}

data "aws_iam_policy_document" "s3_static_website_policy_document" {
  count = var.enable_s3_for_static_website ? 1 : 0

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3_static_website[0].arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity[0].iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.s3_static_website[0].arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity[0].iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_static_website_policy" {
  count = var.enable_s3_for_static_website ? 1 : 0

  bucket = aws_s3_bucket.s3_static_website[0].id
  policy = data.aws_iam_policy_document.s3_static_website_policy_document[0].json
}

# ---------------------------------------------------------------------------------------------------------------------
# OAI for S3 solution bucket
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_identity" "oai_s3_solution_bucket" {
  count = length(var.s3_solution_bucket_cf_behaviours) == 0 ? 0 : 1

  comment = "OAI for S3 solution bucket."
}

data "aws_iam_policy_document" "s3_solution_bucket_policy_document" {
  count = length(var.s3_solution_bucket_cf_behaviours) == 0 ? 0 : 1

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.s3_solution_bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai_s3_solution_bucket[0].iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [var.s3_solution_bucket_arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai_s3_solution_bucket[0].iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_solution_bucket_policy" {
  count = length(var.s3_solution_bucket_cf_behaviours) == 0 ? 0 : 1

  bucket = var.s3_solution_bucket_name
  policy = data.aws_iam_policy_document.s3_solution_bucket_policy_document[0].json
}

# ---------------------------------------------------------------------------------------------------------------------
# Example to demo serving static HTML content from an S3 bucket
# In a real-world scenario static HTML files are transferred via the AWS CLI ("aws s3 sync . s3://<bucket_names>/")
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_object" "object" {
  count = var.add_default_index_html ? 1 : 0

  bucket       = aws_s3_bucket.s3_static_website[0].bucket
  key          = "index.html"
  content      = "<h1>Hello world, Terra3!</h1>"
  content_type = "text/html"
}
