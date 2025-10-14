#!/bin/bash
# Generate AWS Credentials Email for Interview Candidate
# Usage: ./generate-credentials-email.sh <candidate-name> [interview-id]

set -e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
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
REGION=${AWS_DEFAULT_REGION:-us-east-1}

echo -e "${BLUE}🔐 Generating AWS Credentials Email${NC}"
echo "Candidate: $CANDIDATE_NAME"
echo "Interview ID: $INTERVIEW_ID"
echo "Region: $REGION"
echo ""

# Get stack outputs
STACK_NAME="amira-interview-${CANDIDATE_NAME}-${INTERVIEW_ID}"

echo -e "${BLUE}Fetching AWS resources from stack: $STACK_NAME${NC}"

# Check if stack exists and is ready
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --profile personal --region "$REGION" --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$STACK_STATUS" != "CREATE_COMPLETE" ] && [ "$STACK_STATUS" != "UPDATE_COMPLETE" ]; then
    echo -e "${RED}❌ Stack $STACK_NAME status: $STACK_STATUS${NC}"
    if [ "$STACK_STATUS" = "NOT_FOUND" ]; then
        echo "Available stacks:"
        aws cloudformation list-stacks --profile personal --region "$REGION" --query 'StackSummaries[?contains(StackName, `amira-interview`) && StackStatus != `DELETE_COMPLETE`].[StackName,StackStatus]' --output table
    else
        echo "Stack exists but is not ready. Current status: $STACK_STATUS"
        echo "Wait for stack to reach CREATE_COMPLETE or UPDATE_COMPLETE status, then try again."
    fi
    exit 1
fi

echo -e "${GREEN}✅ Stack is ready ($STACK_STATUS)${NC}"

# Get stack outputs
OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --profile personal \
    --region "$REGION" \
    --query 'Stacks[0].Outputs' \
    --output json)

# Extract values
CANDIDATE_ROLE=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="CandidateRoleArn") | .OutputValue')
DB_ENDPOINT=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="DatabaseEndpoint") | .OutputValue')
DB_PASSWORD=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="DatabasePassword") | .OutputValue')
REDIS_ENDPOINT=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="CacheEndpoint") | .OutputValue')
STUDENTS_TABLE=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="StudentsTableName") | .OutputValue')
ASSESSMENTS_TABLE=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="AssessmentsTableName") | .OutputValue')
CLASSES_TABLE=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="ClassesTableName") | .OutputValue')
SCHOOLS_TABLE=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="SchoolsTableName") | .OutputValue')
LAMBDA_ARN=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="BuggyLambdaArn") | .OutputValue')
SAMPLE_DATA_URL=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="SampleDataApiUrl") | .OutputValue')

# Extract Lambda function name from ARN
LAMBDA_NAME=$(echo "$LAMBDA_ARN" | cut -d':' -f7)

echo -e "${BLUE}Generating temporary credentials for candidate...${NC}"

# Assume role to get temporary credentials for candidate (12 hour duration - AWS maximum)
ROLE_RESPONSE=$(aws sts assume-role \
    --role-arn "$CANDIDATE_ROLE" \
    --role-session-name "interview-${CANDIDATE_NAME}" \
    --external-id "${INTERVIEW_ID}-${CANDIDATE_NAME}" \
    --duration-seconds 43200 \
    --profile personal \
    --region "$REGION" \
    --output json)

# Extract credentials from response
TEMP_ACCESS_KEY=$(echo "$ROLE_RESPONSE" | jq -r '.Credentials.AccessKeyId')
TEMP_SECRET_KEY=$(echo "$ROLE_RESPONSE" | jq -r '.Credentials.SecretAccessKey')
TEMP_SESSION_TOKEN=$(echo "$ROLE_RESPONSE" | jq -r '.Credentials.SessionToken')
EXPIRATION=$(echo "$ROLE_RESPONSE" | jq -r '.Credentials.Expiration')

echo -e "${GREEN}✅ Temporary credentials generated (expires: $EXPIRATION)${NC}"

# Validate all connections using the temporary credentials
echo -e "${BLUE}🔍 Running validation tests with candidate credentials...${NC}"

# Set up environment with temporary credentials for testing
export AWS_ACCESS_KEY_ID="$TEMP_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$TEMP_SECRET_KEY"
export AWS_SESSION_TOKEN="$TEMP_SESSION_TOKEN"
export AWS_DEFAULT_REGION="$REGION"

# Initialize validation report
VALIDATION_REPORT=""
VALIDATION_PASSED=true

# Test 1: AWS Identity
echo -n "  Testing AWS identity... "
if aws sts get-caller-identity --output json >/dev/null 2>&1; then
    echo -e "${GREEN}✅${NC}"
    VALIDATION_REPORT+="\n✅ AWS Identity: Successfully assumed role"
