# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Repository  = "base-infrastructure"
      Component   = "networking"
    }
  }
}

# Note: Terraform backend and required_providers are configured in terraform.tf
