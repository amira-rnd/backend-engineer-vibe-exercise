#!/bin/bash
# Download All Interview Challenge Files
# Usage: ./download-challenges.sh [API_BASE_URL]
# Example: ./download-challenges.sh https://9lxu6ect3e.execute-api.us-east-1.amazonaws.com/prod

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get API URL from argument or prompt
if [ -z "$1" ]; then
    echo -e "${YELLOW}Enter the Sample Data API URL from your credentials email:${NC}"
    echo "(Should look like: https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod)"
    read -p "API URL: " API_URL
else
    API_URL="$1"
fi

# Validate URL format
if [[ ! "$API_URL" =~ ^https://.*\.execute-api\..* ]]; then
    echo -e "${RED}❌ Invalid API URL format${NC}"
    echo "Expected format: https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod"
    exit 1
fi

echo -e "${BLUE}📥 Discovering available files from: $API_URL${NC}"

# First, get the list of available files from the API
echo -e "${BLUE}Fetching file list...${NC}"
if ! file_list=$(curl -f "$API_URL" -s); then
    echo -e "${RED}❌ Failed to connect to API${NC}"
    echo "Make sure the API URL is correct and you have network access"
    exit 1
fi

# Parse the JSON response to extract file names
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq not found. Attempting simple JSON parsing...${NC}"
    # Simple grep-based extraction if jq is not available
    files=$(echo "$file_list" | grep -o '"[^"]*\.[^"]*"' | tr -d '"' | grep -E '\.(md|sql|json|txt|js|csv)$' | sort -u)
else
    # Use jq for proper JSON parsing
    files=$(echo "$file_list" | jq -r '.available_files[]? // empty' 2>/dev/null || echo "$file_list" | grep -o '"[^"]*\.[^"]*"' | tr -d '"' | grep -E '\.(md|sql|json|txt|js|csv)$' | sort -u)
fi

if [ -z "$files" ]; then
    echo -e "${RED}❌ No files found or could not parse API response${NC}"
    echo "API Response:"
    echo "$file_list"
    exit 1
fi

echo ""
echo -e "${GREEN}📋 Found available files:${NC}"
echo "$files"

# Create challenges directory if it doesn't exist
mkdir -p challenges
cd challenges

echo ""
echo -e "${BLUE}📥 Downloading all available files...${NC}"

# Download each file
while IFS= read -r file; do
    [ -z "$file" ] && continue

    echo -e "${BLUE}Downloading $file...${NC}"

    # Create directory structure if needed
    if [[ "$file" == */* ]]; then
        mkdir -p "$(dirname "$file")"
    fi

    if curl -f "$API_URL?file=$file" -o "$file" -s; then
        # Verify file has content
        if [ -s "$file" ]; then
            echo -e "${GREEN}✅ $file downloaded successfully${NC}"
        else
            echo -e "${RED}❌ $file downloaded but is empty${NC}"
            rm "$file"
        fi
    else
        echo -e "${RED}❌ Failed to download $file${NC}"
    fi
done <<< "$files"

echo ""
echo -e "${GREEN}📁 Downloaded files:${NC}"
ls -la * 2>/dev/null || echo "No files downloaded"

echo ""
echo -e "${BLUE}💡 Files saved to: $(pwd)${NC}"
echo -e "${BLUE}📝 You can now open these files in your preferred editor${NC}"

# Quick verification
echo ""
echo -e "${BLUE}🔍 Quick verification:${NC}"
for file in *; do
    if [ -f "$file" ]; then
        if [[ "$file" =~ \.(md|txt|sql|js|json|csv)$ ]]; then
            line_count=$(wc -l < "$file" 2>/dev/null || echo "0")
            echo "  $file: $line_count lines"
        else
            size=$(ls -lh "$file" | awk '{print $5}')
            echo "  $file: $size"
        fi
    fi
done

echo ""
echo -e "${GREEN}🎉 Download complete! Ready for interview challenges.${NC}"