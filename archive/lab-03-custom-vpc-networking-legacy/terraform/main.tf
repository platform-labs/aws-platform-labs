# Lab 3 - Custom VPC Networking
#
# Goal: replace the default VPC used in Lab 1/Lab 2 with a real 3-tier
# network. Lab 1 and Lab 2 are frozen as-is (Generation 1) - this lab does
# NOT touch them. Lab 4 will re-provision Lab 1's resources (EC2/RDS/S3/IAM)
# inside this VPC via Terraform.
#
# Architecture:
#
#   Internet
#       |
#       v
#   Internet Gateway
#       |
#       v
#   Public Subnet (x2 AZ)      -> ALB, NAT Gateway, network-test-ec2
#       |
#       v
#   Private App Subnet (x2 AZ) -> ECS tasks (routes 0.0.0.0/0 via NAT)
#       |
#       v
#   Private Data Subnet (x2 AZ)-> RDS (NO route to internet, local only)
#
# Single NAT Gateway lives in the AZ at var.nat_gateway_az_index. Cost
# trade-off for a lab: 1 NAT = ~$32/mo instead of ~$64/mo for 2, at the cost
# of NAT being a single point of failure. Production should use 1 NAT per AZ.

data "aws_availability_zones" "available" {
  state = "available"
}

# --- VPC ---

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# --- Internet Gateway ---

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# --- Public Subnets (ALB, NAT Gateway, test EC2) ---

resource "aws_subnet" "public" {
  count = length(var.azs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${var.azs[count.index]}"
    Tier = "public"
  }
}

# --- Private App Subnets (ECS) ---

resource "aws_subnet" "private_app" {
  count = length(var.azs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-private-app-${var.azs[count.index]}"
    Tier = "private-app"
  }
}

# --- Private Data Subnets (RDS) ---

resource "aws_subnet" "private_data" {
  count = length(var.azs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_data_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-private-data-${var.azs[count.index]}"
    Tier = "private-data"
  }
}

# --- NAT Gateway (single, lab-only cost trade-off) ---

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[var.nat_gateway_az_index].id

  tags = {
    Name = "${var.project_name}-nat-${var.azs[var.nat_gateway_az_index]}"
  }

  depends_on = [aws_internet_gateway.main]
}

# --- Route Tables ---

# Public: one shared RT, default route to IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.azs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private App: one RT per AZ (both point at the single NAT Gateway today;
# if you add a 2nd NAT later, AZ-b's RT just needs its route updated).
resource "aws_route_table" "private_app" {
  count = length(var.azs)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-private-app-rt-${var.azs[count.index]}"
  }
}

resource "aws_route_table_association" "private_app" {
  count = length(var.azs)

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

# Private Data: local-only route table, NO 0.0.0.0/0 anywhere.
# RDS does not need to reach the internet - this is the point of the lab.
resource "aws_route_table" "private_data" {
  vpc_id = aws_vpc.main.id

  # Intentionally no `route` block beyond the implicit local route that
  # every VPC route table gets automatically (10.10.0.0/16 -> local).

  tags = {
    Name = "${var.project_name}-private-data-rt"
  }
}

resource "aws_route_table_association" "private_data" {
  count = length(var.azs)

  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private_data.id
}
