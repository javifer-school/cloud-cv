output "certificate_arn" {
  description = "ACM certificate ARN (us-east-1)"
  value       = aws_acm_certificate.cert.arn
}

output "certificate_arn_regional" {
  description = "Regional ACM certificate ARN"
  value       = aws_acm_certificate.cert_regional.arn
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}
