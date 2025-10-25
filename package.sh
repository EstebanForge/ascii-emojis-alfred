#!/bin/bash

# ASCII Emojis Alfred Workflow Packaging Script
# Author: EstebanForge
# Version: 1.0.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Workflow details
WORKFLOW_NAME="ascii-emojis"
AUTHOR="EstebanForge"
VERSION="1.0.0"
OUTPUT_FILE="${WORKFLOW_NAME}.alfredworkflow"

echo -e "${BLUE}📦 ASCII Emojis Alfred Workflow Packaging Script${NC}"
echo -e "${BLUE}=========================================${NC}"
echo

# Check if required files exist
echo -e "${YELLOW}🔍 Checking required files...${NC}"

required_files=(
    "info.plist"
    "scripts/search.sh"
    "emojis.json"
    "icon.png"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        missing_files+=("$file")
    fi
done

if [[ ${#missing_files[@]} -gt 0 ]]; then
    echo -e "${RED}❌ Error: Missing required files:${NC}"
    for file in "${missing_files[@]}"; do
        echo -e "${RED}   - $file${NC}"
    done
    echo
    echo -e "${YELLOW}Please ensure all required files are present before packaging.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All required files found${NC}"

# Check script executable permissions
echo -e "${YELLOW}🔧 Checking script permissions...${NC}"
if [[ ! -x "scripts/search.sh" ]]; then
    echo -e "${YELLOW}⚠️  Making search.sh executable...${NC}"
    chmod +x scripts/search.sh
else
    echo -e "${GREEN}✅ Scripts are executable${NC}"
fi

# Remove old package if it exists
if [[ -f "$OUTPUT_FILE" ]]; then
    echo -e "${YELLOW}🗑️  Removing old package: $OUTPUT_FILE${NC}"
    rm "$OUTPUT_FILE"
fi

# Create the package
echo -e "${YELLOW}📦 Creating Alfred workflow package...${NC}"
zip -r "$OUTPUT_FILE" info.plist scripts/ emojis.json icon.png > /dev/null

# Verify package was created
if [[ -f "$OUTPUT_FILE" ]]; then
    package_size=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo -e "${GREEN}✅ Package created successfully!${NC}"
    echo
    echo -e "${BLUE}Package Details:${NC}"
    echo -e "  • ${GREEN}Name:${NC} $OUTPUT_FILE"
    echo -e "  • ${GREEN}Size:${NC} $package_size"
    echo -e "  • ${GREEN}Author:${NC} $AUTHOR"
    echo -e "  • ${GREEN}Version:${NC} $VERSION"
    echo
    echo -e "${YELLOW}📋 Installation:${NC}"
    echo -e "  1. Double-click ${OUTPUT_FILE} to install in Alfred"
    echo -e "  2. Use 'ascii <search-term>' to find ASCII emojis"
    echo
else
    echo -e "${RED}❌ Error: Failed to create package${NC}"
    exit 1
fi

# Test the workflow script
echo -e "${YELLOW}🧪 Testing workflow script...${NC}"

# Test basic functionality
test_result=$(./scripts/search.sh "table" 2>/dev/null)
if [[ $? -eq 0 && -n "$test_result" ]]; then
    # Count results without jq by counting "uid" occurrences
    result_count=$(echo "$test_result" | jq '.items | length' 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✅ Script test passed - found $result_count table emojis${NC}"
else
    echo -e "${YELLOW}⚠️  Script test failed, but package was created${NC}"
fi

echo -e "${GREEN}🎉 Done! $OUTPUT_FILE is ready for distribution.${NC}"
