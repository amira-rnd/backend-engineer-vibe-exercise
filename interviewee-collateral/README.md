# Interviewee Collateral

This folder contains all materials that need to be sent to interview candidates.

## Files Overview

### `candidate-prep.md`
**When to send:** 24 hours before interview
**Purpose:** Pre-interview preparation instructions
**Contains:** Software requirements, mental preparation, session structure overview

### `pre-interview-email-template.md`
**When to use:** 24 hours before interview
**Purpose:** Email template for sending preparation instructions
**How to use:** Copy content, customize with candidate name and interview time

### `generate-credentials-email.sh`
**When to use:** 30 minutes before interview
**Purpose:** Generates personalized AWS credentials email with all connection details
**Usage:**
```bash
./generate-credentials-email.sh <candidate-name> [interview-id]
```

**Example:**
```bash
./generate-credentials-email.sh john-doe public-v3
```

## Interview Preparation Workflow

### Step 1: 24 Hours Before Interview
1. Use `pre-interview-email-template.md` as your email template
2. Customize with candidate's name and interview time
3. Send to candidate
4. Attach `candidate-prep.md` for detailed preparation instructions

### Step 2: 30 Minutes Before Interview
1. Ensure your AWS interview stack is deployed and ready
2. Run the credentials generation script:
   ```bash
   ./generate-credentials-email.sh <candidate-name> <interview-id>
   ```
3. Copy the generated email content from the `.txt` file
4. Send to candidate immediately
5. Give candidate 10-15 minutes to set up and test connections

### Step 3: Interview Start
1. Verify candidate can connect to all resources
2. Quick screen share test
3. Begin 60-minute coding session

## Generated Files

The script creates files like:
- `candidate-credentials-{name}-{id}.txt` - Full email content with AWS access details

These files contain sensitive AWS credentials and should be:
- ✅ Sent to candidates securely
- ✅ Deleted after the interview
- ❌ Never committed to version control
- ❌ Never shared publicly

## Troubleshooting

### Script Issues
- **"Stack not found":** Verify the interview stack is deployed with the correct naming pattern
- **"jq command not found":** Install jq: `brew install jq` (macOS) or `apt-get install jq` (Ubuntu)
- **AWS CLI errors:** Ensure your personal AWS profile is configured

### Candidate Setup Issues
- **AWS credentials don't work:** Have them re-run the assume-role command
- **Database connection fails:** Check password copying (special characters)
- **DynamoDB access denied:** Verify they're using the assumed role credentials

## Security Notes

- Candidate credentials expire after 1 hour
- All resources are deleted when the interview stack is cleaned up
- No real sensitive data is exposed
- Strong passwords include AWS Account ID for additional security