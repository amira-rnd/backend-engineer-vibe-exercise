const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
    const bucket = process.env.CHALLENGE_BUCKET;
    const queryParams = event.queryStringParameters || {};
    const file = queryParams.file;

    // Built-in files (not in S3) - keep schemas, docs, and test data inline for simplicity
    const builtInFiles = {
        'schemas.sql': `-- Amira Learning Database Schema
-- Current Production Schema (PostgreSQL)

CREATE TABLE districts (
    district_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    state VARCHAR(2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE schools (
    school_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    district_id UUID REFERENCES districts(district_id),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE classes (
    class_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(school_id),
    teacher_id UUID,
    grade_level INTEGER CHECK (grade_level >= 0 AND grade_level <= 12),
    subject VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE students (
    student_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID REFERENCES classes(class_id),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    grade_level INTEGER CHECK (grade_level >= 0 AND grade_level <= 12),
    reading_level DECIMAL(3,1),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE assessments (
    assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(student_id),
    type VARCHAR(50) NOT NULL, -- BENCHMARK, PROGRESS_MONITORING, INSTRUCT
    window_tag VARCHAR(20), -- BOY, MOY, EOY
    score DECIMAL(5,2),
    reading_level DECIMAL(3,1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_students_class_id ON students(class_id);
CREATE INDEX idx_assessments_student_id ON assessments(student_id);
CREATE INDEX idx_assessments_type_window ON assessments(type, window_tag);`,

        'legacy-api-docs.md': `# Legacy API Documentation

## Students Endpoint
GET /api/v1/students

Returns array of student records with the following issues:
- Grade levels as text (Third, Fourth) instead of numbers
- Negative reading levels
- NULL reading levels
- Inconsistent field naming

Example Response:
\`\`\`json
[
  {
    "StudentID": 123,
    "FirstName": "Sarah",
    "LastName": "Johnson",
    "Grade": "Third",
    "ReadingLevel": 3.2,
    "Status": "Active"
  }
]
\`\`\`

## Migration Notes
- Clean data quality issues
- Standardize field formats
- Generate new UUIDs for DynamoDB`,

        'test-data.json': JSON.stringify({
            "legacy_students": [
                {
                    "StudentID": 123,
                    "FirstName": "Sarah",
                    "LastName": "Johnson",
                    "Grade": "Third",
                    "ReadingLevel": 3.2,
                    "Status": "Active"
                },
                {
                    "StudentID": 124,
                    "FirstName": "Mike",
                    "LastName": "Wilson",
                    "Grade": "3rd",
                    "ReadingLevel": -1.0,
                    "Status": "ACTIVE"
                },
                {
                    "StudentID": 125,
                    "FirstName": "Emma",
                    "LastName": "Davis",
                    "Grade": "Third",
                    "ReadingLevel": null,
                    "Status": "active"
                }
            ]
        }, null, 2)
    };

    if (!file) {
        return {
            statusCode: 200,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                message: 'Sample Data API for Interview',
                available_files: [
                    'schemas.sql',
                    'legacy-api-docs.md',
                    'test-data.json',
                    'challenge-a-migration.md',
                    'challenge-b-debugging.md',
                    'challenge-b-alternative.md',
                    'challenge-c-optimization.md',
                    'rapid-fire-tasks.md',
                    'legacy-students.csv',
                    'legacy-assessments.csv'
                ],
                usage: 'Add ?file=filename to URL',
                example: 'curl "$SAMPLE_DATA_URL?file=challenge-a-migration.md"'
            })
        };
    }

    // Check built-in files first
    if (builtInFiles[file]) {
        const contentType = file.endsWith('.json') ? 'application/json' : 'text/plain';
        return {
            statusCode: 200,
            headers: { 'Content-Type': contentType },
            body: builtInFiles[file]
        };
    }

    // Try to fetch challenge files from S3
    try {
        const params = {
            Bucket: bucket,
            Key: file
        };

        const data = await s3.getObject(params).promise();
        const content = data.Body.toString('utf-8');

        return {
            statusCode: 200,
            headers: { 'Content-Type': 'text/plain' },
            body: content
        };
    } catch (error) {
        if (error.code === 'NoSuchKey') {
            return {
                statusCode: 404,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    error: `File '${file}' not found`,
                    available_files: Object.keys(builtInFiles).concat([
                        'challenge-a-migration.md',
                        'challenge-b-debugging.md',
                        'challenge-b-alternative.md',
                        'challenge-c-optimization.md',
                        'rapid-fire-tasks.md',
                        'legacy-students.csv',
                        'legacy-assessments.csv'
                    ]),
                    note: 'Challenge files are served from S3. If missing, run: aws-setup/sync-challenges.sh <interview-id>'
                })
            };
        }

        console.error('S3 Error:', error);
        return {
            statusCode: 500,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                error: 'Internal server error',
                message: 'Could not retrieve file from S3'
            })
        };
    }
};