# Staging Environment Configuration for Keycloak

environment = "staging"
app_name    = "intelfoundry"
aws_region  = "us-east-1"

# EKS Configuration
eks_cluster_name = "staging-intelfoundry"
namespace        = "intelfoundry"
create_namespace = false

# VPC/Network Configuration
vpc_id             = "vpc-xxxxxxxxx"
private_subnet_ids = [
  "subnet-xxxxxxxxx",
  "subnet-xxxxxxxxx"
]

# ECR Configuration
create_ecr_repository = false
image_tag             = "staging"

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
domain_name       = "auth.staging.intelfoundry.net"
alb_scheme        = "internet-facing"
alb_target_type   = "ip"

# DNS Configuration
create_dns_records = true
hosted_zone_name   = "intelfoundry.net"

# Database Configuration
use_existing_rds              = true
rds_instance_identifier       = "staging-intelfndry-db"
db_name                       = "keycloak"
db_username                   = "keycloak"
db_password_secret_name       = "staging/intelfoundry/keycloak-db-password"

# Keycloak Configuration
keycloak_admin_username             = "admin"
keycloak_admin_password_secret_name = "staging/intelfoundry/keycloak-admin-password"
keycloak_realm                      = "intelfoundry"

# Autoscaling
enable_autoscaling = true
min_replicas       = 2
max_replicas       = 4

# Additional Tags
additional_tags = {
  Team = "Platform"
}
