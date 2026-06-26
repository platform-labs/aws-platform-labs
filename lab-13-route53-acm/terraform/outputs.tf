output "certificate_arn" {
  description = "Validated ACM certificate ARN."
  value       = aws_acm_certificate.api.arn
}

output "https_listener_arn" {
  description = "ALB HTTPS listener ARN."
  value       = aws_lb_listener.https.arn
}

output "api_url" {
  description = "Public HTTPS URL created for the API."
  value       = "https://${var.domain_name}"
}
