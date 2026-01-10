#!/bin/bash
# ============================================================================
# Terraform Initialization Script
# ============================================================================
# Creates S3 backend and initializes Terraform.
# Works for both local development and CI/CD.
#
# Usage:
#   ./scripts/init.sh          # Local development (interactive)
#   ./scripts/init.sh --ci     # CI/CD mode (non-interactive)
# ============================================================================

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_section() { echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${BLUE}$1${NC}\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

# Check CI mode
CI_MODE=false
[ "$1" = "--ci" ] && CI_MODE=true

# Get AWS account ID
log_section "AWS Credentials Setup"
if ! ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null); then
    log_error "AWS credentials not configured or invalid"
    echo "Configure AWS credentials:"
    echo "  aws configure"
    echo "  or set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN"
    exit 1
fi
log_info "AWS Account ID: $ACCOUNT_ID"

# S3 bucket and DynamoDB table names
S3_BUCKET="cloud-cv-terraform-state-${ACCOUNT_ID}"
DYNAMODB_TABLE="cloud-cv-terraform-locks"
AWS_REGION="us-east-1"

log_info "S3 Bucket: $S3_BUCKET"
log_info "DynamoDB Table: $DYNAMODB_TABLE"

# Confirm before setup (local mode)
if [ "$CI_MODE" = false ]; then
    echo ""
    read -p "Setup S3 backend? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && { log_warn "Setup cancelled"; exit 0; }
fi

# Create S3 bucket
log_section "Creating S3 Bucket"
if aws s3api head-bucket --bucket "$S3_BUCKET" 2>/dev/null; then
    log_warn "Bucket already exists: $S3_BUCKET"
else
    log_info "Creating bucket: $S3_BUCKET"
    aws s3api create-bucket --bucket "$S3_BUCKET" --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION" 2>/dev/null || \
    aws s3api create-bucket --bucket "$S3_BUCKET" --region "$AWS_REGION" 2>/dev/null || true
    sleep 2
fi

# Enable versioning
aws s3api put-bucket-versioning --bucket "$S3_BUCKET" \
    --versioning-configuration Status=Enabled 2>/dev/null || true
log_info "Versioning enabled"

# Enable encryption
aws s3api put-bucket-encryption --bucket "$S3_BUCKET" \
    --server-side-encryption-configuration '{
        "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
    }' 2>/dev/null || true
log_info "Encryption enabled"

# Block public access
aws s3api put-public-access-block --bucket "$S3_BUCKET" \
    --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true 2>/dev/null || true
log_info "Public access blocked"

# Create DynamoDB table
log_section "Creating DynamoDB Table"
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" 2>/dev/null | grep -q "TableName"; then
    log_warn "Table already exists: $DYNAMODB_TABLE"
else
    log_info "Creating table: $DYNAMODB_TABLE"
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION" 2>/dev/null || true
    
    log_info "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" 2>/dev/null || sleep 5
fi

# Initialize Terraform
log_section "Initializing Terraform"
cd terraform
if terraform init \
    -backend-config="bucket=$S3_BUCKET" \
    -backend-config="key=terraform.tfstate" \
    -backend-config="region=$AWS_REGION" \
    -backend-config="encrypt=true" \
    -backend-config="dynamodb_table=$DYNAMODB_TABLE" \
    -backend-config="skip_region_validation=false" \
    -backend-config="skip_credentials_validation=false"; then
    log_info "Terraform initialized successfully"
else
    log_error "Terraform initialization failed"
    exit 1
fi

# Remove backend resources from state (they're managed by init.sh with AWS CLI, not Terraform)
log_section "Cleaning up Terraform State"
log_info "Removing backend infrastructure resources from state..."
# Silently remove resources if they exist (errors are suppressed)
terraform state rm 'aws_s3_bucket.terraform_state' >/dev/null 2>&1 || true
terraform state rm 'aws_s3_bucket_versioning.terraform_state' >/dev/null 2>&1 || true
terraform state rm 'aws_s3_bucket_server_side_encryption_configuration.terraform_state' >/dev/null 2>&1 || true
terraform state rm 'aws_s3_bucket_public_access_block.terraform_state' >/dev/null 2>&1 || true
terraform state rm 'aws_dynamodb_table.terraform_locks' >/dev/null 2>&1 || true
terraform state rm 'data.aws_caller_identity.current' >/dev/null 2>&1 || true
log_info "Backend resources removed from state (still exist in AWS, managed outside Terraform)"

# Summary
log_section "Setup Complete ✨"
echo "Backend: S3 (bucket: $S3_BUCKET)"
echo "Locks: DynamoDB (table: $DYNAMODB_TABLE)"
echo ""
echo "Next steps:"
echo "  terraform plan"
echo "  terraform apply"