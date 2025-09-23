#!/bin/bash
# Package Buggy Lambda Function for CloudFormation Deployment
# This creates a deployable version of Challenge B with working dependencies
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHALLENGE_B_DIR="$SCRIPT_DIR/lambda-functions/sample-data-api/challenge-b-project"
PACKAGE_DIR="$SCRIPT_DIR/packaged-lambdas"
BUILD_DIR="/tmp/buggy-lambda-build"

echo "📦 Packaging buggy Lambda function with dependencies..."

# Check if Challenge B project exists
if [ ! -d "$CHALLENGE_B_DIR" ]; then
    echo "❌ Challenge B project not found at: $CHALLENGE_B_DIR"
    exit 1
fi

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy Challenge B project files
echo "Copying Challenge B project files..."
cp "$CHALLENGE_B_DIR/index.js" "$BUILD_DIR/"
cp "$CHALLENGE_B_DIR/main.js" "$BUILD_DIR/"
cp -r "$CHALLENGE_B_DIR/lib" "$BUILD_DIR/"

# Create deployable package.json with working versions
echo "Creating deployable package.json..."
cat > "$BUILD_DIR/package.json" << 'EOF'
{
  "name": "buggy-assessment-api",
  "version": "1.0.0",
  "description": "Amira Learning - Assessment API with Memory Leaks",
  "main": "index.js",
  "dependencies": {
    "edge-js": "^12.3.1",
    "aws-sdk": "^2.1400.0",
    "pg": "^8.11.0",
    "redis": "^4.6.0"
  },
  "scripts": {
    "start": "node main.js"
  }
}
EOF

# Install dependencies
echo "Installing npm dependencies..."
cd "$BUILD_DIR"
npm install --production

# Create deployment package
echo "Creating deployment package..."
zip -r "$PACKAGE_DIR/buggy-lambda.zip" . -x "*.DS_Store" "*.git*"

# Cleanup
rm -rf "$BUILD_DIR"

echo "✅ Buggy Lambda packaged successfully"
echo "📁 Package location: $PACKAGE_DIR/buggy-lambda.zip"
ls -lh "$PACKAGE_DIR/buggy-lambda.zip"

# Verify package contents
echo ""
echo "📋 Package contents:"
unzip -l "$PACKAGE_DIR/buggy-lambda.zip" | head -20