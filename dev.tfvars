# Development environment configuration - Free Tier Optimized
environment = "dev"
aws_region  = "us-east-1"  # Use us-east-1 for better free tier availability

# Project configuration
project_name = "base-infra"

# Application deployment flag - FALSE for base infrastructure
deploy_application = false

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
