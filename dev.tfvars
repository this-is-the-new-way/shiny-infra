# Development environment configuration - Free Tier Optimized
environment = "dev"
aws_region  = "us-east-1"  # Use us-east-1 for better free tier availability

# Project configuration
project_name = "base-infra"

# Application deployment flag - UNIFIED deployment (both infra and app)
deploy_application = true
deploy_base_infrastructure = true

# Network configuration - Free Tier Optimized
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]  # Updated for us-east-1
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# NAT Gateway configuration - Free Tier Optimized
enable_nat_gateway = false  # Disable NAT Gateway to save costs (use public subnets for ECS tasks)
single_nat_gateway = true   # Keep this for when NAT is enabled

# DNS configuration
enable_dns_hostnames = true
enable_dns_support   = true

# VPC Flow Logs (disabled for dev to save costs)
enable_flow_logs = false

# ALB configuration
alb_internal                     = false
alb_deletion_protection          = false
enable_cross_zone_load_balancing = true
alb_idle_timeout                 = 60

# Health check configuration - Free Tier Optimized
health_check_path                = "/"     # Use root path for nginx
health_check_enabled             = true
health_check_healthy_threshold   = 2
health_check_unhealthy_threshold = 2
health_check_timeout             = 5
health_check_interval            = 30
health_check_matcher             = "200"

# Additional tags
additional_tags = {
  Owner       = "development-team"
  Environment = "development"
  Purpose     = "testing"
}

# ECS Configuration - Free Tier Optimized
ecs_cluster_name       = "base-infra-dev"
ecs_capacity_providers = ["FARGATE"]  # Use only FARGATE for simplicity
ecs_default_capacity_provider_strategy = [
  {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
]

# Application Configuration - Free Tier Optimized
app_name          = "base-infra"
app_image         = "nginx:alpine"  # Will be replaced by ECR image after first deployment
app_port          = 80
app_cpu           = 256   # Minimum CPU for Fargate (0.25 vCPU)
app_memory        = 512   # Minimum memory for Fargate (0.5 GB)
app_desired_count = 1     # Single instance to minimize costs
app_min_capacity  = 1
app_max_capacity  = 2     # Keep scaling minimal

# Environment Variables - Free Tier Optimized
app_environment_variables = {
  NODE_ENV  = "development"
  LOG_LEVEL = "info"  # Reduced logging to save on CloudWatch costs
  PORT      = "80"
}

# Secrets (stored in AWS Secrets Manager)
app_secrets = {
  # These will be created in Secrets Manager
  # "DATABASE_PASSWORD" = "arn:aws:secretsmanager:us-east-1:123456789012:secret:dev-db-password"
}

# Auto Scaling Configuration - Disabled for Free Tier
enable_auto_scaling              = false  # Disable to save costs
auto_scaling_target_cpu          = 70
auto_scaling_target_memory       = 80
auto_scaling_scale_up_cooldown   = 300
auto_scaling_scale_down_cooldown = 600

# Logging Configuration - Free Tier Optimized
log_retention_days        = 3     # Short retention for dev
enable_container_insights = false # Disable to save costs

# Monitoring Configuration
enable_detailed_monitoring = false
# notification_topic_arn   = "arn:aws:sns:us-east-1:123456789012:dev-alerts"
