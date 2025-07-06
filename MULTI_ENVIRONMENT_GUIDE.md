# Multi-Environment Deployment Guide

This guide explains how to deploy and manage the shiny-infra project across multiple environments (dev, qa, prod).

## 🏗️ Environment Architecture

### Environment Overview
The project supports three isolated environments:

| Environment | Purpose | ECS Cluster | VPC CIDR | Resource Level |
|-------------|---------|-------------|----------|----------------|
| **dev** | Development & Testing | base-infra-dev | 10.0.0.0/16 | Minimal (Free Tier) |
| **qa** | Quality Assurance | base-infra-qa | 10.1.0.0/16 | Minimal (Free Tier) |
| **prod** | Production | base-infra-prod | 10.2.0.0/16 | High Availability |

### Key Features
- **Shared Docker Image**: All environments use the same Docker image from ECR
- **Isolated Infrastructure**: Each environment has its own VPC, ECS cluster, and resources
- **Environment-Specific Configuration**: Separate Terraform variable files for each environment
- **Unified Workflow**: Single GitHub Actions workflow manages all environments

## 🚀 Deployment Methods

### Method 1: GitHub Actions (Recommended)

#### Deploy an Environment
1. Go to **Actions** → **Deploy Multi-Environment Infrastructure**
2. Click **Run workflow**
3. Select:
   - **Environment**: `dev`, `qa`, or `prod`
   - **Action**: `deploy`
4. Click **Run workflow**

#### Destroy an Environment
1. Go to **Actions** → **Deploy Multi-Environment Infrastructure**
2. Click **Run workflow**
3. Select:
   - **Environment**: `dev`, `qa`, or `prod`
   - **Action**: `destroy`
4. Click **Run workflow**

#### Automatic Triggers
- Push to `main` → deploys to **dev**
- Push to `qa` → deploys to **qa**
- Push to `prod` → deploys to **prod**

### Method 2: Local Scripts

#### Deploy Specific Environment
```bash
# Deploy development environment
./scripts/deploy-complete.sh

# Deploy QA environment
./scripts/deploy-qa.sh

# Deploy production environment
./scripts/deploy-prod.sh
```

#### Destroy Specific Environment
```bash
# Destroy QA environment
./scripts/destroy-qa.sh

# Destroy production environment
./scripts/destroy-prod.sh
```

#### Environment Management Script
```bash
# Deploy any environment
./scripts/manage-envs.sh deploy dev
./scripts/manage-envs.sh deploy qa
./scripts/manage-envs.sh deploy prod

# Destroy any environment
./scripts/manage-envs.sh destroy dev
./scripts/manage-envs.sh destroy qa
./scripts/manage-envs.sh destroy prod

# Check environment status
./scripts/manage-envs.sh status dev
./scripts/manage-envs.sh status qa
./scripts/manage-envs.sh status prod

# List all environments
./scripts/manage-envs.sh list
```

### Method 3: Manual Terraform

#### Development Environment
```bash
# Initialize Terraform
terraform init

# Plan infrastructure
terraform plan -var-file="dev.tfvars" -out=dev-infra-plan
terraform apply dev-infra-plan

# Build and push Docker image
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO_URL

cd docker
docker build -t base-infra:dev .
docker tag base-infra:dev $ECR_REPO_URL:dev
docker push $ECR_REPO_URL:dev
cd ..

# Deploy application
terraform plan -var-file="dev_application.tfvars" -out=dev-app-plan
terraform apply dev-app-plan
```

#### QA Environment
```bash
# Plan and apply QA infrastructure
terraform plan -var-file="qa.tfvars" -out=qa-infra-plan
terraform apply qa-infra-plan

# Build and push Docker image (tagged for QA)
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
cd docker
docker build -t base-infra:qa .
docker tag base-infra:qa $ECR_REPO_URL:qa
docker push $ECR_REPO_URL:qa
cd ..

# Deploy QA application
terraform plan -var-file="qa_application.tfvars" -out=qa-app-plan
terraform apply qa-app-plan
```

#### Production Environment
```bash
# Plan and apply production infrastructure
terraform plan -var-file="prod.tfvars" -out=prod-infra-plan
terraform apply prod-infra-plan

# Build and push Docker image (tagged for prod)
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
cd docker
docker build -t base-infra:prod .
docker tag base-infra:prod $ECR_REPO_URL:prod
docker push $ECR_REPO_URL:prod
cd ..

# Deploy production application
terraform plan -var-file="prod_application.tfvars" -out=prod-app-plan
terraform apply prod-app-plan
```

## 🔄 Environment Management

### Environment Promotion Workflow
1. **Development**: Test new features and bug fixes
2. **QA**: Validate functionality and performance
3. **Production**: Deploy stable, tested code

