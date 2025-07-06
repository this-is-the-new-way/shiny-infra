# ECR Repository for the application - Only create during base infrastructure deployment
resource "aws_ecr_repository" "app" {
  count                = var.deploy_application ? 0 : 1
  name                 = "${var.project_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true  # Allow deletion even if repository contains images

  image_scanning_configuration {
    scan_on_push = false  # Disabled for free tier
  }

  tags = local.common_tags
}

# ECR Lifecycle Policy to manage image retention
resource "aws_ecr_lifecycle_policy" "app" {
  count      = var.deploy_application ? 0 : 1
  repository = aws_ecr_repository.app[0].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Output ECR repository URL for GitHub Actions
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = var.deploy_application ? null : aws_ecr_repository.app[0].repository_url
}
