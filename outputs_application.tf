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
  value       = module.application.service_name
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = module.application.service_arn
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = module.application.task_definition_arn
}

# Application Target Group (from application module)
output "app_target_group_arn" {
  description = "ARN of the application-specific target group"
  value       = module.application.target_group_arn
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
  value       = module.application.log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for the application"
  value       = module.application.log_group_arn
}

# Auto Scaling
output "auto_scaling_target_arn" {
  description = "ARN of the auto scaling target"
  value       = module.application.auto_scaling_target_arn
}

# Monitoring
# output "cloudwatch_dashboard_url" {
#   description = "URL of the CloudWatch dashboard"
#   value       = module.monitoring.dashboard_url
# }

# Security
output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.application.task_execution_role_arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.application.task_role_arn
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
