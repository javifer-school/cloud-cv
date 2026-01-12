# Route 53 Hosted Zone Module
# Creates a public hosted zone for the subdomain delegated from Cloudflare

resource "aws_route53_zone" "main" {
  name    = var.zone_name
  comment = var.comment

  # Permitir que se borre la zona incluso si tiene registros
  # (Terraform borrará los registros primero)
  force_destroy = true

  tags = {
    Name        = "${var.zone_name}-zone"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
