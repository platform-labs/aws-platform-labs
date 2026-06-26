output "vpc_id" {
  description = "ID of the custom VPC. Lab 4 will reuse this."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the custom VPC."
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs, index-aligned with var.azs. For ALB / NAT Gateway."
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "Private app subnet IDs, index-aligned with var.azs. For ECS tasks."
  value       = aws_subnet.private_app[*].id
}

output "private_data_subnet_ids" {
  description = "Private data subnet IDs, index-aligned with var.azs. For RDS subnet group."
  value       = aws_subnet.private_data[*].id
}

output "nat_gateway_id" {
  description = "ID of the lab NAT Gateway."
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_public_ip" {
  description = "Public Elastic IP attached to the NAT Gateway."
  value       = aws_eip.nat.public_ip
}

output "alb_security_group_id" {
  description = "Security group ID for public ALBs."
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks."
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS databases."
  value       = aws_security_group.rds.id
}

output "network_test_ec2_public_ip" {
  description = "Public IP of the temporary verification EC2 - use to SSH in for checks, then terminate."
  value       = aws_instance.network_test.public_ip
}
