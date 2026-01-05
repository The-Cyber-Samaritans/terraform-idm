# Production Environment Configuration for Keycloak

environment = "prod"
app_name    = "intelfoundry"
aws_region  = "us-east-1"

# EKS Configuration
eks_cluster_name = "prod-intelfoundry"
namespace        = "intelfoundry"
create_namespace = false

# VPC/Network Configuration
vpc_id             = "vpc-xxxxxxxxx"
private_subnet_ids = [
  "subnet-xxxxxxxxx",
  "subnet-xxxxxxxxx",
  "subnet-xxxxxxxxx"
]

# ECR Configuration
create_ecr_repository = false
image_tag             = "prod"

# Deployment Configuration
replicas       = 3
container_port = 8080
cpu_request    = "1000m"
cpu_limit      = "2000m"
memory_request = "1Gi"
memory_limit   = "2Gi"

# Ingress Configuration
create_ingress    = true
ingress_class     = "alb"
domain_name       = "auth.intelfoundry.net"
alb_scheme        = "internet-facing"
alb_target_type   = "ip"

# DNS Configuration
create_dns_records = true
hosted_zone_name   = "intelfoundry.net"

# Database Configuration
use_existing_rds              = true
rds_instance_identifier       = "prod-intelfndry-db"
db_name                       = "keycloak"
db_username                   = "keycloak"
db_password_secret_name       = "prod/intelfoundry/keycloak-db-password"

# Keycloak Configuration
keycloak_admin_username             = "admin"
keycloak_admin_password_secret_name = "prod/intelfoundry/keycloak-admin-password"
keycloak_realm                      = "intelfoundry"

# Autoscaling
enable_autoscaling = true
min_replicas       = 3
max_replicas       = 6

# Additional Tags
additional_tags = {
  Team        = "Platform"
  CostCenter  = "Production"
  Criticality = "High"
}
