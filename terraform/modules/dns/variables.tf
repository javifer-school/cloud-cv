variable "domain_name" {
  description = "Full domain name"
  type        = string
}

variable "hosted_zone_name" {
  description = "Parent domain name"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}
