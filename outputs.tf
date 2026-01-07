# ECR Outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = var.create_ecr_repository ? aws_ecr_repository.keycloak[0].repository_url : ""
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = var.create_ecr_repository ? aws_ecr_repository.keycloak[0].arn : ""
}

# Kubernetes Deployment Outputs
output "deployment_name" {
  description = "Name of the Kubernetes deployment"
  value       = kubernetes_deployment.keycloak.metadata[0].name
}

output "service_name" {
  description = "Name of the Kubernetes service"
  value       = kubernetes_service.keycloak.metadata[0].name
}

output "namespace" {
  description = "Kubernetes namespace"
  value       = var.namespace
}

# Ingress Outputs
output "ingress_hostname" {
  description = "Hostname of the ALB ingress"
  value       = var.create_ingress ? kubernetes_ingress_v1.keycloak[0].status[0].load_balancer[0].ingress[0].hostname : ""
}

# DNS/URL Outputs
output "keycloak_url" {
  description = "URL of Keycloak"
  value       = "https://${var.domain_name}"
}

output "keycloak_admin_console" {
  description = "URL of Keycloak admin console"
  value       = "https://${var.domain_name}/admin"
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = local.certificate_arn
}

# Deployment Info
output "deployment_info" {
  description = "Information needed for CI/CD deployment"
  value = {
    ecr_repository_url = var.create_ecr_repository ? aws_ecr_repository.keycloak[0].repository_url : var.image_uri
    eks_cluster_name   = var.eks_cluster_name
    namespace          = var.namespace
    deployment_name    = kubernetes_deployment.keycloak.metadata[0].name
    service_name       = kubernetes_service.keycloak.metadata[0].name
    region             = var.aws_region
    keycloak_url       = "https://${var.domain_name}"
  }
}

# Docker Push Command
output "docker_push_commands" {
  description = "Commands to build and push Docker image to ECR"
  value = var.create_ecr_repository ? join("\n", [
    "# Login to ECR",
    "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.keycloak[0].repository_url}",
    "",
    "# Build and tag image",
    "docker build -t ${local.ecr_repository_name}:${var.image_tag} .",
    "docker tag ${local.ecr_repository_name}:${var.image_tag} ${aws_ecr_repository.keycloak[0].repository_url}:${var.image_tag}",
    "",
    "# Push to ECR",
    "docker push ${aws_ecr_repository.keycloak[0].repository_url}:${var.image_tag}"
  ]) : "ECR repository not created"
}

# Kubectl Commands
output "kubectl_commands" {
  description = "Useful kubectl commands"
  value       = <<-EOT
    # Get pods
    kubectl get pods -n ${var.namespace} -l app.kubernetes.io/name=keycloak

    # Get deployment status
    kubectl rollout status deployment/${local.name_prefix}-keycloak -n ${var.namespace}

    # Restart deployment
    kubectl rollout restart deployment/${local.name_prefix}-keycloak -n ${var.namespace}

    # View logs
    kubectl logs -n ${var.namespace} -l app.kubernetes.io/name=keycloak --tail=100 -f
  EOT
}

# GitHub Actions Outputs (commented out - resource not defined)
# output "github_actions_role_arn" {
#   description = "ARN of the GitHub Actions IAM role"
#   value       = var.create_github_actions_role ? aws_iam_role.github_actions[0].arn : ""
# }

# output "github_actions_setup" {
#   description = "GitHub repository secrets to configure"
#   value = var.create_github_actions_role ? join("\n", [
#     "Add these secrets to your GitHub repository (Settings > Secrets and variables > Actions):",
#     "",
#     "AWS_ROLE_ARN: ${aws_iam_role.github_actions[0].arn}"
#   ]) : "GitHub Actions role not created"
# }
