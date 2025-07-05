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

# Configure Terraform Backend
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "terrastate-file"
    key            = "shiny-infra/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
