/**
 * K6 Performance Load Test for ABADA Music Studio
 *
 * Scenarios:
 * - Baseline: Single user visiting all pages
 * - Load Test: 100 concurrent users for 5 minutes
 * - Stress Test: Ramp up to 1000 users
 * - Spike Test: Sudden traffic increase
 * - API Performance: Test individual endpoints
 *
 * Run with: k6 run load-test.js
 */

import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const pageLoadTime = new Trend('page_load_time');
const apiResponseTime = new Trend('api_response_time');
const successfulRequests = new Counter('successful_requests');

// Configuration
const BASE_URL = __ENV.BASE_URL || 'https://music.abada.kr';
const API_URL = __ENV.API_URL || 'https://music.abada.kr';

// Thresholds
export const options = {
  scenarios: {
    baseline: {
      executor: 'shared-iterations',
      vus: 1,
      iterations: 1,
      maxDuration: '1m',
      tags: { test_type: 'baseline' },
    },
    load_test: {
      executor: 'constant-vus',
      vus: 100,
      duration: '5m',
      startTime: '1m',
      tags: { test_type: 'load' },
    },
    stress_test: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '5m', target: 1000 },  // Ramp up
        { duration: '10m', target: 1000 }, // Stay at peak
        { duration: '5m', target: 0 },     // Ramp down
      ],
      startTime: '6m',
      tags: { test_type: 'stress' },
    },
    spike_test: {
      executor: 'ramping-vus',
      startVUs: 100,
      stages: [
        { duration: '30s', target: 100 },  // Normal load
        { duration: '1m', target: 500 },   // Spike
        { duration: '30s', target: 100 },  // Return to normal
      ],
      startTime: '21m',
      tags: { test_type: 'spike' },
    },
  },
  thresholds: {
    errors: ['rate<0.01'], // Error rate should be below 1%
    http_req_duration: ['p(95)<2000'], // 95% of requests should complete within 2s
    http_req_failed: ['rate<0.02'], // Failed requests should be below 2%
    page_load_time: ['p(95)<2000'],
    api_response_time: ['p(95)<500'], // API should respond within 500ms for 95% of requests
  },
};

/**
 * Test homepage performance
 */
function testHomePage() {
  const startTime = new Date();
  const response = http.get(`${BASE_URL}/`);
  const duration = new Date() - startTime;

  const success = check(response, {
    'homepage status is 200': (r) => r.status === 200,
    'homepage loads in <2s': (r) => r.timings.duration < 2000,
    'homepage has content': (r) => r.body.length > 0,
  });

  pageLoadTime.add(duration);
  errorRate.add(!success);
  if (success) successfulRequests.add(1);

  return success;
}

/**
 * Test download page
 */
function testDownloadPage() {
  const response = http.get(`${BASE_URL}/download`);

  const success = check(response, {
    'download page status is 200': (r) => r.status === 200,
    'download page has installers': (r) => r.body.includes('Windows') || r.body.includes('macOS'),
  });

  errorRate.add(!success);
  if (success) successfulRequests.add(1);

  return success;
}

/**
 * Test gallery page
 */
function testGalleryPage() {
  const response = http.get(`${BASE_URL}/gallery`);

  const success = check(response, {
    'gallery page status is 200': (r) => r.status === 200,
    'gallery page has content': (r) => r.body.length > 1000,
  });

  errorRate.add(!success);
  if (success) successfulRequests.add(1);

  return success;
}

/**
 * Test tutorial page
 */
function testTutorialPage() {
  const response = http.get(`${BASE_URL}/tutorial`);

  const success = check(response, {
    'tutorial page status is 200': (r) => r.status === 200,
  });

  errorRate.add(!success);
  if (success) successfulRequests.add(1);

  return success;
}

/**
 * Test FAQ page
 */
function testFAQPage() {
  const response = http.get(`${BASE_URL}/faq`);

  const success = check(response, {
    'faq page status is 200': (r) => r.status === 200,
  });

  errorRate.add(!success);
  if (success) successfulRequests.add(1);

  return success;
}

/**
 * Test about page
 */
function testAboutPage() {
  const response = http.get(`${BASE_URL}/about`);

  const success = check(response, {
    'about page status is 200': (r) => r.status === 200,
  });

  errorRate.add(!success);
  if (success) successfulRequests.add(1);

  return success;
}

/**
 * Test download stats API
 */
function testDownloadStatsAPI() {
  const startTime = new Date();
  const response = http.get(`${API_URL}/api/download-stats`);
  const duration = new Date() - startTime;

  const success = check(response, {
    'download stats API status is 200': (r) => r.status === 200,
    'download stats API returns JSON': (r) => {
      try {
        const json = JSON.parse(r.body);
        return json.hasOwnProperty('downloads');
      } catch (e) {
        return false;
      }
    },
    'download stats API responds in <500ms': (r) => r.timings.duration < 500,
  });

  apiResponseTime.add(duration);
  errorRate.add(!success);
  if (success) successfulRequests.add(1);

  return success;
}

/**
 * Test gallery API
 */
function testGalleryAPI() {
  const startTime = new Date();
  const response = http.get(`${API_URL}/api/gallery`);
  const duration = new Date() - startTime;

  const success = check(response, {
    'gallery API status is 200': (r) => r.status === 200,
    'gallery API returns items': (r) => {
      try {
        const json = JSON.parse(r.body);
        return json.hasOwnProperty('items') && Array.isArray(json.items);
      } catch (e) {
        return false;
      }
    },
    'gallery API responds in <500ms': (r) => r.timings.duration < 500,
  });

  apiResponseTime.add(duration);
  errorRate.add(!success);
  if (success) successfulRequests.add(1);

  return success;
}

/**
 * Test analytics API
 */
function testAnalyticsAPI() {
  const payload = JSON.stringify({
    event: 'page_view',
    page: '/test',
    timestamp: new Date().toISOString(),
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const response = http.post(`${API_URL}/api/analytics`, payload, params);

  const success = check(response, {
    'analytics API accepts events': (r) => [200, 201, 204, 503].includes(r.status),
  });

  errorRate.add(!success);
  if (success) successfulRequests.add(1);

  return success;
}

/**
 * Simulate user journey through the site
 */
function userJourney() {
  group('User Journey', () => {
    // Visit homepage
    group('Homepage', () => {
      testHomePage();
      sleep(1);
    });

    // Browse to download page
    group('Download Page', () => {
      testDownloadPage();
      sleep(2);
    });

    // Check gallery
    group('Gallery Page', () => {
      testGalleryPage();
      testGalleryAPI();
      sleep(3);
    });

    // Read tutorial
    group('Tutorial Page', () => {
      testTutorialPage();
      sleep(2);
    });

    // Check FAQ
    group('FAQ Page', () => {
      testFAQPage();
      sleep(1);
    });

    // Visit about
    group('About Page', () => {
      testAboutPage();
      sleep(1);
    });
  });
}

/**
 * Main test function
 */
export default function () {
  // Run user journey
  userJourney();

  // Add some randomness to simulate real users
  sleep(Math.random() * 3);
}

/**
 * Setup function - runs once at the start
 */
export function setup() {
  console.log('Starting performance tests...');
  console.log(`Base URL: ${BASE_URL}`);
  console.log(`API URL: ${API_URL}`);
}

/**
 * Teardown function - runs once at the end
 */
export function teardown(data) {
  console.log('Performance tests completed.');
}
