#!/bin/bash

# Deploy QA Environment - Complete Infrastructure and Application
# This script deploys the QA environment using the same Docker image as dev

set -e

echo "🚀 Starting QA Environment Deployment"
echo "====================================="

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
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
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

# Deploy QA infrastructure
deploy_qa_infrastructure() {
    print_status "Deploying QA infrastructure..."
    
    print_status "Initializing Terraform for QA environment..."
    terraform init -backend-config="backend-qa.hcl"
    
    print_status "Validating Terraform configuration..."
    terraform validate
    
    print_status "Planning QA infrastructure deployment..."
    terraform plan -var-file="qa.tfvars" -out=qa-tfplan
    
    print_status "Applying QA infrastructure changes..."
    terraform apply -auto-approve qa-tfplan
    
    print_success "QA infrastructure deployed successfully!"
}

# Use existing Docker image from ECR (same as dev)
deploy_qa_application() {
    print_status "Deploying QA application using existing Docker image..."
    
    # Get ECR repository URL
    ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
    
    if [ -z "$ECR_REPO_URL" ]; then
        print_error "Failed to get ECR repository URL from Terraform output"
        exit 1
    fi
    
    print_status "ECR Repository URL: $ECR_REPO_URL"
    
    # Update qa_application.tfvars with ECR image
    print_status "Updating QA application configuration with ECR image..."
    sed -i.bak "s|app_image.*|app_image = \"$ECR_REPO_URL:latest\"|g" qa_application.tfvars
    
    print_status "Planning QA application deployment..."
    terraform plan -var-file="qa_application.tfvars" -out=qa-app-tfplan
    
    print_status "Applying QA application changes..."
    terraform apply -auto-approve qa-app-tfplan
    
    print_success "QA application deployed successfully!"
}

# Wait for QA ECS service to be stable
wait_for_qa_service() {
    print_status "Waiting for QA ECS service to become stable..."
    
    ECS_CLUSTER="base-infra-qa"
    ECS_SERVICE="base-infra-qa"
    
    print_status "Waiting for service $ECS_SERVICE in cluster $ECS_CLUSTER..."
    
    # Wait for service to be stable (max 10 minutes)
    if aws ecs wait services-stable --cluster $ECS_CLUSTER --services $ECS_SERVICE --timeout 600; then
        print_success "QA ECS service is stable!"
        
        # Check running tasks
        RUNNING_TASKS=$(aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --query 'services[0].runningCount' --output text)
        print_status "Running tasks: $RUNNING_TASKS"
        
        if [ "$RUNNING_TASKS" -gt 0 ]; then
            print_success "QA ECS service has running tasks!"
        else
            print_warning "QA ECS service has no running tasks. Check the logs for issues."
        fi
    else
        print_warning "QA ECS service did not become stable within the timeout period."
    fi
}

# Get QA deployment outputs
get_qa_deployment_info() {
    print_status "Getting QA deployment information..."
    
    ALB_URL=$(terraform output -raw alb_dns_name 2>/dev/null || echo "Not available")
    ECR_REPO_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "Not available")
    ECS_CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "Not available")
    ECS_SERVICE=$(terraform output -raw ecs_service_name 2>/dev/null || echo "Not available")
    
    echo ""
    echo "🎉 QA Environment Deployment Complete!"
    echo "====================================="
    echo "QA Application URL: http://$ALB_URL"
    echo "ECR Repository: $ECR_REPO_URL"
    echo "ECS Cluster: $ECS_CLUSTER"
    echo "ECS Service: $ECS_SERVICE"
    echo ""
    echo "QA Health Check: http://$ALB_URL/health"
    echo ""
    echo "🔗 Compare with Dev Environment:"
    echo "Dev URL: Check dev deployment outputs"
    echo ""
}

# Main deployment flow
main() {
    print_status "Starting QA environment deployment..."
    
    check_prerequisites
    check_aws_credentials
    
    # Deploy QA infrastructure
    deploy_qa_infrastructure
    
    # Deploy QA application (using existing Docker image)
    deploy_qa_application
    
    # Wait for service to be stable
    wait_for_qa_service
    
    # Get deployment info
    get_qa_deployment_info
    
    print_success "QA environment deployment completed successfully!"
}

# Run main function
main "$@"
