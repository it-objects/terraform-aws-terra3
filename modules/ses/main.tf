# ---------------------------------------------------------------------------------------------------------------------
# Amazon Simple Email Service
# ---------------------------------------------------------------------------------------------------------------------
# to use an existingRoute 53 domain.
data "aws_route53_zone" "main" {
  name         = var.hosted_zone_domain
  private_zone = false
}

# to get an access to start sending emails.
resource "aws_ses_domain_identity" "ses_domain" {
  count  = var.create_ses ? 1 : 0
  domain = var.domain
}

resource "aws_ses_domain_mail_from" "main" {
  count            = var.create_ses ? 1 : 0
  domain           = aws_ses_domain_identity.ses_domain[0].domain
  mail_from_domain = "test.${aws_ses_domain_identity.ses_domain[0].domain}"
}

#DKIM and SPF, which is a way to authenticate your emails
resource "aws_route53_record" "amazonses_verification_record" {
  count   = var.create_ses ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = "600"
  records = [join("", aws_ses_domain_identity.ses_domain.*.verification_token)]
}

resource "aws_ses_domain_identity_verification" "amazonses_verification" {
  count  = var.create_ses ? 1 : 0
  domain = aws_ses_domain_identity.ses_domain[0].id
}

resource "aws_ses_domain_dkim" "ses_domain_dkim" {
  count  = var.create_ses ? 1 : 0
  domain = join("", aws_ses_domain_identity.ses_domain.*.domain)
}

resource "aws_route53_record" "amazonses_dkim_record" {
  count   = var.create_ses ? 3 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${element(aws_ses_domain_dkim.ses_domain_dkim[0].dkim_tokens, count.index)}._domainkey.${var.domain}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.ses_domain_dkim[0].dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_route53_record" "spf_mail_from" {
  count   = var.create_ses ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = aws_ses_domain_mail_from.main[0].mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "spf_domain" {
  count   = var.create_ses ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

# amazon SES sends email using SMTP.
# to access the Amazon SES SMTP interface is to create an IAM user.
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
    resources = [aws_ses_domain_identity.ses_domain[0].arn]
  }
}

# storing the smtp credentials as a secret.
resource "aws_secretsmanager_secret" "this" {
  count       = var.create_ses ? 1 : 0
  description = "Secret for ${var.name}"
  name        = "${var.name}-secret"
}

resource "aws_secretsmanager_secret_version" "initial" {
  count         = var.create_ses ? 1 : 0
  secret_id     = aws_secretsmanager_secret.this[0].id
  secret_string = local.initial_value

  lifecycle {
    ignore_changes = [secret_string]
  }
}

locals {
  initial_value = jsonencode({
    AWS_SES_SOURCE_ARN = aws_ses_domain_identity.ses_domain[*].arn
    SMTP_ADDRESS       = "email-smtp.${var.aws_region}.amazonaws.com"
    SMTP_AUTH          = "plain"
    SMTP_DOMAIN        = var.domain
    SMTP_PASSWORD      = aws_iam_access_key.smtp_user[*].ses_smtp_password_v4
    SMTP_PORT          = 2587
    SMTP_REGION        = var.aws_region
    SMTP_SECRET        = aws_iam_access_key.smtp_user[*].secret
    SMTP_USERNAME      = aws_iam_access_key.smtp_user[*].id
  })
}

resource "aws_ssm_parameter" "secret" {
  count       = var.create_ses ? 1 : 0
  name        = "/terra3/ses/smtp/secret"
  description = "The parameter description"
  type        = "SecureString"
  value       = local.initial_value
}
