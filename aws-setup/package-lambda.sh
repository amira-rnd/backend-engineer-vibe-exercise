#!/bin/bash
# Package Lambda Functions for CloudFormation Deployment
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAMBDA_DIR="$SCRIPT_DIR/lambda-functions"
PACKAGE_DIR="$SCRIPT_DIR/packaged-lambdas"

echo "📦 Packaging Lambda functions..."

# Clean and create package directory
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Package Sample Data API
echo "Packaging sample-data-api..."
cd "$LAMBDA_DIR/sample-data-api"
zip -r "$PACKAGE_DIR/sample-data-api.zip" . -x "*.DS_Store" "*.git*"

echo "✅ Lambda functions packaged successfully"
echo "📁 Package location: $PACKAGE_DIR/"
ls -la "$PACKAGE_DIR/"