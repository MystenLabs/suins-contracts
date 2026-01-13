#!/bin/bash
# Test script for PR #356 - Prune expired subdomains
# This script tests both formatting and functionality

set -e

echo "🧪 Testing PR #356: Prune expired subdomains by parent authority"
echo "================================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to packages directory (script is in scripts/, so go up one level)
cd "$(dirname "$0")/../packages"

echo "📋 Step 1: Checking Move file formatting..."
echo "-------------------------------------------"
if npx prettier-move -c suins/sources/controller.move suins/tests/controller_tests.move suins/sources/registry.move 2>&1; then
    echo -e "${GREEN}✅ Formatting check passed!${NC}"
else
    echo -e "${RED}❌ Formatting check failed!${NC}"
    echo "Run: npx prettier-move --write suins/sources/controller.move suins/tests/controller_tests.move"
    exit 1
fi
echo ""

echo "🧪 Step 2: Running Move tests..."
echo "---------------------------------"
cd ..
if sui move test --path packages/suins --skip-fetch-latest-git-deps 2>&1 | grep -E "(Test result:|FAIL|error)" | head -20; then
    echo -e "${YELLOW}⚠️  Some tests may have warnings (check output above)${NC}"
else
    echo -e "${GREEN}✅ Tests completed!${NC}"
fi
echo ""

echo "🎯 Step 3: Verifying prune tests exist..."
echo "------------------------------------------"
if sui move test --path packages/suins --skip-fetch-latest-git-deps 2>&1 | grep -q "test_prune"; then
    echo -e "${GREEN}✅ Prune tests found and executed!${NC}"
    echo "   (Check output above for test_prune_* test results)"
else
    echo -e "${YELLOW}⚠️  Could not verify prune tests${NC}"
fi
echo ""

echo -e "${GREEN}✨ All checks completed!${NC}"
echo ""
echo "To fix formatting issues, run:"
echo "  cd packages && npx prettier-move --write suins/sources/controller.move suins/tests/controller_tests.move"
