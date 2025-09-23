# AWS Interview Resources Reference

This document lists all AWS resources provided for the interview challenges. All resource names are fixed (not candidate-specific) to eliminate confusion.

## Sample Data API
- **URL:** Provided in your credentials email
- **Usage:** `curl "$SAMPLE_DATA_URL?file=schemas.sql"`
- **Available files:** schemas.sql, test-data.json, legacy-api-docs.md, challenge files, CSV data

## Challenge A - Data Migration

**DynamoDB Tables:**
- `interview-students` - Student records with primary key `student_id`
- `interview-assessments` - Assessment data with primary key `assessment_id`
- `interview-classes` - Class information with primary key `class_id`
- `interview-schools` - School data with primary key `school_id`

**Sample Data:**
- `legacy-students.csv` - Source student data with quality issues
- `legacy-assessments.csv` - Source assessment data with quality issues

## Challenge B - Memory Leak Debugging

**Lambda Function:** `interview-buggy-api`
**CloudWatch Logs:** `/aws/lambda/interview-buggy-api`

Access the function code and logs to identify and fix memory leaks.

## Challenge C - Performance Optimization

**PostgreSQL Database:**
- **Endpoint:** `interview-db-performance.[region].rds.amazonaws.com`
- **Username:** `postgres`
- **Password:** Provided in credentials email
- **Database:** `postgres`

Contains tables: districts, schools, classes, students, assessments with performance issues to optimize.

## Important Notes

- All resource names are fixed - no placeholders or variables to substitute
- Resources are isolated per interview session via CloudFormation stack
- No Redis access provided (internal VPC resource only)
- Use your AWS credentials provided in the interview email