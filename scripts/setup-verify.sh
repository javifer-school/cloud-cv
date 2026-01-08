#!/bin/bash

# =============================================================================
# Cloud CV - Setup Verification Script
# =============================================================================
# This script verifies that you have configured all required variables
# before starting the deployment process.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
REQUIRED_OK=0
REQUIRED_FAIL=0
OPTIONAL_OK=0
OPTIONAL_FAIL=0

# Helper functions
check_required() {
    if [ -n "$2" ]; then
        echo -e "${GREEN}✓${NC} $1: Present"
        ((REQUIRED_OK++))
    else
        echo -e "${RED}✗${NC} $1: MISSING"
        ((REQUIRED_FAIL++))
    fi
}

check_optional() {
    if [ -n "$2" ]; then
        echo -e "${GREEN}✓${NC} $1: Present"
        ((OPTIONAL_OK++))
    else
        echo -e "${YELLOW}⚠${NC} $1: Not configured (optional)"
        ((OPTIONAL_FAIL++))
    fi
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Start
clear
echo -e "${BLUE}"
cat << "EOF"
   _____ _____ _______ _    _ ____  
  / ____|  ____|__   __| |  | |  _ \ 
 | (___ | |__     | |  | |  | | |_) |
  \___ \|  __|    | |  | |  | |  _ < 
  ____) | |____   | |  | |__| | |_) |
 |_____/|______|  |_|   \____/|____/ 
                                     
 Environment Setup Verification
EOF
echo -e "${NC}"

# =============================================================================
# 1. AWS Credentials Check
# =============================================================================
section "1. AWS Credentials"

check_required "AWS_ACCESS_KEY_ID" "$AWS_ACCESS_KEY_ID"
check_required "AWS_SECRET_ACCESS_KEY" "$AWS_SECRET_ACCESS_KEY"
check_optional "AWS_REGION" "$AWS_REGION"
check_optional "AWS_ACCOUNT_ID" "$AWS_ACCOUNT_ID"

# Verify credentials work
if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    if command -v aws &> /dev/null; then
        if aws sts get-caller-identity &> /dev/null; then
            info "AWS credentials verified ✓"
        else
            echo -e "${RED}✗${NC} AWS credentials invalid - cannot authenticate"
            ((REQUIRED_FAIL++))
        fi
    fi
fi

# =============================================================================
# 2. GitHub Token Check
# =============================================================================
section "2. GitHub Token"

check_required "TF_VAR_github_token or GH_TOKEN" "${TF_VAR_github_token:-$GH_TOKEN}"

# =============================================================================
# 3. Terraform Variables Check
# =============================================================================
section "3. Terraform Configuration"

if [ -f "terraform/terraform.tfvars" ]; then
    echo -e "${GREEN}✓${NC} terraform/terraform.tfvars exists"
    ((REQUIRED_OK++))
    
    # Check content
    info "Checking terraform.tfvars content:"
    
    if grep -q "github_token" terraform/terraform.tfvars; then
        echo -e "  ${GREEN}✓${NC} github_token found"
    else
        echo -e "  ${YELLOW}⚠${NC} github_token not found (can use -var flag)"
    fi
    
    if grep -q "domain_name" terraform/terraform.tfvars; then
        DOMAIN=$(grep "domain_name" terraform/terraform.tfvars | cut -d'"' -f2)
        echo -e "  ${GREEN}✓${NC} domain_name: $DOMAIN"
    else
        echo -e "  ${YELLOW}⚠${NC} domain_name not found"
    fi
else
    echo -e "${RED}✗${NC} terraform/terraform.tfvars NOT FOUND"
    echo "  Create it with: cp terraform/terraform.tfvars.example terraform/terraform.tfvars"
    ((REQUIRED_FAIL++))
fi

# =============================================================================
# 4. GitHub Secrets Check
# =============================================================================
section "4. GitHub Secrets"

if command -v gh &> /dev/null; then
    echo -e "${BLUE}ℹ${NC} Checking GitHub secrets (requires GitHub CLI)..."
    
    if gh secret list 2>/dev/null | grep -q "AWS_ACCESS_KEY_ID"; then
        echo -e "${GREEN}✓${NC} AWS_ACCESS_KEY_ID secret configured"
        ((OPTIONAL_OK++))
    else
        echo -e "${YELLOW}⚠${NC} AWS_ACCESS_KEY_ID secret not found"
        ((OPTIONAL_FAIL++))
    fi
    
    if gh secret list 2>/dev/null | grep -q "AWS_SECRET_ACCESS_KEY"; then
        echo -e "${GREEN}✓${NC} AWS_SECRET_ACCESS_KEY secret configured"
        ((OPTIONAL_OK++))
    else
        echo -e "${YELLOW}⚠${NC} AWS_SECRET_ACCESS_KEY secret not found"
        ((OPTIONAL_FAIL++))
    fi
    
    if gh secret list 2>/dev/null | grep -q "GH_TOKEN_AMPLIFY"; then
        echo -e "${GREEN}✓${NC} GH_TOKEN_AMPLIFY secret configured"
        ((OPTIONAL_OK++))
    else
        echo -e "${YELLOW}⚠${NC} GH_TOKEN_AMPLIFY secret not found"
        ((OPTIONAL_FAIL++))
    fi
