#!/bin/bash
# Standalone Data Population Script
# Usage: ./populate-data.sh <candidate-name> [interview-id]

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
    echo "Example: $0 jane-smith 20241216-1400"
    exit 1
fi

CANDIDATE_NAME=$1
INTERVIEW_ID=${2:-"$(date +%Y%m%d-%H%M)"}
STACK_NAME="amira-interview-${CANDIDATE_NAME}-${INTERVIEW_ID}"
REGION=${AWS_DEFAULT_REGION:-us-east-1}

echo -e "${BLUE}🔄 Re-populating Data for Interview Environment${NC}"
echo "Candidate: $CANDIDATE_NAME"
echo "Interview ID: $INTERVIEW_ID"
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo ""

# Check if stack exists
echo -e "${BLUE}Checking CloudFormation stack...${NC}"
if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" --profile personal --region "$REGION" >/dev/null 2>&1; then
    echo -e "${RED}❌ Stack $STACK_NAME not found${NC}"
    echo "Run deployment first: ./deploy-interview.sh $CANDIDATE_NAME $INTERVIEW_ID"
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
DB_ENDPOINT=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="DatabaseEndpoint") | .OutputValue')
DB_PASSWORD=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="DatabasePassword") | .OutputValue')

echo "Students Table: $STUDENTS_TABLE"
echo "Database: $DB_ENDPOINT"
echo ""

# Wait for RDS to be available (with extended timeout)
echo -e "${BLUE}Checking RDS availability...${NC}"
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
    echo -e "${RED}❌ RDS instance failed to become available${NC}"
    exit 1
fi

# Test PostgreSQL connection with extended retry
echo -e "${BLUE}Testing PostgreSQL connection...${NC}"
export PGPASSWORD="$DB_PASSWORD"
RETRY_COUNT=0
MAX_RETRIES=10
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

# Create/populate PostgreSQL schema and data
echo -e "${BLUE}Creating PostgreSQL schema...${NC}"
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

# Insert sample data with intentional issues
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

# Verify PostgreSQL data
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

# Check if python3 is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ python3 not found${NC}"
    exit 1
fi

# Run Python script
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

# Get stack outputs to find assessments table name
cf_session = boto3.Session(profile_name='personal', region_name='$REGION')
cf_client = cf_session.client('cloudformation')
stack_outputs = cf_client.describe_stacks(StackName='$STACK_NAME')['Stacks'][0]['Outputs']
assessments_table_name = next(
    output['OutputValue'] for output in stack_outputs
    if output['OutputKey'] == 'AssessmentsTableName'
)
assessments_table = dynamodb.Table(assessments_table_name)

# Create minimal clean reference data for testing (Challenge A starts with clean tables)
# Note: The dirty data is in the CSV files, candidates will migrate CSV -> DynamoDB

reference_student_id = str(uuid.uuid4())
reference_class_id = str(uuid.uuid4())

sample_students = [
    {
        'student_id': reference_student_id,
        'class_id': reference_class_id,
        'first_name': 'Test',
        'last_name': 'Student',
        'grade_level': 3,
        'reading_level': Decimal('3.0'),  # Clean data only
        'status': 'ACTIVE',
        'created_at': datetime.utcnow().isoformat()
    }
]

# One clean reference assessment
sample_assessments = [
    {
        'assessment_id': str(uuid.uuid4()),
        'student_id': reference_student_id,
        'type': 'BENCHMARK',
        'window_tag': 'BOY',
        'score': Decimal('85.0'),  # Clean data only
        'reading_level': Decimal('3.0'),
        'created_at': datetime.utcnow().isoformat()
    }
]

try:
    # Clear existing data from tables (scan and delete all items)
    print("Clearing existing DynamoDB data...")

    # Clear students table
    students_response = students_table.scan()
    with students_table.batch_writer() as batch:
        for item in students_response['Items']:
            batch.delete_item(Key={'student_id': item['student_id']})

    # Clear assessments table
    assessments_response = assessments_table.scan()
    with assessments_table.batch_writer() as batch:
        for item in assessments_response['Items']:
            batch.delete_item(Key={'assessment_id': item['assessment_id']})

    # Populate students table with clean reference data
    with students_table.batch_writer() as batch:
        for student in sample_students:
            batch.put_item(Item=student)

    # Populate assessments table with clean reference data
    with assessments_table.batch_writer() as batch:
        for assessment in sample_assessments:
            batch.put_item(Item=assessment)

    print(f"✅ Clean reference data populated: {len(sample_students)} students, {len(sample_assessments)} assessments")
    print("📋 Note: Dirty data is in CSV files for Challenge A migration task")
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

# Verify DynamoDB data
echo -e "${BLUE}Verifying DynamoDB data...${NC}"
DYNAMO_STUDENTS_COUNT=$(aws dynamodb scan --table-name "$STUDENTS_TABLE" --select "COUNT" --profile personal --region "$REGION" --output text --query 'Count' 2>/dev/null)

# Get assessments table name from CloudFormation outputs
ASSESSMENTS_TABLE=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="AssessmentsTableName") | .OutputValue')
DYNAMO_ASSESSMENTS_COUNT=$(aws dynamodb scan --table-name "$ASSESSMENTS_TABLE" --select "COUNT" --profile personal --region "$REGION" --output text --query 'Count' 2>/dev/null)

if [ "$DYNAMO_STUDENTS_COUNT" -ge 0 ] && [ "$DYNAMO_ASSESSMENTS_COUNT" -ge 0 ]; then
    echo -e "${GREEN}✅ DynamoDB setup completed: $DYNAMO_STUDENTS_COUNT students, $DYNAMO_ASSESSMENTS_COUNT assessments (clean reference data)${NC}"
    echo -e "${BLUE}📋 Note: Challenge A will migrate dirty data from CSV files to these clean DynamoDB tables${NC}"
else
    echo -e "${RED}❌ DynamoDB verification failed: $DYNAMO_STUDENTS_COUNT students, $DYNAMO_ASSESSMENTS_COUNT assessments${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Data population completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Data Summary:${NC}"
echo "PostgreSQL: $STUDENT_COUNT students, $ASSESSMENT_COUNT assessments"
echo "DynamoDB: $DYNAMO_STUDENTS_COUNT students, $DYNAMO_ASSESSMENTS_COUNT assessments"
echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo "1. Run verification: ./verify-interview-environment.sh $CANDIDATE_NAME $INTERVIEW_ID"
echo "2. Generate credentials: ./generate-credentials-email.sh $CANDIDATE_NAME $INTERVIEW_ID"