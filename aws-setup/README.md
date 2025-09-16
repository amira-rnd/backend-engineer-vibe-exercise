# AWS Interview Environment Setup

This directory contains CloudFormation templates and scripts to create isolated, resettable AWS environments for the Amira Learning vibe coding exercise.

## Overview

**Cost:** ~$0.03 per 60-minute interview session
**Approach:** CloudFormation stack per interview for complete isolation
**Resources:** Free tier optimized (DynamoDB, Lambda, RDS t3.micro, ElastiCache t3.micro)

## Quick Start

### 1. Deploy Interview Environment
```bash
cd aws-setup
./deploy-interview.sh john-doe
```
*Automatically runs verification and displays readiness status*

### 2. Generate Candidate Credentials
```bash
cd ../interviewee-collateral
./generate-credentials-email.sh john-doe
```
*Generates cross-platform setup instructions with 4-hour credentials*

### 3. Verify Environment (Optional)
```bash
cd aws-setup
./verify-interview-environment.sh john-doe
```
*Comprehensive health check of all interview resources*

### 4. After Interview - Cleanup
```bash
./cleanup-interview.sh interview-20241216-1400
```

## Files

- `interview-stack.yaml` - CloudFormation template for complete environment
- `deploy-interview.sh` - Creates stack with unique interview ID
- `cleanup-interview.sh` - Deletes stack and all resources
- `README.md` - This file

## Resources Created

### Challenge A: Data Migration
- **DynamoDB Tables:** Students, Assessments, Classes, Schools
- **Sample Data:** Includes intentional data quality issues
- **Access:** Full DynamoDB operations for migration exercise

### Challenge B: Memory Leak Debugging
- **Lambda Function:** Pre-deployed with intentional memory leaks
- **CloudWatch Logs:** Enabled for debugging session
- **Issues:** Singleton pattern problems, unbounded cache, connection accumulation

### Challenge C: Performance Optimization
- **RDS:** PostgreSQL db.t3.micro with slow query dataset
- **ElastiCache:** Redis t3.micro for caching exercise
- **Access:** Read-only database access, cache read/write

### Security & Access Control
- **Candidate IAM Role:** Limited permissions scoped to interview resources
- **External ID:** Unique per interview for secure access
- **Deny Policies:** Prevents access to billing, IAM, or other accounts

## Cost Breakdown

| Resource | Free Tier | Cost/Interview |
|----------|-----------|----------------|
| DynamoDB | 25GB, 25 RCU/WCU | $0.00 |
| Lambda | 1M requests, 400K GB-seconds | $0.00 |
| RDS t3.micro | 750 hours/month | $0.00* |
| ElastiCache t3.micro | No free tier | ~$0.02 |
| CloudWatch | 10 metrics, 1M requests | $0.00 |
| **Total** | | **~$0.03** |

*Free if under 750 hours/month total RDS usage

## Interview Workflow

### Before Interview
1. Run deploy script with candidate name
2. Share generated credentials file
3. Verify environment is ready (RDS available, sample data loaded)

### During Interview (60 minutes)
- Candidate uses provided AWS credentials
- All resources are isolated to their interview session
- No access to other candidates' resources or account billing

### After Interview
1. Run cleanup script to delete all resources
2. Capture any code artifacts before deletion
3. All charges stop immediately

## Advanced Usage

### Custom Interview ID
```bash
./deploy-interview.sh jane-smith interview-20241216-1400
```

### Manual Stack Operations
```bash
# Deploy with AWS CLI directly
aws cloudformation deploy \
    --template-file interview-stack.yaml \
    --stack-name amira-interview-custom \
    --parameter-overrides InterviewId=custom CandidateName=test \
    --capabilities CAPABILITY_NAMED_IAM \
    --profile personal

# Delete with AWS CLI
aws cloudformation delete-stack \
    --stack-name amira-interview-custom \
    --profile personal
```

### Multiple Interviews
The system supports running multiple interviews simultaneously:
- Each gets isolated resources with unique names
- No resource conflicts between sessions
- Independent cleanup of each environment

## Troubleshooting

### Deployment Fails
- Check AWS credentials: `aws sts get-caller-identity --profile personal`
- Verify region has required services available
- Check CloudFormation events in AWS Console

### High Costs
- Ensure cleanup scripts are run after each interview
- Monitor ElastiCache charges (only billable resource)
- RDS charges only apply after 750 hours/month

### Access Issues
- Verify candidate role ARN and external ID
- Check IAM permissions in candidate setup
- Ensure candidate uses correct region

## Security Notes

- Candidate access is read-only to production-like data
- No access to billing, IAM, or account management
- Resources are isolated per interview
- All data is ephemeral and gets deleted post-interview

## Next Steps

Consider adding:
- Automated sample data population for Challenge C (RDS)
- Cost alerts for unexpected charges
- CloudTrail logging for interview sessions
- Automated environment health checks