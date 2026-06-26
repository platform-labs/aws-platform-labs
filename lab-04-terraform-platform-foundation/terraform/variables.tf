variable "aws_region" {
  description = "AWS region for this lab."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod) - used for naming and tagging."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Prefix used for resource names."
  type        = string
  default     = "csnp-platform"
}

variable "vpc_cidr" {
  description = "CIDR block for the custom VPC."
  type        = string
  default     = "10.10.0.0/16"
}

variable "azs" {
  description = "Availability Zones used by this lab. Two is enough to demonstrate Multi-AZ / HA without 3-AZ cost."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per AZ (index-aligned with var.azs). Hosts ALB and the NAT Gateway."
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "Private application subnet CIDRs, one per AZ. Hosts ECS tasks."
  type        = list(string)
  default     = ["10.10.11.0/24", "10.10.12.0/24"]
}

variable "private_data_subnet_cidrs" {
  description = "Private data subnet CIDRs, one per AZ. Hosts RDS. No route to the internet."
  type        = list(string)
  default     = ["10.10.21.0/24", "10.10.22.0/24"]
}

variable "nat_gateway_az_index" {
  description = "Index into var.azs / var.public_subnet_cidrs for where the single NAT Gateway lives. Lab uses 1 NAT Gateway (cost trade-off); production should use 1 per AZ."
  type        = number
  default     = 0
}

variable "my_ip_cidr" {
  description = "Your current public IP in CIDR form (e.g. 203.0.113.10/32), used to restrict SSH access to the test EC2 instance."
  type        = string
}

variable "key_pair_name" {
  description = "Name of an EXISTING EC2 key pair, used only for the temporary network-test-ec2 instance. Generate manually in console, keep .pem out of git."
  type        = string
}

variable "test_ec2_instance_type" {
  description = "Instance type for the temporary verification EC2. t3.micro is Free Tier eligible."
  type        = string
  default     = "t3.micro"
}
