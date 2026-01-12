output "zone_id" {
  description = "The Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "zone_name" {
  description = "The Route 53 hosted zone name"
  value       = aws_route53_zone.main.name
}

output "nameservers" {
  description = "Route 53 nameservers for NS record delegation"
  value       = aws_route53_zone.main.name_servers
}
