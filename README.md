# Shiny Infrastructure - POC Web Application

A simple POC (Proof of Concept) project for deploying a containerized web application on AWS ECS with Terraform.

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
   - Use GitHub Actions "Deploy POC Infrastructure" workflow

3. **Access**:
   - Check workflow summary for application URL
   - Visit `http://your-alb-dns/` to see your app

### Cleanup

Use GitHub Actions "Destroy POC Infrastructure" workflow:
- Type `DESTROY` to confirm
- All resources will be permanently deleted

## 🏗️ Architecture

```
Internet → ALB → ECS Service (Fargate) → Nginx Container
```

## 📁 Project Structure

```
shiny-infra/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Input variables
├── dev.tfvars                 # Development environment
├── dev_application.tfvars     # Application configuration
├── docker/
│   ├── Dockerfile            # Container image
│   ├── nginx.conf            # Web server config
│   └── src/                  # Static web content
├── .github/workflows/
│   ├── deploy-poc.yml        # Deployment automation
│   ├── destroy-infrastructure.yml # Cleanup automation
│   └── pr-validation.yml     # PR validation
└── modules/                   # Terraform modules
```

## 🔧 Configuration

### Environment Variables (dev.tfvars)
- `aws_region`: AWS region (default: us-east-1)
- `environment`: Environment name (dev/staging/prod)
- `project_name`: Project identifier

### Application Variables (dev_application.tfvars)
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

### 1. **Deploy POC Infrastructure** (`.github/workflows/deploy-poc.yml`)
- Builds and deploys infrastructure and application
- Automatically triggered on push to main/develop
- Manual trigger available

### 2. **Destroy POC Infrastructure** (`.github/workflows/destroy-infrastructure.yml`)
- Safely destroys all AWS resources
- Requires `DESTROY` confirmation
- Manual trigger only

### 3. **PR Validation** (`.github/workflows/pr-validation.yml`)
- Validates Terraform code on pull requests
- Checks formatting and syntax

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

- [POC Setup Guide](POC_SETUP.md) - Detailed setup instructions
- [Infrastructure Destruction Guide](INFRASTRUCTURE_DESTRUCTION_GUIDE.md) - Cleanup procedures

## 🎯 POC Goals

This project demonstrates:
- ✅ Containerized application deployment
- ✅ Infrastructure as Code with Terraform
- ✅ CI/CD with GitHub Actions
- ✅ AWS ECS with Fargate
- ✅ Cost-optimized architecture
- ✅ Automated destruction for cleanup

## 🤝 Contributing

This is a POC project - keep changes simple and focused on learning!

## 📄 License

MIT License - feel free to use for learning and testing.

---

**Note**: This is a POC project optimized for learning and demonstration. For production use, consider additional security, monitoring, and scaling configurations.