output "db_url" {
  value = aws_db_instance.db.address
}

output "db_secrets_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "db_secrets_version_arn" {
  value = aws_secretsmanager_secret_version.db_credentials_version.arn
}

output "db_credentials" {
  value = local.secret_string
}

output "db_instance_name" {
  value = aws_db_instance.db.identifier
}

output "db_instance_arn" {
  value = aws_db_instance.db.arn
}
