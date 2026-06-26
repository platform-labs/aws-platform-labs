# Security Groups for the 3-tier network.
#
# Chain: Internet -> ALB SG -> ECS SG -> RDS SG
# No tier ever opens 0.0.0.0/0 except the ALB on port 80, and SSH on the
# temporary test EC2 (restricted to my_ip_cidr). This mirrors the SG
# Reference pattern already used in Lab 1 / Lab 2, just at full 3-tier scale.

# --- ALB SG: public-facing, port 80 from anywhere ---

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB - public on port 80, forwards to ECS SG only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
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

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# --- ECS SG: only reachable from ALB SG, never from the internet directly ---

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "ECS tasks - only reachable from the ALB SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App port from ALB SG only"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

# --- RDS SG: only reachable from ECS SG. Never 0.0.0.0/0. ---

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS PostgreSQL - only reachable from the ECS SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from ECS SG only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  # No egress block needed for a pure database tier, but keeping a default
  # egress avoids surprises if you later need RDS to call out (e.g. extensions).
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# --- Test EC2 SG: temporary, SSH from my IP only, used to verify the network ---

resource "aws_security_group" "test_ec2" {
  name        = "${var.project_name}-test-ec2-sg"
  description = "Temporary verification EC2 - SSH from my IP only. Delete after Lab 3 verification."
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-test-ec2-sg"
  }
}
