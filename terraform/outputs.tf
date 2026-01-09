# DynamoDB outputs
output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = module.dynamodb.table_arn
}

# Lambda outputs
output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.lambda.function_arn
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = module.lambda.api_gateway_url
}

output "api_endpoint" {
  description = "Full API endpoint for visits"
  value       = "${module.lambda.api_gateway_url}/visits"
}

# Amplify outputs
output "amplify_app_id" {
  description = "Amplify App ID"
  value       = module.amplify.app_id
}

output "amplify_default_domain" {
  description = "Amplify default domain"
  value       = module.amplify.default_domain
}

# DNS outputs
output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = module.dns.certificate_arn
}

output "website_url" {
  description = "Website URL"
  value       = "https://${var.domain_name}"
}
