#!/bin/bash
# Verify Interview Environment Readiness
# Usage: ./verify-interview-environment.sh <candidate-name> [interview-id]

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
    echo "Example: $0 jane-smith public-v3"
    exit 1
fi

CANDIDATE_NAME=$1
INTERVIEW_ID=${2:-"$(date +%Y%m%d-%H%M)"}
STACK_NAME="amira-interview-${CANDIDATE_NAME}-${INTERVIEW_ID}"
REGION=${AWS_DEFAULT_REGION:-us-east-1}

echo -e "${BLUE}🔍 Verifying Interview Environment Readiness${NC}"
echo "Candidate: $CANDIDATE_NAME"
echo "Interview ID: $INTERVIEW_ID"
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo ""

# Initialize verification results
VERIFICATION_PASSED=true
VERIFICATION_REPORT=""

# Test 1: CloudFormation Stack Status
echo -e "${BLUE}1. Checking CloudFormation stack status...${NC}"
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --profile personal --region "$REGION" --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$STACK_STATUS" = "CREATE_COMPLETE" ] || [ "$STACK_STATUS" = "UPDATE_COMPLETE" ]; then
    echo -e "   ${GREEN}✅ Stack status: $STACK_STATUS${NC}"
    VERIFICATION_REPORT+="\n✅ CloudFormation: Stack ready ($STACK_STATUS)"
else
    echo -e "   ${RED}❌ Stack status: $STACK_STATUS${NC}"
    VERIFICATION_REPORT+="\n❌ CloudFormation: Stack not ready ($STACK_STATUS)"
    VERIFICATION_PASSED=false
fi

