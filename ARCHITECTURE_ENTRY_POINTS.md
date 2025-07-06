# Architecture & Entry Points Guide
## Technical Project Deep Dive - Code Structure Analysis

### 🏗️ System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           INTERNET                                      │
└─────────────────────────┬───────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    APPLICATION LOAD BALANCER                           │
│                         (ALB)                                          │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │   HTTP:80   │    │  HTTPS:443  │    │ Health Check │                 │
│  │   Listener  │    │   Listener  │    │   /health    │                 │
│  └─────────────┘    └─────────────┘    └─────────────┘                 │
└─────────────────────────┬───────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      ECS FARGATE SERVICE                               │
│                                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │    Task 1   │    │    Task 2   │    │    Task N   │                 │
│  │             │    │             │    │             │                 │
│  │  ┌───────┐  │    │  ┌───────┐  │    │  ┌───────┐  │                 │
│  │  │ Nginx │  │    │  │ Nginx │  │    │  │ Nginx │  │                 │
│  │  │ :80   │  │    │  │ :80   │  │    │  │ :80   │  │                 │
│  │  └───────┘  │    │  └───────┘  │    │  └───────┘  │                 │
│  └─────────────┘    └─────────────┘    └─────────────┘                 │
└─────────────────────────┬───────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      CLOUDWATCH LOGS                                   │
│                                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │   Dev Logs  │    │   QA Logs   │    │  Prod Logs  │                 │
│  │  1-day ret  │    │  1-day ret  │    │  30-day ret │                 │
│  └─────────────┘    └─────────────┘    └─────────────┘                 │
└─────────────────────────────────────────────────────────────────────────┘
```

### 🌐 Multi-Environment Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ENVIRONMENT ISOLATION                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐        │
│  │   DEV ENV       │  │   QA ENV        │  │   PROD ENV      │        │
│  │                 │  │                 │  │                 │        │
│  │ VPC: 10.0.0.0/16│  │ VPC: 10.1.0.0/16│  │ VPC: 10.2.0.0/16│        │
│  │ ECS: base-infra-│  │ ECS: base-infra-│  │ ECS: base-infra-│        │
│  │      dev        │  │      qa         │  │      prod       │        │
│  │                 │  │                 │  │                 │        │
│  │ Resources:      │  │ Resources:      │  │ Resources:      │        │
│  │ • 1 Task        │  │ • 1 Task        │  │ • 2+ Tasks      │        │
│  │ • 0.25 vCPU     │  │ • 0.25 vCPU     │  │ • 0.5 vCPU      │        │
│  │ • 0.5 GB RAM    │  │ • 0.5 GB RAM    │  │ • 1 GB RAM      │        │
│  │ • No AutoScale  │  │ • No AutoScale  │  │ • AutoScale     │        │
│  │                 │  │                 │  │                 │        │
│  │ State:          │  │ State:          │  │ State:          │        │
│  │ shiny-infra/    │  │ shiny-infra/    │  │ shiny-infra/    │        │
│  │ dev/terraform.  │  │ qa/terraform.   │  │ prod/terraform. │        │
│  │ tfstate         │  │ tfstate         │  │ tfstate         │        │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘        │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📂 Project Structure & Entry Points

### 🎯 Primary Entry Points

#### 1. **Infrastructure Entry Point**
- **File**: `main.tf`
- **Purpose**: Core infrastructure orchestration
- **Key Components**:
  - VPC module initialization
  - Security groups module
  - Application Load Balancer module
  - Common resource tagging

```terraform
# main.tf - Infrastructure Entry Point
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge({
    Environment = var.environment
    Project     = var.project_name
  }, var.additional_tags)
}

# Core modules orchestration
module "vpc" { source = "./modules/vpc" ... }
module "security" { source = "./modules/security" ... }
module "alb" { source = "./modules/alb" ... }
```

#### 2. **Application Entry Point**
- **File**: `ecs.tf`
- **Purpose**: ECS cluster and application service orchestration
- **Key Components**:
  - ECS cluster configuration
  - Application module initialization
  - Service and task definitions

```terraform
# ecs.tf - Application Entry Point
module "ecs" {
  source = "./modules/ecs"
  cluster_name = local.cluster_name
  # ... ECS configuration
}

module "application" {
  source = "./modules/application"
  # ... Application configuration
}
```

#### 3. **Configuration Entry Points**
- **Files**: `variables.tf`, `*.tfvars`
- **Purpose**: Environment-specific configuration
- **Key Components**:
  - Input variable definitions
  - Environment-specific values
  - Validation rules

### 🔧 Module Architecture

```
modules/
├── vpc/                    # Network Infrastructure Module
│   ├── main.tf            # VPC, subnets, routing
│   ├── variables.tf       # Network configuration vars
│   └── outputs.tf         # Network resource outputs
├── security/               # Security Module
│   ├── main.tf            # Security groups, IAM roles
│   ├── variables.tf       # Security configuration vars
│   └── outputs.tf         # Security resource outputs
├── alb/                   # Load Balancer Module
│   ├── main.tf            # ALB, listeners, target groups
│   ├── variables.tf       # ALB configuration vars
│   └── outputs.tf         # ALB resource outputs
├── ecs/                   # ECS Cluster Module
│   ├── main.tf            # ECS cluster, capacity providers
│   ├── variables.tf       # ECS configuration vars
│   └── outputs.tf         # ECS cluster outputs
└── application/           # Application Service Module
    ├── main.tf            # ECS service, task definition
    ├── variables.tf       # Application configuration vars
    └── outputs.tf         # Application service outputs
