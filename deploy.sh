#!/bin/bash

# Keycloak EKS Infrastructure Deployment Script
# Usage: ./deploy.sh [ENVIRONMENT] [ACTION]

set -e

# Defaults
ENVIRONMENT=${1:-dev}
ACTION=${2:-plan}

# Show help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Keycloak EKS Infrastructure Deployment"
    echo "Usage: $0 [ENVIRONMENT] [ACTION]"
    echo ""
    echo "Examples:"
    echo "  $0 dev plan     # Plan dev environment"
    echo "  $0 dev apply    # Deploy dev environment"
    echo "  $0 prod plan    # Plan production environment"
    echo ""
    echo "Environments: dev, staging, prod"
    echo "Actions: plan, apply, destroy, validate, output"
    exit 0
fi

# Validate environment
case $ENVIRONMENT in
    dev|staging|prod) ;;
    *)
        echo "Error: Invalid environment: $ENVIRONMENT"
        echo "Valid environments: dev, staging, prod"
        exit 1
        ;;
esac

# Validate action
case $ACTION in
    plan|apply|destroy|validate|output) ;;
    *)
        echo "Error: Invalid action: $ACTION"
        echo "Valid actions: plan, apply, destroy, validate, output"
        exit 1
        ;;
esac

echo "================================================"
echo "Keycloak EKS Deployment"
echo "================================================"
echo "Environment: $ENVIRONMENT"
echo "Action: $ACTION"
echo ""

# Set variables
export TF_VAR_environment=$ENVIRONMENT
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}

# Check dependencies
if ! command -v terraform &> /dev/null; then
    echo "Error: terraform not found"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "Error: aws cli not found"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "Warning: kubectl not found - some features may not work"
fi

# Update kubeconfig for EKS cluster (if kubectl available)
EKS_CLUSTER_NAME="${ENVIRONMENT}-intelfoundry"
if command -v kubectl &> /dev/null; then
    echo "Updating kubeconfig for EKS cluster: $EKS_CLUSTER_NAME"
    aws eks update-kubeconfig --name "$EKS_CLUSTER_NAME" --region "$AWS_DEFAULT_REGION" 2>/dev/null || true
fi

# Initialize Terraform
echo ""
echo "Initializing Terraform..."
terraform init \
    -backend-config="bucket=intelfoundry-terraform-state-us-east-1" \
    -backend-config="key=us-east-1/intelfoundry-idm/${ENVIRONMENT}/terraform.tfstate" \
    -backend-config="region=${AWS_DEFAULT_REGION}" \
    -backend-config="encrypt=true" \
    -backend-config="dynamodb_table=terraform-state-lock" \
    -reconfigure

# Execute action
case $ACTION in
    validate)
        terraform validate
        ;;
    plan)
        terraform validate
        terraform plan \
            -var-file="environments/${ENVIRONMENT}.tfvars" \
            -out="tfplan-${ENVIRONMENT}.out"
        ;;
    apply)
        echo "==============================================="
        echo "STEP 1: VALIDATION & PLAN"
        echo "==============================================="
        terraform validate

        echo ""
        echo "Generating deployment plan..."
        terraform plan \
            -var-file="environments/${ENVIRONMENT}.tfvars" \
            -out="tfplan-${ENVIRONMENT}.out"

        echo ""
        echo "==============================================="
        echo "STEP 2: DEPLOYMENT CONFIRMATION"
        echo "==============================================="
        echo "Environment: $ENVIRONMENT"
        echo "EKS Cluster: $EKS_CLUSTER_NAME"
        echo "Region: ${AWS_DEFAULT_REGION}"
        echo ""

        if [ "$ENVIRONMENT" == "prod" ]; then
            echo "WARNING: This will deploy to PRODUCTION!"
        fi

        echo "Please review the plan above before proceeding."
        echo "This will create/update Keycloak resources."
        echo ""
        read -p "Do you want to apply these changes? (yes/no): " confirm

        case $confirm in
            yes|YES|y|Y)
                echo "Applying planned changes..."
                ;;
            *)
                echo "Deployment cancelled by user"
                exit 0
                ;;
        esac

        terraform apply "tfplan-${ENVIRONMENT}.out"

        echo ""
        echo "==============================================="
        echo "DEPLOYMENT COMPLETE"
        echo "==============================================="
        terraform output

        echo ""
        echo "Useful commands:"
        echo "  kubectl get pods -n intelfoundry -l app.kubernetes.io/name=keycloak"
        echo "  kubectl logs -n intelfoundry -l app.kubernetes.io/name=keycloak -f"
        ;;
    destroy)
        if [ "$ENVIRONMENT" == "prod" ]; then
            echo "WARNING: This will destroy PRODUCTION Keycloak!"
            read -p "Type 'yes' to confirm: " confirm
            if [ "$confirm" != "yes" ]; then
                echo "Cancelled"
                exit 0
            fi
        fi
        terraform destroy \
            -var-file="environments/${ENVIRONMENT}.tfvars" \
            -auto-approve
        ;;
    output)
        terraform output
        ;;
esac

echo ""
echo "Complete!"
