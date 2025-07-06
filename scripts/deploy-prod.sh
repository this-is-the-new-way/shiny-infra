#!/bin/bash

# Deploy Production Environment - Complete Infrastructure and Application
# This script deploys the production environment using the same Docker image as dev

set -e

echo "🚀 Starting Production Environment Deployment"
echo "=============================================="

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

# Production deployment confirmation
confirm_production_deployment() {
    echo ""
    print_warning "⚠️  PRODUCTION DEPLOYMENT WARNING!"
    print_warning "⚠️  You are about to deploy to the PRODUCTION environment!"
    print_warning "⚠️  This will create production resources with:"
    print_warning "    • High availability configuration"
    print_warning "    • Auto-scaling enabled"
    print_warning "    • Enhanced monitoring"
    print_warning "    • Deletion protection"
    print_warning "    • Higher resource costs"
    echo ""
    read -p "Are you sure you want to deploy to PRODUCTION? (yes/no): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Production deployment cancelled by user."
        exit 0
    fi
    
    print_status "Production deployment confirmed. Proceeding..."
}

# Deploy Production infrastructure
deploy_prod_infrastructure() {
    print_status "Deploying Production infrastructure..."
    
    print_status "Initializing Terraform for Production environment..."
    terraform init -backend-config="backend-prod.hcl"
    
    print_status "Validating Terraform configuration..."
    terraform validate
    
    print_status "Planning Production infrastructure deployment..."
    terraform plan -var-file="prod.tfvars" -out=prod-tfplan
    
    print_status "Applying Production infrastructure changes..."
    terraform apply -auto-approve prod-tfplan
    
    print_success "Production infrastructure deployed successfully!"
}

# Use existing Docker image from ECR (same as dev)
deploy_prod_application() {
    print_status "Deploying Production application using existing Docker image..."
    
    # Get ECR repository URL
    ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
    
    if [ -z "$ECR_REPO_URL" ]; then
        print_error "Failed to get ECR repository URL from Terraform output"
        exit 1
    fi
    
    print_status "ECR Repository URL: $ECR_REPO_URL"
    
    # Tag and push production image
    print_status "Tagging and pushing production image..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL
    
    # Pull latest image and retag for production
    docker pull $ECR_REPO_URL:latest
    docker tag $ECR_REPO_URL:latest $ECR_REPO_URL:prod
    docker push $ECR_REPO_URL:prod
    
    # Update prod_application.tfvars with ECR image
    print_status "Updating Production application configuration with ECR image..."
    sed -i.bak "s|app_image.*|app_image = \"$ECR_REPO_URL:prod\"|g" prod_application.tfvars
    
    print_status "Planning Production application deployment..."
    terraform plan -var-file="prod_application.tfvars" -out=prod-app-tfplan
    
    print_status "Applying Production application changes..."
    terraform apply -auto-approve prod-app-tfplan
    
    print_success "Production application deployed successfully!"
}

# Wait for Production ECS service to be stable
wait_for_prod_service() {
    print_status "Waiting for Production ECS service to become stable..."
    
    ECS_CLUSTER="base-infra-prod"
    ECS_SERVICE="base-infra-prod"
    
    print_status "Waiting for service $ECS_SERVICE in cluster $ECS_CLUSTER..."
    
    # Wait for service to be stable (max 15 minutes for production)
    if aws ecs wait services-stable --cluster $ECS_CLUSTER --services $ECS_SERVICE --timeout 900; then
        print_success "Production ECS service is stable!"
        
        # Check running tasks
        RUNNING_TASKS=$(aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --query 'services[0].runningCount' --output text)
        DESIRED_TASKS=$(aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --query 'services[0].desiredCount' --output text)
        
        print_status "Running tasks: $RUNNING_TASKS/$DESIRED_TASKS"
        
        if [ "$RUNNING_TASKS" -eq "$DESIRED_TASKS" ] && [ "$RUNNING_TASKS" -gt 0 ]; then
            print_success "Production ECS service is healthy with all desired tasks running!"
        else
            print_warning "Production ECS service may have issues. Running: $RUNNING_TASKS, Desired: $DESIRED_TASKS"
        fi
    else
        print_error "Production ECS service did not become stable within the timeout period."
        exit 1
    fi
}

# Get Production deployment outputs
get_prod_deployment_info() {
    print_status "Getting Production deployment information..."
    
    ALB_URL=$(terraform output -raw alb_dns_name 2>/dev/null || echo "Not available")
    ECR_REPO_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "Not available")
    ECS_CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "Not available")
    ECS_SERVICE=$(terraform output -raw ecs_service_name 2>/dev/null || echo "Not available")
    
    echo ""
    print_success "🎉 Production Environment Deployment Complete!"
    print_success "============================================="
    echo ""
    echo "🌐 Production Application URL: http://$ALB_URL"
    echo "🏥 Production Health Check: http://$ALB_URL/health"
    echo "🐳 ECR Repository: $ECR_REPO_URL"
    echo "🚀 ECS Cluster: $ECS_CLUSTER"
    echo "⚙️  ECS Service: $ECS_SERVICE"
    echo ""
    echo "🔒 Production Features:"
    echo "  • High Availability: 2+ instances across AZs"
    echo "  • Auto-scaling: Enabled with CPU/Memory targets"
    echo "  • Enhanced Monitoring: Container Insights enabled"
    echo "  • Deletion Protection: Enabled for ALB"
    echo "  • Health Checks: More stringent thresholds"
    echo ""
    echo "🔗 Environment Comparison:"
    echo "  • Dev URL: Check dev deployment outputs"
    echo "  • QA URL: Check qa deployment outputs"
    echo "  • Prod URL: http://$ALB_URL"
    echo ""
}

# Main deployment flow
main() {
    print_status "Starting Production environment deployment..."
    
    check_prerequisites
    check_aws_credentials
    confirm_production_deployment
    
    # Deploy Production infrastructure
    deploy_prod_infrastructure
    
    # Deploy Production application (using existing Docker image)
    deploy_prod_application
    
    # Wait for service to be stable
    wait_for_prod_service
    
    # Get deployment info
    get_prod_deployment_info
    
    print_success "Production environment deployment completed successfully!"
    print_warning "Remember to monitor the production environment and set up alerts!"
}

# Run main function
main "$@"
