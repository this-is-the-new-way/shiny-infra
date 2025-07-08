# Multi-Environment Deployment Guide

## Overview
This GitHub Actions workflow system enables **independent deployment and coexistence** of dev, qa, and prod environments with ECS, ensuring complete isolation while sharing resources where appropriate.

## 🚀 Key Features

### Environment Isolation
- **✅ Terraform Workspaces**: Each environment uses its own isolated Terraform workspace
- **✅ Dedicated VPC**: Each environment has its own VPC (10.0.0.0/16 for dev, 10.1.0.0/16 for qa, 10.2.0.0/16 for prod)
- **✅ Environment-specific Resource Naming**: Resources are prefixed with `base-infra-{env}-` (e.g., `base-infra-dev-cluster`)
- **✅ Independent Lifecycle**: Each environment can be deployed, updated, or destroyed independently

### Shared Resources
- **📦 ECR Repository**: Single shared repository with environment-specific image tags (`dev-latest`, `qa-latest`, `prod-latest`)
- **🔐 IAM Roles**: Environment-specific IAM roles for security isolation
- **📊 CloudWatch Logs**: Separate log groups per environment

### Unified Deployment
- **🏗️ Single-phase Deployment**: Infrastructure and application deployed together
- **⚡ Zero-downtime Updates**: Rolling deployments via ECS
- **🔄 Automatic Resource Import**: Handles existing resource conflicts gracefully

## 🛠️ Available Workflows

### 1. Primary Deployment Workflow
**File**: `.github/workflows/deploy-environments.yml`

**Trigger Options**:
- **Manual**: GitHub Actions UI → "Deploy Multi-Environment Infrastructure with ECS"
- **Automatic**: Push to `main` (dev), `qa`, or `prod` branches

**Actions Available**:
- `deploy`: Full infrastructure deployment
- `update-service`: Update ECS service with new image
- `scale-service`: Scale ECS service (1-10 tasks)
- `plan-only`: Terraform plan without applying
- `destroy`: Destroy environment completely

**Key Parameters**:
- `environment`: dev, qa, or prod
- `force_rebuild`: Force Docker image rebuild
- `import_existing`: Import existing AWS resources
- `desired_count`: ECS task count (1-10)

### 2. Multi-Environment Parallel Deployment
**File**: `.github/workflows/multi-environment-deploy.yml`

**Purpose**: Deploy multiple environments simultaneously or sequentially

**Features**:
- Deploy to multiple environments: `dev,qa,prod`
- Parallel or sequential deployment
- Health checks across all environments
- Batch operations (deploy/destroy/update all)

### 3. Environment Management
**File**: `.github/workflows/environment-management.yml`

**Purpose**: Advanced environment management operations

**Features**:
- List all environments
- Health checks
- Resource cleanup
- State backup/restore
- Environment synchronization

### 4. PR Validation
**File**: `.github/workflows/pr-validation.yml`

**Purpose**: Validate changes before merging

**Features**:
- Terraform validation
- Configuration checks
- Security scanning
- Docker validation

### 5. Automated Provisioning
**File**: `.github/workflows/automated-provisioning.yml`

**Purpose**: Scheduled and automated environment maintenance

**Features**:
- Daily health checks
- Automated provisioning
- Environment verification
- Scaling operations

## 🌍 Environment Configurations

### Development Environment
- **VPC CIDR**: 10.0.0.0/16
- **Cost-optimized**: No NAT Gateway, minimal resources
- **Purpose**: Development and testing
- **Auto-scaling**: Disabled
- **Branch**: `main`

### QA Environment
- **VPC CIDR**: 10.1.0.0/16
- **Testing-optimized**: Balanced cost and functionality
- **Purpose**: Quality assurance and integration testing
- **Auto-scaling**: Basic
- **Branch**: `qa`

### Production Environment
- **VPC CIDR**: 10.2.0.0/16
- **High-availability**: Multiple AZs, NAT Gateways
- **Purpose**: Production workloads
- **Auto-scaling**: Full configuration
- **Branch**: `prod`

