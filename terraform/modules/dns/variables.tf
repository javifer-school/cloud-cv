# =============================================================================
# DNS Module - Variables
# =============================================================================

variable "domain_name" {
  description = "Full domain name for the website"
  type        = string
}

variable "hosted_zone_name" {
  description = "Name of the Route53 hosted zone (parent domain)"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "use_cloudflare" {
  description = "Use Cloudflare DNS instead of Route53"
  type        = bool
  default     = false
}

# variable "amplify_custom_domain" {
#   description = "Amplify custom domain (if configured)"
#   type        = string
#   default     = ""
# }
