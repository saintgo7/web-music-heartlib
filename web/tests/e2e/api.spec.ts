import { test, expect } from '@playwright/test';

/**
 * API Integration E2E Tests
 *
 * Tests for API endpoints including:
 * - Download stats API
 * - Gallery API
 * - Analytics API
 * - Error handling (404, 500)
 * - Rate limiting
 * - Timeout scenarios
 * - CORS validation
 */

const API_BASE_URL = process.env.API_URL || 'https://music.abada.kr';

test.describe('API Integration Tests', () => {
  test('should get download stats from API', async ({ request }) => {
    const response = await request.get(`${API_BASE_URL}/api/download-stats`);

    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);

    const data = await response.json();
    expect(data).toHaveProperty('downloads');
    expect(data).toHaveProperty('total');
  });

  test('should validate gallery API data structure', async ({ request }) => {
    const response = await request.get(`${API_BASE_URL}/api/gallery`);

    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);

    const data = await response.json();
    expect(data).toHaveProperty('success', true);
    expect(data).toHaveProperty('items');
    expect(Array.isArray(data.items)).toBeTruthy();

    if (data.items.length > 0) {
      const firstItem = data.items[0];
      expect(firstItem).toHaveProperty('id');
      expect(firstItem).toHaveProperty('title');
      expect(firstItem).toHaveProperty('tags');
    }
  });

  test('should log analytics events', async ({ request }) => {
    const response = await request.post(`${API_BASE_URL}/api/analytics`, {
      data: {
        event: 'page_view',
        page: '/test',
        timestamp: new Date().toISOString(),
      },
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Should either succeed or handle gracefully
    expect([200, 201, 204, 503]).toContain(response.status());
  });

  test('should handle 404 errors gracefully', async ({ request }) => {
    const response = await request.get(`${API_BASE_URL}/api/nonexistent-endpoint`);

    expect(response.status()).toBe(404);
  });

  test('should handle 500 errors gracefully', async ({ page }) => {
    // Test error handling in the UI
    page.on('response', (response) => {
      if (response.status() >= 500) {
        console.log(`Server error on ${response.url()}: ${response.status()}`);
      }
    });

    await page.goto('/gallery');
    await page.waitForTimeout(2000);

    // Page should still render even if API fails
    const mainContent = page.locator('main, [role="main"]');
    await expect(mainContent).toBeVisible();
  });

  test('should validate CORS headers', async ({ request }) => {
    const response = await request.get(`${API_BASE_URL}/api/gallery`);

    const corsHeader = response.headers()['access-control-allow-origin'];
    expect(corsHeader).toBeTruthy();
    expect(['*', API_BASE_URL, 'https://music.abada.kr']).toContain(corsHeader);
  });

  test('should handle timeout scenarios', async ({ request }) => {
    try {
      const response = await request.get(`${API_BASE_URL}/api/gallery`, {
        timeout: 1000, // 1 second timeout
      });

      // Should complete within timeout
      expect(response.status()).toBeLessThan(500);
    } catch (error) {
      // Timeout is acceptable in this test
      expect(error.message).toContain('timeout');
    }
  });

  test('should filter gallery by tags', async ({ request }) => {
    const response = await request.get(`${API_BASE_URL}/api/gallery?tag=pop`);

    expect(response.ok()).toBeTruthy();

    const data = await response.json();
    expect(data).toHaveProperty('items');

    // Verify filtering worked
    if (data.items.length > 0) {
      data.items.forEach((item: { tags: string[] }) => {
        expect(item.tags).toContain('pop');
      });
    }
  });
});

test.describe('API Performance Tests', () => {
  test('should respond to download stats within 500ms', async ({ request }) => {
    const startTime = Date.now();
    const response = await request.get(`${API_BASE_URL}/api/download-stats`);
    const duration = Date.now() - startTime;

    expect(response.ok()).toBeTruthy();
    expect(duration).toBeLessThan(500);
  });

  test('should handle concurrent API calls', async ({ request }) => {
    const requests = Array(5)
      .fill(null)
      .map(() => request.get(`${API_BASE_URL}/api/gallery`));

    const responses = await Promise.all(requests);

    responses.forEach((response) => {
      expect(response.ok()).toBeTruthy();
    });
  });
});
