# Local values
locals {
  service_name = "${var.app_name}-${var.environment}"
  
  # Convert environment variables and secrets to the format expected by ECS
  environment_vars = [
    for key, value in var.environment_variables : {
      name  = key
      value = value
    }
  ]
  
  secrets_vars = [
    for key, valueFrom in var.secrets : {
      name      = key
      valueFrom = valueFrom
    }
  ]
}

# CloudWatch Log Group for the application
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ecs/${var.cluster_name}/${local.service_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${local.service_name}-logs"
    }
  )
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "task_execution_role" {
  name = "${local.service_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach the AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for secrets access (if secrets are used)
resource "aws_iam_role_policy" "secrets_policy" {
  count = length(var.secrets) > 0 ? 1 : 0
  name  = "${local.service_name}-secrets-policy"
  role  = aws_iam_role.task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [for secret_arn in values(var.secrets) : secret_arn]
      }
    ]
  })
}

# IAM Role for ECS Task (application runtime role)
resource "aws_iam_role" "task_role" {
  name = "${local.service_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Policy for ECS Exec access
resource "aws_iam_role_policy" "ecs_exec_policy" {
  name = "${local.service_name}-ecs-exec-policy"
  role = aws_iam_role.task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = local.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.app_cpu
  memory                   = var.app_memory
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn           = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name  = var.app_name
      image = var.app_image
      
      essential = true
      
      portMappings = [
        {
          containerPort = var.app_port
          protocol      = "tcp"
        }
      ]
      
      environment = local.environment_vars
      secrets     = local.secrets_vars
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:${var.app_port}${var.health_check_path} || exit 1"
        ]
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_unhealthy_threshold
        startPeriod = 60
      }
    }
  ])

  tags = var.tags
}

# ALB Target Group
resource "aws_lb_target_group" "app" {
  name        = "${local.service_name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.service_name}-target-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Listener Rule
resource "aws_lb_listener_rule" "app" {
  listener_arn = var.alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = var.tags
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = local.service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = var.security_group_ids
    subnets          = var.private_subnet_ids
    assign_public_ip = true  # Set to true when using public subnets for free tier
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name
    container_port   = var.app_port
  }

  # Enable ECS Exec
  enable_execute_command = true

  # Deployment configuration
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  # Service discovery (optional)
  # Enable if you need service mesh or internal service discovery
  
  depends_on = [
    aws_lb_listener_rule.app
  ]

  tags = var.tags

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "app" {
  count = var.enable_auto_scaling ? 1 : 0
  
  max_capacity       = var.app_max_capacity
  min_capacity       = var.app_min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = var.tags
}

# Auto Scaling Policy - CPU
resource "aws_appautoscaling_policy" "app_cpu" {
  count = var.enable_auto_scaling ? 1 : 0
  
  name               = "${local.service_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app[0].resource_id
  scalable_dimension = aws_appautoscaling_target.app[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.app[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.auto_scaling_target_cpu
    scale_in_cooldown  = var.auto_scaling_scale_down_cooldown
    scale_out_cooldown = var.auto_scaling_scale_up_cooldown
  }
}

# Auto Scaling Policy - Memory
resource "aws_appautoscaling_policy" "app_memory" {
  count = var.enable_auto_scaling ? 1 : 0
  
  name               = "${local.service_name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app[0].resource_id
  scalable_dimension = aws_appautoscaling_target.app[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.app[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.auto_scaling_target_memory
    scale_in_cooldown  = var.auto_scaling_scale_down_cooldown
    scale_out_cooldown = var.auto_scaling_scale_up_cooldown
  }
}

# Data source for current AWS region
data "aws_region" "current" {}
