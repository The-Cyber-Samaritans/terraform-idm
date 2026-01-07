# ECR Repository for Keycloak/IDM Docker images
resource "aws_ecr_repository" "keycloak" {
  count = var.create_ecr_repository ? 1 : 0

  name                 = local.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.ecr_repository_name
    }
  )
}

# ECR Repository Policy - Allow EKS nodes to pull images
resource "aws_ecr_repository_policy" "keycloak" {
  count = var.create_ecr_repository ? 1 : 0

  repository = aws_ecr_repository.keycloak[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPull"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}