else
    echo -e "${RED}❌${NC}"
    VALIDATION_REPORT+="\n❌ AWS Identity: Failed to verify assumed role"
    VALIDATION_PASSED=false
fi

# Test 2: DynamoDB Access (test specific table access, not ListTables)
echo -n "  Testing DynamoDB access... "
if aws dynamodb scan --table-name "$STUDENTS_TABLE" --limit 1 --output json >/dev/null 2>&1; then
    echo -e "${GREEN}✅${NC}"
    VALIDATION_REPORT+="\n✅ DynamoDB: Successfully accessed students table"
else
    echo -e "${RED}❌${NC}"
    VALIDATION_REPORT+="\n❌ DynamoDB: Failed to access students table"
    VALIDATION_PASSED=false
fi

# Test 3: Lambda Access
echo -n "  Testing Lambda function access... "
if aws lambda get-function --function-name "$LAMBDA_NAME" --output json >/dev/null 2>&1; then
    echo -e "${GREEN}✅${NC}"
    VALIDATION_REPORT+="\n✅ Lambda: Successfully accessed function $LAMBDA_NAME"
else
    echo -e "${RED}❌${NC}"
    VALIDATION_REPORT+="\n❌ Lambda: Failed to access function $LAMBDA_NAME"
    VALIDATION_PASSED=false
fi

# Test 4: Database Connectivity
echo -n "  Testing database connectivity... "
if command -v psql >/dev/null 2>&1; then
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_ENDPOINT" -U postgres -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
        VALIDATION_REPORT+="\n✅ PostgreSQL: Successfully connected to database"
    else
        echo -e "${RED}❌${NC}"
        VALIDATION_REPORT+="\n❌ PostgreSQL: Failed to connect to database"
        VALIDATION_PASSED=false
    fi
else
    echo -e "${BLUE}⚠️${NC}"
    VALIDATION_REPORT+="\n⚠️  PostgreSQL: psql not installed (candidate will need to install)"
fi

# Test 5: Redis Availability (VPC-internal only)
echo -n "  Checking Redis cluster status... "
if aws elasticache describe-cache-clusters --cache-cluster-id "$(echo $REDIS_ENDPOINT | cut -d'.' -f1)" --region "$AWS_DEFAULT_REGION" >/dev/null 2>&1; then
    echo -e "${GREEN}✅${NC}"
    VALIDATION_REPORT+="\n✅ Redis: Cluster running (accessible from Lambda functions only)"
else
    echo -e "${RED}❌${NC}"
    VALIDATION_REPORT+="\n❌ Redis: Cluster not available"
    VALIDATION_PASSED=false
fi

# Clean up environment variables after testing
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}✅ All validation tests passed!${NC}"
else
    echo -e "${RED}❌ Some validation tests failed. Check infrastructure before sending credentials.${NC}"
fi

echo ""

# Create send-to-candidate directory
SEND_DIR="send-to-candidate"
rm -rf "$SEND_DIR"
mkdir -p "$SEND_DIR"

# Generate email content
EMAIL_FILE="$SEND_DIR/candidate-credentials-${CANDIDATE_NAME}-${INTERVIEW_ID}.txt"

cat > "$EMAIL_FILE" << EOF
Subject: Amira Learning - AWS Access Credentials

This file contains AWS credentials for the interview session. Please set these up now and test access before the interview.

⏰ **IMPORTANT**: These credentials are valid for 12 hours from generation time.
🔄 **If expired**: Contact the interviewer for fresh credentials.

=== AWS SETUP INSTRUCTIONS ===

1. SET THESE CREDENTIALS:

**macOS/Linux (Terminal/Bash):**
export AWS_ACCESS_KEY_ID="$TEMP_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$TEMP_SECRET_KEY"
export AWS_SESSION_TOKEN="$TEMP_SESSION_TOKEN"
export AWS_DEFAULT_REGION="$REGION"

**Windows (Command Prompt):**
set AWS_ACCESS_KEY_ID=$TEMP_ACCESS_KEY
set AWS_SECRET_ACCESS_KEY=$TEMP_SECRET_KEY
set AWS_SESSION_TOKEN=$TEMP_SESSION_TOKEN
set AWS_DEFAULT_REGION=$REGION

**Windows (PowerShell):**
\$env:AWS_ACCESS_KEY_ID="$TEMP_ACCESS_KEY"
\$env:AWS_SECRET_ACCESS_KEY="$TEMP_SECRET_KEY"
\$env:AWS_SESSION_TOKEN="$TEMP_SESSION_TOKEN"
\$env:AWS_DEFAULT_REGION="$REGION"

