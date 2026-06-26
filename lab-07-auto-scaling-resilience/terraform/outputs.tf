output "scalable_target_resource_id" {
  description = "Application Auto Scaling resource ID for the ECS service."
  value       = aws_appautoscaling_target.ecs.resource_id
}

output "policy_arns" {
  description = "ARNs of the CPU and memory target-tracking policies."
  value = [
    aws_appautoscaling_policy.cpu.arn,
    aws_appautoscaling_policy.memory.arn
  ]
}
