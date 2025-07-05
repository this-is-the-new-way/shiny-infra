# POC Setup Guide

## Quick Start

This is a simplified POC (Proof of Concept) project for deploying a containerized web application on AWS ECS.

### Prerequisites

- AWS Account with appropriate permissions
- GitHub repository with this code
- AWS CLI configured locally (optional)

### Setup Steps

#### 1. Configure GitHub Secrets

Add these secrets to your GitHub repository:

```
Settings → Secrets and variables → Actions → New repository secret
```

**Required Secrets:**
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

#### 2. Deploy the Infrastructure

**Option A: Automatic Deployment**
- Push code to `main` or `develop` branch
- GitHub Actions will automatically deploy

**Option B: Manual Deployment**
- Go to **Actions** tab in GitHub
- Select **"Deploy POC Infrastructure"**
- Click **"Run workflow"**
- Choose environment (dev/staging/prod)

#### 3. Access Your Application

After deployment completes:
- Check the workflow summary for the application URL
- Visit `http://your-alb-dns-name/` to see your application

### Destruction

To completely remove all resources:

1. Go to **Actions** tab
2. Select **"Destroy POC Infrastructure"**
3. Click **"Run workflow"**
4. Choose the environment
5. Type `DESTROY` in the confirmation field
6. Click **"Run workflow"**

### File Structure

```
shiny-infra/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variables
├── dev.tfvars                 # Development environment config
├── dev_application.tfvars     # Application config
├── docker/
│   ├── Dockerfile            # Docker image configuration
│   ├── nginx.conf            # Nginx configuration
│   └── src/                  # Static web content
├── .github/workflows/
│   ├── deploy-poc.yml        # Deployment workflow
│   ├── destroy-infrastructure.yml # Destruction workflow
│   └── pr-validation.yml     # PR validation
└── modules/                   # Terraform modules
```

### Cost Optimization

This POC is configured for AWS Free Tier:
- Minimal ECS Fargate resources
- Public subnets (no NAT Gateway)
- Basic monitoring only

### Support

For issues:
- Check GitHub Actions logs for deployment errors
- Review AWS console for resource status
- Ensure AWS credentials are correctly configured

---

*This is a POC project - keep it simple and focused on learning!*
