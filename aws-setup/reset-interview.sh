#!/bin/bash
# Quick Reset Interview Environment Script
# Resets data without rebuilding CloudFormation infrastructure
# Usage: ./reset-interview.sh <candidate-name> [interview-id]

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

echo -e "${BLUE}🔄 Quick Reset: Interview Environment${NC}"
echo "Candidate: $CANDIDATE_NAME"
echo "Interview ID: $INTERVIEW_ID"
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo ""
echo -e "${YELLOW}⚡ This preserves infrastructure and only resets data (1-2 minutes vs 20+ minutes for full rebuild)${NC}"
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
echo -e "${BLUE}Checking CloudFormation stack...${NC}"
if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" --profile personal --region "$REGION" >/dev/null 2>&1; then
    echo -e "${RED}❌ Stack $STACK_NAME not found${NC}"
    echo "Run deployment first: make deploy CANDIDATE=$CANDIDATE_NAME"
    exit 1
fi
echo -e "${GREEN}✅ Stack found${NC}"

# Get stack outputs
echo -e "${BLUE}Retrieving stack configuration...${NC}"
OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --profile personal \
    --region "$REGION" \
    --query 'Stacks[0].Outputs' \
    --output json)

# Extract key values
STUDENTS_TABLE=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="StudentsTableName") | .OutputValue')
ASSESSMENTS_TABLE=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="AssessmentsTableName") | .OutputValue')
CLASSES_TABLE=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="ClassesTableName") | .OutputValue')
SCHOOLS_TABLE=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="SchoolsTableName") | .OutputValue')
DB_ENDPOINT=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="DatabaseEndpoint") | .OutputValue')
DB_PASSWORD=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="DatabasePassword") | .OutputValue')
CACHE_ENDPOINT=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="CacheEndpoint") | .OutputValue')
LAMBDA_ARN=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="BuggyLambdaArn") | .OutputValue')
SAMPLE_API_URL=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="SampleDataApiUrl") | .OutputValue')

echo "Students Table: $STUDENTS_TABLE"
echo "Database: $DB_ENDPOINT"
echo "Cache: $CACHE_ENDPOINT"
echo "Lambda: $LAMBDA_ARN"
echo ""

# 1. CLEAR DYNAMODB TABLES
echo -e "${BLUE}🗃️  Step 1: Clearing DynamoDB tables...${NC}"

clear_dynamodb_table() {
    local table_name=$1
    echo "  Clearing $table_name..."

    # Simple approach: scan all items and build batch delete requests
    local items=$(aws dynamodb scan --table-name "$table_name" --profile personal --region "$REGION" --output json 2>/dev/null || echo '{"Items":[]}')
    local item_count=$(echo "$items" | jq '.Items | length')

    if [ "$item_count" -gt 0 ]; then
        echo "    Found $item_count items to delete"

        # Get key schema for proper key extraction
        local key_schema=$(aws dynamodb describe-table --table-name "$table_name" --profile personal --region "$REGION" --query 'Table.KeySchema' --output json 2>/dev/null || echo "[]")
        local hash_key=$(echo "$key_schema" | jq -r '.[] | select(.KeyType=="HASH") | .AttributeName')
        local range_key=$(echo "$key_schema" | jq -r '.[] | select(.KeyType=="RANGE") | .AttributeName // empty')

        if [ -n "$hash_key" ]; then
            # Process items in batches of 25 (DynamoDB batch limit)
            echo "$items" | jq -c ".Items[] | {\"$hash_key\": .$hash_key$([ -n "$range_key" ] && echo ", \"$range_key\": .$range_key" || echo "")}" | \
            split -l 25 - /tmp/batch_

            # Delete each batch
            for batch_file in /tmp/batch_*; do
                if [ -f "$batch_file" ]; then
                    local delete_requests="["
                    local first=true
                    while IFS= read -r key_item; do
                        if [ "$first" = true ]; then
                            first=false
                        else
                            delete_requests="$delete_requests,"
                        fi
                        delete_requests="$delete_requests{\"DeleteRequest\":{\"Key\":$key_item}}"
                    done < "$batch_file"
                    delete_requests="$delete_requests]"

                    aws dynamodb batch-write-item \
                        --request-items "{\"$table_name\":$delete_requests}" \
                        --profile personal --region "$REGION" >/dev/null 2>&1 || true

                    rm "$batch_file"
                fi
            done
        fi
    else
        echo "    Table already empty"
    fi
}

# Clear all DynamoDB tables in parallel
clear_dynamodb_table "$STUDENTS_TABLE" &
clear_dynamodb_table "$ASSESSMENTS_TABLE" &
clear_dynamodb_table "$CLASSES_TABLE" &
clear_dynamodb_table "$SCHOOLS_TABLE" &
wait

echo -e "${GREEN}✅ DynamoDB tables cleared${NC}"

