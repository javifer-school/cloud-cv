# =============================================================================
# Amplify Module - Outputs
# =============================================================================

output "app_id" {
  description = "ID of the Amplify app"
  value       = aws_amplify_app.cv_app.id
}

output "app_arn" {
  description = "ARN of the Amplify app"
  value       = aws_amplify_app.cv_app.arn
}

output "default_domain" {
  description = "Default domain of the Amplify app"
  value       = aws_amplify_app.cv_app.default_domain
}

output "branch_name" {
  description = "Branch name"
  value       = aws_amplify_branch.main.branch_name
}

output "custom_domain" {
  description = "Custom domain association"
  value       = aws_amplify_domain_association.cv_domain.domain_name
}
