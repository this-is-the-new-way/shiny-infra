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
  backend "s3" {
    bucket         = "terrastate-file"
    key            = "shiny-infra/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
  #   encrypt        = true
  # }
}
