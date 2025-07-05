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
  # Uncomment and configure for production use
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "base-infrastructure/terraform.tfstate"
  #   region = "us-west-2"
  #   
  #   # Enable state locking with DynamoDB
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}
