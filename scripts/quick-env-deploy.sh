#!/bin/bash

# Quick Environment Deployment Script
# This script provides a simple interface to deploy to any environment

set -e

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

show_help() {
    echo "Quick Environment Deployment Script"
    echo "=================================="
    echo ""
    echo "Usage: $0 [ENVIRONMENT] [ACTION]"
    echo ""
    echo "Environments:"
    echo "  dev      Development environment"
    echo "  qa       Quality Assurance environment"
    echo "  prod     Production environment"
    echo ""
    echo "Actions:"
    echo "  deploy   Deploy the environment (default)"
    echo "  destroy  Destroy the environment"
    echo "  status   Check environment status"
    echo ""
    echo "Examples:"
    echo "  $0 dev                 # Deploy to dev"
    echo "  $0 qa deploy           # Deploy to qa"
    echo "  $0 prod destroy        # Destroy prod"
    echo "  $0 dev status          # Check dev status"
    echo ""
    echo "Interactive Mode:"
    echo "  $0                     # Interactive menu"
    echo ""
}

# Interactive menu
show_menu() {
    echo "=========================================="
    echo "  Multi-Environment Deployment Tool"
    echo "=========================================="
    echo ""
    echo "Available Environments:"
    echo "  1) Development (dev)"
    echo "  2) Quality Assurance (qa)"
    echo "  3) Production (prod)"
    echo ""
    echo "  0) Exit"
    echo ""
    echo -n "Select environment (0-3): "
    read -r choice
    
    case $choice in
        1) ENV="dev" ;;
        2) ENV="qa" ;;
        3) ENV="prod" ;;
        0) exit 0 ;;
        *) 
            print_error "Invalid selection. Please try again."
            show_menu
            return
            ;;
    esac
    
    echo ""
    echo "Available Actions:"
    echo "  1) Deploy"
    echo "  2) Destroy"
    echo "  3) Status"
    echo "  4) Back to main menu"
    echo ""
    echo -n "Select action (1-4): "
    read -r action_choice
    
    case $action_choice in
        1) ACTION="deploy" ;;
        2) ACTION="destroy" ;;
        3) ACTION="status" ;;
        4) show_menu; return ;;
        *) 
            print_error "Invalid selection. Please try again."
            show_menu
            return
            ;;
    esac
}

# Check if required tools are available
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    print_success "All prerequisites are available"
}

# Validate environment
validate_environment() {
    local env=$1
    
    case $env in
        dev|qa|prod)
            if [[ ! -f "${env}.tfvars" ]]; then
                print_error "Configuration file ${env}.tfvars not found"
                exit 1
            fi
            if [[ ! -f "${env}_application.tfvars" ]]; then
                print_error "Configuration file ${env}_application.tfvars not found"
                exit 1
            fi
            ;;
        *)
            print_error "Invalid environment: $env"
            print_error "Valid environments: dev, qa, prod"
            exit 1
            ;;
    esac
}

# Deploy environment
deploy_environment() {
    local env=$1
    
    print_status "Deploying $env environment..."
    
    # Initialize Terraform
    print_status "Initializing Terraform for $env environment..."
    terraform init -backend-config="backend-${env}.hcl"
    
    # Deploy infrastructure
    print_status "Deploying infrastructure..."
    terraform plan -var-file="${env}.tfvars" -out="${env}-infra-plan"
    terraform apply -auto-approve "${env}-infra-plan"
    
    # Get ECR repository URL
    print_status "Getting ECR repository URL..."
    ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
    
    # Build and push Docker image
    print_status "Building and pushing Docker image..."
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$ECR_REPO_URL"
    
    cd docker
    docker build -t "base-infra:${env}" .
    docker tag "base-infra:${env}" "${ECR_REPO_URL}:${env}"
    docker tag "base-infra:${env}" "${ECR_REPO_URL}:latest"
    docker push "${ECR_REPO_URL}:${env}"
    docker push "${ECR_REPO_URL}:latest"
    cd ..
    
    # Update application configuration with new image
    print_status "Updating application configuration..."
    sed -i.bak "s|app_image.*|app_image = \"${ECR_REPO_URL}:${env}\"|g" "${env}_application.tfvars"
    
    # Deploy application
    print_status "Deploying application..."
    terraform plan -var-file="${env}_application.tfvars" -out="${env}-app-plan"
    terraform apply -auto-approve "${env}-app-plan"
    
    # Wait for service stability
    print_status "Waiting for service to be stable..."
    CLUSTER_NAME="base-infra-${env}"
    SERVICE_NAME="base-infra-${env}"
    
    aws ecs wait services-stable --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" --timeout 600 || {
        print_warning "Service may still be starting. Check ECS console for details."
    }
    
    # Get application URL
    ALB_DNS=$(terraform output -raw alb_dns_name)
    
    print_success "Deployment completed successfully!"
    echo ""
    echo "=========================================="
    echo "  $env Environment Ready!"
    echo "=========================================="
    echo ""
    echo "🌐 Application URL: http://$ALB_DNS"
    echo "🏥 Health Check: http://$ALB_DNS/health"
    echo "📊 Environment: $env"
    echo "🕒 Deployed: $(date)"
    echo ""
    
    if [[ "$env" == "prod" ]]; then
        echo "🔥 Production Notes:"
        echo "  - High availability with multiple instances"
        echo "  - Auto-scaling enabled"
        echo "  - Enhanced monitoring active"
        echo "  - Deletion protection enabled"
    fi
}

