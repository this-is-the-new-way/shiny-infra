variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "allowed_ip_addresses" {
  description = "List of IP addresses/CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Default to open access for backward compatibility
}

variable "enable_restricted_access" {
  description = "Enable restricted access to ALB (when true, only allowed_ip_addresses can access)"
  type        = bool
  default     = false
}
