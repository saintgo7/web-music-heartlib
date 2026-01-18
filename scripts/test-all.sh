#!/bin/bash

###############################################################################
# Comprehensive Test Runner for ABADA Music Studio
#
# Runs all test suites and generates comprehensive reports
#
# Usage:
#   ./scripts/test-all.sh [options]
#
# Options:
#   --e2e-only      Run only E2E tests
#   --perf-only     Run only performance tests
#   --no-report     Skip report generation
#   --ci            Run in CI mode (headless, no browser open)
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_DIR="${PROJECT_ROOT}/web"
TEST_DIR="${PROJECT_ROOT}/tests"
REPORT_DIR="${PROJECT_ROOT}/test-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Parse arguments
RUN_E2E=true
RUN_PERF=true
GENERATE_REPORT=true
CI_MODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --e2e-only)
      RUN_PERF=false
      shift
      ;;
    --perf-only)
      RUN_E2E=false
      shift
      ;;
    --no-report)
      GENERATE_REPORT=false
      shift
      ;;
    --ci)
      CI_MODE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Create report directory
mkdir -p "${REPORT_DIR}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ABADA Music Studio - Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

###############################################################################
# Run E2E Tests
###############################################################################

if [ "$RUN_E2E" = true ]; then
  echo -e "${YELLOW}Running E2E Tests...${NC}"
  echo ""

  cd "${WEB_DIR}"

  # Install dependencies if needed
  if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    npm ci
  fi

  # Install Playwright browsers
  if [ ! -d "node_modules/@playwright/test" ]; then
    echo -e "${YELLOW}Installing Playwright...${NC}"
    npx playwright install --with-deps
  fi

  # Run tests
  if [ "$CI_MODE" = true ]; then
    npx playwright test --reporter=html,json,junit
  else
    npx playwright test --reporter=html,list
  fi

  E2E_EXIT_CODE=$?

  if [ $E2E_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}E2E Tests: PASSED${NC}"
  else
    echo -e "${RED}E2E Tests: FAILED${NC}"
  fi

  # Copy results to report directory
  if [ -d "playwright-report" ]; then
    cp -r playwright-report "${REPORT_DIR}/playwright-report-${TIMESTAMP}"
  fi

  if [ -d "test-results" ]; then
    cp -r test-results "${REPORT_DIR}/e2e-results-${TIMESTAMP}"
  fi

  echo ""
fi

###############################################################################
# Run Performance Tests
###############################################################################

if [ "$RUN_PERF" = true ]; then
  echo -e "${YELLOW}Running Performance Tests...${NC}"
  echo ""

  cd "${PROJECT_ROOT}"

  # Check if k6 is installed
  if ! command -v k6 &> /dev/null; then
    echo -e "${RED}k6 is not installed. Please install k6 to run performance tests.${NC}"
    echo -e "${YELLOW}Install instructions: https://k6.io/docs/getting-started/installation/${NC}"
    PERF_EXIT_CODE=1
  else
    # Run load test
    echo -e "${BLUE}Running load test...${NC}"
    k6 run tests/performance/load-test.js \
      --out json="${REPORT_DIR}/load-test-${TIMESTAMP}.json" \
      --summary-export="${REPORT_DIR}/load-test-summary-${TIMESTAMP}.json" \
      || PERF_EXIT_CODE=$?

    # Run API test
    echo -e "${BLUE}Running API performance test...${NC}"
    k6 run tests/performance/api-test.js \
      --out json="${REPORT_DIR}/api-test-${TIMESTAMP}.json" \
      --summary-export="${REPORT_DIR}/api-test-summary-${TIMESTAMP}.json" \
      || PERF_EXIT_CODE=$?

    if [ $PERF_EXIT_CODE -eq 0 ]; then
      echo -e "${GREEN}Performance Tests: PASSED${NC}"
    else
      echo -e "${RED}Performance Tests: FAILED${NC}"
    fi
  fi

  echo ""
fi

###############################################################################
# Generate Report
###############################################################################

