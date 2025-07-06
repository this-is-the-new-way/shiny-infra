# Testing & Validation Guide
## Multi-Environment Infrastructure Testing

### 🧪 Testing Strategy Overview

This document outlines comprehensive testing strategies for the multi-environment AWS ECS infrastructure, covering infrastructure validation, application testing, and deployment verification.

---

## 🏗️ Infrastructure Testing

### Terraform Validation
```bash
# Validate Terraform configuration
terraform validate

# Format check
terraform fmt -check=true

# Plan verification for each environment
terraform plan -var-file="dev.tfvars" -out=dev-plan
terraform plan -var-file="qa.tfvars" -out=qa-plan
terraform plan -var-file="prod.tfvars" -out=prod-plan
```

### Environment Isolation Tests
```bash
# Test 1: Verify separate VPC CIDRs
terraform output -json | jq '.vpc_cidr.value'

# Test 2: Verify unique ECS cluster names
terraform output -json | jq '.ecs_cluster_name.value'

# Test 3: Verify separate security groups
terraform output -json | jq '.security_group_ids.value'

# Test 4: Verify separate ALB DNS names
terraform output -json | jq '.alb_dns_name.value'
```

### Resource Validation Script
```bash
#!/bin/bash
# infrastructure-test.sh

set -e

ENV=${1:-dev}
echo "Testing $ENV environment..."

# Validate Terraform configuration
terraform validate

# Check required variables
if [ ! -f "${ENV}.tfvars" ]; then
    echo "Error: ${ENV}.tfvars not found"
    exit 1
fi

if [ ! -f "${ENV}_application.tfvars" ]; then
    echo "Error: ${ENV}_application.tfvars not found"
    exit 1
fi

# Plan test
terraform plan -var-file="${ENV}.tfvars" -var-file="${ENV}_application.tfvars" -out="${ENV}-test-plan"

# Validate plan output
if [ $? -eq 0 ]; then
    echo "✅ $ENV environment validation passed"
else
    echo "❌ $ENV environment validation failed"
    exit 1
fi

# Cleanup
rm -f "${ENV}-test-plan"
```

---

## 🐳 Container Testing

### Docker Image Testing
```bash
# Build and test Docker image locally
cd docker

# Build image
docker build -t base-infra:test .

# Test image runs
docker run -d --name test-container -p 8080:80 base-infra:test

# Health check test
curl -f http://localhost:8080/health || echo "Health check failed"
curl -f http://localhost:8080/ || echo "Application not responding"

# Cleanup
docker stop test-container
docker rm test-container
```

### Container Security Testing
```bash
# Scan image for vulnerabilities
docker scan base-infra:test

# Test with security headers
curl -I http://localhost:8080/ | grep -i "security\|x-frame\|x-content"

# Test nginx configuration
docker exec test-container nginx -t
```

---

## 🌐 Application Testing

### Health Endpoint Testing
```bash
#!/bin/bash
# health-test.sh

ALB_URL=${1:-"http://localhost:8080"}

echo "Testing application health..."

# Test health endpoint
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" ${ALB_URL}/health)
if [ "$HEALTH_RESPONSE" -eq 200 ]; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed (HTTP $HEALTH_RESPONSE)"
    exit 1
fi

# Test main page
MAIN_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" ${ALB_URL}/)
if [ "$MAIN_RESPONSE" -eq 200 ]; then
    echo "✅ Main page accessible"
else
    echo "❌ Main page failed (HTTP $MAIN_RESPONSE)"
    exit 1
fi

# Test about page
ABOUT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" ${ALB_URL}/about.html)
if [ "$ABOUT_RESPONSE" -eq 200 ]; then
    echo "✅ About page accessible"
else
    echo "❌ About page failed (HTTP $ABOUT_RESPONSE)"
    exit 1
fi

echo "✅ All application tests passed"
```

### Load Testing
```bash
# Simple load test with Apache Bench
ab -n 1000 -c 10 http://your-alb-url/

# Test with different endpoints
ab -n 500 -c 5 http://your-alb-url/health
ab -n 500 -c 5 http://your-alb-url/about.html
```

---

## 🔧 Deployment Testing

