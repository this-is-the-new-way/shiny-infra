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
