# Lab 2 - Dockerize WalletMinimal -> ECR -> ECS Fargate -> ALB -> CloudWatch
#
# Mirrors the manual console walkthrough in docs/lab-02-hands-on.md.
# Flat resources, no module reuse - this lab is about understanding ECS
# concepts directly. Image build/push is still manual (docker build / docker
# push), Terraform only provisions the AWS side.
#
locals {
  app_name            = "${var.project_name}-api"
  container_name      = "wallet-api"
  effective_db_host   = var.create_data_dependencies ? aws_db_instance.wallet[0].address : var.db_host
  effective_s3_bucket = var.create_data_dependencies ? aws_s3_bucket.wallet[0].bucket : var.s3_bucket
}

resource "aws_ecr_repository" "wallet_api" {
  name                 = local.app_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "wallet" {
  name = "${var.project_name}-cluster"
}

resource "aws_cloudwatch_log_group" "wallet_api" {
  name              = "/ecs/${local.app_name}"
  retention_in_days = 7
}

# --- Data dependencies for standalone Lab 2 runs ---

resource "aws_s3_bucket" "wallet" {
  count  = var.create_data_dependencies ? 1 : 0
  bucket = var.s3_bucket
}

resource "aws_s3_bucket_public_access_block" "wallet" {
  count  = var.create_data_dependencies ? 1 : 0
  bucket = aws_s3_bucket.wallet[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "wallet" {
  count  = var.create_data_dependencies ? 1 : 0
  bucket = aws_s3_bucket.wallet[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "wallet" {
  count  = var.create_data_dependencies ? 1 : 0
  bucket = aws_s3_bucket.wallet[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# --- Task Execution Role (lets ECS Agent pull from ECR + write logs) ---

resource "aws_iam_role" "task_execution" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- Task Role (permissions used by the app code inside the container) ---

resource "aws_iam_role" "task" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Lab uses the AWS-managed policy for parity with the console walkthrough.
# Production should scope this to the exact bucket and object actions.
resource "aws_iam_role_policy_attachment" "task_s3_full_access" {
  role       = aws_iam_role.task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# --- Security Groups: only ALB faces the internet, ECS only accepts ALB ---

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB - public on port 80"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-sg"
  description = "ECS tasks - only reachable from the ALB SG, never directly"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  count       = var.create_data_dependencies ? 1 : 0
  name        = "${var.project_name}-rds-sg"
  description = "RDS - only reachable from ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "rds_from_ecs_tasks" {
  count = var.create_data_dependencies || var.rds_security_group_id == "" ? 0 : 1

  type                     = "ingress"
  description              = "PostgreSQL from ECS tasks"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.rds_security_group_id
  source_security_group_id = aws_security_group.ecs_tasks.id
}

resource "aws_db_subnet_group" "wallet" {
  count      = var.create_data_dependencies ? 1 : 0
  name       = "${var.project_name}-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "wallet" {
  count = var.create_data_dependencies ? 1 : 0

  identifier                   = var.rds_identifier
  engine                       = "postgres"
  engine_version               = var.db_engine_version
  instance_class               = var.db_instance_class
  allocated_storage            = var.db_allocated_storage
  max_allocated_storage        = 0
  db_name                      = var.db_name
  username                     = var.db_username
  password                     = var.db_password
  db_subnet_group_name         = aws_db_subnet_group.wallet[0].name
  vpc_security_group_ids       = [aws_security_group.rds[0].id]
  publicly_accessible          = false
  multi_az                     = false
  backup_retention_period      = 0
  performance_insights_enabled = false
  monitoring_interval          = 0
  auto_minor_version_upgrade   = true
  skip_final_snapshot          = true
}

# --- ALB + Target Group + Listener ---

resource "aws_lb" "wallet" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "wallet" {
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # required for Fargate

  health_check {
    path = "/health"
  }
}

resource "aws_lb_listener" "wallet" {
  load_balancer_arn = aws_lb.wallet.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wallet.arn
  }
}

# --- Task Definition ---

resource "aws_ecs_task_definition" "wallet_api" {
  family                   = local.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = var.container_image
      essential = true
      portMappings = [{
        containerPort = var.container_port
        protocol      = "tcp"
      }]
      environment = [
        { name = "DB_HOST", value = local.effective_db_host },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_USER", value = var.db_username },
        { name = "DB_PASSWORD", value = var.db_password },
        { name = "S3_BUCKET", value = local.effective_s3_bucket },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "AWS_DEFAULT_REGION", value = var.aws_region },
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
}

# --- ECS Service ---

resource "aws_ecs_service" "wallet_api" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.wallet.id
  task_definition = aws_ecs_task_definition.wallet_api.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.wallet.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.wallet]
}
