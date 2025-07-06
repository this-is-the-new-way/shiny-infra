# Base Infrastructure Outputs

# VPC Outputs - Only available during base infrastructure deployment
output "vpc_id" {
  description = "ID of the VPC"
  value       = var.deploy_application ? null : module.vpc[0].vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = var.deploy_application ? null : module.vpc[0].vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = var.deploy_application ? null : module.vpc[0].public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = var.deploy_application ? null : module.vpc[0].private_subnet_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = var.deploy_application ? null : module.vpc[0].internet_gateway_id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = var.deploy_application ? null : module.vpc[0].nat_gateway_ids
}

# Security Group Outputs - Only available during base infrastructure deployment
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = var.deploy_application ? null : module.security[0].alb_security_group_id
}

output "ecs_security_group_id" {
  description = "ID of the ECS security group"
  value       = var.deploy_application ? null : module.security[0].app_security_group_id
}

# Application Load Balancer Outputs - Only available during base infrastructure deployment
output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = var.deploy_application ? null : module.alb[0].alb_arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.deploy_application ? null : module.alb[0].alb_dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer"
  value       = var.deploy_application ? null : module.alb[0].alb_zone_id
}

output "alb_listener_arn" {
  description = "ARN of the ALB listener"
  value       = var.deploy_application ? null : module.alb[0].alb_listener_arn
}

output "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  value       = var.deploy_application ? null : module.alb[0].target_group_arn
}

# Environment Information - Always available
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}
