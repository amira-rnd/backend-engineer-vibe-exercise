# Quick Reset Guide

## Overview

The `make reset` command provides a fast way to reset the interview environment between candidates without rebuilding the entire CloudFormation infrastructure.

## Time Savings

- **Full rebuild**: 20-25 minutes (CloudFormation + RDS provisioning)
- **Quick reset**: 1-2 minutes (data-only reset)
- **Time saved**: ~95% reduction

## Usage

```bash
# Quick reset for next candidate
make reset CANDIDATE=new-candidate-name

# Or use existing interview ID
make reset CANDIDATE=jane-doe INTERVIEW_ID=20241217-1430
```

## What Gets Reset

### ✅ Data and State (Cleared)
1. **DynamoDB Tables** - All data cleared and repopulated with clean reference data
   - `interview-students`
   - `interview-assessments`
   - `interview-classes`
   - `interview-schools`

2. **PostgreSQL Database** - All tables truncated and repopulated with sample data
   - Districts, schools, classes, students, assessments
   - Includes intentional data quality issues for Challenge A

3. **Redis Cache** - Completely flushed
   - All cached data removed

4. **Lambda Function Code** - Reset to original buggy version
   - Memory leaks restored for Challenge B debugging

5. **CloudWatch Logs** - Cleared for clean debugging experience
   - `/aws/lambda/interview-buggy-api` log group deleted

6. **S3 Challenge Files** - Re-synced from local repository
   - Challenge markdown files
   - Project files for Challenge B
   - CSV files for Challenge A

7. **AWS Credentials** - New temporary session generated
   - Previous assume-role sessions invalidated
   - Fresh credentials file created

### ❌ Infrastructure (Preserved)

1. **CloudFormation Stack** - Remains intact
   - No stack deletion/recreation

2. **VPC and Networking** - Unchanged
   - Subnets, route tables, security groups
   - Internet Gateway, NAT Gateway

3. **RDS Instance** - Instance preserved, only data cleared
   - No provisioning time required
   - Connection endpoints remain same

4. **ElastiCache Redis** - Instance preserved, cache flushed
   - No cluster provisioning time

5. **IAM Roles and Policies** - Unchanged
   - Candidate role remains configured
   - Lambda execution role preserved

6. **API Gateway** - Endpoints remain active
   - Sample Data API stays accessible

## When to Use

### ✅ Ideal For
- **Between interview sessions** with different candidates
- **Testing/practice runs** where you need fresh data
- **Quick iteration** during interview development
- **Multiple interviews in one day**

### ❌ Not Suitable For
- **First-time setup** (use `make deploy` instead)
- **Infrastructure changes** (requires full rebuild)
- **Region changes** (requires new deployment)
- **Major version updates** (may need schema changes)

## Verification

After reset, the script automatically verifies:
- DynamoDB tables have clean reference data
- PostgreSQL has sample data with intentional issues
- All services are accessible

## Example Workflow

```bash
# Initial setup for first interview of the day
make deploy CANDIDATE=candidate1

# First interview session
make credentials CANDIDATE=candidate1
# ... interview happens ...

# Quick reset for second interview (same day)
make reset CANDIDATE=candidate2
make credentials CANDIDATE=candidate2
# ... next interview happens ...

# End of day cleanup
make cleanup CANDIDATE=candidate2
```

## Troubleshooting

If reset fails, you can:

1. **Try again** - Script is idempotent
2. **Check logs** - Script shows detailed progress
3. **Verify manually** - `make verify CANDIDATE=name`
4. **Full rebuild** - `make cleanup` then `make deploy` as last resort

## Cost Benefits

- **Eliminates** 20+ minutes of CloudFormation/RDS provisioning
- **Reduces** overall AWS usage time per interview
- **Enables** same-day multiple interviews
- **Maintains** all infrastructure advantages of full deployment