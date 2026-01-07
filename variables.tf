# Environment and Application Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "intelfoundry"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# EKS Configuration
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Keycloak"
  type        = string
  default     = "intelfoundry"
}

variable "create_namespace" {
  description = "Whether to create the Kubernetes namespace"
  type        = bool
  default     = false
}

# Network Configuration
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

# ECR Configuration
variable "create_ecr_repository" {
  description = "Whether to create an ECR repository"
  type        = bool
  default     = true
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = ""
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "image_uri" {
  description = "Full image URI (overrides ECR repository)"
  type        = string
  default     = ""
}

# Deployment Configuration
variable "replicas" {
  description = "Number of pod replicas"
  type        = number
  default     = 2
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8080
}

variable "cpu_request" {
  description = "CPU request for the container"
  type        = string
  default     = "500m"
}

variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "2000m"
}

variable "memory_request" {
  description = "Memory request for the container"
  type        = string
  default     = "512Mi"
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "2Gi"
}

# Ingress Configuration
variable "create_ingress" {
  description = "Whether to create an Ingress resource"
  type        = bool
  default     = true
}

variable "ingress_class" {
  description = "Ingress class name"
  type        = string
  default     = "alb"
}

variable "domain_name" {
  description = "Domain name for Keycloak"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of ACM certificate for HTTPS (auto-detected if empty)"
  type        = string
  default     = ""
}

variable "alb_scheme" {
  description = "ALB scheme (internet-facing or internal)"
  type        = string
  default     = "internet-facing"
  validation {
    condition     = contains(["internet-facing", "internal"], var.alb_scheme)
    error_message = "ALB scheme must be internet-facing or internal."
  }
}

variable "alb_target_type" {
  description = "ALB target type"
  type        = string
  default     = "ip"
}

variable "alb_group_name" {
  description = "ALB group name for sharing ALB across multiple ingresses"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "Health check path for the ALB"
  type        = string
  default     = "/health/ready"
}

# DNS Configuration
variable "create_dns_records" {
  description = "Whether to create Route53 DNS records"
  type        = bool
  default     = true
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name"
  type        = string
  default     = "intelfoundry.net"
}

variable "use_private_zone" {
  description = "Whether the hosted zone is private"
  type        = bool
  default     = false
}

# Database Configuration
variable "use_existing_rds" {
  description = "Whether to use an existing RDS instance"
  type        = bool
  default     = true
}

variable "rds_instance_identifier" {
  description = "RDS instance identifier for Keycloak database"
  type        = string
  default     = ""
}

variable "db_host" {
  description = "Database host (if not using existing RDS)"
  type        = string
  default     = ""
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name for Keycloak"
  type        = string
  default     = "keycloak"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "keycloak"
  sensitive   = true
}

variable "db_password_secret_name" {
  description = "AWS Secrets Manager secret name for database password"
  type        = string
  default     = ""
}

# Keycloak Configuration
variable "keycloak_admin_username" {
  description = "Keycloak admin username"
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password_secret_name" {
  description = "AWS Secrets Manager secret name for Keycloak admin password"
  type        = string
  default     = ""
}

variable "keycloak_realm" {
  description = "Default Keycloak realm to create"
  type        = string
  default     = "intelfoundry"
}

variable "keycloak_features" {
  description = "Keycloak features to enable"
  type        = string
  default     = "token-exchange,admin-fine-grained-authz"
}

# Environment Variables
variable "env_vars" {
  description = "Additional environment variables for the container"
  type        = map(string)
  default     = {}
}

# GitHub Actions OIDC Configuration
variable "create_github_oidc_provider" {
  description = "Whether to create the GitHub OIDC provider"
  type        = bool
  default     = false
}

variable "create_github_actions_role" {
  description = "Whether to create the GitHub Actions IAM role"
  type        = bool
  default     = true
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "The-Cyber-Samaritans"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "idm-service"
}

# Tags
variable "additional_tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
