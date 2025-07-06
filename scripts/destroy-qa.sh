#!/bin/bash

# Destroy QA Environment - Complete cleanup
# This script destroys the QA environment resources

set -e

echo "🗑️ Starting QA Environment Destruction"
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Check AWS credentials
check_aws_credentials() {
    print_status "Checking AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")
    
    print_success "AWS credentials configured for account: $AWS_ACCOUNT_ID in region: $AWS_REGION"
}

# Destroy QA application
destroy_qa_application() {
    print_status "Destroying QA application..."
    
    print_status "Planning QA application destruction..."
    if terraform plan -var-file="qa_application.tfvars" -destroy -out=qa-app-destroy-plan; then
        print_status "Destroying QA application..."
        terraform apply -auto-approve qa-app-destroy-plan
        print_success "QA application destroyed successfully!"
    else
        print_warning "QA application destroy plan failed or no resources to destroy"
    fi
}

# Destroy QA infrastructure
destroy_qa_infrastructure() {
    print_status "Destroying QA infrastructure..."
    
    print_status "Planning QA infrastructure destruction..."
    if terraform plan -var-file="qa.tfvars" -destroy -out=qa-destroy-plan; then
        print_status "Destroying QA infrastructure..."
        terraform apply -auto-approve qa-destroy-plan
        print_success "QA infrastructure destroyed successfully!"
    else
        print_warning "QA infrastructure destroy plan failed or no resources to destroy"
    fi
}

# Clean up Terraform state and plans
cleanup_terraform_files() {
    print_status "Cleaning up Terraform files..."
    
    # Remove QA-specific plan files
    rm -f qa-tfplan qa-app-tfplan qa-destroy-plan qa-app-destroy-plan
    
    print_success "Terraform files cleaned up"
}

# Main destruction flow
main() {
    print_status "Starting QA environment destruction..."
    
    # Confirmation prompt
    echo ""
    print_warning "⚠️  WARNING: This will destroy ALL QA environment resources!"
    print_warning "⚠️  This action cannot be undone!"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Destruction cancelled by user."
        exit 0
    fi
    
    check_prerequisites
    check_aws_credentials
    
    # Initialize Terraform
    print_status "Initializing Terraform for QA environment..."
    terraform init -backend-config="backend-qa.hcl"
    
    # Destroy QA application first
    destroy_qa_application
    
    # Destroy QA infrastructure
    destroy_qa_infrastructure
    
    # Cleanup
    cleanup_terraform_files
    
    echo ""
    print_success "QA environment destruction completed successfully!"
    echo ""
    print_status "All QA resources have been destroyed:"
    print_status "• QA ECS Cluster: base-infra-qa"
    print_status "• QA Application Load Balancer"
    print_status "• QA Target Groups"
    print_status "• QA Security Groups"
    print_status "• QA VPC and Subnets"
    echo ""
    print_status "Note: ECR repository is shared with dev environment and was not destroyed"
    echo ""
}

# Run main function
main "$@"
