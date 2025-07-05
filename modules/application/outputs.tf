# ECS Service outputs
output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.app.id
}

output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.app.id
}

# Task Definition outputs
output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "task_definition_family" {
  description = "Family of the ECS task definition"
  value       = aws_ecs_task_definition.app.family
}

output "task_definition_revision" {
  description = "Revision of the ECS task definition"
  value       = aws_ecs_task_definition.app.revision
}

# Target Group outputs
output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.app.arn
}

output "target_group_name" {
  description = "Name of the ALB target group"
  value       = aws_lb_target_group.app.name
}

# IAM Role outputs
output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.task_execution_role.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.task_role.arn
}

# CloudWatch Log Group outputs
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.arn
}

# Auto Scaling outputs
output "auto_scaling_target_arn" {
  description = "ARN of the auto scaling target"
  value       = var.enable_auto_scaling ? aws_appautoscaling_target.app[0].arn : null
}

output "auto_scaling_cpu_policy_arn" {
  description = "ARN of the CPU auto scaling policy"
  value       = var.enable_auto_scaling ? aws_appautoscaling_policy.app_cpu[0].arn : null
}

output "auto_scaling_memory_policy_arn" {
  description = "ARN of the memory auto scaling policy"
  value       = var.enable_auto_scaling ? aws_appautoscaling_policy.app_memory[0].arn : null
}
