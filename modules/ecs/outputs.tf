output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "exec_log_group_name" {
  description = "Name of the CloudWatch log group for ECS exec"
  value       = aws_cloudwatch_log_group.ecs_exec.name
}

output "exec_log_group_arn" {
  description = "ARN of the CloudWatch log group for ECS exec"
  value       = aws_cloudwatch_log_group.ecs_exec.arn
}
