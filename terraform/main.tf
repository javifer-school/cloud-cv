# DynamoDB module - Visit counter table 
module "dynamodb" {
  source       = "./modules/dynamodb"
  table_name   = var.dynamodb_table_name
  environment  = var.environment
  project_name = var.project_name
}

# Lambda module - Visit counter function + API Gateway
module "lambda" {
  source          = "./modules/lambda"
  function_name   = var.lambda_function_name
  runtime         = var.lambda_runtime
  memory_size     = var.lambda_memory
  timeout         = var.lambda_timeout
  dynamodb_table  = module.dynamodb.table_name
  environment     = var.environment
  project_name    = var.project_name
  lambda_role_arn = var.lambda_role_arn
  allowed_origins = ["https://${var.domain_name}", "http://localhost:3000"]
}

# DNS module - ACM Certificate + Cloudflare DNS
module "dns" {
  source = "./modules/dns"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
  domain_name        = var.domain_name
  hosted_zone_name   = var.hosted_zone_name
  cloudflare_zone_id = var.cloudflare_zone_id
  environment        = var.environment
  project_name       = var.project_name
}

# Amplify module - Static website hosting
module "amplify" {
  source            = "./modules/amplify"
  app_name          = var.project_name
  github_repository = var.github_repository
  github_branch     = var.github_branch
  github_token      = var.github_token
  domain_name       = var.domain_name
  api_endpoint      = module.lambda.api_gateway_url
  environment       = var.environment
  project_name      = var.project_name
  depends_on        = [module.dns]
}

# Cloudflare CNAME record for Amplify domain (CloudFront)
resource "cloudflare_record" "amplify_cname" {
  zone_id    = var.cloudflare_zone_id
  name       = trimsuffix(var.domain_name, ".${var.hosted_zone_name}")
  type       = "CNAME"
  content    = module.amplify.cloudfront_dns_record
  ttl        = 300
  proxied    = false
  depends_on = [module.amplify]
}

# Cloudflare DNS record for Amplify certificate verification
resource "cloudflare_record" "amplify_cert_validation" {
  zone_id    = var.cloudflare_zone_id
  name       = element(split(" ", module.amplify.certificate_verification_dns_record), 0)
  type       = element(split(" ", module.amplify.certificate_verification_dns_record), 1)
  content    = element(split(" ", module.amplify.certificate_verification_dns_record), 2)
  ttl        = 60
  depends_on = [module.amplify]
}
