# Lambda function package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda/visit_counter"
  output_path = "${path.root}/../lambda/visit_counter.zip"
}

# Lambda function
resource "aws_lambda_function" "visit_counter" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role             = var.lambda_role_arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = var.runtime
  memory_size      = var.memory_size
  timeout          = var.timeout

  environment {
    variables = {
      DYNAMODB_TABLE  = var.dynamodb_table
      ALLOWED_ORIGINS = join(",", var.allowed_origins)
    }
  }

  tags = {
    Name        = var.function_name
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
  tags = {
    Name        = "${var.function_name}-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["Content-Type", "X-Forwarded-For"]
    allow_methods     = ["GET", "POST", "OPTIONS"]
    allow_origins     = var.allowed_origins
    max_age           = 300
  }

  tags = {
    Name        = "${var.project_name}-api"
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId   = "$context.requestId"
      ip          = "$context.identity.sourceIp"
      requestTime = "$context.requestTime"
      httpMethod  = "$context.httpMethod"
      routeKey    = "$context.routeKey"
      status      = "$context.status"
    })
  }

  tags = {
    Name        = "${var.project_name}-api-stage"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${var.project_name}-api"
  retention_in_days = 14
  tags = {
    Name        = "${var.project_name}-api-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Lambda Integration
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.visit_counter.invoke_arn
  payload_format_version = "2.0"
}

# API Routes
resource "aws_apigatewayv2_route" "get_visits" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /visits"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "post_visits" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /visits"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visit_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
