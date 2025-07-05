# ECS Configuration
variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

# Application Configuration
variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "app_image" {
  description = "Docker image for the application"
  type        = string
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 80
}

variable "app_cpu" {
  description = "CPU units for the application task"
  type        = number
  default     = 256
}

variable "app_memory" {
  description = "Memory (MB) for the application task"
  type        = number
  default     = 512
}

variable "app_desired_count" {
  description = "Desired number of application tasks"
  type        = number
  default     = 1  # Free tier optimized - single instance
}

variable "app_min_capacity" {
  description = "Minimum number of application tasks for auto scaling"
  type        = number
  default     = 1
}

variable "app_max_capacity" {
  description = "Maximum number of application tasks for auto scaling"
  type        = number
  default     = 2  # Free tier optimized - limited scaling
}

# Environment Configuration
variable "environment_variables" {
  description = "Environment variables for the application"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets for the application (stored in AWS Secrets Manager)"
  type        = map(string)
  default     = {}
}

# Networking
variable "vpc_id" {
  description = "VPC ID for the target group"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the ECS service"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for the ECS service"
  type        = list(string)
}

# Load Balancer Integration
variable "alb_listener_arn" {
  description = "ARN of the ALB listener to attach the target group"
  type        = string
}

# Health Check Configuration
variable "health_check_path" {
  description = "Health check path for the application"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks"
  type        = number
  default     = 3
}

# Auto Scaling Configuration
variable "enable_auto_scaling" {
  description = "Enable auto scaling for the ECS service"
  type        = bool
  default     = false  # Free tier optimized - disabled by default
}

variable "auto_scaling_target_cpu" {
  description = "Target CPU utilization for auto scaling"
  type        = number
  default     = 70
}

variable "auto_scaling_target_memory" {
  description = "Target memory utilization for auto scaling"
  type        = number
  default     = 80
}

variable "auto_scaling_scale_up_cooldown" {
  description = "Cooldown period after scaling up (seconds)"
  type        = number
  default     = 300
}

variable "auto_scaling_scale_down_cooldown" {
  description = "Cooldown period after scaling down (seconds)"
  type        = number
  default     = 300
}

# Logging Configuration
variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 1  # Free tier optimized - minimum retention
}

# Environment and Tags
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
