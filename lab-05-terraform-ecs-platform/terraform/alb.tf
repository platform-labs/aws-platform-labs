# ALB lives in the Public Subnet (both AZs, for HA), forwards to the ECS
# Service in the Private App Subnet. Reuses the ALB Security Group already
# created in Lab 4 (var.alb_security_group_id) - no new SG here.

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids # must span >= 2 AZs

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "wallet_api" {
  name        = "${var.project_name}-wallet-api-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # required for Fargate, same as Lab 2

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-wallet-api-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wallet_api.arn
  }

  # Known gap: HTTP only, no HTTPS/ACM listener in this lab. TLS termination
  # is a separate concern (cert management, Route 53) - out of scope here to
  # keep the lab focused on getting ECS correctly placed in private subnets.
}
