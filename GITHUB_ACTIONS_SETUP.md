# GitHub Actions Setup Guide

This guide will help you set up the complete CI/CD pipeline for the Shiny Infrastructure project using GitHub Actions.

## 📋 Prerequisites

- GitHub repository with the shiny-infra code
- AWS account with appropriate permissions
- Terraform Cloud account (optional, for remote state)

## 🔧 Initial Setup

### 1. **Configure GitHub Secrets**

Go to your GitHub repository → Settings → Secrets and Variables → Actions, and add:

#### Required Secrets:
```
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

#### Optional Secrets (for enhanced features):
```
TERRAFORM_API_TOKEN=your-terraform-cloud-token
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
```

### 2. **Create AWS IAM User**

Create an IAM user with the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "ecs:*",
                "ecr:*",
                "elbv2:*",
                "logs:*",
                "iam:*",
                "application-autoscaling:*",
                "cloudwatch:*",
                "ce:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### 3. **Configure GitHub Environments**

Create environments in GitHub repository settings:

#### Development Environment (`dev`)
- **Protection Rules**: None (allow any branch)
- **Environment Variables**:
  ```
  AWS_REGION=us-east-1
  ENVIRONMENT=dev
  ```

#### Staging Environment (`staging`) - Optional
- **Protection Rules**: Require reviewers
- **Environment Variables**:
  ```
  AWS_REGION=us-east-1
  ENVIRONMENT=staging
  ```

#### Production Environment (`prod`) - Optional
- **Protection Rules**: 
  - Require reviewers
  - Restrict to `main` branch only
  - Wait timer: 5 minutes
- **Environment Variables**:
  ```
  AWS_REGION=us-east-1
  ENVIRONMENT=prod
  ```

## 🚀 Workflow Overview

### 1. **Main Deployment Pipeline** (`deploy.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Manual dispatch via Actions tab
- Pull requests (validation only)

**Jobs:**
1. **Validate & Plan**: Terraform validation and planning
2. **Build & Push**: Docker image build and ECR push
3. **Deploy Infrastructure**: Terraform apply for base infrastructure
4. **Deploy Application**: ECS service deployment
5. **Notify**: Deployment status notification

**Usage:**
```bash
# Automatic: Push to main/develop
git push origin main

# Manual: Go to Actions tab → Deploy Infrastructure and Application → Run workflow
```

### 2. **Pull Request Validation** (`pr-validation.yml`)

**Triggers:**
- Pull requests to `main` or `develop`

**Jobs:**
1. **Code Quality**: Terraform fmt, validate, shellcheck
2. **Security Scan**: Trivy vulnerability scanning
3. **Build Test**: Docker image build and test
4. **Terraform Plan**: Plan changes and comment on PR

**Benefits:**
- Prevents broken code from merging
- Security vulnerability detection
- Cost impact analysis
- Automated code quality checks

### 3. **Monitoring & Health Checks** (`monitoring.yml`)

**Triggers:**
- Scheduled (every 15 minutes)
- Manual dispatch

**Jobs:**
1. **Application Health**: HTTP health checks
2. **Infrastructure Health**: ECS service and ALB health
3. **Performance Check**: Load testing
4. **Resource Monitoring**: CPU/Memory utilization

**Usage:**
```bash
# Manual: Actions tab → Monitoring and Health Checks → Run workflow
```

### 4. **Cleanup & Cost Management** (`cleanup.yml`)

**Triggers:**
- Scheduled (daily at 2 AM UTC)
- Manual dispatch

**Jobs:**
1. **Cleanup Images**: Remove old ECR images
2. **Cost Report**: Generate AWS cost analysis
3. **Service Control**: Start/stop dev services
4. **Environment Cleanup**: Destroy unused environments

**Usage:**
```bash
# Manual: Actions tab → Cleanup and Cost Management → Run workflow
# Actions: cleanup-old-images, stop-dev-services, start-dev-services, cost-report
```

## 🔄 Development Workflow

