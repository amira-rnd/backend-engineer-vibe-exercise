#!/bin/bash
# Force Cleanup Interview Environment Script
# Usage: ./force-cleanup.sh <candidate-name> [interview-id]
# This script forcefully removes AWS resources when normal CloudFormation deletion fails

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
PROFILE=${AWS_PROFILE:-personal}

echo -e "${BLUE}🚨 FORCE CLEANUP - Interview Environment${NC}"
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo "Profile: $PROFILE"
echo ""

# Validate AWS credentials
echo -e "${BLUE}Validating AWS credentials...${NC}"
aws sts get-caller-identity --profile $PROFILE > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ AWS credentials not configured properly${NC}"
    exit 1
fi
echo -e "${GREEN}✅ AWS credentials validated${NC}"

# Warning
echo -e "${RED}⚠️  WARNING: This script will forcefully delete AWS resources${NC}"
echo -e "${RED}⚠️  Use only when normal cleanup has failed${NC}"
echo -e "${RED}⚠️  This may leave some resources orphaned${NC}"
echo ""

# Confirmation
read -p "Are you absolutely sure you want to force cleanup? (type 'FORCE' to continue): " -r
if [[ $REPLY != "FORCE" ]]; then
    echo -e "${BLUE}Force cleanup cancelled${NC}"
    exit 0
fi

echo -e "${BLUE}Starting force cleanup...${NC}"

# Function to safely delete resources with error handling
safe_delete() {
    local resource_type=$1
    local resource_id=$2
    local command=$3

    echo -e "${BLUE}Attempting to delete $resource_type: $resource_id${NC}"
    if eval $command 2>/dev/null; then
        echo -e "${GREEN}✅ Successfully deleted $resource_type: $resource_id${NC}"
    else
        echo -e "${YELLOW}⚠️  Failed to delete $resource_type: $resource_id (may not exist)${NC}"
    fi
}

# 1. Force empty and delete S3 buckets
echo -e "${BLUE}=== Step 1: S3 Buckets ===${NC}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile $PROFILE --query 'Account' --output text --no-cli-pager)
CHALLENGE_BUCKET="${AWS_ACCOUNT_ID}-challenges"
DEPLOYMENT_BUCKET="${AWS_ACCOUNT_ID}-deployment"

for bucket in "$CHALLENGE_BUCKET" "$DEPLOYMENT_BUCKET"; do
    if aws s3api head-bucket --bucket "$bucket" --profile $PROFILE --region $REGION 2>/dev/null; then
        echo "Force emptying bucket: $bucket"

        # Delete all objects including versions
        aws s3 rm s3://$bucket --recursive --profile $PROFILE --region $REGION 2>/dev/null || true

        # Abort incomplete multipart uploads
        aws s3api abort-incomplete-multipart-uploads --bucket "$bucket" --profile $PROFILE --region $REGION 2>/dev/null || true

        # Delete all versions if versioning was enabled
        aws s3api delete-objects --bucket "$bucket" \
            --delete "$(aws s3api list-object-versions --bucket "$bucket" --profile $PROFILE --region $REGION \
            --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null || echo '{}')" \
            --profile $PROFILE --region $REGION 2>/dev/null || true

        # Delete delete markers
        aws s3api delete-objects --bucket "$bucket" \
            --delete "$(aws s3api list-object-versions --bucket "$bucket" --profile $PROFILE --region $REGION \
            --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json 2>/dev/null || echo '{}')" \
            --profile $PROFILE --region $REGION 2>/dev/null || true

        # Force delete bucket
        safe_delete "S3 Bucket" "$bucket" "aws s3api delete-bucket --bucket '$bucket' --profile $PROFILE --region $REGION"
    else
        echo "Bucket $bucket not found or already deleted"
    fi
done

# 2. Delete Lambda functions
echo -e "${BLUE}=== Step 2: Lambda Functions ===${NC}"
LAMBDA_FUNCTIONS=(
    "interview-sample-data-api"
    "interview-memory-leak-function"
)

for func in "${LAMBDA_FUNCTIONS[@]}"; do
    safe_delete "Lambda Function" "$func" "aws lambda delete-function --function-name '$func' --profile $PROFILE --region $REGION"
done

# 3. Delete API Gateway
echo -e "${BLUE}=== Step 3: API Gateway ===${NC}"
API_ID=$(aws apigateway get-rest-apis --profile $PROFILE --region $REGION \
    --query "items[?name=='interview-api'].id" --output text --no-cli-pager 2>/dev/null || echo "")

if [ "$API_ID" != "" ] && [ "$API_ID" != "None" ]; then
    safe_delete "API Gateway" "$API_ID" "aws apigateway delete-rest-api --rest-api-id '$API_ID' --profile $PROFILE --region $REGION"
fi

# 4. Delete RDS instances
echo -e "${BLUE}=== Step 4: RDS Instances ===${NC}"
DB_INSTANCE="interview-db-performance"
safe_delete "RDS Instance" "$DB_INSTANCE" "aws rds delete-db-instance --db-instance-identifier '$DB_INSTANCE' --skip-final-snapshot --profile $PROFILE --region $REGION"

# 5. Delete ElastiCache clusters
echo -e "${BLUE}=== Step 5: ElastiCache Clusters ===${NC}"
CACHE_CLUSTER="interview-cache"
safe_delete "ElastiCache Cluster" "$CACHE_CLUSTER" "aws elasticache delete-cache-cluster --cache-cluster-id '$CACHE_CLUSTER' --profile $PROFILE --region $REGION"

# 6. Delete DynamoDB tables
echo -e "${BLUE}=== Step 6: DynamoDB Tables ===${NC}"
DYNAMO_TABLES=(
    "interview-students"
    "interview-assessments"
    "interview-classes"
    "interview-schools"
)

