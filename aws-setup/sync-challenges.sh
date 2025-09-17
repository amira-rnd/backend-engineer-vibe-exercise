#!/bin/bash

# Sync Challenge Files to S3
# This script uploads all challenge markdown files to the S3 bucket for interview consumption

set -e

# Parse command line arguments
INTERVIEW_ID=${1}
if [ -z "$INTERVIEW_ID" ]; then
    echo "Usage: $0 <interview-id>"
    echo "Example: $0 roba-20250917-0327"
    exit 1
fi

BUCKET_NAME="${INTERVIEW_ID}-challenge-files"
CHALLENGES_DIR="$(cd "$(dirname "$0")/../challenges" && pwd)"

echo "Syncing challenge files to S3..."
echo "Bucket: $BUCKET_NAME"
echo "Source: $CHALLENGES_DIR"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "Error: AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if bucket exists
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Error: S3 bucket '$BUCKET_NAME' does not exist."
    echo "Please deploy the CloudFormation stack first: make deploy CANDIDATE=name"
    exit 1
fi

# Sync challenge files
echo "Uploading challenge files..."
cd "$CHALLENGES_DIR"

for file in *.md; do
    if [ -f "$file" ]; then
        echo "  -> $file"
        aws s3 cp "$file" "s3://$BUCKET_NAME/$file" --content-type "text/plain"
    fi
done

echo ""
echo "✅ Challenge files synced successfully!"
echo ""
echo "Files available at Sample Data API:"
for file in *.md; do
    if [ -f "$file" ]; then
        echo "  curl \"\$SAMPLE_DATA_URL?file=$file\""
    fi
done

echo ""
echo "Test the API with:"
echo "  curl \"\$SAMPLE_DATA_URL\" | jq"