### 1. **Feature Development**
```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes
# ... code changes ...

# Push and create PR
git push origin feature/new-feature
# Create PR in GitHub UI
```

### 2. **Pull Request Process**
1. PR validation runs automatically
2. Code review and approval
3. Merge to `develop` branch
4. Automatic deployment to dev environment

### 3. **Production Deployment**
```bash
# Merge develop to main
git checkout main
git merge develop
git push origin main
# Automatic deployment to production
```

## 🎯 Manual Operations

### 1. **Deploy Specific Environment**
```bash
# Go to: Actions → Deploy Infrastructure and Application
# Select: Run workflow
# Choose: Environment (dev/staging/prod)
# Option: Destroy infrastructure (checkbox)
```

### 2. **Cost Management**
```bash
# Go to: Actions → Cleanup and Cost Management
# Select: Run workflow
# Choose: Action type
# Options:
#   - cleanup-old-images: Remove old ECR images
#   - stop-dev-services: Stop development services
#   - start-dev-services: Start development services
#   - cost-report: Generate cost analysis
#   - destroy-dev-environment: Destroy everything
```

### 3. **Health Monitoring**
```bash
# Go to: Actions → Monitoring and Health Checks
# Select: Run workflow
# Choose: Check type (all/application/infrastructure/performance)
```

## 🔍 Monitoring & Alerting

### GitHub Actions Notifications
- Workflow status in GitHub UI
- Email notifications for failures
- Slack integration (if configured)

### Application Monitoring
- Health checks every 15 minutes
- Performance testing reports
- Cost analysis reports

### AWS CloudWatch
- ECS service metrics
- Application Load Balancer metrics
- Container logs

## 🐛 Troubleshooting

### Common Issues

1. **AWS Credentials Error**
   ```
   Error: AccessDenied: User is not authorized to perform...
   ```
   **Solution**: Check IAM permissions and GitHub secrets

2. **Terraform State Lock**
   ```
   Error: Resource already exists
   ```
   **Solution**: Check for existing resources or use `terraform import`

3. **ECR Push Failures**
   ```
   Error: authentication token has expired
   ```
   **Solution**: Check ECR repository exists and permissions are correct

4. **Health Check Failures**
   ```
   Error: Health check failed
   ```
   **Solution**: Check ECS service logs and security groups

### Debugging Commands

```bash
# View workflow logs in GitHub Actions tab
# Check ECS service events
aws ecs describe-services --cluster my-app-dev --services my-app-service

# Check container logs
aws logs tail my-app-dev-logs --follow

# Check load balancer health
aws elbv2 describe-target-health --target-group-arn <arn>
```

## 🔒 Security Best Practices

1. **Use GitHub Environments** for sensitive operations
2. **Limit IAM permissions** to minimum required
3. **Enable branch protection** rules
4. **Require code reviews** for production
5. **Use secrets** for sensitive data
6. **Regular security scanning** with Trivy
7. **Monitor AWS costs** regularly

## 📊 Cost Optimization

1. **Automated cleanup** of old resources
2. **Development environment** start/stop scheduling
3. **Regular cost reports** and analysis
4. **Free tier optimization** configurations
5. **Resource monitoring** and alerts

## 🎨 Customization

### Adding New Workflows
1. Create new `.yml` file in `.github/workflows/`
2. Define triggers and jobs
3. Test with manual dispatch
4. Enable for automatic triggers

### Modifying Existing Workflows
1. Edit workflow files
2. Test changes in feature branch
3. Validate with PR process
4. Merge to main branch

### Environment-Specific Configurations
1. Add environment variables in GitHub
2. Update workflow files as needed
3. Test deployment process
4. Document changes

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [Docker Build Action](https://github.com/docker/build-push-action)

## 🤝 Support

For issues with the CI/CD pipeline:
1. Check GitHub Actions logs
2. Review this setup guide
3. Check AWS console for resource status
4. Create an issue in the repository

---

**Note**: This setup guide assumes you have the necessary permissions and knowledge of AWS, Terraform, and GitHub Actions. Adjust configurations based on your specific requirements.
