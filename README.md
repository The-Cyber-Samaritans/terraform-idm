# Terraform IDM (Keycloak) Infrastructure

Terraform configuration for deploying Keycloak to AWS EKS.

**Terraform Repository:** https://github.com/The-Cyber-Samaritans/terraform-idm
**Application Repository:** https://github.com/The-Cyber-Samaritans/idm-service

## Architecture

- **EKS**: Kubernetes deployment with service and ingress
- **ECR**: Container image registry
- **ALB**: Application Load Balancer via AWS Load Balancer Controller
- **RDS**: PostgreSQL database for Keycloak
- **ACM Certificate**: SSL/TLS certificate for HTTPS
- **Route53**: DNS records pointing to ALB
- **Secrets Manager**: Database and admin credentials

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- kubectl configured for EKS cluster
- EKS cluster with AWS Load Balancer Controller installed
- RDS PostgreSQL instance for Keycloak database
- AWS Secrets Manager secrets for credentials

## Directory Structure

```
terraform-idm/
├── README.md
├── backend.tf          # S3 backend configuration
├── providers.tf        # AWS, Kubernetes, Helm providers
├── versions.tf         # Terraform and provider versions
├── variables.tf        # Input variables
├── locals.tf           # Local values
├── data.tf             # Data sources (EKS, VPC, RDS, etc.)
├── ecr.tf              # ECR repository
├── secrets.tf          # Secrets Manager data sources
├── kubernetes.tf       # Kubernetes Deployment, Service, Ingress
├── dns.tf              # Route53 DNS records
├── github-oidc.tf      # GitHub Actions OIDC role
├── outputs.tf          # Output values
├── deploy.sh           # Infrastructure deployment script
└── environments/
    ├── example.tfvars  # Template with all variables
    ├── dev.tfvars      # Development environment
    ├── staging.tfvars  # Staging environment
    └── prod.tfvars     # Production environment
```

## Quick Start

1. Copy the template:
   ```bash
   cp environments/example.tfvars environments/dev.tfvars
   ```

2. Fill in required values (VPC ID, subnet IDs, RDS details, etc.)

3. Create Secrets Manager secrets:
   ```bash
   aws secretsmanager create-secret --name dev/intelfoundry/keycloak-db-password --secret-string "your-db-password"
   aws secretsmanager create-secret --name dev/intelfoundry/keycloak-admin-password --secret-string "your-admin-password"
   ```

4. Deploy:
   ```bash
   ./deploy.sh dev apply
   ```

## Usage

### Deploy Infrastructure

```bash
./deploy.sh dev plan    # Plan changes
./deploy.sh dev apply   # Deploy
./deploy.sh dev output  # View outputs
```

### Build and Push Docker Image

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ecr-url>

# Build and push
docker build -t intelfoundry-idm:latest .
docker tag intelfoundry-idm:latest <ecr-url>:latest
docker push <ecr-url>:latest
```

### Restart Deployment

```bash
kubectl rollout restart deployment/intelfoundry-dev-keycloak -n intelfoundry
kubectl rollout status deployment/intelfoundry-dev-keycloak -n intelfoundry
```

## Environment Configuration

| Environment | Domain | Replicas | Autoscaling |
|-------------|--------|----------|-------------|
| dev | auth.dev.intelfoundry.net | 1 | No |
| staging | auth.staging.intelfoundry.net | 2-4 | Yes |
| prod | auth.intelfoundry.net | 3-6 | Yes |

## Outputs

| Output | Description |
|--------|-------------|
| `ecr_repository_url` | ECR repository URL |
| `keycloak_url` | Keycloak URL |
| `keycloak_admin_console` | Admin console URL |
| `github_actions_role_arn` | GitHub Actions IAM role ARN |

## Debugging

```bash
# Get pods
kubectl get pods -n intelfoundry -l app.kubernetes.io/name=keycloak

# View logs
kubectl logs -n intelfoundry -l app.kubernetes.io/name=keycloak -f

# Describe pod
kubectl describe pod -n intelfoundry -l app.kubernetes.io/name=keycloak

# Get ingress
kubectl get ingress -n intelfoundry
kubectl describe ingress/intelfoundry-dev-keycloak -n intelfoundry
```

## Notes

- Keycloak requires sticky sessions for clustering (configured in ingress annotations)
- Database credentials are stored in AWS Secrets Manager
- Initial realm import happens on first deployment via container init
- Health checks use `/health/ready` endpoint
