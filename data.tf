# Local values for referencing infrastructure resources
# Since we're using local state, we'll reference the modules directly
locals {
  # VPC and Networking
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # Security Groups
  ecs_security_group_id = module.security.app_security_group_id
  alb_security_group_id = module.security.alb_security_group_id

  # Load Balancer
  alb_arn          = module.alb.alb_arn
  alb_dns_name     = module.alb.alb_dns_name
  alb_zone_id      = module.alb.alb_zone_id
  alb_listener_arn = module.alb.alb_listener_arn

  # Route53 (if available) - set to null for now
  route53_zone_id   = null
  route53_zone_name = null
}