2. TEST YOUR ACCESS:

aws sts get-caller-identity

You should see your assumed role in the response.

=== AVAILABLE RESOURCES ===

DynamoDB Tables:
- Students: interview-students
- Assessments: interview-assessments
- Classes: interview-classes
- Schools: interview-schools

Lambda Function: interview-buggy-api

Sample Data & Schema API: $SAMPLE_DATA_URL
- Access with: curl "$SAMPLE_DATA_URL?file=schemas.sql"
- Available files: schemas.sql, test-data.json, legacy-api-docs.md, challenge files

Database Connection:
- Host: interview-db-performance.[region].rds.amazonaws.com
- User: postgres
- Password: [generated password]
- Database: postgres

Redis Cache: $REDIS_ENDPOINT (VPC-internal only, accessible from Lambda functions)

=== CONNECTION TESTS ===

Test DynamoDB access:
aws dynamodb scan --table-name $STUDENTS_TABLE --limit 1

Test Lambda access:
aws lambda get-function --function-name $LAMBDA_NAME

Test Database connection:
psql -h $DB_ENDPOINT -U postgres -d postgres
(Use password: $DB_PASSWORD)

Test Sample Data API:
curl "$SAMPLE_DATA_URL"
curl "$SAMPLE_DATA_URL?file=schemas.sql"

Note: Redis is available for Lambda functions but not directly accessible from your machine.

=== TROUBLESHOOTING ===

If credentials don't work:
- Re-run the credential commands above (tokens expire after 12 hours)
- Make sure you copied all credentials exactly as provided
- Install AWS CLI if needed:
  * macOS: brew install awscli
  * Windows: Download from https://aws.amazon.com/cli/
  * Linux: apt-get install awscli or yum install awscli

If database connection fails:
- Ensure you copied the password exactly (includes special characters)
- Install PostgreSQL client if needed:
  * macOS: brew install libpq && brew link --force libpq
  * Windows: Download any PostgreSQL client or use your preferred database tool
  * Linux: apt-get install postgresql-client or yum install postgresql
- You can use any database client tool you prefer (pgAdmin, DBeaver, etc.)
- Try from a different network if your company blocks outbound database connections

=== INTERVIEW CHALLENGES ===

Challenges will be presented during the interview session. They test agentic AI-powered development - your ability to work strategically with AI tools:
- 2-3 main challenges (15 minutes each)
- 5 rapid fire tasks (2-3 minutes each, if time permits)

Focus areas: Data migration, debugging, optimization, and adaptability

Expected approach: Use AI for boilerplate/syntax, but demonstrate your problem-solving methodology.

All challenge materials will be provided through the Sample Data API above during the interview.

=== READY TO GO ===

Once all test commands above run successfully, the environment is ready for the interview session.

The interview will start with a quick verification that everything works, then proceed to the coding challenges.
EOF

echo -e "${GREEN}✅ Email generated: $EMAIL_FILE${NC}"
echo ""
echo -e "${BLUE}📋 Validation Report:${NC}"
echo -e "$VALIDATION_REPORT"
echo ""

if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}📧 Credentials ready to send!${NC}"
    echo ""
    echo -e "${BLUE}📁 Contents of $SEND_DIR:${NC}"
    ls -la "$SEND_DIR"
else
    echo -e "${RED}⚠️  WARNING: Some tests failed. Fix issues before sending credentials.${NC}"
fi
echo ""
echo -e "${GREEN}🔗 CHALLENGE URLs FOR INTERVIEWER (save these for interview):${NC}"
echo ""
echo "Base API: $SAMPLE_DATA_URL"
echo ""
echo "📋 Copy/paste these during interview (saves files to current directory):"
echo "Challenge A: curl \"$SAMPLE_DATA_URL?file=challenge-a-migration.md\" -o challenge-a-migration.md"
echo "Challenge B (C++/.NET): curl \"$SAMPLE_DATA_URL?file=challenge-b-debugging.md\" -o challenge-b-debugging.md"
echo "Challenge B (Alternative): curl \"$SAMPLE_DATA_URL?file=challenge-b-alternative.md\" -o challenge-b-alternative.md"
echo "Challenge C: curl \"$SAMPLE_DATA_URL?file=challenge-c-optimization.md\" -o challenge-c-optimization.md"
echo "Rapid Fire: curl \"$SAMPLE_DATA_URL?file=rapid-fire-tasks.md\" -o rapid-fire-tasks.md"
echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo "1. Send email file to candidate:"
echo "   - Email: $(basename $EMAIL_FILE)"
echo "2. Send 30 minutes before interview"
echo "3. Have candidate test connections and environment setup"
echo "4. Use URLs above to present challenges during interview"
echo "5. Start interview once verification is complete"