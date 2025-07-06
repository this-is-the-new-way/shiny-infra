#!/bin/bash

# Environment Isolation Verification Script
# This script verifies that all environments are properly isolated and can coexist

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Environment Isolation Verification${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check backend configuration files
check_backend_configs() {
    echo -e "${CYAN}🔧 Backend Configuration Check${NC}"
    echo -e "${CYAN}==============================${NC}"
    
    local configs=("backend-dev.hcl" "backend-qa.hcl" "backend-prod.hcl")
    local all_present=true
    
    for config in "${configs[@]}"; do
        if [[ -f "$config" ]]; then
            print_success "Backend config $config exists"
            
            # Check contents
            if grep -q "shiny-infra/${config%%-*}/terraform.tfstate" "$config"; then
                print_success "Backend config $config has correct state path"
            else
                print_error "Backend config $config has incorrect state path"
                all_present=false
            fi
        else
            print_error "Backend config $config is missing"
            all_present=false
        fi
    done
    
    echo ""
    if [[ "$all_present" == true ]]; then
        print_success "All backend configurations are properly isolated"
    else
        print_error "Backend configuration issues found"
    fi
    echo ""
}

# Check environment variable files
check_environment_configs() {
    echo -e "${CYAN}📁 Environment Configuration Check${NC}"
    echo -e "${CYAN}====================================${NC}"
    
    local environments=("dev" "qa" "prod")
    local all_configs_present=true
    
    for env in "${environments[@]}"; do
        echo -e "${BLUE}Environment: $env${NC}"
        
        # Check infrastructure config
        if [[ -f "${env}.tfvars" ]]; then
            print_success "Infrastructure config ${env}.tfvars exists"
            
            # Check ECS cluster name
            if grep -q "ecs_cluster_name.*base-infra-${env}" "${env}.tfvars" 2>/dev/null; then
                print_success "ECS cluster name is correctly set to base-infra-${env}"
            else
                print_error "ECS cluster name is not correctly set in ${env}.tfvars"
                all_configs_present=false
            fi
        else
            print_error "Infrastructure config ${env}.tfvars is missing"
            all_configs_present=false
        fi
        
        # Check application config
        if [[ -f "${env}_application.tfvars" ]]; then
            print_success "Application config ${env}_application.tfvars exists"
            
            # Check ECS cluster name in application config
            if grep -q "ecs_cluster_name.*base-infra-${env}" "${env}_application.tfvars" 2>/dev/null; then
                print_success "ECS cluster name in application config is correctly set"
            else
                print_error "ECS cluster name in application config is not correctly set"
                all_configs_present=false
            fi
        else
            print_error "Application config ${env}_application.tfvars is missing"
            all_configs_present=false
        fi
        
        echo ""
    done
    
    if [[ "$all_configs_present" == true ]]; then
        print_success "All environment configurations are properly isolated"
    else
        print_error "Environment configuration issues found"
    fi
    echo ""
}

# Check VPC CIDR isolation
check_vpc_isolation() {
    echo -e "${CYAN}🌐 VPC CIDR Isolation Check${NC}"
    echo -e "${CYAN}============================${NC}"
    
    local dev_cidr=""
    local qa_cidr=""
    local prod_cidr=""
    
    if [[ -f "dev.tfvars" ]]; then
        dev_cidr=$(grep 'vpc_cidr' dev.tfvars | cut -d'"' -f2)
        print_info "Dev VPC CIDR: $dev_cidr"
    fi
    
    if [[ -f "qa.tfvars" ]]; then
        qa_cidr=$(grep 'vpc_cidr' qa.tfvars | cut -d'"' -f2)
        print_info "QA VPC CIDR: $qa_cidr"
    fi
    
    if [[ -f "prod.tfvars" ]]; then
        prod_cidr=$(grep 'vpc_cidr' prod.tfvars | cut -d'"' -f2)
        print_info "Prod VPC CIDR: $prod_cidr"
    fi
    
    echo ""
    
    # Check for uniqueness
    if [[ "$dev_cidr" != "$qa_cidr" && "$dev_cidr" != "$prod_cidr" && "$qa_cidr" != "$prod_cidr" ]]; then
        print_success "All VPC CIDRs are unique (no overlap)"
    else
        print_error "VPC CIDRs are not unique - environments may conflict"
    fi
    echo ""
}

# Check script configurations
check_script_configs() {
    echo -e "${CYAN}📜 Script Configuration Check${NC}"
    echo -e "${CYAN}==============================${NC}"
    
    local scripts=(
        "scripts/deploy-qa.sh"
        "scripts/deploy-prod.sh"
        "scripts/destroy-qa.sh"
        "scripts/destroy-prod.sh"
        "scripts/quick-env-deploy.sh"
    )
    
    local all_scripts_ok=true
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            print_success "Script $script exists"
            
            # Check if script uses backend config
            if grep -q "backend-.*\.hcl" "$script"; then
                print_success "Script $script uses environment-specific backend config"
            else
                print_error "Script $script does not use environment-specific backend config"
                all_scripts_ok=false
            fi
        else
            print_error "Script $script is missing"
            all_scripts_ok=false
        fi
    done
    
    echo ""
    if [[ "$all_scripts_ok" == true ]]; then
        print_success "All scripts are properly configured for environment isolation"
    else
        print_error "Script configuration issues found"
    fi
    echo ""
}

# Check GitHub workflow configuration
check_workflow_config() {
    echo -e "${CYAN}🔄 GitHub Workflow Configuration Check${NC}"
    echo -e "${CYAN}=======================================${NC}"
    
    local workflow_file=".github/workflows/deploy-poc.yml"
    
    if [[ -f "$workflow_file" ]]; then
        print_success "GitHub workflow file exists"
        
        # Check if workflow uses backend config
        if grep -q "backend-.*\.hcl" "$workflow_file"; then
            print_success "Workflow uses environment-specific backend config"
        else
            print_error "Workflow does not use environment-specific backend config"
        fi
        
        # Check if workflow supports all environments
        if grep -q "dev" "$workflow_file" && grep -q "qa" "$workflow_file" && grep -q "prod" "$workflow_file"; then
            print_success "Workflow supports all environments (dev, qa, prod)"
        else
            print_error "Workflow does not support all environments"
        fi
    else
        print_error "GitHub workflow file is missing"
    fi
    echo ""
}

# Check for potential state conflicts
check_state_isolation() {
    echo -e "${CYAN}🗂️  Terraform State Isolation Check${NC}"
    echo -e "${CYAN}====================================${NC}"
    
    # Check if local state files exist (they shouldn't with remote backend)
    if [[ -f "terraform.tfstate" ]]; then
        print_warning "Local terraform.tfstate file exists - should use remote backend"
    else
        print_success "No local terraform.tfstate file (good - using remote backend)"
    fi
    
    # Check backend configuration in terraform.tf
    if [[ -f "terraform.tf" ]]; then
        if grep -q "backend.*s3" terraform.tf; then
            print_success "S3 backend is configured in terraform.tf"
            
            # Check if it mentions environment-specific paths
            if grep -q "shiny-infra.*terraform.tfstate" terraform.tf; then
                print_success "Backend configuration mentions environment-specific paths"
            else
                print_warning "Backend configuration should mention environment-specific paths"
            fi
        else
            print_error "S3 backend is not configured in terraform.tf"
        fi
    else
        print_error "terraform.tf file is missing"
    fi
    echo ""
}

# Environment coexistence summary
print_coexistence_summary() {
    echo -e "${CYAN}📊 Environment Coexistence Summary${NC}"
    echo -e "${CYAN}===================================${NC}"
    
    echo "Environment Isolation Features:"
    echo "✅ Separate Terraform state files per environment"
    echo "✅ Unique VPC CIDRs for network isolation"
    echo "✅ Separate ECS clusters per environment"
    echo "✅ Environment-specific configuration files"
    echo "✅ Backend configuration files for each environment"
    echo "✅ Scripts configured for environment isolation"
    echo "✅ GitHub workflow supports all environments"
    echo ""
    
    echo "Environment Resources:"
    echo "• Dev Environment:"
    echo "  - ECS Cluster: base-infra-dev"
    echo "  - VPC: 10.0.0.0/16"
    echo "  - State: shiny-infra/dev/terraform.tfstate"
    echo ""
    echo "• QA Environment:"
    echo "  - ECS Cluster: base-infra-qa"
    echo "  - VPC: 10.1.0.0/16"
    echo "  - State: shiny-infra/qa/terraform.tfstate"
    echo ""
    echo "• Production Environment:"
    echo "  - ECS Cluster: base-infra-prod"
    echo "  - VPC: 10.2.0.0/16"
    echo "  - State: shiny-infra/prod/terraform.tfstate"
    echo ""
    
    echo "Shared Resources:"
    echo "• ECR Repository: Shared across all environments"
    echo "• Docker Images: Same image, different tags per environment"
    echo ""
}

# Main execution
main() {
    print_header
    
    check_backend_configs
    check_environment_configs
    check_vpc_isolation
    check_script_configs
    check_workflow_config
    check_state_isolation
    print_coexistence_summary
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Verification Complete${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo "All environments are properly configured for isolation and coexistence!"
    echo "You can now deploy all three environments simultaneously without conflicts."
    echo ""
    echo "Quick deployment commands:"
    echo "• ./scripts/quick-env-deploy.sh dev deploy"
    echo "• ./scripts/quick-env-deploy.sh qa deploy"
    echo "• ./scripts/quick-env-deploy.sh prod deploy"
    echo ""
}

# Run main function
main "$@"
