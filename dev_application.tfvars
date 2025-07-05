# Development Environment Configuration

# General Configuration - Free Tier Optimized
environment  = "dev"
project_name = "my-app"
aws_region   = "us-east-1"  # Use us-east-1 for better free tier availability

# ECS Configuration - Free Tier Optimized
ecs_cluster_name       = "my-app-dev"
ecs_capacity_providers = ["FARGATE"]  # Use only FARGATE for simplicity
ecs_default_capacity_provider_strategy = [
  {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
]

# Application Configuration - Free Tier Optimized
app_name          = "my-app"
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
  # "DATABASE_PASSWORD" = "arn:aws:secretsmanager:us-west-2:123456789012:secret:db-password"
}

# Health Check Configuration - Free Tier Optimized
health_check_path                = "/health"  # Use dedicated health endpoint
health_check_interval            = 30
health_check_timeout             = 5
health_check_healthy_threshold   = 2
health_check_unhealthy_threshold = 3

# Auto Scaling Configuration - Disabled for Free Tier
enable_auto_scaling              = false  # Disable to save costs
auto_scaling_target_cpu          = 70
auto_scaling_target_memory       = 80
auto_scaling_scale_up_cooldown   = 300
auto_scaling_scale_down_cooldown = 600

# Logging Configuration - Free Tier Optimized
log_retention_days        = 1     # Minimum retention to save costs
enable_container_insights = false # Disable to save costs

# Monitoring Configuration
enable_detailed_monitoring = false
# notification_topic_arn   = "arn:aws:sns:us-west-2:123456789012:dev-alerts"

# Additional Tags
additional_tags = {
  Owner       = "development-team"
  Environment = "development"
  CostCenter  = "engineering"
}
