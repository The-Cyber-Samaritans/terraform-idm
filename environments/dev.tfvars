# Development Environment Configuration for Keycloak

environment = "dev"
app_name    = "intelfoundry"
aws_region  = "us-east-1"

# EKS Configuration
eks_cluster_name = "nonprod-cluster-132"
namespace        = "ns-dev"
create_namespace = false

# VPC/Network Configuration
vpc_id             = "vpc-054b2ef6355880765"
private_subnet_ids = [
  "subnet-02495bf1e9b8728fa",
  "subnet-02c53e405128e509e",
  "subnet-0bcb8103a9375a6ec"
]

# ECR Configuration
create_ecr_repository = false
ecr_repository_name   = "intelfoundry/idm-service"
image_tag             = "v1.0.0"
image_uri             = "553022076960.dkr.ecr.us-east-1.amazonaws.com/intelfoundry/idm-service:v1.0.0"

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
domain_name       = "auth.dev.cloud.onceamerican.com"
certificate_arn   = "arn:aws:acm:us-east-1:553022076960:certificate/45908302-6092-4eda-b3bd-c15054b7188b"
alb_scheme        = "internal"
alb_target_type   = "ip"
alb_group_name    = "multi-env-alb"
health_check_path = "/health/ready"

# DNS Configuration
create_dns_records = false
hosted_zone_name   = "cloud.onceamerican.com"
use_private_zone   = true

# Database Configuration
use_existing_rds              = true
rds_instance_identifier       = "dev-idm-db"
db_name                       = "idm_dev"
db_username                   = "intelfndry_admin"
db_password_secret_name       = "/dev/idm/rds/idm_dev/master"

# Keycloak Configuration
keycloak_admin_username             = "admin"
keycloak_admin_password_secret_name = "/dev/idm/keycloak/admin-password"
keycloak_realm                      = "intelfoundry"

# GitHub Actions (disabled for now)
create_github_actions_role = false

# Additional Tags
additional_tags = {
  Team    = "Platform"
  Service = "IDM"
}