# Destroy environment
destroy_environment() {
    local env=$1
    
    print_warning "You are about to destroy the $env environment!"
    print_warning "This action cannot be undone."
    echo ""
    echo -n "Type 'DESTROY' to confirm: "
    read -r confirmation
    
    if [[ "$confirmation" != "DESTROY" ]]; then
        print_error "Destruction cancelled. You must type 'DESTROY' to confirm."
        exit 1
    fi
    
    print_status "Destroying $env environment..."
    
    # Initialize Terraform
    terraform init -backend-config="backend-${env}.hcl"
    
    # Destroy application
    print_status "Destroying application..."
    terraform plan -var-file="${env}_application.tfvars" -destroy -out="${env}-app-destroy-plan"
    terraform apply -auto-approve "${env}-app-destroy-plan"
    
    # Destroy infrastructure
    print_status "Destroying infrastructure..."
    terraform plan -var-file="${env}.tfvars" -destroy -out="${env}-destroy-plan"
    terraform apply -auto-approve "${env}-destroy-plan"
    
    print_success "Environment $env destroyed successfully!"
    echo ""
    echo "=========================================="
    echo "  $env Environment Destroyed"
    echo "=========================================="
    echo ""
    echo "🗑️ Destroyed: $(date)"
    echo "👤 Destroyed by: $(whoami)"
    echo ""
}

# Check environment status
check_status() {
    local env=$1
    
    print_status "Checking $env environment status..."
    
    # Initialize Terraform
    terraform init -backend-config="backend-${env}.hcl" > /dev/null 2>&1
    
    # Check if infrastructure exists
    if terraform show -json | jq -e '.values.root_module.resources[] | select(.type == "aws_ecs_cluster")' > /dev/null 2>&1; then
        print_success "Infrastructure: Active"
        
        # Get details
        CLUSTER_NAME="base-infra-${env}"
        SERVICE_NAME="base-infra-${env}"
        
        # Check ECS service
        if aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" --query 'services[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
            print_success "ECS Service: Active"
            
            # Get running tasks
            RUNNING_TASKS=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" --query 'services[0].runningCount' --output text 2>/dev/null)
            echo "  Running Tasks: $RUNNING_TASKS"
            
            # Get ALB URL
            if terraform output alb_dns_name > /dev/null 2>&1; then
                ALB_DNS=$(terraform output -raw alb_dns_name)
                echo "  Application URL: http://$ALB_DNS"
            fi
        else
            print_warning "ECS Service: Inactive or not found"
        fi
    else
        print_error "Infrastructure: Not found"
    fi
    
    echo ""
}

# Main execution
main() {
    # Check if help was requested
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    # If no arguments provided, show interactive menu
    if [[ $# -eq 0 ]]; then
        show_menu
    else
        ENV=$1
        ACTION=${2:-deploy}
    fi
    
    # Validate inputs
    validate_environment "$ENV"
    check_prerequisites
    
    # Execute requested action
    case $ACTION in
        deploy)
            deploy_environment "$ENV"
            ;;
        destroy)
            destroy_environment "$ENV"
            ;;
        status)
            check_status "$ENV"
            ;;
        *)
            print_error "Invalid action: $ACTION"
            print_error "Valid actions: deploy, destroy, status"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
