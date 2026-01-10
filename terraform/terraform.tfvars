# Terraform Variables
# Non-sensitive values only - sensitive values passed via GitHub secrets

# AWS Configuration
aws_region = "us-east-1"

# Project Configuration
project_name = "cloud-cv"
environment  = "production"

# Domain Configuration
domain_name      = "cv.aws10.atercates.cat"
hosted_zone_name = "atercates.cat"

# GitHub Configuration
github_repository = "https://github.com/javifer-school/cloud-cv"
github_branch     = "main"

# DynamoDB Configuration
dynamodb_table_name = "cv-visit-counter"

# Lambda Configuration
lambda_function_name = "cv-visit-counter"
lambda_runtime       = "python3.11"
lambda_memory        = 128
lambda_timeout       = 10
