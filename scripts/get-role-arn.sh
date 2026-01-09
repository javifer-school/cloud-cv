#!/bin/bash
# Script to get the Lambda role ARN for AWS Learner Lab

echo "Getting AWS account information..."
IDENTITY=$(aws sts get-caller-identity 2>/dev/null)

if [ $? -eq 0 ]; then
    ACCOUNT_ID=$(echo $IDENTITY | jq -r '.Account')
    CURRENT_ARN=$(echo $IDENTITY | jq -r '.Arn')
    
    echo ""
    echo "Current AWS Identity:"
    echo "Account ID: $ACCOUNT_ID"
    echo "ARN: $CURRENT_ARN"
    echo ""
    
    # Extract role name from ARN (e.g., LabRole or voclabs)
    if [[ $CURRENT_ARN == *"assumed-role"* ]]; then
        ROLE_NAME=$(echo $CURRENT_ARN | cut -d'/' -f2)
        ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
        
        echo "Detected IAM Role for Lambda:"
        echo "Role ARN: $ROLE_ARN"
        echo ""
        echo "Add this to your terraform.tfvars file:"
        echo "lambda_role_arn = \"$ROLE_ARN\""
    else
        echo "Warning: Not using an assumed role. You may need to specify the role manually."
        echo "Common Learner Lab role: arn:aws:iam::${ACCOUNT_ID}:role/LabRole"
    fi
else
    echo "Error: AWS CLI is not configured or credentials are invalid"
    exit 1
fi