### Pre-Deployment Validation
```bash
#!/bin/bash
# pre-deployment-test.sh

ENV=${1:-dev}
echo "Pre-deployment validation for $ENV..."

# Check AWS credentials
aws sts get-caller-identity > /dev/null || {
    echo "❌ AWS credentials not configured"
    exit 1
}

# Check required files
required_files=(
    "${ENV}.tfvars"
    "${ENV}_application.tfvars"
    "backend-${ENV}.hcl"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Required file $file not found"
        exit 1
    fi
done

# Validate Terraform configuration
terraform validate || {
    echo "❌ Terraform validation failed"
    exit 1
}

# Check ECR repository exists
ECR_REPO=$(aws ecr describe-repositories --repository-names base-infra --query 'repositories[0].repositoryUri' --output text 2>/dev/null)
if [ "$ECR_REPO" == "None" ] || [ -z "$ECR_REPO" ]; then
    echo "⚠️  ECR repository not found - will be created during deployment"
else
    echo "✅ ECR repository exists: $ECR_REPO"
fi

echo "✅ Pre-deployment validation completed"
```

### Post-Deployment Testing
```bash
#!/bin/bash
# post-deployment-test.sh

ENV=${1:-dev}
echo "Post-deployment testing for $ENV..."

# Get ALB URL from Terraform output
ALB_URL=$(terraform output -raw application_url)

if [ -z "$ALB_URL" ]; then
    echo "❌ Could not get ALB URL from Terraform output"
    exit 1
fi

echo "Testing application at: $ALB_URL"

# Wait for ALB to be ready
echo "Waiting for ALB to be ready..."
sleep 60

# Test health endpoint
for i in {1..10}; do
    if curl -f "$ALB_URL/health" > /dev/null 2>&1; then
        echo "✅ Health check passed"
        break
    else
        echo "Attempt $i: Health check failed, retrying..."
        sleep 30
    fi
    
    if [ $i -eq 10 ]; then
        echo "❌ Health check failed after 10 attempts"
        exit 1
    fi
done

# Test main application
if curl -f "$ALB_URL/" > /dev/null 2>&1; then
    echo "✅ Main application accessible"
else
    echo "❌ Main application not accessible"
    exit 1
fi

# Test ECS service
ECS_SERVICE=$(terraform output -raw ecs_service_name)
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name)

SERVICE_STATUS=$(aws ecs describe-services --cluster "$ECS_CLUSTER" --services "$ECS_SERVICE" --query 'services[0].runningCount' --output text)

if [ "$SERVICE_STATUS" -gt 0 ]; then
    echo "✅ ECS service running ($SERVICE_STATUS tasks)"
else
    echo "❌ ECS service not running"
    exit 1
fi

echo "✅ All post-deployment tests passed"
```

---

## 🔍 Monitoring & Alerting Tests

### CloudWatch Logs Testing
```bash
#!/bin/bash
# logs-test.sh

ENV=${1:-dev}
LOG_GROUP="/aws/ecs/base-infra-${ENV}/base-infra-${ENV}"

echo "Testing CloudWatch logs for $ENV..."

# Check if log group exists
if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --query 'logGroups[0].logGroupName' --output text | grep -q "$LOG_GROUP"; then
    echo "✅ Log group exists: $LOG_GROUP"
else
    echo "❌ Log group not found: $LOG_GROUP"
    exit 1
fi

# Check for recent log events
RECENT_LOGS=$(aws logs describe-log-streams --log-group-name "$LOG_GROUP" --order-by LastEventTime --descending --max-items 1 --query 'logStreams[0].lastEventTime' --output text)

if [ "$RECENT_LOGS" != "None" ] && [ -n "$RECENT_LOGS" ]; then
    echo "✅ Recent log events found"
else
    echo "⚠️  No recent log events found"
fi
```

### Metrics Testing
```bash
#!/bin/bash
# metrics-test.sh

ENV=${1:-dev}
CLUSTER_NAME="base-infra-${ENV}"
SERVICE_NAME="base-infra-${ENV}"

echo "Testing CloudWatch metrics for $ENV..."

# Check ECS service metrics
CPU_METRIC=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/ECS \
    --metric-name CPUUtilization \
    --dimensions Name=ServiceName,Value="$SERVICE_NAME" Name=ClusterName,Value="$CLUSTER_NAME" \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average \
    --query 'Datapoints[0].Average' \
    --output text)

if [ "$CPU_METRIC" != "None" ] && [ -n "$CPU_METRIC" ]; then
    echo "✅ CPU metrics available: $CPU_METRIC%"
else
    echo "⚠️  No CPU metrics found (may be normal for new deployment)"
fi

# Check ALB metrics
ALB_ARN=$(terraform output -raw alb_arn)
ALB_SUFFIX=$(echo "$ALB_ARN" | cut -d'/' -f2-)

REQUEST_COUNT=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name RequestCount \
    --dimensions Name=LoadBalancer,Value="$ALB_SUFFIX" \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum \
    --query 'Datapoints[0].Sum' \
    --output text)

if [ "$REQUEST_COUNT" != "None" ] && [ -n "$REQUEST_COUNT" ]; then
    echo "✅ ALB request metrics available: $REQUEST_COUNT requests"
else
    echo "⚠️  No ALB request metrics found"
fi
```

