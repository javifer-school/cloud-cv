# =============================================================================
# General Variables
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "cloud-cv"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

# =============================================================================
# Domain Variables
# =============================================================================

variable "domain_name" {
  description = "Full domain name for the CV website"
  type        = string
  default     = "cv.aws10.atercates.cat"
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name (parent domain)"
  type        = string
  default     = "atercates.cat"
}

# =============================================================================
# GitHub Variables
# =============================================================================

variable "github_repository" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/javifer-school/cloud-cv"
}

variable "github_branch" {
  description = "GitHub branch to deploy"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub personal access token for Amplify"
  type        = string
  sensitive   = true
  default     = ""
}

# =============================================================================
# DynamoDB Variables
# =============================================================================

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for visit counter"
  type        = string
  default     = "cv-visit-counter"
}

# =============================================================================
# Lambda Variables
# =============================================================================

variable "lambda_function_name" {
  description = "Name of the Lambda function"
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
  description = "ARN of the existing IAM role for Lambda (required for AWS Learner Lab)"
  type        = string
}

# =============================================================================
# Cloudflare Variables
# =============================================================================

variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS management"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain"
  type        = string
  default     = ""
}