# Get stack outputs if stack exists
if [ "$STACK_STATUS" = "CREATE_COMPLETE" ] || [ "$STACK_STATUS" = "UPDATE_COMPLETE" ]; then
    OUTPUTS=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --profile personal \
        --region "$REGION" \
        --query 'Stacks[0].Outputs' \
        --output json)

    DB_ENDPOINT=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="DatabaseEndpoint") | .OutputValue')
    DB_PASSWORD=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="DatabasePassword") | .OutputValue')
    STUDENTS_TABLE=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="StudentsTableName") | .OutputValue')
    LAMBDA_ARN=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="BuggyLambdaArn") | .OutputValue')
    SAMPLE_DATA_URL=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="SampleDataApiUrl") | .OutputValue')

    # Test 2: PostgreSQL Data
    echo -e "${BLUE}2. Checking PostgreSQL database...${NC}"
    export PGPASSWORD="$DB_PASSWORD"

    STUDENT_COUNT=$(psql -h "$DB_ENDPOINT" -U postgres -d postgres -t -c "SELECT COUNT(*) FROM students;" 2>/dev/null | xargs || echo "0")
    ASSESSMENT_COUNT=$(psql -h "$DB_ENDPOINT" -U postgres -d postgres -t -c "SELECT COUNT(*) FROM assessments;" 2>/dev/null | xargs || echo "0")

    if [ "$STUDENT_COUNT" -gt 0 ] && [ "$ASSESSMENT_COUNT" -gt 0 ]; then
        echo -e "   ${GREEN}✅ PostgreSQL: $STUDENT_COUNT students, $ASSESSMENT_COUNT assessments${NC}"
        VERIFICATION_REPORT+="\n✅ PostgreSQL: $STUDENT_COUNT students, $ASSESSMENT_COUNT assessments"

        # Check for intentional data issues
        BAD_READING_LEVELS=$(psql -h "$DB_ENDPOINT" -U postgres -d postgres -t -c "SELECT COUNT(*) FROM students WHERE reading_level < 0 OR reading_level IS NULL;" 2>/dev/null | xargs || echo "0")
        if [ "$BAD_READING_LEVELS" -gt 0 ]; then
            echo -e "   ${GREEN}✅ Data issues present: $BAD_READING_LEVELS students with bad reading levels${NC}"
            VERIFICATION_REPORT+="\n✅ Data Quality Issues: $BAD_READING_LEVELS problematic records (as expected)"
        else
            echo -e "   ${YELLOW}⚠️  No data quality issues found (may impact Challenge A)${NC}"
            VERIFICATION_REPORT+="\n⚠️  Data Quality: No problematic records found"
        fi
    else
        echo -e "   ${RED}❌ PostgreSQL: No data found ($STUDENT_COUNT students, $ASSESSMENT_COUNT assessments)${NC}"
        VERIFICATION_REPORT+="\n❌ PostgreSQL: No data found"
        VERIFICATION_PASSED=false
    fi

    unset PGPASSWORD

    # Test 3: DynamoDB Data
    echo -e "${BLUE}3. Checking DynamoDB tables...${NC}"
    DDB_SCAN_RESULT=$(aws dynamodb scan --table-name "$STUDENTS_TABLE" --limit 1 --profile personal --region "$REGION" 2>/dev/null || echo "{}")
    DDB_COUNT=$(echo "$DDB_SCAN_RESULT" | jq -r '.Count // 0')

    if [ "$DDB_COUNT" -gt 0 ]; then
        echo -e "   ${GREEN}✅ DynamoDB: Sample data present in $STUDENTS_TABLE${NC}"
        VERIFICATION_REPORT+="\n✅ DynamoDB: Sample data present"
    else
        echo -e "   ${RED}❌ DynamoDB: No sample data in $STUDENTS_TABLE${NC}"
        VERIFICATION_REPORT+="\n❌ DynamoDB: No sample data found"
        VERIFICATION_PASSED=false
    fi

    # Test 4: Lambda Function
    echo -e "${BLUE}4. Checking Lambda function...${NC}"
    LAMBDA_NAME=$(echo "$LAMBDA_ARN" | cut -d':' -f7)
    LAMBDA_STATE=$(aws lambda get-function --function-name "$LAMBDA_NAME" --profile personal --region "$REGION" --query 'Configuration.State' --output text 2>/dev/null || echo "NOT_FOUND")

    if [ "$LAMBDA_STATE" = "Active" ]; then
        echo -e "   ${GREEN}✅ Lambda: $LAMBDA_NAME is active${NC}"
        VERIFICATION_REPORT+="\n✅ Lambda: Function is active"
    else
        echo -e "   ${RED}❌ Lambda: $LAMBDA_NAME state is $LAMBDA_STATE${NC}"
        VERIFICATION_REPORT+="\n❌ Lambda: Function not ready ($LAMBDA_STATE)"
        VERIFICATION_PASSED=false
    fi

    # Test 5: Sample Data API
    echo -e "${BLUE}5. Checking Sample Data API...${NC}"
    API_RESPONSE=$(curl -s "$SAMPLE_DATA_URL" 2>/dev/null || echo "{}")
    API_FILES=$(echo "$API_RESPONSE" | jq -r '.available_files // [] | length' 2>/dev/null || echo "0")

    if [ "$API_FILES" -gt 0 ]; then
        echo -e "   ${GREEN}✅ Sample Data API: $API_FILES files available${NC}"
        VERIFICATION_REPORT+="\n✅ Sample Data API: $API_FILES files available"

        # Test specific file
        SCHEMA_RESPONSE=$(curl -s "$SAMPLE_DATA_URL?file=schemas.sql" 2>/dev/null || echo "")
        if [[ "$SCHEMA_RESPONSE" == *"CREATE TABLE"* ]]; then
            echo -e "   ${GREEN}✅ Schema file: Successfully retrieved${NC}"
            VERIFICATION_REPORT+="\n✅ Schema File: Retrieved successfully"
        else
            echo -e "   ${YELLOW}⚠️  Schema file: Unexpected content${NC}"
            VERIFICATION_REPORT+="\n⚠️  Schema File: Unexpected content"
        fi
    else
        echo -e "   ${RED}❌ Sample Data API: Not responding or no files${NC}"
        VERIFICATION_REPORT+="\n❌ Sample Data API: Not responding"
        VERIFICATION_PASSED=false
    fi

else
    echo -e "${RED}Skipping detailed checks - stack not ready${NC}"
fi

# Generate final report
echo ""
echo "════════════════════════════════════════════════════════════════"
echo -e "${BLUE}📋 VERIFICATION REPORT${NC}"
echo "════════════════════════════════════════════════════════════════"
echo -e "$VERIFICATION_REPORT"
echo ""

if [ "$VERIFICATION_PASSED" = true ]; then
    echo -e "${GREEN}🎉 ENVIRONMENT READY FOR INTERVIEW!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Generate candidate credentials: ./generate-credentials-email.sh $CANDIDATE_NAME $INTERVIEW_ID"
    echo "2. Send credentials to candidate 30 minutes before interview"
    echo "3. Start interview session"
    exit 0
else
    echo -e "${RED}⚠️  ENVIRONMENT NOT READY - Issues found${NC}"
    echo ""
    echo -e "${BLUE}Recommended actions:${NC}"
    echo "1. Check CloudFormation stack in AWS Console"
    echo "2. Re-run deployment: ./deploy-interview.sh $CANDIDATE_NAME $INTERVIEW_ID"
    echo "3. Wait for stack completion and run this script again"
    exit 1
fi