### Best Practices

#### Development Environment
- Use for active development and testing
- Deploy frequently to test changes
- Safe to experiment with new features

#### QA Environment
- Deploy stable development code
- Perform comprehensive testing
- Validate before production deployment

#### Production Environment
- Deploy only tested and approved code
- Use high availability configuration
- Monitor closely for issues
- Enable deletion protection

### Environment Synchronization
All environments use the same Docker image but different configurations:

```bash
# The same image is tagged for each environment
docker tag base-infra:latest $ECR_REPO_URL:dev
docker tag base-infra:latest $ECR_REPO_URL:qa
docker tag base-infra:latest $ECR_REPO_URL:prod
```

## 🐛 Troubleshooting

### Common Issues

#### Environment Not Deploying
1. Check AWS credentials in GitHub Secrets
2. Verify Terraform state is not locked
3. Check CloudWatch logs for container errors

#### Service Health Check Failures
```bash
# Check ECS service status
aws ecs describe-services --cluster base-infra-dev --services base-infra-dev

# View container logs
aws logs tail base-infra-dev-logs --follow
```

#### Cannot Access Application
1. Check ALB target group health
2. Verify security group rules
3. Check DNS resolution

### Debugging Commands

```bash
# Check all environments
./scripts/manage-envs.sh list

# Get environment details
./scripts/manage-envs.sh status dev
./scripts/manage-envs.sh status qa
./scripts/manage-envs.sh status prod

# Check AWS resources
aws ecs list-clusters
aws ecs list-services --cluster base-infra-dev
aws elbv2 describe-load-balancers
```

## 💰 Cost Management

### Development/QA (Free Tier Optimized)
- **Fargate**: 0.25 vCPU, 0.5 GB RAM
- **Instances**: 1 instance
- **Storage**: Minimal
- **Network**: Public subnets (no NAT Gateway)

### Production (Performance Optimized)
- **Fargate**: 0.5 vCPU, 1 GB RAM
- **Instances**: 2+ instances with auto-scaling
- **Storage**: Enhanced monitoring
- **Network**: Private subnets with NAT Gateway

### Cost Optimization Tips
1. Destroy non-production environments when not needed
2. Use spot instances for development (if applicable)
3. Monitor CloudWatch costs
4. Set up billing alerts

## 🔐 Security Considerations

### Environment Isolation
- Each environment has its own VPC and security groups
- No cross-environment access by default
- Separate IAM roles where applicable

### Production Security
- Enable deletion protection on ALB
- Use private subnets with NAT Gateway
- Enhanced monitoring and logging
- Regular security audits

### Secrets Management
- Use AWS Secrets Manager for sensitive data
- Separate secrets per environment
- Rotate secrets regularly

## 📊 Monitoring

### CloudWatch Metrics
- ECS service health
- ALB request metrics
- Container CPU/memory usage

### Health Checks
- ALB health check on `/` endpoint
- ECS service health monitoring
- Container restart policies

### Alerts (Production)
- Service down alerts
- High CPU/memory usage
- Failed health checks
- Unusual traffic patterns

## 🚀 Advanced Usage

### Blue/Green Deployments
```bash
# Deploy to staging environment first
./scripts/manage-envs.sh deploy staging

# Test staging environment
# ... perform tests ...

# Deploy to production
./scripts/manage-envs.sh deploy prod
```

### Rollback Strategy
```bash
# Deploy previous version
docker tag base-infra:previous $ECR_REPO_URL:prod
docker push $ECR_REPO_URL:prod

# Update ECS service
aws ecs update-service --cluster base-infra-prod --service base-infra-prod --force-new-deployment
```

## 📚 Configuration Files

### Infrastructure Files
- `dev.tfvars` - Development infrastructure configuration
- `qa.tfvars` - QA infrastructure configuration
- `prod.tfvars` - Production infrastructure configuration

### Application Files
- `dev_application.tfvars` - Development application configuration
- `qa_application.tfvars` - QA application configuration
- `prod_application.tfvars` - Production application configuration

### Workflow Files
- `.github/workflows/deploy-poc.yml` - Multi-environment deployment workflow
- `.github/workflows/deploy-qa.yml` - Legacy QA deployment workflow
- `.github/workflows/destroy-infrastructure.yml` - Infrastructure destruction workflow

## 🎯 Next Steps

1. Test all environments to ensure proper deployment
2. Set up monitoring dashboards
3. Implement automated testing in QA
4. Configure production alerts
5. Document environment-specific procedures
6. Plan for disaster recovery

---

**Note**: This is a comprehensive guide for managing multiple environments. Always test deployments in non-production environments first!