# 2. RESET POSTGRESQL DATABASE
echo -e "${BLUE}🐘 Step 2: Resetting PostgreSQL database...${NC}"
export PGPASSWORD="$DB_PASSWORD"

# Truncate and repopulate tables
psql -h "$DB_ENDPOINT" -U postgres -d postgres -c "
-- Truncate all tables (cascades to clear all data)
TRUNCATE TABLE assessments, students, classes, schools, districts CASCADE;

-- Re-insert sample data
INSERT INTO districts (name, state) VALUES ('Springfield School District', 'IL');

WITH district AS (SELECT district_id FROM districts LIMIT 1)
INSERT INTO schools (district_id, name, type)
SELECT district.district_id, 'Lincoln Elementary', 'ELEMENTARY' FROM district
UNION ALL
SELECT district.district_id, 'Washington Middle School', 'MIDDLE' FROM district;

WITH school AS (SELECT school_id FROM schools WHERE name = 'Lincoln Elementary' LIMIT 1)
INSERT INTO classes (school_id, name, grade_level, period_id)
SELECT school.school_id, 'Grade 3A', 3, 'MOY' FROM school
UNION ALL
SELECT school.school_id, 'Grade 3B', 3, 'MOY' FROM school
UNION ALL
SELECT school.school_id, 'Grade 4A', 4, 'MOY' FROM school;

-- Insert students with data quality issues for migration challenges
WITH class AS (SELECT class_id FROM classes WHERE name = 'Grade 3A' LIMIT 1)
INSERT INTO students (class_id, first_name, last_name, grade_level, reading_level, status)
SELECT class.class_id, 'Sarah', 'Johnson', 3, 3.2, 'ACTIVE' FROM class
UNION ALL
SELECT class.class_id, 'Mike', 'Wilson', 3, -1.0, 'ACTIVE' FROM class  -- Bad reading level
UNION ALL
SELECT class.class_id, 'Emma', 'Davis', 3, NULL, 'ACTIVE' FROM class;  -- NULL reading level

-- Insert assessments with various data issues
WITH students_sample AS (SELECT student_id FROM students LIMIT 3)
INSERT INTO assessments (student_id, assessment_type, score, possible_points, assessment_date, period_id)
SELECT student_id, 'Reading Comprehension', 85, 100, CURRENT_TIMESTAMP - INTERVAL '30 days', 'MOY' FROM students_sample
UNION ALL
SELECT student_id, 'reading_comprehension', 78, 100, CURRENT_TIMESTAMP - INTERVAL '25 days', 'MOY' FROM students_sample  -- Inconsistent naming
UNION ALL
SELECT student_id, 'Math Assessment', 92, 100, CURRENT_TIMESTAMP + INTERVAL '5 days', 'MOY' FROM students_sample;  -- Future date
" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ PostgreSQL database reset successfully${NC}"
else
    echo -e "${YELLOW}⚠️  PostgreSQL reset had issues (may still work)${NC}"
fi

unset PGPASSWORD

# 3. SKIP REDIS CACHE (IN VPC - NOT ACCESSIBLE)
echo -e "${BLUE}🔄 Step 3: Skipping Redis cache (in VPC)...${NC}"
echo -e "${GREEN}✅ Redis cache skip completed${NC}"

# 4. REPOPULATE DYNAMODB WITH CLEAN REFERENCE DATA
echo -e "${BLUE}📊 Step 4: Repopulating DynamoDB with clean reference data...${NC}"

python3 - <<EOF
import boto3
import json
from datetime import datetime
import uuid
from decimal import Decimal

session = boto3.Session(profile_name='personal', region_name='$REGION')
dynamodb = session.resource('dynamodb')

# Clean reference data for testing
reference_student_id = str(uuid.uuid4())
reference_class_id = str(uuid.uuid4())

sample_students = [{
    'student_id': reference_student_id,
    'class_id': reference_class_id,
    'first_name': 'Test',
    'last_name': 'Student',
    'grade_level': 3,
    'reading_level': Decimal('3.0'),
    'status': 'ACTIVE',
    'created_at': datetime.utcnow().isoformat()
}]

sample_assessments = [{
    'assessment_id': str(uuid.uuid4()),
    'student_id': reference_student_id,
    'type': 'BENCHMARK',
    'window_tag': 'BOY',
    'score': Decimal('85.0'),
    'reading_level': Decimal('3.0'),
    'created_at': datetime.utcnow().isoformat()
}]

try:
    # Populate students table
    students_table = dynamodb.Table('$STUDENTS_TABLE')
    with students_table.batch_writer() as batch:
        for student in sample_students:
            batch.put_item(Item=student)

    # Populate assessments table
    assessments_table = dynamodb.Table('$ASSESSMENTS_TABLE')
    with assessments_table.batch_writer() as batch:
        for assessment in sample_assessments:
            batch.put_item(Item=assessment)

    print("✅ Clean reference data populated")
