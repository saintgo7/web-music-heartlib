#!/bin/bash

###############################################################################
# Test Setup Verification Script
#
# Verifies that all test dependencies and configurations are properly set up
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test Setup Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

ERRORS=0

# Check Node.js version
echo -e "${YELLOW}Checking Node.js version...${NC}"
if command -v node &> /dev/null; then
  NODE_VERSION=$(node --version)
  echo -e "${GREEN}Node.js installed: ${NODE_VERSION}${NC}"
else
  echo -e "${RED}Node.js not found${NC}"
  ((ERRORS++))
fi
echo ""

# Check npm
echo -e "${YELLOW}Checking npm...${NC}"
if command -v npm &> /dev/null; then
  NPM_VERSION=$(npm --version)
  echo -e "${GREEN}npm installed: ${NPM_VERSION}${NC}"
else
  echo -e "${RED}npm not found${NC}"
  ((ERRORS++))
fi
echo ""

# Check k6
echo -e "${YELLOW}Checking k6...${NC}"
if command -v k6 &> /dev/null; then
  K6_VERSION=$(k6 version | head -n1)
  echo -e "${GREEN}k6 installed: ${K6_VERSION}${NC}"
else
  echo -e "${YELLOW}k6 not found (optional for local testing)${NC}"
  echo -e "${YELLOW}Install: https://k6.io/docs/getting-started/installation/${NC}"
fi
echo ""

# Check web dependencies
echo -e "${YELLOW}Checking web dependencies...${NC}"
cd "${PROJECT_ROOT}/web"
if [ -d "node_modules" ]; then
  echo -e "${GREEN}Dependencies installed${NC}"
else
  echo -e "${YELLOW}Dependencies not installed. Run: cd web && npm ci${NC}"
fi
echo ""

# Check Playwright
echo -e "${YELLOW}Checking Playwright...${NC}"
if [ -d "node_modules/@playwright" ]; then
  echo -e "${GREEN}Playwright installed${NC}"
else
  echo -e "${YELLOW}Playwright not installed. Run: cd web && npm run test:install${NC}"
fi
echo ""

# Check test files
echo -e "${YELLOW}Checking test files...${NC}"
cd "${PROJECT_ROOT}"

TEST_FILES=(
  "web/tests/e2e/home.spec.ts"
  "web/tests/e2e/download.spec.ts"
  "web/tests/e2e/tutorial.spec.ts"
  "web/tests/e2e/gallery.spec.ts"
  "web/tests/e2e/faq.spec.ts"
  "web/tests/e2e/about.spec.ts"
  "web/tests/e2e/navigation.spec.ts"
  "web/tests/e2e/api.spec.ts"
  "tests/performance/load-test.js"
  "tests/performance/api-test.js"
)

MISSING_FILES=0
for file in "${TEST_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo -e "${GREEN}✓${NC} $file"
  else
    echo -e "${RED}✗${NC} $file"
    ((MISSING_FILES++))
    ((ERRORS++))
  fi
done
echo ""

if [ $MISSING_FILES -eq 0 ]; then
  echo -e "${GREEN}All test files present${NC}"
else
  echo -e "${RED}$MISSING_FILES test file(s) missing${NC}"
fi
echo ""

# Check configuration files
echo -e "${YELLOW}Checking configuration files...${NC}"

CONFIG_FILES=(
  "web/playwright.config.ts"
  "web/tests/fixtures/test-data.json"
  ".github/workflows/e2e-tests.yml"
  "scripts/test-all.sh"
  "tests/report-generator.js"
  "docs/TESTING_GUIDE.md"
  "docs/TEST_STATUS.md"
)

MISSING_CONFIGS=0
for file in "${CONFIG_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo -e "${GREEN}✓${NC} $file"
  else
    echo -e "${RED}✗${NC} $file"
    ((MISSING_CONFIGS++))
    ((ERRORS++))
  fi
done
echo ""

if [ $MISSING_CONFIGS -eq 0 ]; then
  echo -e "${GREEN}All configuration files present${NC}"
else
  echo -e "${RED}$MISSING_CONFIGS configuration file(s) missing${NC}"
fi
echo ""

# Check package.json scripts
echo -e "${YELLOW}Checking package.json test scripts...${NC}"
cd "${PROJECT_ROOT}/web"

SCRIPTS=(
  "test:e2e"
  "test:e2e:ui"
  "test:e2e:debug"
  "test:report"
)

for script in "${SCRIPTS[@]}"; do
  if grep -q "\"$script\"" package.json; then
    echo -e "${GREEN}✓${NC} $script"
  else
    echo -e "${RED}✗${NC} $script"
    ((ERRORS++))
  fi
done
echo ""

# Final summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Verification Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}All checks passed!${NC}"
  echo ""
  echo -e "${BLUE}You can now run tests:${NC}"
  echo -e "  ./scripts/test-all.sh"
  echo -e "  cd web && npm run test:e2e"
  echo ""
  exit 0
else
  echo -e "${RED}$ERRORS error(s) found${NC}"
  echo ""
  echo -e "${YELLOW}Please fix the issues above before running tests${NC}"
  echo ""
  exit 1
fi
