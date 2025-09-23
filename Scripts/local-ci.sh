#!/bin/bash
# Scripts/local-ci.sh
# Local CI script that mirrors GitHub Actions workflow for faster feedback

set -e  # Exit on any error
set -u  # Exit on undefined variables

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COVERAGE_THRESHOLD=${COVERAGE_THRESHOLD:-35}
PROJECT_NAME="NotBad"
SCHEME="NotBad"
TEST_PLAN="UnitTestPlan"
DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro Max"

echo -e "${BLUE}🚀 Starting Local CI for $PROJECT_NAME${NC}"
echo -e "${BLUE}Coverage Threshold: $COVERAGE_THRESHOLD%${NC}"
echo ""

# Step 1: Show Xcode version
echo -e "${YELLOW}📱 Xcode Version${NC}"
xcodebuild -version
echo ""

# Step 2: List available simulators (debug)
echo -e "${YELLOW}🎯 Available iOS Simulators${NC}"
if command -v jq &> /dev/null; then
    xcrun simctl list devices --json | jq -r '.devices | to_entries[] | select(.key | contains("iOS")) | .key as $ios | .value[] | select(.isAvailable == true) | "\($ios): \(.name) (\(.udid))"' | head -10
else
    echo "jq not available, using basic list:"
    xcrun simctl list devices | grep "iPhone\|iPad" | head -10
fi
echo ""

# Step 3: Resolve SwiftPM dependencies
echo -e "${YELLOW}📦 Resolving SwiftPM Dependencies${NC}"
xcodebuild -resolvePackageDependencies -project $PROJECT_NAME.xcodeproj -scheme $SCHEME
echo ""

# Step 4: Run unit tests with coverage
echo -e "${YELLOW}🧪 Running Unit Tests with Coverage${NC}"
echo "Destination: $DESTINATION"
echo "Test Plan: $TEST_PLAN"

# Clean up previous results
rm -rf TestResults.xcresult
rm -rf local_artifacts

set -o pipefail
xcodebuild \
    -project $PROJECT_NAME.xcodeproj \
    -scheme $SCHEME \
    -destination "$DESTINATION" \
    -testPlan $TEST_PLAN \
    -enableCodeCoverage YES \
    -resultBundlePath TestResults.xcresult \
    test

echo ""

# Step 5: Convert coverage to JSON
echo -e "${YELLOW}📊 Converting Coverage to JSON${NC}"
mkdir -p local_artifacts
xcrun xccov view --report --json TestResults.xcresult > local_artifacts/coverage-local.json
echo "Coverage report saved to: local_artifacts/coverage-local.json"
echo ""

# Step 6: Enforce coverage threshold
echo -e "${YELLOW}🎯 Enforcing Coverage Threshold${NC}"
if python3 Scripts/check_coverage.py local_artifacts/coverage-local.json "$COVERAGE_THRESHOLD"; then
    echo -e "${GREEN}✅ Coverage threshold passed!${NC}"
    echo ""
    
    # Step 7: Optional - Run markdownlint check
    echo -e "${YELLOW}📝 Running Markdownlint Check${NC}"
    if command -v markdownlint &> /dev/null; then
        if markdownlint "**/*.md" --ignore node_modules --config .markdownlint.jsonc; then
            echo -e "${GREEN}✅ Markdownlint passed!${NC}"
        else
            echo -e "${YELLOW}⚠️  Markdownlint warnings (check ignore list)${NC}"
        fi
    else
        echo "markdownlint not available, install with: npm install -g markdownlint-cli"
    fi
    echo ""
    
    echo -e "${GREEN}🎉 LOCAL CI PASSED! 🎉${NC}"
    echo -e "${GREEN}All checks completed successfully.${NC}"
    echo -e "${BLUE}📋 Artifacts generated:${NC}"
    echo "  - TestResults.xcresult"
    echo "  - local_artifacts/coverage-local.json"
    
else
    echo -e "${RED}❌ Coverage threshold failed!${NC}"
    echo -e "${RED}LOCAL CI FAILED${NC}"
    exit 1
fi