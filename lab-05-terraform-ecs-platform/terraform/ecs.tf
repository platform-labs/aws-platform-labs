# Task Definition + Service. Tasks run in the Private App Subnet (Lab 4's
# output), with no public IP - inbound traffic only via the ALB.

resource "aws_cloudwatch_log_group" "wallet_api" {
  name              = "/ecs/${var.project_name}-wallet-api"
  retention_in_days = 14 # cost control default; revisit in Lab 6 (Observability)
}

resource "aws_ecs_task_definition" "wallet_api" {
  family                   = "${var.project_name}-wallet-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc" # required for Fargate
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "wallet-api"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "ASPNETCORE_URLS", value = "http://+:${var.container_port}" },
        { name = "DB_HOST", value = aws_db_instance.wallet_db.address },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_USER", value = var.db_user },
        { name = "S3_BUCKET", value = aws_s3_bucket.wallet_uploads.id },
        # Known gap: DB_PASSWORD passed as a plain environment variable, not
        # via Secrets Manager `secrets` block. Deferred to Lab 6/7 on purpose
        # - see README "Known Gaps". Do not "fix" this inline here.
        { name = "DB_PASSWORD", value = var.db_password },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.wallet_api.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-wallet-api-task"
  }
}

resource "aws_ecs_service" "wallet_api" {
  name            = "${var.project_name}-wallet-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.wallet_api.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_app_subnet_ids  # Private App Subnet, both AZs
    security_groups  = [var.ecs_security_group_id] # reused from Lab 4, already scoped to ALB SG only
    assign_public_ip = false                       # the key fix vs. Lab 2's default-VPC version
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.wallet_api.arn
    container_name   = "wallet-api"
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.http,
    aws_db_instance.wallet_db,
    aws_s3_bucket.wallet_uploads
  ]

  tags = {
    Name = "${var.project_name}-wallet-api-service"
  }
}
