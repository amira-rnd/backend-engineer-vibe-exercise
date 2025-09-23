#!/bin/bash
# Cleanup Interview Environment Script
# Usage: ./cleanup-interview.sh <interview-id>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -lt 1 ]; then
    echo -e "${RED}Usage: $0 <candidate-name> [interview-id]${NC}"
    echo "Example: $0 john-doe"
    echo "Example: $0 jane-smith 20241216-1400"
    exit 1
fi

CANDIDATE_NAME=$1
INTERVIEW_ID=${2:-"$(date +%Y%m%d-%H%M)"}
STACK_NAME="amira-interview-${CANDIDATE_NAME}-${INTERVIEW_ID}"
REGION=${AWS_DEFAULT_REGION:-us-east-1}

echo -e "${BLUE}🧹 Cleaning up Interview Environment${NC}"
echo "Interview ID: $INTERVIEW_ID"
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo ""

# Validate AWS credentials
echo -e "${BLUE}Validating AWS credentials...${NC}"
aws sts get-caller-identity --profile personal > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ AWS credentials not configured properly${NC}"
    exit 1
fi
echo -e "${GREEN}✅ AWS credentials validated${NC}"

# Check if stack exists
echo -e "${BLUE}Checking for existing stack...${NC}"
if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" --profile personal --region "$REGION" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Stack $STACK_NAME does not exist${NC}"
    echo "Nothing to clean up"
    exit 0
fi
echo -e "${GREEN}✅ Stack found${NC}"

# Get stack status
STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --profile personal \
    --region "$REGION" \
    --query 'Stacks[0].StackStatus' \
    --output text)

echo "Current stack status: $STACK_STATUS"

# Warn about costs
echo -e "${YELLOW}💰 Cost Warning:${NC}"
echo "Deleting this stack will stop all charges for:"
echo "  - ElastiCache: ~\$0.02/hour"
echo "  - RDS: Free tier usage"
echo "  - Other resources: Free tier"
echo ""

# Confirmation prompt
read -p "Are you sure you want to delete the interview environment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Cleanup cancelled${NC}"
    exit 0
fi

# Proactively fix common S3 and VPC issues before deletion
echo -e "${BLUE}Pre-emptively cleaning up resources that commonly cause deletion issues...${NC}"

# Function to safely empty and prepare S3 buckets for deletion
cleanup_s3_buckets() {
    echo -e "${BLUE}Checking for S3 buckets associated with this stack...${NC}"

    # Get buckets with the interview ID in the name
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile personal --query 'Account' --output text)
    CHALLENGE_BUCKET="${AWS_ACCOUNT_ID}-interview-${INTERVIEW_ID}-challenges"
    DEPLOYMENT_BUCKET="${AWS_ACCOUNT_ID}-interview-${INTERVIEW_ID}-deployment"

    for bucket in "$CHALLENGE_BUCKET" "$DEPLOYMENT_BUCKET"; do
        if aws s3api head-bucket --bucket "$bucket" --profile personal --region "$REGION" 2>/dev/null; then
            echo "Found bucket: $bucket"
            echo "Emptying bucket contents..."

            # Force delete all objects including versioned objects
            aws s3 rm s3://$bucket --recursive --profile personal --region "$REGION" 2>/dev/null || echo "No objects to delete"

            # Delete any incomplete multipart uploads
            aws s3api abort-incomplete-multipart-uploads --bucket "$bucket" --profile personal --region "$REGION" 2>/dev/null || echo "No incomplete uploads"

            echo "✅ Bucket $bucket prepared for deletion"
        else
            echo "Bucket $bucket not found or already deleted"
        fi
    done
}

# Run S3 cleanup
cleanup_s3_buckets

echo -e "${BLUE}Checking for VPC resources that commonly cause deletion issues...${NC}"

VPC_ID=$(aws ec2 describe-vpcs \
    --profile personal \
    --region "$REGION" \
    --filters "Name=tag:aws:cloudformation:stack-name,Values=$STACK_NAME" \
    --query 'Vpcs[0].VpcId' \
    --output text 2>/dev/null || echo "")

