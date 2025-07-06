#!/bin/bash

# Destroy Production Environment - Complete cleanup
# This script destroys the production environment resources

set -e

echo "🗑️ Starting Production Environment Destruction"
echo "==============================================="

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

# Production destruction confirmation
confirm_production_destruction() {
    echo ""
    print_error "🚨 CRITICAL WARNING - PRODUCTION DESTRUCTION! 🚨"
    print_error "🚨 You are about to DESTROY the PRODUCTION environment!"
    print_error "🚨 This will permanently delete:"
    print_error "    • Production ECS cluster and all running services"
    print_error "    • Production Application Load Balancer"
    print_error "    • Production VPC and all networking resources"
    print_error "    • Production security groups and configurations"
    print_error "    • All production data and configurations"
    print_error "🚨 THIS ACTION CANNOT BE UNDONE!"
    echo ""
    print_warning "Type 'DESTROY PRODUCTION' exactly (case-sensitive) to confirm:"
    read -r CONFIRM_DESTROY
    echo ""
    
    if [ "$CONFIRM_DESTROY" != "DESTROY PRODUCTION" ]; then
        print_status "Production destruction cancelled - confirmation text did not match."
        exit 0
    fi
    
    print_warning "Final confirmation - are you absolutely sure? (yes/no):"
    read -r FINAL_CONFIRM
    echo ""
    
    if [[ ! $FINAL_CONFIRM =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Production destruction cancelled by user."
        exit 0
    fi
    
    print_warning "Production destruction confirmed. Proceeding with caution..."
}

# Disable deletion protection
disable_deletion_protection() {
    print_status "Checking and disabling deletion protection..."
    
    # Get ALB ARN
    ALB_ARN=$(aws elbv2 describe-load-balancers --names "base-infra-prod-alb" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "")
    
    if [ "$ALB_ARN" != "" ] && [ "$ALB_ARN" != "None" ]; then
        print_status "Disabling deletion protection for production ALB..."
        aws elbv2 modify-load-balancer-attributes --load-balancer-arn "$ALB_ARN" --attributes Key=deletion_protection.enabled,Value=false
        print_success "Deletion protection disabled"
    else
        print_status "No ALB found or deletion protection already disabled"
    fi
}

# Destroy Production application
destroy_prod_application() {
    print_status "Destroying Production application..."
    
    print_status "Planning Production application destruction..."
    if terraform plan -var-file="prod_application.tfvars" -destroy -out=prod-app-destroy-plan; then
        print_status "Destroying Production application..."
        terraform apply -auto-approve prod-app-destroy-plan
        print_success "Production application destroyed successfully!"
    else
        print_warning "Production application destroy plan failed or no resources to destroy"
    fi
}

# Destroy Production infrastructure
destroy_prod_infrastructure() {
    print_status "Destroying Production infrastructure..."
    
    print_status "Planning Production infrastructure destruction..."
    if terraform plan -var-file="prod.tfvars" -destroy -out=prod-destroy-plan; then
        print_status "Destroying Production infrastructure..."
        terraform apply -auto-approve prod-destroy-plan
        print_success "Production infrastructure destroyed successfully!"
    else
        print_warning "Production infrastructure destroy plan failed or no resources to destroy"
    fi
}

# Clean up Terraform state and plans
cleanup_terraform_files() {
    print_status "Cleaning up Terraform files..."
    
    # Remove Production-specific plan files
    rm -f prod-tfplan prod-app-tfplan prod-destroy-plan prod-app-destroy-plan
    
    print_success "Terraform files cleaned up"
}

# Main destruction flow
main() {
    print_status "Starting Production environment destruction..."
    
    check_prerequisites
    check_aws_credentials
    confirm_production_destruction
    
    # Initialize Terraform
    print_status "Initializing Terraform for Production environment..."
    terraform init -backend-config="backend-prod.hcl"
    
    # Disable deletion protection
    disable_deletion_protection
    
    # Destroy Production application first
    destroy_prod_application
    
    # Destroy Production infrastructure
    destroy_prod_infrastructure
    
    # Cleanup
    cleanup_terraform_files
    
    echo ""
    print_success "Production environment destruction completed successfully!"
    echo ""
    print_status "All Production resources have been destroyed:"
    print_status "• Production ECS Cluster: base-infra-prod"
    print_status "• Production Application Load Balancer"
    print_status "• Production Target Groups"
    print_status "• Production Security Groups"
    print_status "• Production VPC and Subnets"
    print_status "• Production NAT Gateways"
    echo ""
    print_status "Remaining environments:"
    print_status "• Dev environment: base-infra-dev (if deployed)"
    print_status "• QA environment: base-infra-qa (if deployed)"
    print_status "• ECR repository: Shared across environments (not destroyed)"
    echo ""
    print_warning "Production environment has been completely removed."
    echo ""
}

# Run main function
main "$@"
