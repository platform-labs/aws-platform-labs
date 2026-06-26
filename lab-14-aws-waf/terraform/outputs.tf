output "web_acl_arn" {
  description = "Regional WAF Web ACL ARN."
  value       = aws_wafv2_web_acl.api.arn
}

output "web_acl_capacity" {
  description = "Web ACL capacity units consumed by the configured rules."
  value       = aws_wafv2_web_acl.api.capacity
}
