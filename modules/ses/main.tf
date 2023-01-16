# ---------------------------------------------------------------------------------------------------------------------
# Amazon Simple Email Service
# ---------------------------------------------------------------------------------------------------------------------

# SES Domain Verification
# To get an access to start sending emails.
resource "aws_ses_domain_identity" "ses_domain" {
  count  = var.create_ses ? 1 : 0
  domain = var.ses_domain_name
}

resource "aws_ses_domain_identity_verification" "amazonses_verification" {
  count  = var.create_ses ? 1 : 0
  domain = aws_ses_domain_identity.ses_domain[0].id
}

resource "aws_route53_record" "amazonses_verification_record" {
  count   = var.create_ses ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_amazonses.${var.ses_domain_name}"
  type    = "TXT"
  ttl     = "600"
  records = [join("", aws_ses_domain_identity.ses_domain.*.verification_token)]
}

# SES MAIL FROM Domain
resource "aws_ses_domain_mail_from" "main" {
  count            = var.create_ses ? 1 : 0
  domain           = aws_ses_domain_identity.ses_domain[0].domain
  mail_from_domain = var.mail_from_domain
}

# Sending MX Record
resource "aws_route53_record" "mx_send_mail_from" {
  count   = var.create_ses ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${data.aws_region.current_region.name}.amazonses.com"]
}

# Receiving MX Record
resource "aws_route53_record" "mx_receive" {
  count   = var.create_ses ? 1 : 0
  name    = var.ses_domain_name
  zone_id = data.aws_route53_zone.main.zone_id
  type    = "MX"
  ttl     = "600"
  records = ["10 inbound-smtp.${data.aws_region.current_region.name}.amazonaws.com"]
}

# SES DKIM Verification
# DKIM and SPF, which is a way to authenticate your emails

resource "aws_ses_domain_dkim" "ses_domain_dkim" {
  count  = var.create_ses ? 1 : 0
  domain = join("", aws_ses_domain_identity.ses_domain.*.domain)
}

resource "aws_route53_record" "amazonses_dkim_record" {
  count   = var.create_ses ? 3 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${element(aws_ses_domain_dkim.ses_domain_dkim[0].dkim_tokens, count.index)}._domainkey.${var.ses_domain_name}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.ses_domain_dkim[0].dkim_tokens, count.index)}.dkim.amazonses.com"]
}

# SPF validation record
resource "aws_route53_record" "spf_mail_from" {
  count   = var.create_ses ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = aws_ses_domain_mail_from.main[0].mail_from_domain #"${var.solution_name}.${aws_ses_domain_identity.ses_domain[0].domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "spf_domain" {
  count   = var.create_ses ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.ses_domain_name #domain_name
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

# Amazon SES sends email using SMTP.
# To access the Amazon SES SMTP interface is to create an IAM user.
# tfsec:ignore:aws-iam-no-user-attached-policies
resource "aws_iam_user" "ses" {
  count = var.create_ses ? 1 : 0
  name  = "${var.name}-iam-user"
}

resource "aws_iam_access_key" "smtp_user" {
  count = var.create_ses ? 1 : 0
  user  = aws_iam_user.ses[0].name
}

resource "aws_iam_user_policy_attachment" "send_mail" {
  count      = var.create_ses ? 1 : 0
  policy_arn = aws_iam_policy.send_mail[0].arn
  user       = aws_iam_user.ses[0].name
}

resource "aws_iam_policy" "send_mail" {
  count       = var.create_ses ? 1 : 0
  name        = "${var.name}-send-mail-policy"
  description = "Allows sending of e-mails via Simple Email Service"
  policy      = data.aws_iam_policy_document.send_mail[0].json
}

data "aws_iam_policy_document" "send_mail" {
  count = var.create_ses ? 1 : 0
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }
}

locals {
  initial_value = jsonencode({
    AWS_SES_SOURCE_ARN = aws_ses_domain_identity.ses_domain[*].arn
    SMTP_ADDRESS       = "email-smtp.${data.aws_region.current_region.name}.amazonaws.com"
    SMTP_AUTH          = "plain"
    SMTP_DOMAIN        = var.ses_domain_name
    SMTP_PASSWORD      = aws_iam_access_key.smtp_user[*].ses_smtp_password_v4
    SMTP_PORT          = 2587
    SMTP_REGION        = data.aws_region.current_region.name
    SMTP_SECRET        = aws_iam_access_key.smtp_user[*].secret
    SMTP_USERNAME      = aws_iam_access_key.smtp_user[*].id
  })
}

# Stored secretes in AWS SSM parameter store
resource "aws_ssm_parameter" "secret" {
  count       = var.create_ses ? 1 : 0
  name        = "/terra3/ses/smtp/secret"
  description = "The parameter description"
  type        = "SecureString"
  value       = local.initial_value
}
