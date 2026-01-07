# Local values for environment-specific configuration
locals {
  # Resource naming
  name_prefix = "${var.app_name}-${var.environment}"

  # ECR repository name
  ecr_repository_name = var.ecr_repository_name != "" ? var.ecr_repository_name : "${var.app_name}-idm"

  # Image URI
  image_uri = var.image_uri != "" ? var.image_uri : "${aws_ecr_repository.keycloak[0].repository_url}:${var.image_tag}"

  # Certificate ARN (from variable or data source)
  certificate_arn = var.certificate_arn != "" ? var.certificate_arn : (
    length(data.aws_acm_certificate.alb) > 0 ? data.aws_acm_certificate.alb[0].arn : ""
  )

  # Subnet IDs as comma-separated string for ALB annotations
  subnet_ids_string = join(",", var.private_subnet_ids)

  # Database host
  db_host = var.use_existing_rds && length(data.aws_db_instance.keycloak) > 0 ? data.aws_db_instance.keycloak[0].address : var.db_host

  # Database URL
  db_url = "jdbc:postgresql://${local.db_host}:${var.db_port}/${var.db_name}"

  # Read .env template file and prepare for substitution
  env_template = file("${path.module}/.env.tmpl")
  
  # .env file content with actual values (passwords will be injected at runtime)
  env_file_content = templatefile("${path.module}/.env.tmpl", {
    env                    = var.environment
    keycloak_admin         = var.keycloak_admin_username
    keycloak_admin_password = "<from-secret>"  # Will be replaced by init container
    keycloak_port          = var.container_port
    postgres_host          = local.db_host
    postgres_port          = var.db_port
    postgres_db            = var.db_name
    postgres_user          = var.db_username
    postgres_password      = "<from-secret>"  # Will be replaced by init container
  })

  # Environment variables for container (Keycloak standard env vars)
  container_env_vars = merge(
    {
      KC_DB                = "postgres"
      KC_DB_URL            = local.db_url
      KC_DB_USERNAME       = var.db_username
      KC_HOSTNAME          = var.domain_name
      KC_HOSTNAME_STRICT   = "false"
      KC_HTTP_ENABLED      = "true"
      KC_HEALTH_ENABLED    = "true"
      KC_METRICS_ENABLED   = "true"
      KC_PROXY             = "edge"
      KC_FEATURES          = var.keycloak_features
      KEYCLOAK_ADMIN       = var.keycloak_admin_username
    },
    var.env_vars
  )

  # Common labels
  common_labels = {
    "app.kubernetes.io/name"       = "keycloak"
    "app.kubernetes.io/instance"   = var.environment
    "app.kubernetes.io/component"  = "idm"
    "app.kubernetes.io/part-of"    = var.app_name
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Common tags
  common_tags = merge(
    {
      Environment = var.environment
      Application = var.app_name
      Component   = "idm"
      ManagedBy   = "terraform"
    },
    var.additional_tags
  )
}
