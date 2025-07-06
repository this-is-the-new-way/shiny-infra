# Local values for referencing infrastructure resources
# Use data sources when deploy_application is true, use module outputs when false
locals {
  # VPC and Networking
  vpc_id             = var.deploy_application ? data.aws_vpc.app[0].id : module.vpc[0].vpc_id
  private_subnet_ids = var.deploy_application ? data.aws_subnets.private[0].ids : module.vpc[0].private_subnet_ids
  public_subnet_ids  = var.deploy_application ? data.aws_subnets.public[0].ids : module.vpc[0].public_subnet_ids

  # Security Groups
  ecs_security_group_id = var.deploy_application ? data.aws_security_group.ecs[0].id : module.security[0].app_security_group_id
  alb_security_group_id = var.deploy_application ? data.aws_security_group.alb[0].id : module.security[0].alb_security_group_id

  # Load Balancer
  alb_arn          = var.deploy_application ? data.aws_lb.main[0].arn : module.alb[0].alb_arn
  alb_dns_name     = var.deploy_application ? data.aws_lb.main[0].dns_name : module.alb[0].alb_dns_name
  alb_zone_id      = var.deploy_application ? data.aws_lb.main[0].zone_id : module.alb[0].alb_zone_id
  alb_listener_arn = var.deploy_application ? data.aws_lb_listener.main[0].arn : module.alb[0].alb_listener_arn

  # Route53 (if available) - set to null for now
  route53_zone_id   = null
  route53_zone_name = null
}

# Data sources for existing infrastructure when deploying applications
data "aws_vpc" "app" {
  count = var.deploy_application ? 1 : 0
  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

data "aws_subnets" "private" {
  count = var.deploy_application ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.app[0].id]
  }
  tags = {
    Type = "private"
  }
}

data "aws_subnets" "public" {
  count = var.deploy_application ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.app[0].id]
  }
  tags = {
    Type = "public"
  }
}

data "aws_security_group" "ecs" {
  count = var.deploy_application ? 1 : 0
  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-sg"
  }
}

data "aws_security_group" "alb" {
  count = var.deploy_application ? 1 : 0
  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

data "aws_lb" "main" {
  count = var.deploy_application ? 1 : 0
  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# ECS Cluster data source for application deployment
data "aws_ecs_cluster" "main" {
  count        = var.deploy_application ? 1 : 0
  cluster_name = "${var.project_name}-${var.environment}"
}

data "aws_lb_listener" "main" {
  count             = var.deploy_application ? 1 : 0
  load_balancer_arn = data.aws_lb.main[0].arn
  port              = 80
}
