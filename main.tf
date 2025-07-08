# Main Terraform configuration for Base Infrastructure
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge({
    Environment = var.environment
    Project     = var.project_name
  }, var.additional_tags)
}

# VPC Module - Create during base infrastructure deployment
module "vpc" {
  count  = var.deploy_base_infrastructure ? 1 : 0
  source = "./modules/vpc"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  enable_flow_logs     = var.enable_flow_logs

  tags = local.common_tags
}

# Security Groups Module - Create during base infrastructure deployment
module "security" {
  count  = var.deploy_base_infrastructure ? 1 : 0
  source = "./modules/security"

  name_prefix = local.name_prefix
  vpc_id      = var.deploy_base_infrastructure ? module.vpc[0].vpc_id : null
  vpc_cidr    = var.vpc_cidr

  # IP-based access control
  enable_restricted_access = var.enable_restricted_access
  allowed_ip_addresses     = var.allowed_ip_addresses

  tags = local.common_tags
}

# Application Load Balancer Module - Create during base infrastructure deployment
module "alb" {
  count  = var.deploy_base_infrastructure ? 1 : 0
  source = "./modules/alb"

  name_prefix        = local.name_prefix
  vpc_id             = var.deploy_base_infrastructure ? module.vpc[0].vpc_id : null
  public_subnet_ids  = var.deploy_base_infrastructure ? module.vpc[0].public_subnet_ids : null
  security_group_ids = var.deploy_base_infrastructure ? [module.security[0].alb_security_group_id] : null

  internal                         = var.alb_internal
  deletion_protection              = var.alb_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  idle_timeout                     = var.alb_idle_timeout

  health_check_path                = var.health_check_path
  health_check_enabled             = var.health_check_enabled
  health_check_healthy_threshold   = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold
  health_check_timeout             = var.health_check_timeout
  health_check_interval            = var.health_check_interval
  health_check_matcher             = var.health_check_matcher

  tags = local.common_tags
}
