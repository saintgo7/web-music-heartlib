# Test Suite

Comprehensive testing suite for ABADA Music Studio.

## Structure

```
tests/
├── performance/          # k6 performance tests
│   ├── load-test.js     # Load, stress, and spike tests
│   └── api-test.js      # API-focused performance tests
├── fixtures/            # Test data and fixtures (in web/tests/)
├── report-generator.js  # Test report aggregator
└── README.md           # This file
```

## Quick Start

```bash
# Run all tests
./scripts/test-all.sh

# Run E2E tests only
cd web && npm run test:e2e

# Run performance tests only
k6 run tests/performance/load-test.js
```

## Test Categories

### 1. E2E Tests (48 tests)

Located in `/web/tests/e2e/`

- HomePage: 8 tests
- DownloadPage: 6 tests
- TutorialPage: 6 tests
- GalleryPage: 6 tests
- FAQPage: 5 tests
- AboutPage: 4 tests
- Navigation: 5 tests
- API Integration: 8 tests

### 2. Performance Tests

Located in `/tests/performance/`

- Load Test: 100 concurrent users
- Stress Test: Ramp to 1000 users
- Spike Test: Sudden traffic changes
- API Performance: Endpoint-specific testing

## Running Tests

### Local Development

```bash
# E2E tests
npm run test:e2e                    # All browsers
npm run test:e2e:ui                 # Interactive mode
npm run test:e2e:debug              # Debug mode
npm run test:e2e:chromium           # Chromium only
npm run test:e2e:mobile             # Mobile browsers

# Performance tests
k6 run tests/performance/load-test.js
k6 run tests/performance/api-test.js

# Generate report
node tests/report-generator.js
```

### CI/CD

Tests run automatically on:
- Push to main (web/** or functions/**)
- Pull requests
- Daily schedule (2 AM UTC)
- Manual trigger

## Test Data

Test fixtures located in `/web/tests/fixtures/test-data.json`

Contains:
- Sample gallery items
- Download statistics
- Analytics events
- Error scenarios

## Thresholds

| Metric | Target | Alert |
|--------|--------|-------|
| E2E Pass Rate | > 98% | < 95% |
| Page Load p95 | < 2s | > 3s |
| API Response p95 | < 200ms | > 500ms |
| Error Rate | < 1% | > 2% |

## Documentation

See `/docs/TESTING_GUIDE.md` for comprehensive documentation.

## Troubleshooting

### Playwright not found

```bash
cd web
npm run test:install
```

### k6 not installed

```bash
# macOS
brew install k6

# Ubuntu
sudo apt-get install k6

# See: https://k6.io/docs/getting-started/installation/
```

### Tests failing locally

1. Ensure dev server is running: `npm run dev`
2. Check Playwright browsers are installed
3. Review test output and screenshots
4. Run in debug mode: `npm run test:e2e:debug`

## Contributing

When adding new tests:

1. Follow existing patterns
2. Use descriptive test names
3. Ensure tests are atomic and independent
4. Add to appropriate test file
5. Update documentation if needed

## License

CC BY-NC 4.0
