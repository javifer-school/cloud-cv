output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.visit_counter.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.visit_counter.arn
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = aws_apigatewayv2_api.api.api_endpoint
}
