/**
 * K6 API Performance Test
 *
 * Focused testing of API endpoints for detailed performance metrics
 *
 * Run with: k6 run api-test.js
 */

import http from 'k6/http';
import { check, group } from 'k6';
import { Trend } from 'k6/metrics';

// Custom metrics for each endpoint
const downloadStatsLatency = new Trend('download_stats_latency');
const galleryLatency = new Trend('gallery_latency');
const analyticsLatency = new Trend('analytics_latency');

const API_URL = __ENV.API_URL || 'https://music.abada.kr';

export const options = {
  stages: [
    { duration: '30s', target: 50 },   // Ramp up to 50 users
    { duration: '2m', target: 100 },   // Increase to 100 users
    { duration: '1m', target: 100 },   // Stay at 100 users
    { duration: '30s', target: 0 },    // Ramp down
  ],
  thresholds: {
    'http_req_duration{endpoint:download_stats}': ['p(95)<200'],
    'http_req_duration{endpoint:gallery}': ['p(95)<200'],
    'http_req_duration{endpoint:analytics}': ['p(95)<200'],
    download_stats_latency: ['p(50)<100', 'p(95)<200', 'p(99)<500'],
    gallery_latency: ['p(50)<100', 'p(95)<200', 'p(99)<500'],
    analytics_latency: ['p(50)<100', 'p(95)<200', 'p(99)<500'],
  },
};

/**
 * Test download stats endpoint with various parameters
 */
function testDownloadStats() {
  group('Download Stats API', () => {
    // Test default (all stats)
    const r1 = http.get(`${API_URL}/api/download-stats`, {
      tags: { endpoint: 'download_stats' },
    });
    check(r1, {
      'download stats default succeeds': (r) => r.status === 200,
    });
    downloadStatsLatency.add(r1.timings.duration);

    // Test with period filter
    const r2 = http.get(`${API_URL}/api/download-stats?period=week`, {
      tags: { endpoint: 'download_stats' },
    });
    check(r2, {
      'download stats with period succeeds': (r) => r.status === 200,
    });
    downloadStatsLatency.add(r2.timings.duration);

    // Test with OS filter
    const r3 = http.get(`${API_URL}/api/download-stats?os=windows-x64`, {
      tags: { endpoint: 'download_stats' },
    });
    check(r3, {
      'download stats with OS succeeds': (r) => r.status === 200,
    });
    downloadStatsLatency.add(r3.timings.duration);
  });
}

/**
 * Test gallery endpoint with various filters
 */
function testGallery() {
  group('Gallery API', () => {
    // Test default
    const r1 = http.get(`${API_URL}/api/gallery`, {
      tags: { endpoint: 'gallery' },
    });
    check(r1, {
      'gallery default succeeds': (r) => r.status === 200,
      'gallery returns items': (r) => {
        try {
          const json = JSON.parse(r.body);
          return Array.isArray(json.items);
        } catch (e) {
          return false;
        }
      },
    });
    galleryLatency.add(r1.timings.duration);

    // Test with pagination
    const r2 = http.get(`${API_URL}/api/gallery?limit=10&offset=0`, {
      tags: { endpoint: 'gallery' },
    });
    check(r2, {
      'gallery pagination succeeds': (r) => r.status === 200,
    });
    galleryLatency.add(r2.timings.duration);

    // Test with tag filter
    const r3 = http.get(`${API_URL}/api/gallery?tag=pop`, {
      tags: { endpoint: 'gallery' },
    });
    check(r3, {
      'gallery tag filter succeeds': (r) => r.status === 200,
    });
    galleryLatency.add(r3.timings.duration);

    // Test featured items
    const r4 = http.get(`${API_URL}/api/gallery?featured=true`, {
      tags: { endpoint: 'gallery' },
    });
    check(r4, {
      'gallery featured filter succeeds': (r) => r.status === 200,
    });
    galleryLatency.add(r4.timings.duration);
  });
}

/**
 * Test analytics endpoint
 */
function testAnalytics() {
  group('Analytics API', () => {
    const events = [
      { event: 'page_view', page: '/' },
      { event: 'download_click', os: 'windows-x64' },
      { event: 'gallery_filter', tag: 'pop' },
    ];

    events.forEach((event) => {
      const payload = JSON.stringify({
        ...event,
        timestamp: new Date().toISOString(),
      });

      const response = http.post(`${API_URL}/api/analytics`, payload, {
        headers: { 'Content-Type': 'application/json' },
        tags: { endpoint: 'analytics' },
      });

      check(response, {
        'analytics event accepted': (r) => [200, 201, 204, 503].includes(r.status),
      });

      analyticsLatency.add(response.timings.duration);
    });
  });
}

/**
 * Test concurrent API calls
 */
function testConcurrentCalls() {
  group('Concurrent API Calls', () => {
    const requests = {
      stats: {
        method: 'GET',
        url: `${API_URL}/api/download-stats`,
      },
      gallery: {
        method: 'GET',
        url: `${API_URL}/api/gallery`,
      },
    };

    const responses = http.batch(requests);

    check(responses.stats, {
      'concurrent stats request succeeds': (r) => r.status === 200,
    });

    check(responses.gallery, {
      'concurrent gallery request succeeds': (r) => r.status === 200,
    });
  });
}

/**
 * Main test function
 */
export default function () {
  testDownloadStats();
  testGallery();
  testAnalytics();
  testConcurrentCalls();
}
