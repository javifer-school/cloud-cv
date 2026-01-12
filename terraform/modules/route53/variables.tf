variable "zone_name" {
  description = "Route 53 hosted zone name (e.g., aws.atercates.cat)"
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

variable "comment" {
  description = "Comment for the hosted zone"
  type        = string
  default     = "Managed by Terraform"
}
