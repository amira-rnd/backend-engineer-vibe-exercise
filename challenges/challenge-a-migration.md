# Challenge A: Legacy Data Migration
## ⭐ PRIORITY CHALLENGE
## Time: 15 minutes

### Background

Amira is migrating student assessment data from a legacy SQL Server system to our new AWS-based architecture. The legacy system has data quality issues and uses different schemas than our current system.

### Your Task

Create a migration script that:
1. Reads from the legacy database structure
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
// Student Record
{
  "PK": "STUDENT#<uuid>",
  "SK": "PROFILE",
  "firstName": "string",
  "lastName": "string", 
  "grade": number,  // Must be 0-12
  "schoolId": "SCHOOL#<uuid>",
  "createdAt": "ISO-8601",
  "status": "ACTIVE|INACTIVE",
  "readingLevel": number,  // Must be 0.0-12.0
  "entityType": "STUDENT"
}

// Assessment Record
{
  "PK": "STUDENT#<uuid>",
  "SK": "ASSESSMENT#<timestamp>",
  "assessmentId": "string",
  "type": "BENCHMARK|PROGRESS_MONITORING|INSTRUCT",
  "score": number,
  "completedAt": "ISO-8601",
  "teacherNotes": "string",
  "status": "COMPLETED|PROCESSING|ERROR",
  "entityType": "ASSESSMENT"
}
```

### Data Quality Issues to Handle

1. **Grade normalization**: Convert text grades ('Third') to numbers (3)
2. **Reading levels**: Handle NULL and negative values (default to grade level - 0.5)
3. **Assessment types**: Standardize inconsistent naming
4. **Dates**: Some dates are in the future (data entry errors)
5. **Orphaned assessments**: Some assessments reference non-existent students

### Requirements

- Use BatchWriteItem for efficiency (25 items max per batch)
- Implement retry logic with exponential backoff
- Log all data quality issues for review
- Generate new UUIDs for the DynamoDB PKs
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

### Evaluation Criteria

**Excellent (5/5):**
- Handles critical data quality issues (grade, reading level)
- Implements batch processing
- Basic error handling
- Efficient AI usage for boilerplate

**Good (4/5):**
- Handles most data quality issues
- Basic batch processing works
- Some error handling

**Acceptable (3/5):**
- Basic migration works
- Handles some edge cases
- Gets data moving

**Below Expectations (<3/5):**
- Doesn't handle critical data issues
- No batch processing
- Major bugs

### Hints

After 5 minutes:
- "Focus on grade normalization first"
- "Don't worry about perfect retry logic"
- "BatchWriteItem has a 25 item limit"

### Discussion Questions

1. How would you handle this at scale (millions of records)?
2. What monitoring would you add?
3. How would you validate the migration was successful?
4. What would you do differently if this was a live migration?
