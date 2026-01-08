# Backend configuration for Terraform state
# Uncomment and configure after creating the S3 bucket manually or via bootstrap

# terraform {
#   backend "s3" {
#     bucket         = "cloud-cv-terraform-state"
#     key            = "terraform.tfstate"
#     region         = "eu-west-1"
#     encrypt        = true
#     use_lockfile   = true  # S3 native locking (no DynamoDB needed)
#   }
# }

# For initial setup, use local backend
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
