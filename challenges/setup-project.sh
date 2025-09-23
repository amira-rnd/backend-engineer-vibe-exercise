#!/bin/bash
# Challenge B Setup Script - Buggy Assessment API Project
# Downloads all project files and sets up directory structure

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Setting up Challenge B - Buggy Assessment API Project${NC}"
echo ""

# Check if SAMPLE_DATA_URL is available
if [ -z "$SAMPLE_DATA_URL" ]; then
    echo -e "${RED}❌ SAMPLE_DATA_URL environment variable not set${NC}"
    echo "Please set SAMPLE_DATA_URL from your interview credentials email"
    echo "Example: export SAMPLE_DATA_URL=\"https://abc123.execute-api.us-east-1.amazonaws.com/prod\""
    exit 1
fi

# Create project directory structure
echo -e "${BLUE}📁 Creating project directory structure...${NC}"
mkdir -p buggy-assessment-api/lib
cd buggy-assessment-api

# Download main files
echo -e "${BLUE}📥 Downloading project files...${NC}"

echo "  → main.js"
curl -s "$SAMPLE_DATA_URL?file=main.js" -o main.js

echo "  → package.json"
curl -s "$SAMPLE_DATA_URL?file=package.json" -o package.json

echo "  → README.md"
curl -s "$SAMPLE_DATA_URL?file=README.md" -o README.md

# Download lib files
echo "  → lib/request-processor.js"
curl -s "$SAMPLE_DATA_URL?file=lib/request-processor.js" -o lib/request-processor.js

echo "  → lib/legacy-client.js"
curl -s "$SAMPLE_DATA_URL?file=lib/legacy-client.js" -o lib/legacy-client.js

echo "  → lib/cache-manager.js"
curl -s "$SAMPLE_DATA_URL?file=lib/cache-manager.js" -o lib/cache-manager.js

echo "  → lib/metrics-collector.js"
curl -s "$SAMPLE_DATA_URL?file=lib/metrics-collector.js" -o lib/metrics-collector.js

echo "  → lib/data-enricher.js"
curl -s "$SAMPLE_DATA_URL?file=lib/data-enricher.js" -o lib/data-enricher.js

# Verify all files downloaded successfully
echo ""
echo -e "${BLUE}✅ Verifying downloaded files...${NC}"

EXPECTED_FILES=("main.js" "package.json" "README.md" "lib/request-processor.js" "lib/legacy-client.js" "lib/cache-manager.js" "lib/metrics-collector.js" "lib/data-enricher.js")
MISSING_FILES=()

for file in "${EXPECTED_FILES[@]}"; do
    if [ ! -f "$file" ] || [ ! -s "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ All files downloaded successfully!${NC}"
    echo ""
    echo -e "${BLUE}📊 Project structure created:${NC}"
    tree . 2>/dev/null || find . -type f | sort
    echo ""
    echo -e "${GREEN}🚀 Ready to debug! Start with: cat README.md${NC}"
    echo -e "${BLUE}💡 Remember to look for memory leaks across all 6 modules${NC}"
else
    echo -e "${RED}❌ Some files failed to download: ${MISSING_FILES[*]}${NC}"
    echo "Check your SAMPLE_DATA_URL and internet connection"
    exit 1
fi