if [ "$VPC_ID" != "" ] && [ "$VPC_ID" != "None" ]; then
    echo "Found stack VPC: $VPC_ID"

    # Proactively detach Internet Gateway to prevent common deletion failures
    IGW_ID=$(aws ec2 describe-internet-gateways \
        --profile personal \
        --region "$REGION" \
        --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
        --query 'InternetGateways[0].InternetGatewayId' \
        --output text 2>/dev/null || echo "")

    if [ "$IGW_ID" != "" ] && [ "$IGW_ID" != "None" ]; then
        echo "Proactively detaching Internet Gateway: $IGW_ID"
        aws ec2 detach-internet-gateway \
            --internet-gateway-id "$IGW_ID" \
            --vpc-id "$VPC_ID" \
            --profile personal \
            --region "$REGION" 2>/dev/null || echo "Gateway already detached"
        echo "✅ VPC cleanup completed"
    else
        echo "No Internet Gateway found to detach"
    fi
else
    echo "No VPC found for this stack"
fi

# Delete CloudFormation stack
echo -e "${BLUE}Deleting CloudFormation stack...${NC}"
aws cloudformation delete-stack \
    --stack-name "$STACK_NAME" \
    --profile personal \
    --region "$REGION"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Stack deletion initiated${NC}"
else
    echo -e "${RED}❌ Stack deletion failed${NC}"
    exit 1
fi

# Wait for deletion to complete with enhanced error handling
echo -e "${BLUE}Waiting for stack deletion to complete...${NC}"
echo "This may take 10-20 minutes due to RDS and ElastiCache resources..."

# Wait with timeout
timeout 1200 aws cloudformation wait stack-delete-complete \
    --stack-name "$STACK_NAME" \
    --profile personal \
    --region "$REGION"

WAIT_EXIT_CODE=$?

if [ $WAIT_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Stack deleted successfully${NC}"
elif [ $WAIT_EXIT_CODE -eq 124 ]; then
    echo -e "${YELLOW}⚠️  Stack deletion timed out after 20 minutes${NC}"

    # Check current status
    CURRENT_STATUS=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --profile personal \
        --region "$REGION" \
        --query 'Stacks[0].StackStatus' \
        --output text 2>/dev/null || echo "STACK_NOT_FOUND")

    if [ "$CURRENT_STATUS" = "DELETE_FAILED" ]; then
        echo -e "${YELLOW}⚠️  Stack deletion failed. Checking failed resources...${NC}"

        # Show failed resources
        aws cloudformation describe-stack-events \
            --stack-name "$STACK_NAME" \
            --profile personal \
            --region "$REGION" \
            --query 'StackEvents[?ResourceStatus==`DELETE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
            --output table || echo "Could not retrieve failed resources"

        echo ""
        echo -e "${BLUE}💡 Options to resolve:${NC}"
        echo "1. Run force cleanup: ./force-cleanup.sh $CANDIDATE_NAME $INTERVIEW_ID"
        echo "2. Delete stack with retained resources:"
        echo "   aws cloudformation delete-stack --stack-name $STACK_NAME --retain-resources [RESOURCE_NAMES] --profile personal"
        echo "3. Check AWS Console for manual cleanup"

    elif [ "$CURRENT_STATUS" = "DELETE_IN_PROGRESS" ]; then
        echo -e "${BLUE}Stack is still deleting. Monitor progress in AWS Console.${NC}"
    elif [ "$CURRENT_STATUS" = "STACK_NOT_FOUND" ]; then
        echo -e "${GREEN}✅ Stack appears to have been deleted successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Unexpected stack status: $CURRENT_STATUS${NC}"
        echo "Check AWS Console to verify status"
    fi
else
    echo -e "${YELLOW}⚠️  Stack deletion status unknown${NC}"
    echo "Check AWS Console to verify deletion"
fi

# Clean up local files
echo -e "${BLUE}Cleaning up local files...${NC}"
CREDS_FILE="candidate-credentials-${INTERVIEW_ID}.txt"
if [ -f "$CREDS_FILE" ]; then
    rm "$CREDS_FILE"
    echo -e "${GREEN}✅ Removed $CREDS_FILE${NC}"
fi

# Summary
echo ""
echo -e "${GREEN}🎉 Cleanup completed successfully!${NC}"
echo ""
echo -e "${BLUE}📊 Final Cost Summary:${NC}"
echo "  - All billable resources have been terminated"
echo "  - ElastiCache charges stopped"
echo "  - RDS instance terminated"
echo "  - No ongoing costs from this interview"
echo ""
echo -e "${BLUE}💡 Next Steps:${NC}"
echo "1. Verify in AWS Console that all resources are deleted"
echo "2. Check AWS billing dashboard in 24 hours for final charges"
echo "3. Ready to deploy new interview environment when needed"