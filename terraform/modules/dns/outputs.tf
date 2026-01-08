# =============================================================================
# DNS Module - Outputs
# =============================================================================

output "certificate_arn" {
  description = "ARN of the ACM certificate (us-east-1)"
  value       = aws_acm_certificate.cert.arn
}

output "certificate_arn_regional" {
  description = "ARN of the regional ACM certificate"
  value       = aws_acm_certificate.cert_regional.arn
}

output "hosted_zone_id" {
  description = "ID of the Route53 hosted zone"
  value       = data.aws_route53_zone.main.zone_id
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}

output "certificate_status" {
  description = "Status of the ACM certificate"
  value       = aws_acm_certificate.cert.status
}
