output "distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.api.id
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.api.domain_name
}
