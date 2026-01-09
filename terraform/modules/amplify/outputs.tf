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
