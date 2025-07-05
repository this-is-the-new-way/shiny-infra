# Local values for common configurations
locals {
  cluster_name = var.ecs_cluster_name != null ? var.ecs_cluster_name : "${var.project_name}-${var.environment}"
}

# ECS Cluster Module
module "ecs" {
  source = "./modules/ecs"

  cluster_name                       = local.cluster_name
  capacity_providers                 = var.ecs_capacity_providers
  default_capacity_provider_strategy = var.ecs_default_capacity_provider_strategy
  enable_container_insights          = var.enable_container_insights

  tags = local.common_tags
}

# Application Module
module "application" {
  source = "./modules/application"

  # ECS Configuration
  cluster_id   = module.ecs.cluster_id
  cluster_name = module.ecs.cluster_name

  # Application Configuration
  app_name              = var.app_name
  app_image             = var.app_image
  app_port              = var.app_port
  app_cpu               = var.app_cpu
  app_memory            = var.app_memory
  app_desired_count     = var.app_desired_count
  app_min_capacity      = var.app_min_capacity
  app_max_capacity      = var.app_max_capacity
  environment_variables = var.app_environment_variables
  secrets               = var.app_secrets

  # Networking - Free Tier Optimized (use public subnets)
  vpc_id             = local.vpc_id
  private_subnet_ids = local.public_subnet_ids  # Use public subnets to avoid NAT Gateway costs
  security_group_ids = [local.ecs_security_group_id]

  # Load Balancer Integration
  alb_listener_arn                 = local.alb_listener_arn
  health_check_path                = var.health_check_path
  health_check_interval            = var.health_check_interval
  health_check_timeout             = var.health_check_timeout
  health_check_healthy_threshold   = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold

  # Auto Scaling
  enable_auto_scaling              = var.enable_auto_scaling
  auto_scaling_target_cpu          = var.auto_scaling_target_cpu
  auto_scaling_target_memory       = var.auto_scaling_target_memory
  auto_scaling_scale_up_cooldown   = var.auto_scaling_scale_up_cooldown
  auto_scaling_scale_down_cooldown = var.auto_scaling_scale_down_cooldown

  # Logging
  log_retention_days = var.log_retention_days

  # Environment and Tags
  environment  = var.environment
  project_name = var.project_name
  tags         = local.common_tags
}