---

## 🚀 Automated Testing Pipeline

### GitHub Actions Test Workflow
```yaml
name: Infrastructure Testing

on:
  pull_request:
    branches: [ main, develop ]
  push:
    branches: [ main, develop ]

jobs:
  terraform-test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, qa, prod]
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.11.0
    
    - name: Terraform Init
      run: terraform init -backend-config="backend-${{ matrix.environment }}.hcl"
    
    - name: Terraform Validate
      run: terraform validate
    
    - name: Terraform Plan
      run: terraform plan -var-file="${{ matrix.environment }}.tfvars" -var-file="${{ matrix.environment }}_application.tfvars"
    
    - name: Test Configuration
      run: |
        echo "Testing ${{ matrix.environment }} configuration..."
        # Add specific tests here
```

### Complete Test Suite
```bash
#!/bin/bash
# complete-test-suite.sh

ENV=${1:-dev}
echo "Running complete test suite for $ENV environment..."

# Pre-deployment tests
echo "1. Running pre-deployment tests..."
./scripts/pre-deployment-test.sh "$ENV"

# Infrastructure tests
echo "2. Running infrastructure tests..."
./scripts/infrastructure-test.sh "$ENV"

# Container tests
echo "3. Running container tests..."
./scripts/container-test.sh

# If deployment exists, run post-deployment tests
if terraform output alb_dns_name > /dev/null 2>&1; then
    echo "4. Running post-deployment tests..."
    ./scripts/post-deployment-test.sh "$ENV"
    
    echo "5. Running application tests..."
    ./scripts/health-test.sh "$(terraform output -raw application_url)"
    
    echo "6. Running monitoring tests..."
    ./scripts/logs-test.sh "$ENV"
    ./scripts/metrics-test.sh "$ENV"
else
    echo "4. Skipping post-deployment tests (no deployment found)"
fi

echo "✅ All tests completed successfully!"
```

---

## 📋 Test Checklist

### Pre-Deployment
- [ ] Terraform configuration validation
- [ ] Required files exist
- [ ] AWS credentials configured
- [ ] ECR repository accessible
- [ ] Variable files syntax check

### Infrastructure
- [ ] VPC CIDR uniqueness
- [ ] Security group configuration
- [ ] IAM role permissions
- [ ] Load balancer configuration
- [ ] ECS cluster settings

### Application
- [ ] Docker image builds successfully
- [ ] Container starts and runs
- [ ] Health endpoint responds
- [ ] All pages accessible
- [ ] Security headers present

### Post-Deployment
- [ ] ALB accessible
- [ ] ECS service running
- [ ] CloudWatch logs flowing
- [ ] Metrics collection working
- [ ] Auto-scaling configured (prod)

### Security
- [ ] Security groups restrictive
- [ ] IAM roles minimal permissions
- [ ] Secrets not in plain text
- [ ] HTTPS redirect configured
- [ ] Container image scanning

---

## 🔧 Testing Tools & Commands

### Quick Test Commands
```bash
# Test all environments
for env in dev qa prod; do
    echo "Testing $env..."
    ./scripts/complete-test-suite.sh "$env"
done

# Test specific component
./scripts/infrastructure-test.sh dev
./scripts/container-test.sh
./scripts/health-test.sh "http://your-alb-url"

# Continuous testing
watch -n 30 './scripts/health-test.sh "$(terraform output -raw application_url)"'
```

### Monitoring Commands
```bash
# Monitor deployment
watch 'aws ecs describe-services --cluster base-infra-dev --services base-infra-dev --query "services[0].runningCount"'

# Monitor logs
aws logs tail /aws/ecs/base-infra-dev/base-infra-dev --follow

# Monitor metrics
aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ServiceName,Value=base-infra-dev Name=ClusterName,Value=base-infra-dev --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Average
```

---

**Note**: This testing framework ensures comprehensive validation of the multi-environment infrastructure, from development through production deployment.
