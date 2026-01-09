# =============================================================================
# Cloud CV - Main Terraform Configuration
# =============================================================================

# =============================================================================
# DynamoDB Module - Visit Counter Table
# =============================================================================
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name   = var.dynamodb_table_name
  environment  = var.environment
  project_name = var.project_name
}

# =============================================================================
# Lambda Module - Visit Counter Function + API Gateway
# =============================================================================
module "lambda" {
  source = "./modules/lambda"

  function_name   = var.lambda_function_name
  runtime         = var.lambda_runtime
  memory_size     = var.lambda_memory
  timeout         = var.lambda_timeout
  dynamodb_table  = module.dynamodb.table_name
  dynamodb_arn    = module.dynamodb.table_arn
  environment     = var.environment
  project_name    = var.project_name
  lambda_role_arn = var.lambda_role_arn
  allowed_origins = ["https://${var.domain_name}", "http://localhost:3000"]
}

# =============================================================================
# Amplify Module - Static Website Hosting
# =============================================================================
module "amplify" {
  source = "./modules/amplify"

  app_name          = var.project_name
  github_repository = var.github_repository
  github_branch     = var.github_branch
  github_token      = var.github_token
  domain_name       = var.domain_name
  certificate_arn   = module.dns.certificate_arn
  api_endpoint      = module.lambda.api_gateway_url
  environment       = var.environment
  project_name      = var.project_name

  depends_on = [module.dns]
}

# =============================================================================
# DNS Module - Route53 + ACM Certificate + Cloudflare
# =============================================================================
module "dns" {
  source = "./modules/dns"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
    cloudflare    = cloudflare
  }

  domain_name      = var.domain_name
  hosted_zone_name = var.hosted_zone_name
  environment      = var.environment
  project_name     = var.project_name
  use_cloudflare   = var.cloudflare_api_token != ""
  # amplify_custom_domain   = module.amplify.amplify_default_domain  # Quitar dependencia circular
}
