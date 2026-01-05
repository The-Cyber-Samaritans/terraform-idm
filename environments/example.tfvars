# Example Environment Configuration Template for Keycloak
# Copy this file to dev.tfvars, staging.tfvars, or prod.tfvars

environment = "dev"
app_name    = "intelfoundry"
aws_region  = "us-east-1"

# EKS Configuration
eks_cluster_name = "dev-intelfoundry"
namespace        = "intelfoundry"
create_namespace = false

# VPC/Network Configuration
vpc_id             = "vpc-xxxxxxxxx"
private_subnet_ids = [
  "subnet-xxxxxxxxx",
  "subnet-xxxxxxxxx"
]

# ECR Configuration
create_ecr_repository = true
image_tag             = "latest"

# Deployment Configuration
replicas       = 2
container_port = 8080
cpu_request    = "500m"
cpu_limit      = "2000m"
memory_request = "512Mi"
memory_limit   = "2Gi"

# Ingress Configuration
create_ingress    = true
ingress_class     = "alb"
domain_name       = "auth.dev.intelfoundry.net"
alb_scheme        = "internet-facing"
alb_target_type   = "ip"
health_check_path = "/health/ready"

# DNS Configuration
create_dns_records = true
hosted_zone_name   = "intelfoundry.net"
use_private_zone   = false

# Database Configuration
use_existing_rds              = true
rds_instance_identifier       = "dev-intelfndry-db"
db_name                       = "keycloak"
db_username                   = "keycloak"
db_password_secret_name       = "dev/intelfoundry/keycloak-db-password"

# Keycloak Configuration
keycloak_admin_username             = "admin"
keycloak_admin_password_secret_name = "dev/intelfoundry/keycloak-admin-password"
keycloak_realm                      = "intelfoundry"
keycloak_features                   = "token-exchange,admin-fine-grained-authz"

# Autoscaling (disabled for dev)
enable_autoscaling = false

# Additional Tags
additional_tags = {
  Team = "Platform"
}
