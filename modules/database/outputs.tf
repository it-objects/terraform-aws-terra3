output "db_url" {
  value = aws_db_instance.mysql_db.address
}

output "db_secrets_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "db_secrets_version_arn" {
  value = aws_secretsmanager_secret_version.db_credentials_version.arn
}