else
    echo -e "${YELLOW}⚠${NC} GitHub CLI not installed - cannot check secrets"
    echo "  Install: https://cli.github.com"
    echo "  Or check manually in: GitHub Settings → Secrets and variables → Actions"
fi

# =============================================================================
# 5. AWS Resources Check
# =============================================================================
section "5. AWS Resources"

if command -v aws &> /dev/null; then
    # Hosted Zone
    if aws route53 list-hosted-zones-by-name --query "HostedZones[?Name=='atercates.cat.']" 2>/dev/null | grep -q "atercates.cat"; then
        echo -e "${GREEN}✓${NC} Hosted zone 'atercates.cat' found"
        ((OPTIONAL_OK++))
    else
        echo -e "${YELLOW}⚠${NC} Hosted zone 'atercates.cat' not found"
        echo "  Create with: aws route53 create-hosted-zone --name atercates.cat --caller-reference \$(date +%s)"
        ((OPTIONAL_FAIL++))
    fi
    
    # Check for existing resources (if deployed before)
    if aws lambda get-function --function-name cv-visit-counter &>/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Lambda function 'cv-visit-counter' already deployed"
    else
        echo -e "${BLUE}ℹ${NC} Lambda function 'cv-visit-counter' not yet deployed (expected)"
    fi
else
    echo -e "${YELLOW}⚠${NC} AWS CLI not available - skipping resource checks"
fi

# =============================================================================
# 6. File Presence Check
# =============================================================================
section "6. Required Files"

files=(
    "curriculum/index.html"
    "lambda/visit_counter/handler.py"
    "terraform/main.tf"
    ".github/workflows/frontend-deploy.yml"
    ".github/workflows/backend-deploy.yml"
    ".github/workflows/terraform-deploy.yml"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
        ((REQUIRED_OK++))
    else
        echo -e "${RED}✗${NC} $file MISSING"
        ((REQUIRED_FAIL++))
    fi
done

# =============================================================================
# 7. Summary
# =============================================================================
section "Summary"

REQUIRED_TOTAL=$((REQUIRED_OK + REQUIRED_FAIL))
OPTIONAL_TOTAL=$((OPTIONAL_OK + OPTIONAL_FAIL))

echo ""
echo -e "${BLUE}Required Checks:${NC}"
echo -e "  ${GREEN}✓ Passed: $REQUIRED_OK${NC}"
echo -e "  ${RED}✗ Failed: $REQUIRED_FAIL${NC}"
echo ""

echo -e "${BLUE}Optional Checks:${NC}"
echo -e "  ${GREEN}✓ Passed: $OPTIONAL_OK${NC}"
echo -e "  ${YELLOW}⚠ Failed: $OPTIONAL_FAIL${NC}"
echo ""

# Final verdict
if [ $REQUIRED_FAIL -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ SETUP COMPLETE! Ready to deploy${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Deploy infrastructure:"
    echo "     cd terraform && terraform init"
    echo "     terraform apply -var=\"github_token=YOUR_TOKEN\""
    echo ""
    echo "  2. Update Amplify API endpoint:"
    echo "     Edit: curriculum/scripts/visitor-counter.js"
    echo "     Replace: const API_ENDPOINT = \"...\""
    echo ""
    echo "  3. Commit and push:"
    echo "     git add . && git commit -m 'Deploy'"
    echo "     git push origin main"
    echo ""
    
    if [ $OPTIONAL_FAIL -gt 0 ]; then
        echo -e "${YELLOW}Note: $OPTIONAL_FAIL optional check(s) failed.${NC}"
        echo "Review them but they won't block deployment."
        echo ""
    fi
    
    exit 0
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}✗ SETUP INCOMPLETE - $REQUIRED_FAIL critical issue(s)${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Fix the issues above before proceeding."
    echo ""
    echo "For detailed setup instructions, see:"
    echo "  - SETUP_GUIDE.md (complete guide)"
    echo "  - CONFIG_MAP.md (visual reference)"
    echo ""
    exit 1
fi
