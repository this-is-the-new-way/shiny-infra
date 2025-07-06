# Application-specific Terraform configuration
# This file is only applied when using *_application.tfvars files

# Data sources to reference base infrastructure resources
data "aws_ecs_cluster" "main" {
  cluster_name = "${var.project_name}-${var.environment}"
}

data "aws_vpc" "main" {
  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  tags = {
    Name = "*public*"
  }
}

data "aws_security_group" "ecs" {
  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-sg"
  }
}

data "aws_lb_listener" "main" {
  load_balancer_arn = data.aws_lb.main.arn
  port              = 80
}

data "aws_lb" "main" {
  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# Local values for application configuration
locals {
  app_name_prefix = "${var.project_name}-${var.environment}"
  
  app_common_tags = merge({
    Environment = var.environment
    Project     = var.project_name
    Component   = "application"
  }, var.additional_tags)
}

# Application Module - Only deployed during application phase
module "application" {
  source = "./modules/application"

  # ECS Configuration
  cluster_id   = data.aws_ecs_cluster.main.id
  cluster_name = data.aws_ecs_cluster.main.cluster_name

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
  vpc_id             = data.aws_vpc.main.id
  private_subnet_ids = data.aws_subnets.public.ids  # Use public subnets to avoid NAT Gateway costs
  security_group_ids = [data.aws_security_group.ecs.id]

  # Load Balancer Integration
  alb_listener_arn                 = data.aws_lb_listener.main.arn
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
  tags         = local.app_common_tags
}
