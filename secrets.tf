# AWS Secrets Manager for Keycloak credentials

# Database password secret
data "aws_secretsmanager_secret_version" "db_password" {
  count     = var.db_password_secret_name != "" ? 1 : 0
  secret_id = var.db_password_secret_name
}

# Admin password secret
data "aws_secretsmanager_secret_version" "admin_password" {
  count     = var.keycloak_admin_password_secret_name != "" ? 1 : 0
  secret_id = var.keycloak_admin_password_secret_name
}
