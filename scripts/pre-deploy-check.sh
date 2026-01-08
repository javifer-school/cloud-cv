#!/bin/bash

# =============================================================================
# Cloud CV - Pre-deployment Checklist Script
# =============================================================================
# This script verifies that all required components are in place before
# deploying the infrastructure to AWS.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

# Helper functions
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((CHECKS_FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Start
clear
echo -e "${BLUE}"
cat << "EOF"
   ____ _                 _    ____ __     __
  / ___| | ___  _   _  __| |  / ___|\ \   / /
 | |   | |/ _ \| | | |/ _` | | |     \ \ / / 
 | |___| | (_) | |_| | (_| | | |___   \ V /  
  \____|_|\___/ \__,_|\__,_|  \____|   \_/   
                                              
  Pre-deployment Checklist
EOF
echo -e "${NC}"

# =============================================================================
# 1. File Structure Check
# =============================================================================
section "1. Checking File Structure"

# Frontend files
if [ -f "curriculum/index.html" ]; then
    check_pass "curriculum/index.html exists"
else
    check_fail "curriculum/index.html not found"
fi

if [ -f "curriculum/styles/main.css" ]; then
    check_pass "curriculum/styles/main.css exists"
else
    check_fail "curriculum/styles/main.css not found"
fi

if [ -f "curriculum/scripts/visitor-counter.js" ]; then
    check_pass "curriculum/scripts/visitor-counter.js exists"
else
    check_fail "curriculum/scripts/visitor-counter.js not found"
fi

# Lambda files
if [ -f "lambda/visit_counter/handler.py" ]; then
    check_pass "lambda/visit_counter/handler.py exists"
else
    check_fail "lambda/visit_counter/handler.py not found"
fi

if [ -f "lambda/tests/test_handler.py" ]; then
    check_pass "lambda/tests/test_handler.py exists"
else
    check_fail "lambda/tests/test_handler.py not found"
fi

# Terraform files
if [ -f "terraform/main.tf" ]; then
    check_pass "terraform/main.tf exists"
else
    check_fail "terraform/main.tf not found"
fi

if [ -d "terraform/modules/dynamodb" ]; then
    check_pass "terraform/modules/dynamodb exists"
else
    check_fail "terraform/modules/dynamodb not found"
fi

if [ -d "terraform/modules/lambda" ]; then
    check_pass "terraform/modules/lambda exists"
else
    check_fail "terraform/modules/lambda not found"
fi

if [ -d "terraform/modules/amplify" ]; then
    check_pass "terraform/modules/amplify exists"
else
    check_fail "terraform/modules/amplify not found"
fi

if [ -d "terraform/modules/dns" ]; then
    check_pass "terraform/modules/dns exists"
else
    check_fail "terraform/modules/dns not found"
fi

# GitHub Actions
if [ -f ".github/workflows/frontend-deploy.yml" ]; then
    check_pass ".github/workflows/frontend-deploy.yml exists"
else
    check_fail ".github/workflows/frontend-deploy.yml not found"
fi

if [ -f ".github/workflows/backend-deploy.yml" ]; then
    check_pass ".github/workflows/backend-deploy.yml exists"
else
    check_fail ".github/workflows/backend-deploy.yml not found"
fi

if [ -f ".github/workflows/terraform-deploy.yml" ]; then
    check_pass ".github/workflows/terraform-deploy.yml exists"
else
    check_fail ".github/workflows/terraform-deploy.yml not found"
fi

# =============================================================================
# 2. Tool Availability Check
# =============================================================================
section "2. Checking Required Tools"

# Terraform
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
    check_pass "Terraform installed (v$TF_VERSION)"
else
    check_fail "Terraform not installed"
fi

# AWS CLI
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version | cut -d' ' -f1 | cut -d'/' -f2)
    check_pass "AWS CLI installed (v$AWS_VERSION)"
else
    check_warn "AWS CLI not installed (recommended for testing)"
fi

# Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    check_pass "Python 3 installed (v$PYTHON_VERSION)"
else
    check_fail "Python 3 not installed"
fi

# Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    check_pass "Git installed (v$GIT_VERSION)"
else
    check_fail "Git not installed"
fi

# =============================================================================
# 3. AWS Credentials Check
# =============================================================================
section "3. Checking AWS Configuration"

if [ -f "$HOME/.aws/credentials" ] || [ -n "$AWS_ACCESS_KEY_ID" ]; then
    check_pass "AWS credentials configured"
    
    if command -v aws &> /dev/null; then
        if aws sts get-caller-identity &> /dev/null; then
            ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
            check_pass "AWS credentials valid (Account: $ACCOUNT_ID)"
        else
            check_fail "AWS credentials invalid or expired"
        fi
    fi
else
    check_warn "AWS credentials not found (set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY)"
fi

# =============================================================================
# 4. Python Dependencies Check
# =============================================================================
section "4. Checking Python Dependencies"

if [ -f "lambda/tests/requirements-test.txt" ]; then
    check_pass "Test requirements file exists"
    
    if command -v pip3 &> /dev/null; then
        if pip3 show pytest &> /dev/null; then
            check_pass "pytest installed"
        else
            check_warn "pytest not installed (run: pip install -r lambda/tests/requirements-test.txt)"
        fi
    fi
fi

# =============================================================================
# 5. Terraform Validation
# =============================================================================
section "5. Validating Terraform Configuration"

cd terraform

if terraform fmt -check -recursive &> /dev/null; then
    check_pass "Terraform code is properly formatted"
else
    check_warn "Terraform code needs formatting (run: terraform fmt -recursive)"
fi

if terraform init -backend=false &> /dev/null; then
    check_pass "Terraform initialization successful"
    
    if terraform validate &> /dev/null; then
        check_pass "Terraform configuration is valid"
    else
        check_fail "Terraform validation failed"
    fi
else
    check_fail "Terraform initialization failed"
fi

cd ..

# =============================================================================
# 6. Git Repository Check
# =============================================================================
section "6. Checking Git Configuration"

if [ -d ".git" ]; then
    check_pass "Git repository initialized"
    
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$REMOTE_URL" ]; then
        check_pass "Git remote configured: $REMOTE_URL"
    else
        check_warn "Git remote not configured"
    fi
    
    CURRENT_BRANCH=$(git branch --show-current)
    check_pass "Current branch: $CURRENT_BRANCH"
    
    if [ "$(git status --porcelain | wc -l)" -gt 0 ]; then
        check_warn "Uncommitted changes detected"
    else
        check_pass "No uncommitted changes"
    fi
else
    check_fail "Not a git repository"
fi

# =============================================================================
# Summary
# =============================================================================
section "Summary"

TOTAL_CHECKS=$((CHECKS_PASSED + CHECKS_FAILED))

echo ""
echo -e "Checks passed:  ${GREEN}$CHECKS_PASSED${NC}"
echo -e "Checks failed:  ${RED}$CHECKS_FAILED${NC}"
echo -e "Warnings:       ${YELLOW}$WARNINGS${NC}"
echo -e "Total checks:   $TOTAL_CHECKS"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "You're ready to deploy! Next steps:"
    echo ""
    echo "  1. Configure GitHub Secrets:"
    echo "     - AWS_ACCESS_KEY_ID"
    echo "     - AWS_SECRET_ACCESS_KEY"
    echo "     - GH_TOKEN_AMPLIFY"
    echo ""
    echo "  2. Deploy infrastructure:"
    echo "     cd terraform"
    echo "     terraform init"
    echo "     terraform apply -var=\"github_token=YOUR_TOKEN\""
    echo ""
    echo "  3. Push to GitHub:"
    echo "     git add ."
    echo "     git commit -m \"Initial deployment\""
    echo "     git push origin main"
    echo ""
    
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Note: $WARNINGS warning(s) detected. Review them before deploying.${NC}"
        echo ""
    fi
    
    exit 0
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}✗ $CHECKS_FAILED check(s) failed!${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Please fix the failed checks before deploying."
    echo ""
    exit 1
fi
