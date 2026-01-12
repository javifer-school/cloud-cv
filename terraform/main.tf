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

# Route 53 module - Hosted zone for subdomain delegation
module "route53" {
  source       = "./modules/route53"
  zone_name    = var.route53_zone_name
  environment  = var.environment
  project_name = var.project_name
  comment      = "Delegated zone from Cloudflare for ${var.project_name}"
}

# Cloudflare NS records for Route 53 delegation
resource "cloudflare_record" "route53_delegation" {
  count   = 4
  zone_id = var.cloudflare_zone_id
  name    = trimsuffix(var.route53_zone_name, ".${var.hosted_zone_name}")
  type    = "NS"
  content = module.route53.nameservers[count.index]
  ttl     = 3600
}

# DNS module - ACM Certificate + Route 53 DNS validation
module "dns" {
  source = "./modules/dns"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
  domain_name        = var.domain_name
  hosted_zone_name   = var.hosted_zone_name
  route53_zone_id    = module.route53.zone_id
  cloudflare_zone_id = var.cloudflare_zone_id
  environment        = var.environment
  project_name       = var.project_name
  depends_on         = [cloudflare_record.route53_delegation]
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

# Route 53 CNAME record for Amplify domain (CloudFront)
resource "aws_route53_record" "amplify_cname" {
  zone_id    = module.route53.zone_id
  name       = var.domain_name
  type       = "CNAME"
  ttl        = 300
  records    = [module.amplify.cloudfront_dns_record]
  depends_on = [module.amplify, module.dns]
}

# Route 53 record for Amplify certificate verification
resource "aws_route53_record" "amplify_cert_validation" {
  zone_id         = module.route53.zone_id
  name            = element(split(" ", module.amplify.certificate_verification_dns_record), 0)
  type            = element(split(" ", module.amplify.certificate_verification_dns_record), 1)
  ttl             = 60
  records         = [element(split(" ", module.amplify.certificate_verification_dns_record), 2)]
  allow_overwrite = true
  depends_on      = [module.amplify, module.dns]
}
