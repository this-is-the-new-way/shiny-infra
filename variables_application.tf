# Application-specific Variables
# These variables are used only during the application deployment phase

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "base-infra"
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Application Configuration
variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "my-app"
}

variable "app_image" {
  description = "Docker image for the application"
  type        = string
  default     = "nginx:latest"
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
  default     = 2
}

variable "app_min_capacity" {
  description = "Minimum number of application tasks for auto scaling"
  type        = number
  default     = 1
}

variable "app_max_capacity" {
  description = "Maximum number of application tasks for auto scaling"
  type        = number
  default     = 10
}

# Environment Variables
variable "app_environment_variables" {
  description = "Environment variables for the application"
  type        = map(string)
  default     = {}
}

variable "app_secrets" {
  description = "Secrets for the application (stored in AWS Secrets Manager)"
  type        = map(string)
  default     = {}
}

# Health Check Configuration
variable "health_check_path" {
  description = "Path for ALB health check"
  type        = string
  default     = "/health"
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive health checks successes required"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures required"
  type        = number
  default     = 2
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

# Auto Scaling Configuration
variable "enable_auto_scaling" {
  description = "Enable auto scaling for the ECS service"
  type        = bool
  default     = true
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

# Logging Configuration - Free Tier Optimized
variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 1  # Minimum retention to save costs
}