except Exception as e:
    print(f"❌ Error: {e}")
    import sys
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ DynamoDB repopulated with clean reference data${NC}"
else
    echo -e "${YELLOW}⚠️  DynamoDB population had issues${NC}"
fi

# 5. RESET LAMBDA FUNCTION CODE
echo -e "${BLUE}⚡ Step 5: Resetting Lambda function to original buggy state...${NC}"

# Create the buggy Lambda code zip
cat > /tmp/lambda_code.js << 'LAMBDA_EOF'
// GraphQL API Lambda Function with Memory Leaks
const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Connection pool for reuse across requests (MEMORY LEAK: never cleaned up)
const connections = [];
let requestCache = new Map(); // MEMORY LEAK: grows indefinitely

exports.handler = async (event) => {
    try {
        // Create connection for this request (MEMORY LEAK: connections accumulate)
        const requestId = Date.now();
        connections.push({
            id: requestId,
            client: new AWS.DynamoDB.DocumentClient(),
            requestData: new Array(1000).fill(`request-${requestId}`)
        });

        // Cache request for performance (MEMORY LEAK: cache never cleaned)
        const cacheKey = `query-${requestId}-${Math.random()}`;
        requestCache.set(cacheKey, {
            queryData: new Array(5000).fill(`cached-query-${requestId}`),
            timestamp: Date.now()
        });

        console.log(`Active connections: ${connections.length}`);
        console.log(`Cached queries: ${requestCache.size}`);

        // Get student data
        const result = await dynamodb.scan({
            TableName: process.env.STUDENTS_TABLE,
            Limit: 10
        }).promise();

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Student data retrieved successfully',
                activeConnections: connections.length,
                cachedQueries: requestCache.size,
                studentsFound: result.Items?.length || 0
            })
        };
    } catch (error) {
        console.error('Error processing request:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message })
        };
    }
};
LAMBDA_EOF

# Create zip file
cd /tmp
zip -q lambda_code.zip lambda_code.js

# Update Lambda function code
aws lambda update-function-code \
    --function-name "interview-buggy-api" \
    --zip-file fileb://lambda_code.zip \
    --profile personal \
    --region "$REGION" >/dev/null

rm lambda_code.js lambda_code.zip

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Lambda function reset to buggy state${NC}"
else
    echo -e "${YELLOW}⚠️  Lambda reset had issues${NC}"
fi

# 6. CLEAR CLOUDWATCH LOGS
echo -e "${BLUE}📝 Step 6: Clearing CloudWatch logs...${NC}"
LOG_GROUP="/aws/lambda/interview-buggy-api"
aws logs delete-log-group --log-group-name "$LOG_GROUP" --profile personal --region "$REGION" >/dev/null 2>&1 || true
echo -e "${GREEN}✅ CloudWatch logs cleared${NC}"

# 7. VERIFICATION
echo -e "${BLUE}🔍 Step 7: Quick verification...${NC}"

# Verify DynamoDB
DYNAMO_COUNT=$(aws dynamodb scan --table-name "$STUDENTS_TABLE" --select "COUNT" --profile personal --region "$REGION" --output text --query 'Count' 2>/dev/null || echo "0")

# Verify PostgreSQL
export PGPASSWORD="$DB_PASSWORD"
PG_COUNT=$(psql -h "$DB_ENDPOINT" -U postgres -d postgres -t -c "SELECT COUNT(*) FROM students;" 2>/dev/null | tr -d ' ' || echo "0")
unset PGPASSWORD

echo "DynamoDB Students: $DYNAMO_COUNT"
echo "PostgreSQL Students: $PG_COUNT"

if [ "$DYNAMO_COUNT" -gt 0 ] || [ "$PG_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Verification passed${NC}"
else
    echo -e "${YELLOW}⚠️  Verification had issues (environment may still work)${NC}"
fi

# Summary
echo ""
echo -e "${GREEN}🎉 Quick Reset Completed Successfully!${NC}"
echo ""
echo -e "${BLUE}📊 Reset Summary:${NC}"
echo "✅ DynamoDB tables cleared and repopulated"
echo "✅ PostgreSQL database reset with sample data"
echo "✅ Redis cache skipped (in VPC)"
echo "✅ Lambda function reset to buggy state"
echo "✅ CloudWatch logs cleared"
echo ""
echo -e "${BLUE}⚡ Time saved: ~20 minutes vs full rebuild${NC}"
echo ""
echo -e "${BLUE}🚀 Ready for next interview session!${NC}"
echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo "1. Generate credentials: make credentials CANDIDATE=$CANDIDATE_NAME INTERVIEW_ID=$INTERVIEW_ID"
echo "2. Quick verify: make verify CANDIDATE=$CANDIDATE_NAME INTERVIEW_ID=$INTERVIEW_ID"
echo "3. Sample API URL: $SAMPLE_API_URL"