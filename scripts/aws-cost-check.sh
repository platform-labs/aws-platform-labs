#!/bin/bash

echo "======================================"
echo "AWS CLEANUP CHECK"
echo "======================================"
echo

echo "Checking ECS Clusters..."
aws ecs list-clusters \
  --query "clusterArns" \
  --output table

echo
echo "Checking ECR Repositories..."
aws ecr describe-repositories \
  --query "repositories[*].repositoryName" \
  --output table

echo
echo "Checking Load Balancers..."
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[*].LoadBalancerName" \
  --output table

echo
echo "Checking EC2 Instances..."
aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=running,stopped,pending \
  --query "Reservations[*].Instances[*].[InstanceId,State.Name]" \
  --output table

echo
echo "Checking RDS Instances..."
aws rds describe-db-instances \
  --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]" \
  --output table

echo
echo "Checking RDS Snapshots..."
aws rds describe-db-snapshots \
  --query "DBSnapshots[*].[DBSnapshotIdentifier,Status]" \
  --output table

echo
echo "Checking S3 Buckets..."
aws s3 ls

echo
echo "Checking NAT Gateways..."
aws ec2 describe-nat-gateways \
  --query "NatGateways[*].[NatGatewayId,State]" \
  --output table

echo
echo "======================================"
echo "Review resources above before cleanup"
echo "======================================"
