# EKS Cluster Data Sources
data "aws_eks_cluster" "target" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "target" {
  name = var.eks_cluster_name
}

# VPC Data Source
data "aws_vpc" "target" {
  id = var.vpc_id
}

# Subnets Data Source
data "aws_subnet" "private" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

# Route53 Hosted Zone (for Ingress DNS)
data "aws_route53_zone" "target" {
  count        = var.create_dns_records ? 1 : 0
  name         = var.hosted_zone_name
  private_zone = var.use_private_zone
}

# Current AWS caller identity
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

# ACM Certificate (for ALB Ingress HTTPS)
data "aws_acm_certificate" "alb" {
  count       = var.certificate_arn == "" ? 1 : 0
  domain      = var.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

# RDS Instance (for Keycloak database)
data "aws_db_instance" "keycloak" {
  count                  = var.use_existing_rds ? 1 : 0
  db_instance_identifier = var.rds_instance_identifier
}
