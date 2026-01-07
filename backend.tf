# Store Terraform state in S3 with dynamic path based on environment and DB name
# Path format: s3://intelfoundry-terraform-state-us-east-1/us-east-1/{vpc_name}/{env_name}/{service-name}/terraform.tfstate
terraform {
  backend "s3" {
    bucket  = "intelfoundry-terraform-state-us-east-1"
    region  = "us-east-1"
    encrypt = true
    # Note: key is set via -backend-config flag during init
    # Example: terraform init -backend-config="key=us-east-1/eks-nonprod-vpc/dev/idm-service/terraform.tfstate"
  }
}
