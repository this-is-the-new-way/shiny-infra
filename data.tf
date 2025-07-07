# Local values for referencing infrastructure resources
# Simplified for unified deployment approach
locals {
  # VPC and Networking - Use module outputs directly for unified deployment
  vpc_id             = var.deploy_base_infrastructure ? module.vpc[0].vpc_id : null
  private_subnet_ids = var.deploy_base_infrastructure ? module.vpc[0].private_subnet_ids : null  
  public_subnet_ids  = var.deploy_base_infrastructure ? module.vpc[0].public_subnet_ids : null

  # Security Groups - Use module outputs directly for unified deployment
  ecs_security_group_id = var.deploy_base_infrastructure ? module.security[0].app_security_group_id : null
  alb_security_group_id = var.deploy_base_infrastructure ? module.security[0].alb_security_group_id : null

  # Load Balancer - Use module outputs directly for unified deployment
  alb_arn          = var.deploy_base_infrastructure ? module.alb[0].alb_arn : null
  alb_dns_name     = var.deploy_base_infrastructure ? module.alb[0].alb_dns_name : null
  alb_zone_id      = var.deploy_base_infrastructure ? module.alb[0].alb_zone_id : null
  alb_listener_arn = var.deploy_base_infrastructure ? module.alb[0].alb_listener_arn : null

  # Route53 (if available) - set to null for now
  route53_zone_id   = null
  route53_zone_name = null
}
