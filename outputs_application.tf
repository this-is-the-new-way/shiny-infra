# ECS Cluster outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

# ECS Service outputs
output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = var.deploy_application ? module.application_conditional[0].service_name : null
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = var.deploy_application ? module.application_conditional[0].service_arn : null
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = var.deploy_application ? module.application_conditional[0].task_definition_arn : null
}

# Application Target Group (from application module)
output "app_target_group_arn" {
  description = "ARN of the application-specific target group"
  value       = var.deploy_application ? module.application_conditional[0].target_group_arn : null
}

# Application URL
output "application_url" {
  description = "URL of the application"
  value       = "http://${local.alb_dns_name}"
}

output "application_https_url" {
  description = "HTTPS URL of the application (if SSL is configured)"
  value       = "https://${local.alb_dns_name}"
}

# CloudWatch Log Group
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for the application"
  value       = var.deploy_application ? module.application_conditional[0].log_group_name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for the application"
  value       = var.deploy_application ? module.application_conditional[0].log_group_arn : null
}

# Auto Scaling
output "auto_scaling_target_arn" {
  description = "ARN of the auto scaling target"
  value       = var.deploy_application ? module.application_conditional[0].auto_scaling_target_arn : null
}

# Monitoring
# output "cloudwatch_dashboard_url" {
#   description = "URL of the CloudWatch dashboard"
#   value       = module.monitoring.dashboard_url
# }

# Security
output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = var.deploy_application ? module.application_conditional[0].task_execution_role_arn : null
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = var.deploy_application ? module.application_conditional[0].task_role_arn : null
}

# Base Infrastructure References
output "base_infra_vpc_id" {
  description = "VPC ID from base infrastructure"
  value       = local.vpc_id
}

output "base_infra_alb_dns_name" {
  description = "ALB DNS name from base infrastructure"
  value       = local.alb_dns_name
}
