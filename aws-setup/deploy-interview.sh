#!/bin/bash
# Deploy Interview Environment Script
# Usage: ./deploy-interview.sh <candidate-name> [interview-id]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -lt 1 ]; then
    echo -e "${RED}Usage: $0 <candidate-name> [interview-id]${NC}"
    echo "Example: $0 john-doe"
    echo "Example: $0 jane-smith interview-20241216-1400"
    exit 1
fi

CANDIDATE_NAME=$1
INTERVIEW_ID=${2:-"$(date +%Y%m%d-%H%M)"}
STACK_NAME="amira-interview-${CANDIDATE_NAME}-${INTERVIEW_ID}"
REGION=${AWS_DEFAULT_REGION:-us-east-1}

echo -e "${BLUE}🚀 Deploying Amira Interview Environment${NC}"
echo "Candidate: $CANDIDATE_NAME"
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

# Pre-flight checks
echo -e "${BLUE}Running pre-flight checks...${NC}"

# Check AWS CLI version
AWS_CLI_VERSION=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
echo "AWS CLI Version: $AWS_CLI_VERSION"

# Check available disk space
AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
echo "Available disk space: $AVAILABLE_SPACE"

# Check for existing resources that might conflict
echo -e "${BLUE}Checking for resource name conflicts...${NC}"

# Check for existing S3 buckets
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile personal --query 'Account' --output text)
CHALLENGE_BUCKET="${AWS_ACCOUNT_ID}-challenges"
DEPLOYMENT_BUCKET="${AWS_ACCOUNT_ID}-deployment"

if aws s3api head-bucket --bucket "$CHALLENGE_BUCKET" --profile personal --region "$REGION" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  S3 bucket '$CHALLENGE_BUCKET' already exists${NC}"
    echo "This may indicate a previous deployment wasn't cleaned up properly"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled"
        exit 1
    fi
fi

# Check for stuck stacks in DELETE_FAILED state
echo -e "${BLUE}Checking for stuck CloudFormation stacks...${NC}"
STUCK_STACKS=$(aws cloudformation list-stacks \
    --profile personal \
    --region "$REGION" \
    --stack-status-filter DELETE_FAILED \
    --query "StackSummaries[?contains(StackName, 'amira-interview')].StackName" \
    --output text 2>/dev/null || echo "")

if [ "$STUCK_STACKS" != "" ]; then
    echo -e "${YELLOW}⚠️  Found stuck CloudFormation stacks in DELETE_FAILED state:${NC}"
    echo "$STUCK_STACKS"
    echo ""
    echo -e "${BLUE}💡 To clean up stuck stacks, run:${NC}"
    echo "  ./force-cleanup.sh <candidate-name> <interview-id>"
    echo ""
    echo -e "${BLUE}ℹ️  Continuing with deployment (different stack name)...${NC}"
fi

# Check AWS service limits
echo -e "${BLUE}Checking AWS service quotas...${NC}"

# Check VPC limit
VPC_COUNT=$(aws ec2 describe-vpcs --profile personal --region "$REGION" --query 'length(Vpcs)' --output text 2>/dev/null || echo "0")
echo "Current VPCs in region: $VPC_COUNT (limit usually 5)"

# Check RDS instances
RDS_COUNT=$(aws rds describe-db-instances --profile personal --region "$REGION" --query 'length(DBInstances)' --output text 2>/dev/null || echo "0")
echo "Current RDS instances in region: $RDS_COUNT"

# Validate template before deployment
echo -e "${BLUE}Validating CloudFormation template...${NC}"
aws cloudformation validate-template \
    --template-body file://interview-stack.yaml \
    --profile personal \
    --region "$REGION" > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ CloudFormation template is valid${NC}"
else
    echo -e "${RED}❌ CloudFormation template validation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Pre-flight checks completed${NC}"
echo ""

