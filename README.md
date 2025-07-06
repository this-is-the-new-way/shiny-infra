# Shiny Infrastructure - Multi-Environment POC Web Application

A containerized web application deployment on AWS ECS with Terraform, supporting multiple environments (dev, qa, prod) with modern responsive design.

## 🔄 Important: ECS Service Separation

**NEW**: This infrastructure now implements a **two-phase deployment pattern** to prevent ECS service deletion/recreation cycles:

1. **Base Infrastructure Phase**: VPC, ALB, ECS Cluster, Security Groups (using `*_environment.tfvars`)
2. **Application Phase**: ECS Service, Task Definition, Auto-scaling (using `*_environment_application.tfvars`)

This ensures that base infrastructure changes don't disrupt running applications. See [ECS_SERVICE_SEPARATION.md](./ECS_SERVICE_SEPARATION.md) for detailed implementation.

## 🚀 Quick Start

### Prerequisites

- AWS Account
- GitHub repository with this code
- AWS credentials

### Setup

1. **Configure GitHub Secrets**:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

2. **Deploy**:
   - Push to `main` branch OR
   - Use GitHub Actions workflow "Deploy Multi-Environment Infrastructure":
     - Select environment: **dev**, **qa**, or **prod**
     - Select action: **deploy** or **destroy**

3. **Access**:
   - Check workflow summary for application URL
   - Visit `http://your-alb-dns/` to see your app

### Cleanup

Use GitHub Actions workflow "Deploy Multi-Environment Infrastructure":
- Select environment: **dev**, **qa**, or **prod**
- Select action: **destroy**

## 🌟 Features

- **Multi-Environment Support**: Dev, QA, and Production environments with isolated resources
- **Modern UI**: Beautiful glassmorphism design with responsive layout
- **Container Orchestration**: ECS Fargate with health checks and auto-scaling
- **Infrastructure as Code**: Complete Terraform automation
- **CI/CD Ready**: Unified GitHub Actions workflow for all environments
- **Cost Optimized**: AWS Free Tier friendly configuration for dev/qa
- **Production Ready**: High availability and auto-scaling for production

## 🏗️ Architecture

```
Internet → ALB → ECS Service (Fargate) → Nginx Container
                    ↓
            CloudWatch Logs & Monitoring
```

### Multi-Environment Setup
- **Dev Environment**: `base-infra-dev` cluster with VPC `10.0.0.0/16`
- **QA Environment**: `base-infra-qa` cluster with VPC `10.1.0.0/16`
- **Production Environment**: `base-infra-prod` cluster with VPC `10.2.0.0/16`
- **Shared Resources**: ECR repository for Docker images

## 📁 Project Structure

```
shiny-infra/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Input variables
├── dev.tfvars                 # Development environment
├── qa.tfvars                  # QA environment
├── prod.tfvars                # Production environment
├── dev_application.tfvars     # Development application configuration
├── qa_application.tfvars      # QA application configuration
├── prod_application.tfvars    # Production application configuration
├── docker/
│   ├── Dockerfile            # Container image
│   ├── nginx.conf            # Web server config
│   └── src/                  # Static web content
├── .github/workflows/
│   ├── deploy-poc.yml        # Multi-environment deployment
│   ├── deploy-qa.yml         # QA-specific deployment
│   └── destroy-infrastructure.yml # Cleanup automation
└── modules/                   # Terraform modules
```

## 🔧 Configuration

### Environment Variables (dev.tfvars, qa.tfvars)
- `aws_region`: AWS region (default: us-east-1)
- `environment`: Environment name (dev/staging/prod)
- `project_name`: Project identifier

### Application Variables (dev_application.tfvars, qa_application.tfvars)
- `app_name`: Application name
- `app_image`: Docker image URL (auto-updated)
- `app_port`: Container port (80)
- `app_cpu`: CPU units (256)
- `app_memory`: Memory in MB (512)

## 🔍 Monitoring

- **Health Checks**: Built-in health endpoint at `/health`
- **Logs**: CloudWatch logs for container output
- **Metrics**: Basic ECS and ALB metrics

## 💰 Cost Optimization

Configured for AWS Free Tier:
- Minimal Fargate resources (0.25 vCPU, 0.5 GB RAM)
- Public subnets only (no NAT Gateway)
- Basic monitoring

## 🚀 GitHub Actions Workflows

### 1. **Deploy Multi-Environment Infrastructure** (`.github/workflows/deploy-poc.yml`)
- Unified workflow for all environments (dev, qa, prod)
- Supports both deployment and destruction
- Environment selection via workflow input
- Automatically triggered on push to main/develop/qa/prod branches
- Manual trigger available with environment selection

### 2. **Destroy Infrastructure** (`.github/workflows/destroy-infrastructure.yml`)
- Legacy workflow for dev environment destruction
- Requires `DESTROY` confirmation
- Manual trigger only

### 3. **Deploy QA Environment** (`.github/workflows/deploy-qa.yml`)
- Legacy QA-specific workflow
- Superseded by the unified multi-environment workflow
- Kept for backward compatibility

## 🚀 Deployment Options

The GitHub workflow now supports **four deployment modes** for maximum flexibility:

### 1. **Full Deployment** (Recommended for new environments)
```bash
Action: deploy
```
- Deploys base infrastructure (VPC, ALB, ECS Cluster)
- Builds and deploys application (ECS Service, Task Definition)
- Complete end-to-end setup

### 2. **Infrastructure Only** (Safe for existing environments)
```bash
Action: deploy-infra-only
```
- Updates base infrastructure only
- Leaves running applications untouched
- Prevents service disruption during infrastructure changes

