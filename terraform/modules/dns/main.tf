# =============================================================================
# DNS Module - Route53 + ACM Certificate + Cloudflare DNS
# =============================================================================

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws, aws.us_east_1]
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

# =============================================================================
# Data: Fetch existing Cloudflare Zone
# =============================================================================
data "cloudflare_zone" "main" {
  count = var.use_cloudflare ? 1 : 0
  name  = var.hosted_zone_name
}

# =============================================================================
# Data: Try to find existing Hosted Zone (Route53 - fallback si no Cloudflare)
# If it doesn't exist, we'll create one
# =============================================================================
data "aws_route53_zone" "main" {
  name         = var.hosted_zone_name
  private_zone = false

  # Don't fail if zone doesn't exist, we'll create it
  depends_on = [aws_route53_zone.main]
}

# -----------------------------------------------------------------------------
# Resource: Create Hosted Zone if it doesn't exist
# This will be created automatically
# -----------------------------------------------------------------------------
resource "aws_route53_zone" "main" {
  name          = var.hosted_zone_name
  comment       = "Hosted zone for ${var.project_name}"
  force_destroy = false

  tags = {
    Name        = var.hosted_zone_name
    Environment = var.environment
    Project     = var.project_name
  }
}

# -----------------------------------------------------------------------------
# ACM Certificate (us-east-1 for Amplify/CloudFront)
# -----------------------------------------------------------------------------
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.domain_name}-cert"
    Environment = var.environment
    Project     = var.project_name
  }
}

# -----------------------------------------------------------------------------
# ACM Certificate in main region (for API Gateway)
# -----------------------------------------------------------------------------
resource "aws_acm_certificate" "cert_regional" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.domain_name}-cert-regional"
    Environment = var.environment
    Project     = var.project_name
  }
}

# -----------------------------------------------------------------------------
# =============================================================================
# DNS Validation Records - Cloudflare Version
# =============================================================================
resource "cloudflare_record" "cert_validation" {
  count = var.use_cloudflare ? 1 : 0

  zone_id = data.cloudflare_zone.main[0].id
  name    = trimprefix(element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_name, "${var.domain_name}.")
  content = element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_value
  type    = element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_type
  ttl     = 60
}

# =============================================================================
# DNS Validation Records - Route53 Version (fallback)
# =============================================================================
resource "aws_route53_record" "cert_validation" {
  count = !var.use_cloudflare ? 1 : 0

  allow_overwrite = true
  name            = element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_name
  records         = [element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_value]
  ttl             = 60
  type            = element(tolist(aws_acm_certificate.cert.domain_validation_options), 0).resource_record_type
  zone_id         = aws_route53_zone.main.zone_id
}

# -----------------------------------------------------------------------------
# =============================================================================
# ACM Certificate Validation with Cloudflare
# =============================================================================
resource "aws_acm_certificate_validation" "cert" {
  provider = aws.us_east_1
  count    = var.use_cloudflare ? 1 : 0

  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = ["${cloudflare_record.cert_validation[0].hostname}"]

  timeouts {
    create = "15m"
  }

  depends_on = [cloudflare_record.cert_validation]
}

resource "aws_acm_certificate_validation" "cert_regional" {
  count = var.use_cloudflare ? 1 : 0

  certificate_arn         = aws_acm_certificate.cert_regional.arn
  validation_record_fqdns = ["${cloudflare_record.cert_validation[0].hostname}"]

  timeouts {
    create = "15m"
  }

  depends_on = [cloudflare_record.cert_validation]
}

# =============================================================================
# ACM Certificate Validation with Route53 (fallback)
# =============================================================================
resource "aws_acm_certificate_validation" "cert_route53" {
  provider = aws.us_east_1
  count    = !var.use_cloudflare ? 1 : 0

  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation[0].fqdn]

  timeouts {
    create = "15m"
  }

  depends_on = [aws_route53_record.cert_validation]
}

resource "aws_acm_certificate_validation" "cert_regional_route53" {
  count = !var.use_cloudflare ? 1 : 0

  certificate_arn         = aws_acm_certificate.cert_regional.arn
  validation_record_fqdns = [aws_route53_record.cert_validation[0].fqdn]

  timeouts {
    create = "15m"
  }

  depends_on = [aws_route53_record.cert_validation]
}
