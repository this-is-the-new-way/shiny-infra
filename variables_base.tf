# Base Infrastructure Variables
# These variables are used during the base infrastructure deployment phase

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"  # Use us-east-1 for better free tier availability
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

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]  # Updated for us-east-1
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = false  # Disabled by default for free tier
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "alb_internal" {
  description = "Make the ALB internal (private)"
  type        = bool
  default     = false
}

variable "alb_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing for ALB"
  type        = bool
  default     = true
}

variable "alb_idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "health_check_path" {
  description = "Path for ALB health check"
  type        = string
  default     = "/health"
}

variable "health_check_enabled" {
  description = "Enable health check for ALB target group"
  type        = bool
  default     = true
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

variable "health_check_matcher" {
  description = "HTTP status codes for successful health checks"
  type        = string
  default     = "200"
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ECS Configuration (Base Infrastructure)
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = null
}

variable "ecs_capacity_providers" {
  description = "List of capacity providers for the ECS cluster"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "ecs_default_capacity_provider_strategy" {
  description = "Default capacity provider strategy for the ECS cluster"
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = number
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 1
    }
  ]
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the ECS cluster"
  type        = bool
  default     = false  # Disabled by default for free tier
}

# Monitoring Configuration
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "notification_topic_arn" {
  description = "SNS topic ARN for monitoring notifications"
  type        = string
  default     = null
}
