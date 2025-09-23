#!/bin/bash
# Sync Challenge B project files back to CloudFormation template
# This allows editing in separate files but keeps deployment simple

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/lambda-functions/sample-data-api/challenge-b-project"
CLOUDFORMATION_FILE="$SCRIPT_DIR/interview-stack.yaml"

echo "🔄 Syncing Challenge B project files to CloudFormation..."

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Project directory not found: $PROJECT_DIR"
    exit 1
fi

echo "📁 Reading files from: $PROJECT_DIR"
echo "📝 Updating: $CLOUDFORMATION_FILE"

echo "⚠️  This script needs to be implemented to update the CloudFormation template"
echo "💡 For now, edit files in $PROJECT_DIR and manually update the template"

# TODO: Implement automatic sync to CloudFormation
# This would read the files and update the inline content in interview-stack.yaml

echo "✅ Sync completed (manual process for now)"