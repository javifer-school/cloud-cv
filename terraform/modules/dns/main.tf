# DNS Module - ACM Certificate + Route 53 DNS validation
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws, aws.us_east_1]
    }
  }
}

# ACM Certificate (us-east-1 for Amplify/CloudFront)
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
  tags = {
    Name        = "${var.domain_name}-cert"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ACM Certificate (regional for API Gateway)
resource "aws_acm_certificate" "cert_regional" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
  tags = {
    Name        = "${var.domain_name}-cert-regional"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Route 53 DNS validation record - compartida para ambos certificados
# Ambos certificatos (us-east-1 y regional) tienen el mismo dominio,
# por lo que comparten el mismo domain_validation_option[0]
resource "aws_route53_record" "cert_validation" {
  zone_id = var.route53_zone_id
  name    = element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_name
  type    = element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_type
  records = [element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_value]
  ttl     = 60
}

# ACM Certificate validation (us-east-1)
resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
  timeouts { create = "15m" }
  depends_on              = [aws_route53_record.cert_validation]
}

# ACM Certificate validation (regional) - usa el mismo registro que cert
resource "aws_acm_certificate_validation" "cert_regional" {
  certificate_arn         = aws_acm_certificate.cert_regional.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
  timeouts { create = "15m" }
  depends_on              = [aws_route53_record.cert_validation]
}
