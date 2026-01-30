#!/bin/bash
# Local test script for suins-contracts
# Runs formatting checks and Move tests before pushing

set -e

echo "🧪 Running local checks for suins-contracts"
echo "============================================"
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
if npx prettier-move -c suins/sources/*.move suins/tests/*.move 2>&1; then
    echo -e "${GREEN}✅ Formatting check passed!${NC}"
else
    echo -e "${RED}❌ Formatting check failed!${NC}"
    echo "Run: cd packages && npx prettier-move --write suins/sources/*.move suins/tests/*.move"
    exit 1
fi
echo ""

echo "🧪 Step 2: Running Move tests..."
echo "---------------------------------"
cd ..
TEST_OUTPUT=$(sui move test --path packages/suins 2>&1) || true
echo "$TEST_OUTPUT" | tail -20
echo ""
if echo "$TEST_OUTPUT" | grep -q "Test result: OK"; then
    echo -e "${GREEN}✅ Tests passed!${NC}"
else
    echo -e "${RED}❌ Tests failed!${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}✨ All checks passed!${NC}"
echo ""
echo "To fix formatting issues, run:"
echo "  cd packages && npx prettier-move --write suins/sources/*.move suins/tests/*.move"
