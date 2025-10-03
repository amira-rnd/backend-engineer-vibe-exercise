# Challenge A: Legacy Data Migration
## ⭐ PRIORITY CHALLENGE
## Time: 15 minutes

### Background

Amira is migrating student assessment data from a legacy SQL Server system to our new AWS-based architecture. The legacy system has data quality issues and uses different schemas than our current system.

### Getting the Legacy Data

Download the sample legacy data files (exports from the SQL Server database):

```bash
# Download legacy student data
curl "$SAMPLE_DATA_URL?file=legacy-students.csv" -o legacy-students.csv

# Download legacy assessment data
curl "$SAMPLE_DATA_URL?file=legacy-assessments.csv" -o legacy-assessments.csv
```

**These CSV files contain actual exported data from the legacy SQL Server system** with all the data quality issues described below. Use these files as your data source for migration.

### Your Task

Create a migration script that:
1. Reads from the legacy CSV files (legacy-students.csv and legacy-assessments.csv)
2. Transforms the data to match our new schema
3. Handles data quality issues gracefully
4. Writes to DynamoDB in batches

### Legacy Schema (SQL Server)

```sql
-- Legacy Students Table
CREATE TABLE Students (
    StudentID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Grade VARCHAR(10),  -- Sometimes text like 'Third', sometimes numbers like '3'
    SchoolCode VARCHAR(20),
    CreatedDate DATETIME,
    IsActive BIT,
    ReadingLevel FLOAT  -- Can be NULL or negative (data quality issue)
);

-- Legacy Assessments Table  
CREATE TABLE Assessments (
    AssessmentID INT PRIMARY KEY,
    StudentID INT,
    AssessmentType VARCHAR(50), -- 'DIBELS', 'PROGRESS', 'BENCHMARK' (inconsistent)
    Score FLOAT,
    DateTaken DATETIME,
    TeacherNotes TEXT,
    ProcessingStatus VARCHAR(20) -- Often NULL
);
```

### Target DynamoDB Schema

```javascript
// Table: interview-students
{
  "student_id": "uuid",  // Primary Key
  "class_id": "uuid",
  "first_name": "string",
  "last_name": "string",
  "grade_level": number,  // Must be 0-12
  "reading_level": number,  // Must be 0.0-12.0
  "status": "ACTIVE|INACTIVE",
  "created_at": "ISO-8601"
}

// Table: interview-assessments
{
  "assessment_id": "uuid",  // Primary Key
  "student_id": "uuid",
  "type": "BENCHMARK|PROGRESS_MONITORING|INSTRUCT",
  "score": number,
  "window_tag": "BOY|MOY|EOY",
  "created_at": "ISO-8601",
  "teacher_notes": "string",
  "status": "COMPLETED|PROCESSING|ERROR"
}
```

### Known Data Quality Issues

⚠️ **The product owner has identified the following data quality issues** that are expected in the legacy system. Your migration script should handle these gracefully:

1. **Grade normalization**: Convert text grades ('Third') to numbers (3)
2. **Reading levels**: Handle NULL and negative values (default to grade level - 0.5)
3. **Assessment types**: Standardize inconsistent naming
4. **Dates**: Some dates are in the future (data entry errors)
5. **Orphaned assessments**: Some assessments reference non-existent students

### Requirements

- Write to DynamoDB tables: `interview-students` and `interview-assessments`
- Use BatchWriteItem for efficiency (25 items max per batch)
- Implement retry logic with exponential backoff
- Log all data quality issues for review
- Generate new UUIDs for primary keys
- Maintain a mapping of old IDs to new IDs

### Sample Data Issues

```javascript
// Example problematic records
{
  StudentID: 123,
  FirstName: "Sarah",
  LastName: "Johnson",
  Grade: "Third",  // Text instead of number
  ReadingLevel: -1  // Invalid negative value
}

{
  AssessmentID: 456,
  StudentID: 999,  // This student doesn't exist
  AssessmentType: "DIBELS",  // Should map to BENCHMARK
  DateTaken: "2026-01-01"  // Future date
}
```