```

---

## 🚀 Deployment Flow Analysis

### 1. **GitHub Actions Workflow Entry**
- **File**: `.github/workflows/deploy-poc.yml`
- **Trigger Points**:
  - Push to `main` → Deploy to **dev**
  - Push to `qa` → Deploy to **qa**
  - Push to `prod` → Deploy to **prod**
  - Manual workflow dispatch

### 2. **Terraform Execution Flow**
```
1. terraform init -backend-config="backend-{env}.hcl"
   └── Initializes environment-specific state backend

2. terraform plan -var-file="{env}.tfvars" -var-file="{env}_application.tfvars"
   └── Creates execution plan with environment configs

3. terraform apply
   └── Executes in order:
       ├── VPC Module (networking)
       ├── Security Module (security groups)
       ├── ALB Module (load balancer)
       ├── ECS Module (cluster)
       └── Application Module (services)
```

### 3. **Docker Build & Deploy Flow**
```
1. Docker Build
   └── docker/Dockerfile → Base image with Nginx

2. ECR Push
   └── Tagged with environment (dev, qa, prod)

3. ECS Service Update
   └── Rolling deployment with health checks
```

---

## 🎨 Code Organization Patterns

### 1. **Modular Architecture Pattern**
```
Root Configuration (main.tf, ecs.tf)
├── Calls Modules
├── Passes Environment Variables
├── Manages State
└── Handles Outputs

Modules (./modules/*)
├── Self-contained functionality
├── Reusable across environments
├── Standard input/output interface
└── Environment-agnostic logic
```

### 2. **Environment Configuration Pattern**
```
Base Variables (variables.tf)
├── Default values
├── Validation rules
├── Type definitions
└── Documentation

Environment Variables (*.tfvars)
├── Environment-specific overrides
├── Resource sizing
├── Feature flags
└── Cost optimization settings
```

### 3. **State Management Pattern**
```
Backend Configuration (backend-*.hcl)
├── Environment-specific S3 keys
├── State locking with DynamoDB
├── Encryption at rest
└── Version control integration
```

---

## 🔍 Key Code Entry Points for Interview

### 1. **Architecture Discussion** (Start Here)
```terraform
# main.tf - Line 1-20
# Shows overall architecture and module orchestration
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge({
    Environment = var.environment
    Project     = var.project_name
  }, var.additional_tags)
}
```

### 2. **Environment Isolation** (Core Feature)
```terraform
# variables.tf - Line 7-16
# Shows environment validation and configuration
variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, prod."
  }
}
```

### 3. **Security Implementation** (Security Focus)
```terraform
# modules/security/main.tf - Line 1-30
# Shows security group configuration
resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-"
  description = "Security group for Application Load Balancer"
  # ... security rules
}
```

### 4. **Container Orchestration** (ECS Focus)
```terraform
# modules/application/main.tf - Line 120-170
# Shows ECS task definition and service configuration
resource "aws_ecs_task_definition" "app" {
  family                   = local.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  # ... container configuration
}
```

### 5. **Auto-scaling Configuration** (Scalability)
```terraform
# modules/application/main.tf - Line 270-300
# Shows auto-scaling policies
resource "aws_appautoscaling_policy" "app_cpu" {
  name               = "${local.service_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  # ... scaling configuration
}
```

---

## 📊 Data Flow Analysis

### 1. **Configuration Data Flow**
```
Environment Variables (*.tfvars)
├── Passed to main.tf
├── Distributed to modules
├── Transformed by locals
└── Applied to resources
```

### 2. **Network Data Flow**
```
Internet → ALB (Public Subnets)
├── Target Group Health Checks
├── Load Balancing Algorithm
├── Forward to ECS Tasks
└── Response path optimization
```

### 3. **Container Data Flow**
```
ECR Repository → ECS Task Definition
├── Container Image Pull
├── Environment Variable Injection
├── Secrets Manager Integration
└── CloudWatch Logs Streaming
```

---

## 🎯 Interview Code Walk-through Strategy

### 1. **Start with Architecture Overview** (5 minutes)
- Show `main.tf` structure
- Explain module relationships
- Highlight environment isolation

### 2. **Dive into Modules** (10 minutes)
- Walk through `modules/vpc/main.tf`
- Show `modules/application/main.tf`
- Explain resource dependencies

### 3. **Configuration Management** (10 minutes)
- Compare `dev.tfvars` vs `prod.tfvars`
- Show environment-specific settings
- Explain cost optimization

### 4. **Deployment Pipeline** (10 minutes)
- Show GitHub Actions workflow
- Explain state management
- Demonstrate environment promotion

### 5. **Security & Scalability** (5 minutes)
- Review security groups
- Show auto-scaling configuration
- Explain monitoring setup

---

## 🔧 Quick Code Navigation Commands

### VS Code Navigation
```bash
# Jump to main entry points
code main.tf                           # Infrastructure entry
code ecs.tf                            # Application entry
code variables.tf                      # Configuration entry
code .github/workflows/deploy-poc.yml  # CI/CD entry
```

### Search for Key Patterns
```bash
# Find security configurations
grep -r "aws_security_group" modules/

# Find auto-scaling settings
grep -r "auto_scaling" .

# Find environment-specific configs
grep -r "environment" *.tfvars
```

### Module Dependency Analysis
```bash
# Show module call hierarchy
grep -r "module\s" *.tf

# Show variable passing
grep -r "var\." modules/
```

---

**Note**: This guide provides a comprehensive roadmap for navigating the codebase during a technical interview, highlighting key architectural decisions and implementation patterns.
