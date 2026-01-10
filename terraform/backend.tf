# ============================================================================
# Terraform Backend Configuration - S3 Backend
# ============================================================================
# S3 backend for remote state storage with DynamoDB locking.
# Used consistently across local development and CI/CD.
#
# The S3 bucket and DynamoDB table are created automatically by init.sh
# Backend configuration is completed at init time with account ID.
# ============================================================================

terraform {
  backend "s3" {
    # Backend values are provided via -backend-config flags during terraform init
    # by scripts/init.sh. This ensures the bucket name includes the AWS account ID.
    # Bucket format: cloud-cv-terraform-state-{account_id}
  }
}