## 🚀 Deployment Examples

### Deploy Single Environment
```yaml
# Via GitHub Actions UI
Environment: dev
Action: deploy
Force Rebuild: false
Import Existing: false
```

### Deploy All Environments
```yaml
# Via Multi-Environment Workflow
Environments: dev,qa,prod
Action: deploy
Parallel Deployment: true
```

### Update ECS Service Only
```yaml
# Via Primary Workflow
Environment: prod
Action: update-service
Force Rebuild: true
```

### Scale ECS Service
```yaml
# Via Primary Workflow
Environment: qa
Action: scale-service
Desired Count: 3
```

## 📊 Environment Status Monitoring

### Health Check Endpoints
- **Dev**: `http://{dev-alb-dns}/health`
- **QA**: `http://{qa-alb-dns}/health`
- **Prod**: `http://{prod-alb-dns}/health`

### AWS Resources to Monitor
- **ECS Clusters**: `base-infra-{env}`
- **ECS Services**: `base-infra-{env}-service`
- **ALB**: `base-infra-{env}-alb`
- **VPC**: `base-infra-{env}-vpc`

## 🔒 Security and Isolation

### Workspace Isolation
Each environment uses its own Terraform workspace:
```bash
# Development
terraform workspace select dev

# QA
terraform workspace select qa

# Production
terraform workspace select prod
```

### Resource Naming Convention
All resources follow the pattern: `base-infra-{environment}-{resource-type}`

Examples:
- `base-infra-dev-cluster`
- `base-infra-qa-service`
- `base-infra-prod-alb`

### Network Isolation
- **Separate VPCs**: Each environment has its own VPC
- **No Cross-Environment Communication**: Environments are completely isolated
- **Environment-specific Security Groups**: Tailored security rules per environment

## 🛠️ Troubleshooting

### Common Issues

#### 1. Resource Conflicts
**Error**: Resources already exist
**Solution**: Use `import_existing: true` parameter

#### 2. Workspace Not Found
**Error**: Terraform workspace doesn't exist
**Solution**: Workflow will create workspace automatically

#### 3. ECS Service Deployment Stuck
**Error**: ECS service not reaching stable state
**Solution**: Check ECS logs and health check configuration

#### 4. Docker Image Build Failures
**Error**: Docker build fails
**Solution**: Use `force_rebuild: true` and check Dockerfile

### Debugging Steps

1. **Check Workflow Logs**: GitHub Actions → Run details
2. **Verify AWS Resources**: AWS Console → ECS, VPC, ALB
3. **Check Terraform State**: `terraform state list`
4. **Verify Docker Images**: ECR → Repository → Images

## 📋 Maintenance

### Regular Tasks
- **Weekly**: Run health checks on all environments
- **Monthly**: Review and cleanup unused Docker images
- **Quarterly**: Update Terraform version and dependencies

### Environment Refresh
To completely refresh an environment:
1. Run `destroy` action
2. Wait for completion
3. Run `deploy` action

### Cost Optimization
- **Dev**: Keep minimal resources, destroy when not needed
- **QA**: Scale down during non-testing hours
- **Prod**: Monitor and optimize based on usage

## 🔗 Related Documentation
- [Terraform Configuration](./main.tf)
- [Environment Variables](./variables.tf)
- [Docker Configuration](./docker/Dockerfile)
- [ECS Module](./modules/ecs/main.tf)

## 🎯 Best Practices

1. **Use Branch Protection**: Require PR approval for prod branch
2. **Test in Dev First**: Always test changes in dev before QA/prod
3. **Monitor Resource Usage**: Regular cost and performance monitoring
4. **Backup Important Data**: Use automated backup strategies
5. **Document Changes**: Update this README when making workflow changes

## 🆘 Support

For issues or questions:
1. Check workflow logs in GitHub Actions
2. Review AWS CloudWatch logs
3. Verify Terraform state consistency
4. Check resource quotas and limits

---

**Last Updated**: December 2024
**Version**: 2.0 (Enhanced Multi-Environment Support)
