# General variables
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloud-cv"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

# Domain variables
variable "domain_name" {
  description = "Full domain name for the CV website"
  type        = string
}

variable "hosted_zone_name" {
  description = "Parent domain name (Cloudflare managed)"
  type        = string
}

variable "route53_zone_name" {
  description = "Route 53 subdomain zone (delegated from Cloudflare)"
  type        = string
}

# GitHub variables
variable "github_repository" {
  description = "GitHub repository URL"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to deploy"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

# DynamoDB variables
variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "cv-visit-counter"
}

# Lambda variables
variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
  default     = "cv-visit-counter"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "lambda_memory" {
  description = "Lambda memory in MB"
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 10
}

variable "lambda_role_arn" {
  description = "IAM role ARN for Lambda (LabRole)"
  type        = string
}

# Cloudflare variables
variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}