for table in "${DYNAMO_TABLES[@]}"; do
    safe_delete "DynamoDB Table" "$table" "aws dynamodb delete-table --table-name '$table' --profile $PROFILE --region $REGION"
done

# 7. Delete VPC components (in correct order)
echo -e "${BLUE}=== Step 7: VPC Components ===${NC}"

# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs \
    --profile $PROFILE \
    --region $REGION \
    --filters "Name=tag:aws:cloudformation:stack-name,Values=$STACK_NAME" \
    --query 'Vpcs[0].VpcId' \
    --output text --no-cli-pager 2>/dev/null || echo "")

if [ "$VPC_ID" != "" ] && [ "$VPC_ID" != "None" ]; then
    echo "Found VPC: $VPC_ID"

    # Delete NAT Gateway first
    NAT_GW_ID=$(aws ec2 describe-nat-gateways \
        --profile $PROFILE \
        --region $REGION \
        --filter "Name=vpc-id,Values=$VPC_ID" \
        --query 'NatGateways[0].NatGatewayId' \
        --output text --no-cli-pager 2>/dev/null || echo "")

    if [ "$NAT_GW_ID" != "" ] && [ "$NAT_GW_ID" != "None" ]; then
        safe_delete "NAT Gateway" "$NAT_GW_ID" "aws ec2 delete-nat-gateway --nat-gateway-id '$NAT_GW_ID' --profile $PROFILE --region $REGION"
        echo "Waiting 60 seconds for NAT Gateway deletion..."
        sleep 60
    fi

    # Detach and delete Internet Gateway
    IGW_ID=$(aws ec2 describe-internet-gateways \
        --profile $PROFILE \
        --region $REGION \
        --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
        --query 'InternetGateways[0].InternetGatewayId' \
        --output text --no-cli-pager 2>/dev/null || echo "")

    if [ "$IGW_ID" != "" ] && [ "$IGW_ID" != "None" ]; then
        echo "Detaching Internet Gateway: $IGW_ID"
        aws ec2 detach-internet-gateway \
            --internet-gateway-id "$IGW_ID" \
            --vpc-id "$VPC_ID" \
            --profile $PROFILE \
            --region $REGION 2>/dev/null || true

        safe_delete "Internet Gateway" "$IGW_ID" "aws ec2 delete-internet-gateway --internet-gateway-id '$IGW_ID' --profile $PROFILE --region $REGION"
    fi

    # Delete subnets
    SUBNET_IDS=$(aws ec2 describe-subnets \
        --profile $PROFILE \
        --region $REGION \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query 'Subnets[].SubnetId' \
        --output text --no-cli-pager 2>/dev/null || echo "")

    for subnet_id in $SUBNET_IDS; do
        if [ "$subnet_id" != "" ] && [ "$subnet_id" != "None" ]; then
            safe_delete "Subnet" "$subnet_id" "aws ec2 delete-subnet --subnet-id '$subnet_id' --profile $PROFILE --region $REGION"
        fi
    done

    # Delete route tables (except main)
    ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables \
        --profile $PROFILE \
        --region $REGION \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.main,Values=false" \
        --query 'RouteTables[].RouteTableId' \
        --output text --no-cli-pager 2>/dev/null || echo "")

    for rt_id in $ROUTE_TABLE_IDS; do
        if [ "$rt_id" != "" ] && [ "$rt_id" != "None" ]; then
            safe_delete "Route Table" "$rt_id" "aws ec2 delete-route-table --route-table-id '$rt_id' --profile $PROFILE --region $REGION"
        fi
    done

    # Delete security groups (except default)
    SG_IDS=$(aws ec2 describe-security-groups \
        --profile $PROFILE \
        --region $REGION \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
        --output text --no-cli-pager 2>/dev/null || echo "")

    for sg_id in $SG_IDS; do
        if [ "$sg_id" != "" ] && [ "$sg_id" != "None" ]; then
            safe_delete "Security Group" "$sg_id" "aws ec2 delete-security-group --group-id '$sg_id' --profile $PROFILE --region $REGION"
        fi
    done

    # Finally delete VPC
    safe_delete "VPC" "$VPC_ID" "aws ec2 delete-vpc --vpc-id '$VPC_ID' --profile $PROFILE --region $REGION"
else
    echo "No VPC found for this stack"
fi

# 8. Try to delete CloudFormation stack one more time
echo -e "${BLUE}=== Step 8: Final CloudFormation Stack Deletion ===${NC}"
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --profile $PROFILE --region $REGION >/dev/null 2>&1; then
    echo "Attempting final CloudFormation stack deletion..."
    aws cloudformation delete-stack \
        --stack-name "$STACK_NAME" \
        --profile $PROFILE \
        --region $REGION

    echo "Waiting for stack deletion (timeout 5 minutes)..."
    timeout 300 aws cloudformation wait stack-delete-complete \
        --stack-name "$STACK_NAME" \
        --profile $PROFILE \
        --region $REGION || echo "Stack deletion timed out - check AWS Console"
else
    echo "CloudFormation stack no longer exists"
fi

# 9. Clean up local files
echo -e "${BLUE}=== Step 9: Local File Cleanup ===${NC}"
CREDS_FILE="candidate-credentials-${INTERVIEW_ID}.txt"
if [ -f "$CREDS_FILE" ]; then
    rm "$CREDS_FILE"
    echo -e "${GREEN}✅ Removed $CREDS_FILE${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Force cleanup completed!${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Verify in AWS Console that all resources are deleted${NC}"
echo -e "${YELLOW}⚠️  Some resources may take additional time to fully delete${NC}"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Check AWS Console for any remaining resources"
echo "2. Monitor AWS billing for unexpected charges"
echo "3. If issues persist, contact AWS Support"