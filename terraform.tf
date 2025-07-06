# Terraform settings
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2"
    }
  }

  # Configure S3 backend for shared state
  # Note: The key will be overridden by -backend-config during initialization
  backend "s3" {
    bucket         = "terrastate-file"
    key            = "shiny-infra/dev/terraform.tfstate"  # Default to dev, will be overridden
    region         = "us-east-1"
  }
  #   encrypt        = true
  # }
}