### 3. **Application Only** (Fast iterations)
```bash
Action: deploy-app-only
```
- Updates application components only
- Builds new Docker image and updates ECS service
- Zero downtime rolling deployment
- Keeps infrastructure unchanged

### 4. **Complete Cleanup**
```bash
Action: destroy
```
- Destroys application resources first
- Then destroys base infrastructure
- Proper dependency management

See [GITHUB_WORKFLOW_UPDATES.md](./GITHUB_WORKFLOW_UPDATES.md) for detailed workflow documentation.

## 🛠️ Manual Deployment

If you prefer manual deployment:

```bash
# Deploy infrastructure
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# Build and push Docker image
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO_URL

cd docker
docker build -t poc-app:latest .
docker tag poc-app:latest $ECR_REPO_URL:latest
docker push $ECR_REPO_URL:latest

# Deploy application
terraform plan -var-file="dev_application.tfvars"
terraform apply -var-file="dev_application.tfvars"
```

## 🚀 Deployment Options

### Option 1: GitHub Actions (Recommended)
1. **Deploy Dev Environment**:
   - Use "Deploy POC Infrastructure" workflow
   - Select `dev` environment
   - Auto-deploys on push to `main` branch

2. **Deploy QA Environment**:
   - Use "Deploy Multi-Environment Infrastructure" workflow
   - Select `qa` environment
   - Auto-deploys on push to `qa` branch

3. **Deploy Production Environment**:
   - Use "Deploy Multi-Environment Infrastructure" workflow
   - Select `prod` environment and `deploy` action
   - Requires manual confirmation for safety

### Option 2: Quick Deployment Script
```bash
# Interactive deployment (Linux/macOS)
./scripts/quick-env-deploy.sh

# Direct deployment (Linux/macOS)
./scripts/quick-env-deploy.sh dev deploy
./scripts/quick-env-deploy.sh qa deploy
./scripts/quick-env-deploy.sh prod deploy

# Windows
.\scripts\quick-env-deploy.bat
.\scripts\quick-env-deploy.bat dev deploy
.\scripts\quick-env-deploy.bat qa deploy
.\scripts\quick-env-deploy.bat prod deploy
```

### Option 3: Environment-Specific Scripts
```bash
# Deploy dev environment
./scripts/deploy-complete.sh

# Deploy QA environment
./scripts/deploy-qa.sh

# Deploy Production environment
./scripts/deploy-prod.sh

# Environment management
./scripts/manage-envs.sh deploy dev
./scripts/manage-envs.sh deploy qa
./scripts/manage-envs.sh deploy prod
./scripts/manage-envs.sh status dev
./scripts/manage-envs.sh list
```

### Option 4: Manual Terraform
```bash
# Dev environment
terraform init
terraform plan -var-file="dev.tfvars" -out=dev-plan
terraform apply dev-plan

# QA environment
terraform plan -var-file="qa.tfvars" -out=qa-plan
terraform apply qa-plan

# Production environment
terraform plan -var-file="prod.tfvars" -out=prod-plan
terraform apply prod-plan
```

## 🔄 Environment Management

### Environment Comparison
| Feature | Dev | QA | Prod |
|---------|-----|----|----- |
| Status | ✅ Active | ✅ Active | ✅ Active |
| Cluster | base-infra-dev | base-infra-qa | base-infra-prod |
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| Purpose | Development | QA Testing | Production |
| Resources | Minimal | Minimal | High Availability |
| CPU/Memory | 0.25 vCPU / 0.5 GB | 0.25 vCPU / 0.5 GB | 0.5 vCPU / 1 GB |
| Instances | 1 | 1 | 2+ (Auto-scaling) |
| Cost | Free Tier | Free Tier | Production Cost |

### Environment Lifecycle
1. **Development**: Code changes → Dev environment
2. **Quality Assurance**: Stable code → QA environment
3. **Production**: Approved releases → Production environment

## 🐛 Troubleshooting

### Common Issues

1. **GitHub Actions Fails**: Check AWS credentials are configured
2. **ECS Service Unhealthy**: Verify container port and health check
3. **Access Denied**: Ensure proper IAM permissions

### Debugging

```bash
# Check ECS service
aws ecs describe-services --cluster my-app-dev --services my-app-service

# View logs
aws logs tail my-app-dev-logs --follow

# Check ALB health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## 📚 Documentation

- **[Multi-Environment Deployment Guide](MULTI_ENVIRONMENT_GUIDE.md)** - Complete guide for managing all environments
- **[POC Setup Guide](POC_SETUP.md)** - Detailed setup instructions
- **[Infrastructure Destruction Guide](INFRASTRUCTURE_DESTRUCTION_GUIDE.md)** - Cleanup procedures
- **[QA Environment Integration](QA_ENVIRONMENT_INTEGRATION.md)** - QA-specific documentation

## 🎯 POC Goals

This project demonstrates:
- ✅ Containerized application deployment
- ✅ Infrastructure as Code with Terraform
- ✅ CI/CD with GitHub Actions
- ✅ AWS ECS with Fargate
- ✅ Multi-environment support (dev, qa, prod)
- ✅ Cost-optimized architecture
- ✅ Automated destruction for cleanup
- ✅ Unified deployment workflows
- ✅ Environment-specific configurations

## 🤝 Contributing

This is a POC project - keep changes simple and focused on learning!

## 📄 License

MIT License - feel free to use for learning and testing.

---

**Note**: This is a POC project optimized for learning and demonstration. For production use, consider additional security, monitoring, and scaling configurations.