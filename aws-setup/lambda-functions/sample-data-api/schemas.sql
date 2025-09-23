-- Amira Learning Database Schema
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

CREATE TABLE students (
    student_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(school_id),
    district_id UUID REFERENCES districts(district_id),
    external_id VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    grade INTEGER CHECK (grade >= 0 AND grade <= 12),
    reading_level DECIMAL(3,1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE assessments (
    assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(student_id),
    type VARCHAR(50) NOT NULL,
    score INTEGER,
    raw_score DECIMAL(5,2),
    percentile INTEGER CHECK (percentile >= 0 AND percentile <= 100),
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Legacy SQL Server Schema (for migration reference)
-- Note: Different naming conventions and data types

CREATE TABLE dbo.Students_Legacy (
    StudentID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    SchoolCode VARCHAR(20),
    StudentNumber VARCHAR(50),
    FirstName NVARCHAR(100),
    LastName NVARCHAR(100),
    Grade INT,
    ReadingLevel FLOAT,  -- Can be negative!
    EnrollmentDate DATETIME2,
    LastModified DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE dbo.Assessments_Legacy (
    AssessmentID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    StudentID UNIQUEIDENTIFIER FOREIGN KEY REFERENCES Students_Legacy(StudentID),
    AssessmentType VARCHAR(50),
    ScoreValue INT,
    CompletedDate DATETIME2,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);

-- Migration Notes:
-- 1. Legacy ReadingLevel can be negative (data quality issue)
-- 2. Grade mappings: "Kindergarten" -> 0, "First" -> 1, etc.
-- 3. AssessmentType priority: BENCHMARK > PROGRESS_MONITORING > INSTRUCT