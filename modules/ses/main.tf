data "aws_route53_zone" "main" {
  name         = var.hosted_zone_domain
  private_zone = false
}

resource "aws_ses_domain_identity" "ses_domain" {
  domain = var.domain
}

resource "aws_route53_record" "amazonses_verification_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = "600"
  records = [join("", aws_ses_domain_identity.ses_domain.*.verification_token)]
}

resource "aws_ses_domain_identity_verification" "amazonses_verification" {
  domain = aws_ses_domain_identity.ses_domain.id
}

resource "aws_ses_domain_dkim" "ses_domain_dkim" {
  domain = join("", aws_ses_domain_identity.ses_domain.*.domain)
}

resource "aws_route53_record" "amazonses_dkim_record" {
  count   = 3
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${element(aws_ses_domain_dkim.ses_domain_dkim.dkim_tokens, count.index)}._domainkey.${var.domain}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.ses_domain_dkim.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_ses_domain_mail_from" "main" {
  domain           = aws_ses_domain_identity.ses_domain.domain
  mail_from_domain = "test.${aws_ses_domain_identity.ses_domain.domain}"
}

resource "aws_route53_record" "spf_mail_from" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = aws_ses_domain_mail_from.main.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "spf_domain" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_iam_user" "ses" {
  name = "${var.name}-iam-user"
}

resource "aws_iam_access_key" "smtp_user" {
  user = aws_iam_user.ses.name
}

resource "aws_iam_user_policy_attachment" "send_mail" {
  policy_arn = aws_iam_policy.send_mail.arn
  user       = aws_iam_user.ses.name
}

resource "aws_iam_policy" "send_mail" {
  name        = "${var.name}-send-mail-policy"
  description = "Allows sending of e-mails via Simple Email Service"
  policy      = data.aws_iam_policy_document.send_mail.json
}

data "aws_iam_policy_document" "send_mail" {
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = [aws_ses_domain_identity.ses_domain.arn]
  }
}

resource "aws_secretsmanager_secret" "this" {
  description = "Secret for ${var.name}"
  name        = "${var.name}-secret"
}

resource "aws_secretsmanager_secret_version" "initial" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = local.initial_value

  lifecycle {
    ignore_changes = [secret_string]
  }
}

locals {
  initial_value = jsonencode({
    AWS_SES_SOURCE_ARN = aws_ses_domain_identity.ses_domain.arn
    SMTP_ADDRESS       = "email-smtp.${var.aws_region}.amazonaws.com"
    SMTP_AUTH          = "plain"
    SMTP_DOMAIN        = var.domain
    SMTP_PASSWORD      = aws_iam_access_key.smtp_user.ses_smtp_password_v4
    SMTP_PORT          = 2587
    SMTP_REGION        = var.aws_region
    SMTP_SECRET        = aws_iam_access_key.smtp_user.secret
    SMTP_USERNAME      = aws_iam_access_key.smtp_user.id
  })
}

resource "aws_ssm_parameter" "secret" {
  name        = "/terra3/ses/smtp/secret"
  description = "The parameter description"
  type        = "SecureString"
  value       = local.initial_value
}
