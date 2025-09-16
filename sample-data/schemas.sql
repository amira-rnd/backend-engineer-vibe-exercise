-- Amira Learning Database Schema
-- Current Production Schema (PostgreSQL)

-- Districts Table
CREATE TABLE districts (
    district_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    state VARCHAR(2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Schools Table
CREATE TABLE schools (
    school_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    district_id UUID REFERENCES districts(district_id),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50), -- 'ELEMENTARY', 'MIDDLE', 'HIGH'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Classes Table
CREATE TABLE classes (
    class_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(school_id),
    teacher_id UUID,
    name VARCHAR(255),
    grade_level INTEGER CHECK (grade_level >= 0 AND grade_level <= 12),
    period_id VARCHAR(50), -- 'BOY', 'MOY', 'EOY'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Students Table
CREATE TABLE students (
    student_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID REFERENCES classes(class_id),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    grade_level INTEGER CHECK (grade_level >= 0 AND grade_level <= 12),
    reading_level DECIMAL(3,1),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Assessments Table
CREATE TABLE assessments (
    assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(student_id),
    type VARCHAR(50) NOT NULL, -- 'BENCHMARK', 'PROGRESS_MONITORING', 'INSTRUCT'
    score DECIMAL(5,2),
    window_tag VARCHAR(20), -- 'BOY_2024', 'MOY_2024', 'EOY_2024'
    status VARCHAR(20) DEFAULT 'COMPLETED',
    teacher_notes TEXT,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indices for Performance
CREATE INDEX idx_assessments_student_id ON assessments(student_id);
CREATE INDEX idx_assessments_type ON assessments(type);
CREATE INDEX idx_assessments_window ON assessments(window_tag);
CREATE INDEX idx_assessments_completed ON assessments(completed_at);

CREATE INDEX idx_students_class_id ON students(class_id);
CREATE INDEX idx_students_status ON students(status);

CREATE INDEX idx_classes_school_id ON classes(school_id);
CREATE INDEX idx_schools_district_id ON schools(district_id);

-- Legacy Schema (SQL Server - for migration challenge)
-- Note: Different field names and types

-- Legacy Students Table
-- StudentID INT PRIMARY KEY
-- FirstName VARCHAR(50)
-- LastName VARCHAR(50) 
-- Grade VARCHAR(10) -- Sometimes 'Third', sometimes '3'
-- SchoolCode VARCHAR(20)
-- CreatedDate DATETIME
-- IsActive BIT
-- ReadingLevel FLOAT -- Can be NULL or negative

-- Legacy Assessments Table
-- AssessmentID INT PRIMARY KEY
-- StudentID INT
-- AssessmentType VARCHAR(50) -- 'DIBELS', 'PROGRESS', 'BENCHMARK'
-- Score FLOAT
-- DateTaken DATETIME
-- TeacherNotes TEXT
-- ProcessingStatus VARCHAR(20) -- Often NULL
