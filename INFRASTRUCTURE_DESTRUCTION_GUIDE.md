# POC Infrastructure Destruction Guide

## Overview

This guide provides instructions for destroying the POC (Proof of Concept) infrastructure using GitHub Actions. This is a simplified process designed for temporary testing environments.

## 🚨 Important Warning

**⚠️ POC INFRASTRUCTURE DESTRUCTION IS IRREVERSIBLE**

This will permanently delete all AWS resources including:
- ECS clusters and services
- Application Load Balancers
- VPC and networking components
- Security groups and CloudWatch logs
- ECR repositories and container images

## Prerequisites

1. **GitHub Repository Access**: Write permissions to the repository
2. **AWS Credentials**: Valid AWS credentials configured as GitHub secrets
3. **Terraform State**: Accessible Terraform state files in the S3 bucket

## GitHub Secrets Required

```
AWS_ACCESS_KEY_ID       # AWS Access Key ID
AWS_SECRET_ACCESS_KEY   # AWS Secret Access Key
```

## Running the Destruction Workflow

### Step 1: Access the Workflow

1. Navigate to your GitHub repository
2. Click on the **Actions** tab
3. Find the **"Destroy POC Infrastructure"** workflow
4. Click **"Run workflow"**

### Step 2: Configure Parameters

- **Environment**: Select the environment to destroy (dev/staging/prod)
- **Confirmation**: Type `DESTROY` (case-sensitive)

### Step 3: Execute the Workflow

1. Fill in the required parameters
2. Click **"Run workflow"**
3. The workflow will begin execution immediately

## Workflow Process

The destruction workflow follows these steps:

1. **Validation** (1 min): Validates confirmation and displays destruction plan
2. **Scale Down** (2 min): Scales ECS services to 0 tasks
3. **ECR Cleanup** (2 min): Deletes container images and repository
4. **Infrastructure Destruction** (5-10 min): Destroys all remaining resources
5. **Summary** (1 min): Provides destruction status report

**Total Duration**: 10-15 minutes

## Post-Destruction

After successful destruction:
- All AWS resources are permanently deleted
- No backups are created (POC environment)
- Infrastructure can be recreated using the main deployment workflow

## Troubleshooting

### Common Issues

1. **Invalid Confirmation**: Ensure you type `DESTROY` exactly (case-sensitive)
2. **AWS Credentials Error**: Verify AWS secrets are configured in GitHub
3. **Resources Not Destroyed**: Check AWS console and manually remove remaining resources

### Manual Cleanup

If some resources remain after the workflow:

1. Check AWS console for remaining resources
2. Delete them manually through the AWS console
3. Focus on: ECS services, Load Balancers, VPC components

## Recreation

To recreate the POC infrastructure after destruction:
1. Use the main deployment workflow
2. Select the same environment
3. Follow the normal deployment process

---

## Quick Reference

### Required Secrets
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

### Workflow Parameters
- Environment: dev/staging/prod
- Confirmation: DESTROY

### S3 Backend
```
Bucket: terrastate-file
Key: shiny-infra/terraform.tfstate
Region: us-east-1
```

---

*This is a simplified POC guide. No backups are created during the destruction process.*
