# AWS specific
resource "aws_s3_account_public_access_block" "enable_s3_account_level_block" {
  count = var.enable_account_wide_block_public_s3_access ? 1 : 0

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_ebs_encryption_by_default" "enable_ebs_account_level_encryption" {
  count = var.enable_account_wide_ebs_encryption ? 1 : 0

  enabled = true
}

resource "aws_ebs_snapshot_block_public_access" "block_public_access" {
  count = var.enable_account_wide_ebs_snapshot_block_public_access ? 1 : 0

  state = "block-all-sharing"
}

resource "aws_ssm_service_setting" "ssm_document_block_public_sharing" {
  count = var.enable_account_wide_ssm_document_block_public_sharing ? 1 : 0

  setting_id    = "arn:aws:ssm:${data.aws_region.current_region.name}:${data.aws_caller_identity.current.account_id}:servicesetting/ssm/documents/console/public-sharing-permission"
  setting_value = "Disable"
}