# Check if stack already exists
echo -e "${BLUE}Checking for existing stack...${NC}"
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --profile personal --region "$REGION" >/dev/null 2>&1; then
    STACK_STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --profile personal --region "$REGION" --query 'Stacks[0].StackStatus' --output text)
    if [ "$STACK_STATUS" = "CREATE_COMPLETE" ] || [ "$STACK_STATUS" = "UPDATE_COMPLETE" ]; then
        echo -e "${YELLOW}⚠️  Stack $STACK_NAME already exists (status: $STACK_STATUS)${NC}"
        echo "Would you like to:"
        echo "1. Populate data in existing stack (recommended)"
        echo "2. Update stack with latest template"
        echo "3. Exit and use cleanup-interview.sh first"
        read -p "Choose option [1-3]: " choice

        case $choice in
            1)
                echo -e "${BLUE}Proceeding with data population only...${NC}"
                SKIP_STACK_DEPLOY=true
                ;;
            2)
                echo -e "${BLUE}Updating existing stack...${NC}"
                SKIP_STACK_DEPLOY=false
                ;;
            3)
                echo "Use cleanup-interview.sh first or choose different interview ID"
                exit 1
                ;;
            *)
                echo "Invalid choice. Defaulting to data population only."
                SKIP_STACK_DEPLOY=true
                ;;
        esac
    else
        echo -e "${RED}❌ Stack $STACK_NAME exists but is not ready (status: $STACK_STATUS)${NC}"
        echo "Wait for stack to complete or use cleanup-interview.sh first"
        exit 1
    fi
else
    echo -e "${GREEN}✅ No existing stack found${NC}"
    SKIP_STACK_DEPLOY=false
fi

# Package Lambda functions and upload to S3
echo -e "${BLUE}Packaging Lambda functions...${NC}"
./package-lambda.sh
./package-buggy-lambda.sh

# Create temporary deployment bucket for Lambda upload (CloudFormation will create the official one)
TEMP_DEPLOYMENT_BUCKET="${AWS_ACCOUNT_ID}-temp-deployment-$(date +%s)"
echo -e "${BLUE}Creating temporary deployment bucket...${NC}"
aws s3 mb "s3://$TEMP_DEPLOYMENT_BUCKET" --region "$REGION" --profile personal

# Upload packaged Lambdas to temp bucket
echo -e "${BLUE}Uploading Lambda packages to temporary S3 bucket...${NC}"
aws s3 cp packaged-lambdas/sample-data-api.zip "s3://$TEMP_DEPLOYMENT_BUCKET/${INTERVIEW_ID}/sample-data-api.zip" --profile personal --region "$REGION"
aws s3 cp packaged-lambdas/buggy-lambda.zip "s3://$TEMP_DEPLOYMENT_BUCKET/${INTERVIEW_ID}/buggy-lambda.zip" --profile personal --region "$REGION"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Lambda packages uploaded successfully${NC}"
else
    echo -e "${RED}❌ Lambda package upload failed${NC}"
    exit 1
fi

# Deploy CloudFormation stack
echo -e "${BLUE}Deploying CloudFormation stack...${NC}"
aws cloudformation deploy \
    --template-file interview-stack.yaml \
    --stack-name "$STACK_NAME" \
    --parameter-overrides \
        InterviewId="$INTERVIEW_ID" \
        CandidateName="$CANDIDATE_NAME" \
        DeploymentBucketName="$TEMP_DEPLOYMENT_BUCKET" \
    --capabilities CAPABILITY_NAMED_IAM \
    --profile personal \
    --region "$REGION" \
    --no-fail-on-empty-changeset

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Stack deployed successfully${NC}"
else
    echo -e "${RED}❌ Stack deployment failed${NC}"
    exit 1
fi

# Get stack outputs
echo -e "${BLUE}Retrieving stack outputs...${NC}"
OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --profile personal \
    --region "$REGION" \
    --query 'Stacks[0].Outputs' \
    --output json)

# Extract key values
STUDENTS_TABLE=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="StudentsTableName") | .OutputValue')
BUGGY_LAMBDA=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="BuggyLambdaArn") | .OutputValue')
CANDIDATE_ROLE=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="CandidateRoleArn") | .OutputValue')
SAMPLE_DATA_API_URL=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="SampleDataApiUrl") | .OutputValue')

