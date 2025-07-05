# Shiny Infrastructure - AWS ECS with Nginx

A modern, containerized web application running on AWS ECS with Terraform infrastructure as code. This project showcases best practices for cloud-native application deployment using nginx, optimized for AWS Free Tier.

## 🏗️ Architecture

```
Internet → ALB → ECS Service (Fargate) → Nginx Container
                    ↓
                CloudWatch Logs
```

## 🚀 Features

- **Containerized**: Nginx-based web application with custom static content
- **Cloud Native**: Deployed on AWS ECS with Fargate for serverless containers
- **Infrastructure as Code**: Complete Terraform configuration for reproducible deployments
- **Cost Optimized**: Configured for AWS Free Tier with minimal resource usage
- **Auto-scaling**: ECS service with configurable scaling policies
- **Health Monitoring**: Built-in health checks and CloudWatch monitoring
- **Security**: Security groups, IAM roles, and security headers

## 📋 Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Docker Desktop
- Git

## 🛠️ Technology Stack

- **Frontend**: Static HTML/CSS served by Nginx
- **Web Server**: Nginx (Alpine Linux)
- **Container Platform**: AWS ECS with Fargate
- **Load Balancer**: Application Load Balancer (ALB)
- **Infrastructure**: Terraform
- **Container Registry**: Amazon ECR
- **Networking**: VPC with public subnets (free tier optimized)
- **Monitoring**: CloudWatch Logs and Metrics

## 🚀 Quick Start

### Option 1: Automated Deployment

Run the deployment script:

```bash
# Linux/Mac
./scripts/deploy.sh

# Windows
scripts\deploy.bat
```

### Option 2: Manual Deployment

1. **Deploy Infrastructure**:
   ```bash
   terraform init
   terraform plan -var-file="dev.tfvars"
   terraform apply -var-file="dev.tfvars"
   ```

2. **Build and Push Docker Image**:
   ```bash
   # Get ECR repository URL from Terraform output
   ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
   
   # Login to ECR
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO_URL
   
   # Build and push
   cd docker
   docker build -t my-app:latest .
   docker tag my-app:latest $ECR_REPO_URL:latest
   docker push $ECR_REPO_URL:latest
   ```

3. **Deploy Application**:
   ```bash
   # Update the app_image in dev_application.tfvars with your ECR image URL
   terraform plan -var-file="dev_application.tfvars"
   terraform apply -var-file="dev_application.tfvars"
   ```

4. **Access Application**:
   ```bash
   # Get the load balancer DNS name
   terraform output alb_dns_name
   ```

## 📁 Project Structure

```
shiny-infra/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Input variables
├── outputs.tf             # Output values
├── ecs.tf                 # ECS cluster and service configuration
├── ecr.tf                 # ECR repository
├── dev.tfvars             # Development environment variables
├── dev_application.tfvars # Application-specific variables
├── docker/
│   ├── Dockerfile         # Multi-stage Docker build
│   ├── docker-compose.yml # Local development
│   ├── nginx.conf         # Nginx configuration
│   └── src/
│       ├── index.html     # Home page
│       └── about.html     # About page
├── modules/
│   ├── vpc/              # VPC module
│   ├── security/         # Security groups
│   ├── alb/              # Application Load Balancer
│   ├── ecs/              # ECS cluster
│   └── application/      # ECS service and task definition
└── scripts/
    ├── deploy.sh         # Deployment script (Linux/Mac)
    └── deploy.bat        # Deployment script (Windows)
```

## 🔧 Configuration

### Environment Variables

Key variables in `dev.tfvars`:
- `aws_region`: AWS region (default: us-east-1)
- `environment`: Environment name (dev/qa/prod)
- `project_name`: Project identifier
- `vpc_cidr`: VPC CIDR block

### Application Variables

Key variables in `dev_application.tfvars`:
- `app_name`: Application name
- `app_image`: Docker image URL
- `app_port`: Container port (80 for nginx)
- `app_cpu`: CPU units (256 for free tier)
- `app_memory`: Memory in MB (512 for free tier)

## 🔍 Monitoring

### Health Checks
- **Container Health**: Docker HEALTHCHECK using wget
- **Load Balancer Health**: ALB health checks on `/health` endpoint
- **Service Health**: ECS service health monitoring

### Logging
- **Application Logs**: CloudWatch Logs group
- **Access Logs**: Nginx access logs
- **Error Logs**: Nginx error logs

### Metrics
- **ECS Metrics**: CPU, memory, task count
- **ALB Metrics**: Request count, latency, errors
- **Custom Metrics**: Application-specific metrics

## 💰 Cost Optimization

This project is optimized for AWS Free Tier:
- **Region**: us-east-1 for best free tier availability
- **Compute**: Minimum Fargate resources (0.25 vCPU, 0.5 GB RAM)
- **Networking**: Public subnets only (no NAT Gateway)
- **Storage**: No persistent storage
- **Monitoring**: Basic CloudWatch metrics only

## 🔒 Security

- **Network Security**: Security groups with minimal required access
- **IAM**: Least privilege IAM roles and policies
- **Container Security**: Non-root user, minimal base image
- **Web Security**: Security headers in nginx configuration
- **Secrets**: AWS Systems Manager Parameter Store integration

## 🧪 Testing

### Local Testing
```bash
cd docker
docker-compose up -d
curl http://localhost/health
```

### Production Testing
```bash
# Health check
curl http://your-alb-dns/health

# Load test (optional)
ab -n 1000 -c 10 http://your-alb-dns/
```

## 🔄 CI/CD

The project is ready for CI/CD integration:
- **GitHub Actions**: Workflow templates included
- **Automated Testing**: Health checks and smoke tests
- **Blue-Green Deployment**: ECS service update strategy
- **Rollback**: Easy rollback using Terraform

## 🐛 Troubleshooting

### Common Issues

1. **ECS Service Not Starting**:
   - Check CloudWatch logs for container errors
   - Verify security group rules
   - Ensure ECR image exists and is accessible

2. **Load Balancer Unhealthy**:
   - Check health check path and port
   - Verify container is listening on correct port
   - Check security group rules

3. **Terraform Errors**:
   - Ensure AWS credentials are configured
   - Check resource limits and quotas
   - Verify region and availability zones

### Debugging Commands

```bash
# View ECS service events
aws ecs describe-services --cluster my-app-dev --services my-app-service

# View container logs
aws logs tail my-app-dev-logs --follow

# Check ALB health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## 📚 Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For issues and questions:
- Create an issue in the GitHub repository
- Check the troubleshooting section
- Review AWS documentation

---

**Note**: This project is configured for learning and demonstration purposes. For production use, consider additional security, monitoring, and scaling configurations.