if [ "$GENERATE_REPORT" = true ]; then
  echo -e "${YELLOW}Generating comprehensive report...${NC}"
  echo ""

  REPORT_HTML="${REPORT_DIR}/test-report-${TIMESTAMP}.html"

  cat > "${REPORT_HTML}" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Test Report - ${TIMESTAMP}</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
      background: #f5f5f5;
    }
    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 30px;
      border-radius: 10px;
      margin-bottom: 30px;
    }
    .section {
      background: white;
      padding: 20px;
      margin-bottom: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .status {
      display: inline-block;
      padding: 5px 15px;
      border-radius: 20px;
      font-weight: bold;
      margin-left: 10px;
    }
    .passed { background: #10b981; color: white; }
    .failed { background: #ef4444; color: white; }
    .skipped { background: #f59e0b; color: white; }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 15px;
    }
    th, td {
      padding: 12px;
      text-align: left;
      border-bottom: 1px solid #ddd;
    }
    th {
      background: #f8f9fa;
      font-weight: 600;
    }
    .metric {
      display: flex;
      justify-content: space-between;
      padding: 10px 0;
      border-bottom: 1px solid #eee;
    }
    .metric-value {
      font-weight: bold;
      color: #667eea;
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>ABADA Music Studio - Test Report</h1>
    <p>Generated: ${TIMESTAMP}</p>
  </div>

  <div class="section">
    <h2>Test Summary</h2>
    <div class="metric">
      <span>E2E Tests</span>
      <span class="status ${E2E_EXIT_CODE:-1 -eq 0 && echo 'passed' || echo 'failed'}">${E2E_EXIT_CODE:-1 -eq 0 && echo 'PASSED' || echo 'FAILED'}</span>
    </div>
    <div class="metric">
      <span>Performance Tests</span>
      <span class="status ${PERF_EXIT_CODE:-1 -eq 0 && echo 'passed' || echo 'failed'}">${PERF_EXIT_CODE:-1 -eq 0 && echo 'PASSED' || echo 'FAILED'}</span>
    </div>
  </div>

  <div class="section">
    <h2>E2E Test Results</h2>
    <p>Detailed E2E test results available in: <code>playwright-report-${TIMESTAMP}</code></p>
    <a href="playwright-report-${TIMESTAMP}/index.html">View Playwright Report</a>
  </div>

  <div class="section">
    <h2>Performance Test Results</h2>
    <p>Performance test data available in:</p>
    <ul>
      <li>Load Test: <code>load-test-${TIMESTAMP}.json</code></li>
      <li>API Test: <code>api-test-${TIMESTAMP}.json</code></li>
    </ul>
  </div>

  <div class="section">
    <h2>Test Artifacts</h2>
    <ul>
      <li>Screenshots: <code>e2e-results-${TIMESTAMP}</code></li>
      <li>Videos: <code>e2e-results-${TIMESTAMP}</code></li>
      <li>Performance Data: <code>test-reports/</code></li>
    </ul>
  </div>
</body>
</html>
EOF

  echo -e "${GREEN}Report generated: ${REPORT_HTML}${NC}"

  # Open report in browser (unless in CI mode)
  if [ "$CI_MODE" = false ] && command -v open &> /dev/null; then
    echo -e "${BLUE}Opening report in browser...${NC}"
    open "${REPORT_HTML}"
  fi

  echo ""
fi

###############################################################################
# Final Summary
###############################################################################

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test Run Complete${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

OVERALL_EXIT_CODE=0

if [ "$RUN_E2E" = true ] && [ ${E2E_EXIT_CODE:-1} -ne 0 ]; then
  OVERALL_EXIT_CODE=1
fi

if [ "$RUN_PERF" = true ] && [ ${PERF_EXIT_CODE:-1} -ne 0 ]; then
  OVERALL_EXIT_CODE=1
fi

if [ $OVERALL_EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}All tests PASSED${NC}"
else
  echo -e "${RED}Some tests FAILED${NC}"
fi

echo ""
echo -e "Reports saved to: ${YELLOW}${REPORT_DIR}${NC}"
echo ""

exit $OVERALL_EXIT_CODE