# Wait for RDS to be available (with extended timeout)
echo -e "${BLUE}Waiting for RDS instance to be available...${NC}"
echo -e "${BLUE}⏱️  This can take 10-15 minutes for new RDS instances${NC}"
DB_INSTANCE_ID="interview-db-performance"
aws rds wait db-instance-available \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --profile personal \
    --region "$REGION" \
    --cli-read-timeout 900 \
    --cli-connect-timeout 60

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ RDS instance is ready${NC}"
else
    echo -e "${RED}❌ RDS instance failed to become available or timed out${NC}"
    echo -e "${BLUE}💡 You can continue data population later with:${NC}"
    echo "   ./populate-data.sh $CANDIDATE_NAME $INTERVIEW_ID"
    echo -e "${BLUE}💡 Or use the Makefile:${NC}"
    echo "   make populate-data CANDIDATE=$CANDIDATE_NAME INTERVIEW_ID=$INTERVIEW_ID"
    exit 1
fi

# Get database connection details
DB_ENDPOINT=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="DatabaseEndpoint") | .OutputValue')
DB_PASSWORD=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="DatabasePassword") | .OutputValue')

# Populate PostgreSQL with schema and sample data
echo -e "${BLUE}Populating PostgreSQL with schema and sample data...${NC}"
export PGPASSWORD="$DB_PASSWORD"

# Test PostgreSQL connection with retry logic
echo -e "${BLUE}Testing PostgreSQL connection...${NC}"
RETRY_COUNT=0
MAX_RETRIES=5
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if psql -h "$DB_ENDPOINT" -U postgres -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL connection successful${NC}"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo -e "${BLUE}Connection attempt $RETRY_COUNT/$MAX_RETRIES failed, retrying in 30 seconds...${NC}"
        sleep 30
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}❌ Failed to connect to PostgreSQL after $MAX_RETRIES attempts${NC}"
    exit 1
fi

