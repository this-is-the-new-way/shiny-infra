# QA Environment Configuration

# General Configuration - Free Tier Optimized
environment  = "qa"
project_name = "base-infra"
aws_region   = "us-east-1"  # Use us-east-1 for better free tier availability

# Application deployment flag - FALSE for base infrastructure
deploy_application = false

# VPC Configuration - Free Tier Optimized
vpc_cidr                    = "10.1.0.0/16"  # Different CIDR for QA
public_subnet_cidrs         = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs        = ["10.1.3.0/24", "10.1.4.0/24"]
availability_zones          = ["us-east-1a", "us-east-1b"]
enable_dns_hostnames        = true
enable_dns_support          = true
enable_nat_gateway          = false  # Disable for cost savings
single_nat_gateway          = true   # Use single NAT if enabled

# Security Configuration
allowed_cidr_blocks = ["0.0.0.0/0"]  # Restrict in production

# ALB Configuration - Free Tier Optimized
alb_name                    = "base-infra-qa-alb"
alb_type                    = "application"
alb_scheme                  = "internet-facing"
alb_ip_address_type         = "ipv4"
enable_deletion_protection  = false  # Disable for easy teardown
enable_cross_zone_load_balancing = true
enable_http2                = true
idle_timeout                = 60
drop_invalid_header_fields  = true

# Target Group Configuration
target_group_name           = "base-infra-qa-tg"
target_group_port           = 80
target_group_protocol       = "HTTP"
target_group_type           = "ip"
health_check_enabled        = true
health_check_healthy_threshold   = 2
health_check_unhealthy_threshold = 2
health_check_timeout             = 5
health_check_interval            = 30
health_check_path               = "/health"
health_check_matcher            = "200"
health_check_protocol           = "HTTP"
health_check_port               = "traffic-port"

# ECS Configuration - Free Tier Optimized
ecs_cluster_name       = "base-infra-qa"
ecs_capacity_providers = ["FARGATE"]  # Use only FARGATE for simplicity
ecs_default_capacity_provider_strategy = [
  {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
]

# Container Insights - Disabled for Free Tier
container_insights = "disabled"

# ECR Configuration
ecr_repository_name         = "base-infra"  # Shared with dev
ecr_image_tag_mutability    = "MUTABLE"
ecr_scan_on_push            = true
ecr_encryption_type         = "AES256"
ecr_lifecycle_policy        = {
  rules = [
    {
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["qa-"]
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }
  ]
}

# Common Tags
common_tags = {
  Project     = "base-infra"
  Environment = "qa"
  ManagedBy   = "Terraform"
  Owner       = "DevOps Team"
  CreatedDate = "2025-07-05"
  Purpose     = "QA Environment"
  CostCenter  = "engineering"
}
