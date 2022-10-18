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