# Create tables from schema
echo -e "${BLUE}Creating database schema...${NC}"
psql -h "$DB_ENDPOINT" -U postgres -d postgres -c "
-- Create tables with sample data for interview challenges
CREATE TABLE IF NOT EXISTS districts (
    district_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    state VARCHAR(2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS schools (
    school_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    district_id UUID REFERENCES districts(district_id),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS classes (
    class_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(school_id),
    teacher_id UUID,
    name VARCHAR(255),
    grade_level INTEGER CHECK (grade_level >= 0 AND grade_level <= 12),
    period_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS students (
    student_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID REFERENCES classes(class_id),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    grade_level INTEGER CHECK (grade_level >= 0 AND grade_level <= 12),
    reading_level DECIMAL(3,1),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS assessments (
    assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(student_id),
    assessment_type VARCHAR(100),
    score INTEGER,
    possible_points INTEGER,
    assessment_date TIMESTAMP,
    period_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample district
INSERT INTO districts (name, state) VALUES ('Springfield School District', 'IL')
ON CONFLICT DO NOTHING;

-- Insert sample schools
WITH district AS (SELECT district_id FROM districts LIMIT 1)
INSERT INTO schools (district_id, name, type)
SELECT district.district_id, 'Lincoln Elementary', 'ELEMENTARY' FROM district
UNION ALL
SELECT district.district_id, 'Washington Middle School', 'MIDDLE' FROM district
ON CONFLICT DO NOTHING;

-- Insert sample classes
WITH school AS (SELECT school_id FROM schools WHERE name = 'Lincoln Elementary' LIMIT 1)
INSERT INTO classes (school_id, name, grade_level, period_id)
SELECT school.school_id, 'Grade 3A', 3, 'MOY' FROM school
UNION ALL
SELECT school.school_id, 'Grade 3B', 3, 'MOY' FROM school
UNION ALL
SELECT school.school_id, 'Grade 4A', 4, 'MOY' FROM school
ON CONFLICT DO NOTHING;
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database schema created successfully${NC}"
else
    echo -e "${RED}❌ Failed to create database schema${NC}"
    exit 1
fi

# Insert legacy data with intentional issues for Challenge A
echo -e "${BLUE}Inserting sample data with intentional data quality issues...${NC}"
psql -h "$DB_ENDPOINT" -U postgres -d postgres -c "
-- Insert students with data quality issues for migration challenges
WITH class AS (SELECT class_id FROM classes WHERE name = 'Grade 3A' LIMIT 1)
INSERT INTO students (class_id, first_name, last_name, grade_level, reading_level, status)
SELECT class.class_id, 'Sarah', 'Johnson', 3, 3.2, 'ACTIVE' FROM class
UNION ALL
SELECT class.class_id, 'Mike', 'Wilson', 3, -1.0, 'ACTIVE' FROM class  -- Bad reading level
UNION ALL
SELECT class.class_id, 'Emma', 'Davis', 3, NULL, 'ACTIVE' FROM class  -- NULL reading level
ON CONFLICT DO NOTHING;

-- Insert assessments with various data issues
WITH students_sample AS (
    SELECT student_id FROM students LIMIT 3
)
INSERT INTO assessments (student_id, assessment_type, score, possible_points, assessment_date, period_id)
SELECT student_id, 'Reading Comprehension', 85, 100, CURRENT_TIMESTAMP - INTERVAL '30 days', 'MOY' FROM students_sample
UNION ALL
SELECT student_id, 'reading_comprehension', 78, 100, CURRENT_TIMESTAMP - INTERVAL '25 days', 'MOY' FROM students_sample  -- Inconsistent naming
UNION ALL
SELECT student_id, 'Math Assessment', 92, 100, CURRENT_TIMESTAMP + INTERVAL '5 days', 'MOY' FROM students_sample  -- Future date
ON CONFLICT DO NOTHING;
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ PostgreSQL data insertion completed${NC}"
else
    echo -e "${RED}❌ Error inserting data into PostgreSQL${NC}"
    exit 1
fi

# Verify data was actually inserted
echo -e "${BLUE}Verifying PostgreSQL data...${NC}"
STUDENT_COUNT=$(psql -h "$DB_ENDPOINT" -U postgres -d postgres -t -c "SELECT COUNT(*) FROM students;" 2>/dev/null | tr -d ' ')
ASSESSMENT_COUNT=$(psql -h "$DB_ENDPOINT" -U postgres -d postgres -t -c "SELECT COUNT(*) FROM assessments;" 2>/dev/null | tr -d ' ')

if [ "$STUDENT_COUNT" -gt 0 ] && [ "$ASSESSMENT_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ PostgreSQL populated successfully: $STUDENT_COUNT students, $ASSESSMENT_COUNT assessments${NC}"
else
    echo -e "${RED}❌ PostgreSQL verification failed: $STUDENT_COUNT students, $ASSESSMENT_COUNT assessments${NC}"
    exit 1
fi

unset PGPASSWORD

# Populate DynamoDB with sample data
echo -e "${BLUE}Populating DynamoDB with sample data...${NC}"

# Check if python3 and boto3 are available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ python3 not found${NC}"
    exit 1
fi

# Run Python script with exit code capture
python3 - <<EOF
import boto3
import json
from datetime import datetime
import uuid
from decimal import Decimal

session = boto3.Session(profile_name='personal', region_name='$REGION')
dynamodb = session.resource('dynamodb')

# Sample data for students table
students_table = dynamodb.Table('$STUDENTS_TABLE')

sample_students = [
    {
        'student_id': str(uuid.uuid4()),
        'class_id': 'class-001',
        'first_name': 'Alice',
        'last_name': 'Johnson',
        'grade_level': 3,
        'reading_level': Decimal('3.2'),
        'status': 'ACTIVE'
    },
    {
        'student_id': str(uuid.uuid4()),
        'class_id': 'class-001',
        'first_name': 'Bob',
        'last_name': 'Smith',
        'grade_level': 3,
        'reading_level': Decimal('-1.0'),  # Intentional bad data for Challenge A
        'status': 'ACTIVE'
    },
    {
        'student_id': str(uuid.uuid4()),
        'class_id': 'class-002',
        'first_name': 'Charlie',
        'last_name': 'Brown',
        'grade_level': 4,
        'reading_level': Decimal('4.5'),
        'status': 'ACTIVE'
    }
]

try:
    with students_table.batch_writer() as batch:
        for student in sample_students:
            batch.put_item(Item=student)
    print("✅ Sample data populated successfully")
except Exception as e:
    print(f"❌ Error populating sample data: {e}")
    import sys
    sys.exit(1)
EOF

# Check if Python script succeeded
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ DynamoDB population failed${NC}"
    exit 1
fi

# Verify DynamoDB data was inserted
echo -e "${BLUE}Verifying DynamoDB data...${NC}"
DYNAMO_COUNT=$(aws dynamodb scan --table-name "$STUDENTS_TABLE" --select "COUNT" --profile personal --region "$REGION" --output text --query 'Count' 2>/dev/null)

if [ "$DYNAMO_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ DynamoDB populated successfully: $DYNAMO_COUNT student records${NC}"
else
    echo -e "${RED}❌ DynamoDB verification failed: $DYNAMO_COUNT student records${NC}"
    exit 1
fi

# Create candidate credentials file
CREDS_FILE="candidate-credentials-${INTERVIEW_ID}.txt"
cat > "$CREDS_FILE" << EOF
# Amira Learning Interview - AWS Access Credentials
# Candidate: $CANDIDATE_NAME
# Interview ID: $INTERVIEW_ID
# Generated: $(date)

## AWS Configuration
Region: $REGION
Role ARN: $CANDIDATE_ROLE
External ID: ${INTERVIEW_ID}-${CANDIDATE_NAME}

## Resources Available
Students Table: $STUDENTS_TABLE
Assessments Table: ${INTERVIEW_ID}-assessments
Classes Table: ${INTERVIEW_ID}-classes
Schools Table: ${INTERVIEW_ID}-schools

Buggy Lambda: $BUGGY_LAMBDA
Database: ${INTERVIEW_ID}-performance-db
Cache: ${INTERVIEW_ID}-cache

## Challenge Files API
Sample Data API: $SAMPLE_DATA_API_URL
Challenge A: $SAMPLE_DATA_API_URL?file=challenge-a-migration.md
Challenge B (C++/.NET): $SAMPLE_DATA_API_URL?file=challenge-b-debugging.md
Challenge B (Alternative): $SAMPLE_DATA_API_URL?file=challenge-b-alternative.md
Challenge C: $SAMPLE_DATA_API_URL?file=challenge-c-optimization.md
Rapid Fire: $SAMPLE_DATA_API_URL?file=rapid-fire-tasks.md

## AWS CLI Setup (for candidate)
aws configure set region $REGION
aws sts assume-role \\
  --role-arn $CANDIDATE_ROLE \\
  --role-session-name interview-session \\
  --external-id ${INTERVIEW_ID}-${CANDIDATE_NAME} \\
  --duration-seconds 14400

## AWS SDK Setup (for candidate code)
Role ARN: $CANDIDATE_ROLE
External ID: ${INTERVIEW_ID}-${CANDIDATE_NAME}
Region: $REGION
EOF

echo -e "${GREEN}🎉 Interview environment deployed successfully!${NC}"
echo ""

# Run verification to ensure everything is ready
echo -e "${BLUE}🔍 Running environment verification...${NC}"
./verify-interview-environment.sh "$CANDIDATE_NAME" "$INTERVIEW_ID"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo "1. Generate credentials: ./generate-credentials-email.sh $CANDIDATE_NAME $INTERVIEW_ID"
    echo "2. Send credentials to candidate 30 minutes before interview"
    echo "3. After interview, run: ./cleanup-interview.sh $INTERVIEW_ID"
else
    echo ""
    echo -e "${RED}⚠️  Environment verification failed. Check output above.${NC}"
    echo "You may need to wait a few minutes for all resources to be fully ready."
    echo "Re-run verification: ./verify-interview-environment.sh $CANDIDATE_NAME $INTERVIEW_ID"
fi
echo ""
echo -e "${BLUE}📊 Cost Monitor:${NC}"
echo "ElastiCache: ~\$0.02/hour"
echo "RDS: Free tier (if under 750 hours/month)"
echo "Lambda/DynamoDB: Free tier"
echo ""
echo -e "${BLUE}⏰ Remember: Stack auto-deletes after 24 hours via lifecycle policy${NC}"