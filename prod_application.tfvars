# Production Environment Application Configuration

# General Configuration - Production Optimized
environment  = "prod"
project_name = "base-infra"
aws_region   = "us-east-1"  # Use us-east-1 for better availability

# ECS Configuration - Production Optimized
ecs_cluster_name       = "base-infra-prod"
ecs_capacity_providers = ["FARGATE"]  # Use only FARGATE for production
ecs_default_capacity_provider_strategy = [
  {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
]

# Application Configuration - Production Optimized
app_name          = "base-infra"
app_image         = "nginx:alpine"  # Will be replaced by ECR image after first deployment
app_port          = 80
app_cpu           = 512   # Higher CPU for production (0.5 vCPU)
app_memory        = 1024  # Higher memory for production (1 GB)
app_desired_count = 2     # Multiple instances for HA
app_min_capacity  = 2     # Minimum 2 instances
app_max_capacity  = 10    # Higher scaling limit for production

# Environment Variables - Production Optimized
app_environment_variables = {
  NODE_ENV  = "production"
  LOG_LEVEL = "warn"  # Reduced logging for production
  PORT      = "80"
  ENV       = "production"
}

# Secrets (stored in AWS Secrets Manager)
app_secrets = {
  # These will be created in Secrets Manager
  # "DATABASE_PASSWORD" = "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod-db-password"
  # "API_KEY" = "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod-api-key"
}

# Health Check Configuration - Production Optimized
health_check_path                = "/health"  # Use dedicated health endpoint
health_check_interval            = 30
health_check_timeout             = 10   # Longer timeout for production
health_check_healthy_threshold   = 3    # More strict for production
health_check_unhealthy_threshold = 2

# Auto Scaling Configuration - Enabled for Production
enable_auto_scaling              = true   # Enable for production
auto_scaling_target_cpu          = 70
auto_scaling_target_memory       = 80
auto_scaling_scale_up_cooldown   = 300
auto_scaling_scale_down_cooldown = 600

# Logging Configuration - Production Optimized
log_retention_days        = 30    # Longer retention for production
enable_container_insights = true  # Enable for production monitoring

# Monitoring Configuration - Production Enabled
enable_detailed_monitoring = true
# notification_topic_arn   = "arn:aws:sns:us-east-1:123456789012:prod-alerts"

# Additional Tags - Production
additional_tags = {
  Owner        = "production-team"
  Environment  = "production"
  Purpose      = "production-workload"
  CostCenter   = "production"
  BusinessUnit = "engineering"
  Compliance   = "required"
  DataClass    = "confidential"
  Backup       = "required"
  Monitoring   = "critical"
}
