# ABADA Music Studio - Testing Guide

Complete guide for running, writing, and maintaining tests for the ABADA Music Studio project.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Test Types](#test-types)
- [Running Tests Locally](#running-tests-locally)
- [Writing New Tests](#writing-new-tests)
- [Interpreting Results](#interpreting-results)
- [Debugging Failed Tests](#debugging-failed-tests)
- [CI/CD Integration](#cicd-integration)
- [Performance Benchmarks](#performance-benchmarks)
- [Known Issues](#known-issues)

---

## Overview

The ABADA Music Studio project uses a comprehensive testing strategy covering:

- **E2E Tests**: 48+ tests using Playwright
- **Performance Tests**: Load, stress, and API tests using k6
- **Accessibility Tests**: Automated accessibility checking
- **Visual Regression**: Screenshot comparison (optional)

### Test Metrics & Thresholds

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| E2E Pass Rate | > 98% | < 95% |
| Page Load (p95) | < 2s | > 3s |
| API Response (p95) | < 200ms | > 500ms |
| Error Rate | < 1% | > 2% |
| Lighthouse Score | > 90 | < 80 |

---

## Quick Start

### Prerequisites

```bash
# Node.js 18+ required
node --version

# k6 for performance tests
brew install k6  # macOS
# OR
sudo apt-get install k6  # Ubuntu
```

### Run All Tests

```bash
# Run comprehensive test suite
./scripts/test-all.sh

# Run only E2E tests
./scripts/test-all.sh --e2e-only

# Run only performance tests
./scripts/test-all.sh --perf-only

# CI mode (headless, no browser)
./scripts/test-all.sh --ci
```

---

## Test Types

### 1. E2E Tests (Playwright)

Located in `/web/tests/e2e/`

**Test Files:**
- `home.spec.ts` - Homepage tests (8 tests)
- `download.spec.ts` - Download page tests (6 tests)
- `tutorial.spec.ts` - Tutorial page tests (6 tests)
- `gallery.spec.ts` - Gallery page tests (6 tests)
- `faq.spec.ts` - FAQ page tests (5 tests)
- `about.spec.ts` - About page tests (4 tests)
- `navigation.spec.ts` - Navigation tests (5 tests)
- `api.spec.ts` - API integration tests (8 tests)

**Total: 48 test cases**

### 2. Performance Tests (k6)

Located in `/tests/performance/`

**Test Files:**
- `load-test.js` - Comprehensive load, stress, and spike tests
- `api-test.js` - Focused API endpoint performance testing

**Scenarios:**
- Baseline: Single user journey
- Load Test: 100 concurrent users for 5 minutes
- Stress Test: Ramp to 1000 users
- Spike Test: Sudden traffic increase
- API Performance: Individual endpoint testing

### 3. Accessibility Tests

Integrated with Playwright using @axe-core/playwright

Tests WCAG 2.1 Level AA compliance.

---

## Running Tests Locally

### E2E Tests

```bash
cd web

# Install dependencies (first time only)
npm ci

# Install Playwright browsers (first time only)
npx playwright install --with-deps

# Run all E2E tests
npm run test:e2e

# Run specific test file
npx playwright test tests/e2e/home.spec.ts

# Run tests in UI mode (interactive)
npx playwright test --ui

# Run tests with specific browser
npx playwright test --project=chromium
npx playwright test --project=firefox
npx playwright test --project=webkit

# Run mobile tests
npx playwright test --project="Mobile Chrome"
npx playwright test --project="Mobile Safari"

# Debug mode
npx playwright test --debug

# Show HTML report
npx playwright show-report
```

### Performance Tests

```bash
# Run load test
k6 run tests/performance/load-test.js

# Run API test
k6 run tests/performance/api-test.js

# Run with custom base URL
k6 run tests/performance/load-test.js \
  -e BASE_URL=http://localhost:5173 \
  -e API_URL=http://localhost:8787

# Run with custom parameters
k6 run tests/performance/load-test.js \
  --vus 50 \
  --duration 2m

# Generate HTML report
k6 run tests/performance/load-test.js \
  --out json=results.json

# Then use k6 cloud for visualization
# or process JSON with custom tools
```

---

## Writing New Tests

### E2E Test Template

```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature Name Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to page before each test
    await page.goto('/your-page');
  });

  test('should do something specific', async ({ page }) => {
    // Arrange
    const element = page.locator('selector');

    // Act
    await element.click();

    // Assert
    await expect(element).toHaveText('Expected Text');
  });

  test('should handle edge case', async ({ page }) => {
    // Test edge cases and error scenarios
  });
});
```

### Performance Test Template

```javascript
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 10,
  duration: '30s',
  thresholds: {
    'http_req_duration': ['p(95)<500'],
  },
};

export default function () {
  const response = http.get('https://music.abada.kr/');

  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
}
```

### Best Practices

1. **Atomic Tests**: Each test should be independent
2. **Descriptive Names**: Use clear, descriptive test names
3. **Arrange-Act-Assert**: Follow AAA pattern
4. **Wait Strategies**: Use Playwright's auto-waiting
5. **Selectors**: Prefer data-testid, role, or text selectors
6. **Cleanup**: Ensure tests clean up after themselves

---

## Interpreting Results

### E2E Test Results

**Playwright HTML Report:**
- Green: Passed tests
- Red: Failed tests
- Yellow: Flaky tests (passed on retry)

**Key Metrics:**
- Total tests run
- Pass/fail rate
- Execution time
- Screenshots on failure
- Video recordings

### Performance Test Results

**k6 Output:**

```
checks.........................: 100.00% ✓ 1234 ✗ 0
http_req_duration..............: avg=125ms  p(95)=250ms
http_req_failed................: 0.00%   ✓ 0    ✗ 1234
iterations.....................: 1234
vus............................: 100
```

**Key Metrics:**
- `http_req_duration`: Response time (avg, p50, p95, p99)
- `http_req_failed`: Error rate
- `checks`: Assertion pass rate
- `iterations`: Total requests completed

**Interpreting Thresholds:**
- Green: All thresholds passed
- Red: One or more thresholds failed

---

## Debugging Failed Tests

### E2E Test Failures

**1. Check Screenshots**

Failed tests automatically capture screenshots:

```bash
open web/test-results/<test-name>/test-failed-1.png
```

**2. Watch Video Recording**

```bash
open web/test-results/<test-name>/video.webm
```

**3. Enable Trace**

Traces capture detailed execution steps:

```bash
npx playwright test --trace on

# View trace
npx playwright show-trace web/test-results/<test-name>/trace.zip
```

**4. Run in Debug Mode**

```bash
npx playwright test --debug tests/e2e/home.spec.ts
```

This opens Playwright Inspector for step-by-step debugging.

**5. Check Console Logs**

Tests capture console errors. Check test output for:
- JavaScript errors
- Network failures
- API errors

### Performance Test Failures

**Common Issues:**

1. **Threshold Exceeded**
   - Check which metric failed
   - Review server logs for bottlenecks
   - Verify network connectivity

2. **High Error Rate**
   - Check API responses
   - Verify endpoint availability
   - Review CORS configuration

3. **Timeout Errors**
   - Increase timeout settings
   - Check server capacity
   - Verify database performance

**Debug Commands:**

```bash
# Increase verbosity
k6 run --http-debug tests/performance/load-test.js

# Run with fewer VUs for debugging
k6 run tests/performance/load-test.js --vus 1 --iterations 1
```

---

## CI/CD Integration

### GitHub Actions Workflow

Tests run automatically on:
- Push to main branch (web/** or functions/**)
- Pull requests to main
- Daily schedule (2 AM UTC)
- Manual trigger (workflow_dispatch)

**Workflow Jobs:**
1. **E2E Tests**: Run across chromium, firefox, webkit
2. **Accessibility Tests**: WCAG 2.1 AA compliance
3. **Performance Baseline**: k6 load tests
4. **Lighthouse**: Performance scoring
5. **Test Summary**: Aggregate results

### Viewing CI Results

1. Go to **Actions** tab in GitHub
2. Click on workflow run
3. Review job status
4. Download artifacts for detailed reports

### Artifacts

- Playwright HTML reports
- Screenshots and videos
- Performance JSON data
- Lighthouse reports

---

## Performance Benchmarks

### Expected Performance

**Page Load Times (p95):**
- Homepage: < 1.5s
- Download: < 1.8s
- Gallery: < 2.0s
- Tutorial: < 1.8s
- FAQ: < 1.5s
- About: < 1.2s

**API Response Times (p95):**
- Download Stats: < 150ms
- Gallery: < 200ms
- Analytics: < 100ms

**Lighthouse Scores:**
- Performance: > 90
- Accessibility: > 95
- Best Practices: > 90
- SEO: > 95

### Baseline Metrics

Run baseline tests to establish performance metrics:

```bash
./scripts/test-all.sh --perf-only
```

Compare new results against baseline to detect regressions.

---

## Known Issues and Workarounds

### Issue 1: Flaky Network Tests

**Symptom:** API tests occasionally fail with timeout errors

**Workaround:**
```typescript
// Add retry logic for network-dependent tests
test.describe.configure({ retries: 2 });
```

### Issue 2: Mobile Safari Rendering

**Symptom:** Some CSS animations cause test failures on Mobile Safari

**Workaround:**
```typescript
// Disable animations for testing
await page.addInitScript(() => {
  document.documentElement.style.cssText = `
    *, *::before, *::after {
      animation-duration: 0s !important;
      transition-duration: 0s !important;
    }
  `;
});
```

### Issue 3: k6 Installation on CI

**Symptom:** k6 not found in CI environment

**Solution:** Use setup script in workflow (already implemented)

### Issue 4: Cloudflare KV Delays

**Symptom:** Gallery tests fail intermittently due to KV propagation

**Workaround:** Add wait time or poll until data is available:

```typescript
await page.waitForResponse(
  (response) => response.url().includes('/api/gallery') && response.status() === 200,
  { timeout: 10000 }
);
```

---

## Test Maintenance

### Regular Tasks

**Weekly:**
- Review test results
- Update flaky tests
- Check performance trends

**Monthly:**
- Update dependencies
- Review test coverage
- Optimize slow tests

**Quarterly:**
- Audit test relevance
- Update test data
- Review performance baselines

### Updating Tests

When adding new features:

1. Write tests first (TDD)
2. Ensure tests pass locally
3. Submit PR with tests included
4. Verify CI passes
5. Update documentation

### Test Coverage Goals

- E2E: Cover all user flows
- API: Test all endpoints
- Performance: Baseline all pages
- Accessibility: WCAG 2.1 AA compliance

---

## Useful Commands Cheat Sheet

```bash
# E2E Tests
npm run test:e2e                    # Run all E2E tests
npx playwright test --ui            # Interactive mode
npx playwright test --debug         # Debug mode
npx playwright show-report          # View report

# Performance Tests
k6 run tests/performance/load-test.js   # Load test
k6 run tests/performance/api-test.js    # API test

# Comprehensive
./scripts/test-all.sh               # All tests
./scripts/test-all.sh --e2e-only    # E2E only
./scripts/test-all.sh --ci          # CI mode

# Development
npm run dev                         # Start dev server
npm run build                       # Build for production
npm run preview                     # Preview production build
```

---

## Getting Help

- Check test output and error messages
- Review screenshots and videos
- Search GitHub issues
- Check Playwright docs: https://playwright.dev
- Check k6 docs: https://k6.io/docs

---

## Contributing

When contributing tests:

1. Follow existing test patterns
2. Write descriptive test names
3. Add comments for complex logic
4. Ensure tests pass locally
5. Update this guide if needed

---

Last Updated: 2026-01-19
Version: 1.0.0
