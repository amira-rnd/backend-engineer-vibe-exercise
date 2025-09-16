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

# Wait for deletion to complete
echo -e "${BLUE}Waiting for stack deletion to complete...${NC}"
echo "This may take several minutes..."

aws cloudformation wait stack-delete-complete \
    --stack-name "$STACK_NAME" \
    --profile personal \
    --region "$REGION"

WAIT_EXIT_CODE=$?

if [ $WAIT_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Stack deleted successfully${NC}"
elif [ $WAIT_EXIT_CODE -eq 255 ]; then
    echo -e "${RED}❌ Stack deletion failed or timed out${NC}"
    echo "Check AWS Console for details"
    exit 1
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