# AWS Secrets Manager for Keycloak credentials

# Database password secret
data "aws_secretsmanager_secret_version" "db_password" {
  count     = var.db_password_secret_name != "" ? 1 : 0
  secret_id = var.db_password_secret_name
}

locals {
  # Parse the JSON secret string to get the password field
  db_password = var.db_password_secret_name != "" ? jsondecode(data.aws_secretsmanager_secret_version.db_password[0].secret_string)["password"] : ""
}

# Admin password secret
data "aws_secretsmanager_secret_version" "admin_password" {
  count     = var.keycloak_admin_password_secret_name != "" ? 1 : 0
  secret_id = var.keycloak_admin_password_secret_name
}
