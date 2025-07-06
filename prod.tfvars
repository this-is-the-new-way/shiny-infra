# Production Environment Configuration

# General Configuration - Production Optimized
environment  = "prod"
project_name = "base-infra"
aws_region   = "us-east-1"  # Use us-east-1 for better availability

# Application deployment flag - FALSE for base infrastructure
deploy_application = false

# VPC Configuration - Production Optimized
vpc_cidr                    = "10.2.0.0/16"  # Different CIDR for Production
public_subnet_cidrs         = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnet_cidrs        = ["10.2.3.0/24", "10.2.4.0/24"]
availability_zones          = ["us-east-1a", "us-east-1b"]
enable_dns_hostnames        = true
enable_dns_support          = true
enable_nat_gateway          = true   # Enable for production security
single_nat_gateway          = false  # Use multiple NAT gateways for HA

# Security Configuration - Production Restricted
allowed_cidr_blocks = ["0.0.0.0/0"]  # Should be restricted in real production

# ALB Configuration - Production Optimized
alb_name                    = "base-infra-prod-alb"
alb_type                    = "application"
alb_scheme                  = "internet-facing"
alb_ip_address_type         = "ipv4"
enable_deletion_protection  = true   # Enable for production
enable_cross_zone_load_balancing = true
enable_http2                = true
idle_timeout                = 300    # Higher timeout for production
drop_invalid_header_fields  = true

# Target Group Configuration - Production Optimized
target_group_name           = "base-infra-prod-tg"
target_group_port           = 80
target_group_protocol       = "HTTP"
target_group_type           = "ip"
health_check_enabled        = true
health_check_healthy_threshold   = 3   # More strict for production
health_check_unhealthy_threshold = 2
health_check_timeout             = 10  # Longer timeout for production
health_check_interval            = 30
health_check_path               = "/health"
health_check_matcher            = "200"
health_check_protocol           = "HTTP"
health_check_port               = "traffic-port"

# ECS Configuration - Production Optimized
ecs_cluster_name       = "base-infra-prod"
ecs_capacity_providers = ["FARGATE"]  # Use FARGATE for production
ecs_default_capacity_provider_strategy = [
  {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
]

# Container Insights - Enabled for Production
container_insights = "enabled"

# ECR Configuration - Production Optimized
ecr_repository_name         = "base-infra"  # Shared with dev and qa
ecr_image_tag_mutability    = "IMMUTABLE"   # Immutable for production
ecr_scan_on_push            = true
ecr_encryption_type         = "AES256"
ecr_lifecycle_policy        = {
  rules = [
    {
      rulePriority = 1
      description  = "Keep last 20 production images"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["prod-"]
        countType     = "imageCountMoreThan"
        countNumber   = 20
      }
      action = {
        type = "expire"
      }
    },
    {
      rulePriority = 2
      description  = "Keep last 5 latest images"
      selection = {
        tagStatus   = "tagged"
        tagPrefixList = ["latest"]
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }
  ]
}

# Common Tags - Production
common_tags = {
  Project      = "base-infra"
  Environment  = "prod"
  ManagedBy    = "Terraform"
  Owner        = "DevOps Team"
  CreatedDate  = "2025-07-05"
  Purpose      = "Production Environment"
  CostCenter   = "production"
  BusinessUnit = "engineering"
  Compliance   = "required"
}
