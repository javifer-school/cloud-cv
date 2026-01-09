output "app_id" {
  description = "Amplify app ID"
  value       = aws_amplify_app.cv_app.id
}

output "default_domain" {
  description = "Amplify default domain"
  value       = aws_amplify_app.cv_app.default_domain
}

output "domain_association_sub_domains" {
  description = "Sub-domains configuration"
  value       = aws_amplify_domain_association.cv_domain.sub_domain
}

output "certificate_verification_dns_record" {
  description = "DNS record for certificate verification"
  value       = aws_amplify_domain_association.cv_domain.certificate_verification_dns_record
}

output "cloudfront_dns_record" {
  description = "CloudFront DNS record from subdomain"
  value       = trimspace(element(split("CNAME", tolist(aws_amplify_domain_association.cv_domain.sub_domain)[0].dns_record), 1))
}
