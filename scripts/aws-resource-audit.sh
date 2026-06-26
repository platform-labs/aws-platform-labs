#!/bin/bash

echo "===== ECS CLUSTERS ====="
aws ecs list-clusters

echo
echo "===== ECS TASK DEFINITIONS (ACTIVE) ====="
aws ecs list-task-definitions --status ACTIVE

echo
echo "===== ECR REPOSITORIES ====="
aws ecr describe-repositories

echo
echo "===== LOAD BALANCERS ====="
aws elbv2 describe-load-balancers

echo
echo "===== TARGET GROUPS ====="
aws elbv2 describe-target-groups

echo
echo "===== EC2 INSTANCES ====="
aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=running,stopped,pending

echo
echo "===== ELASTIC IP ====="
aws ec2 describe-addresses

echo
echo "===== RDS INSTANCES ====="
aws rds describe-db-instances

echo
echo "===== RDS SNAPSHOTS ====="
aws rds describe-db-snapshots

echo
echo "===== S3 BUCKETS ====="
aws s3 ls

echo
echo "===== CSNP IAM ROLES ====="
aws iam list-roles \
  --query "Roles[?contains(RoleName,'csnp')].RoleName"

echo
echo "===== SECURITY GROUPS ====="
aws ec2 describe-security-groups \
  --query "SecurityGroups[*].[GroupName,GroupId]"

echo
echo "===== CLOUDWATCH LOG GROUPS ====="
aws logs describe-log-groups \
  --query "logGroups[*].logGroupName"

echo
echo "===== NAT GATEWAYS ====="
aws ec2 describe-nat-gateways

echo
echo "===== VPC ENDPOINTS ====="
aws ec2 describe-vpc-endpoints
