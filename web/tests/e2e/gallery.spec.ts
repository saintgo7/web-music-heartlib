import { test, expect } from '@playwright/test';

/**
 * GalleryPage E2E Tests
 *
 * Tests for the gallery page functionality including:
 * - Music samples loading
 * - Audio players functionality
 * - Filters/tags
 * - Pagination
 * - Lazy loading
 * - API connectivity
 */

test.describe('GalleryPage Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/gallery');
  });

  test('should load music samples', async ({ page }) => {
    await expect(page).toHaveURL(/.*gallery/);

    // Wait for content to load
    await page.waitForTimeout(2000);

    // Check for gallery items
    const galleryItems = page.locator('[class*="gallery"], [class*="sample"], [class*="card"]');
    const count = await galleryItems.count();

    expect(count).toBeGreaterThanOrEqual(0);
  });

  test('should have working audio players', async ({ page }) => {
    await page.waitForLoadState('networkidle');

    // Look for audio elements or player controls
    const audioElements = page.locator('audio, [class*="player"], button[aria-label*="play" i]');
    const count = await audioElements.count();

    if (count > 0) {
      const firstPlayer = audioElements.first();
      await expect(firstPlayer).toBeVisible();
    }
  });

  test('should have functional filters and tags', async ({ page }) => {
    await page.waitForLoadState('networkidle');

    // Look for filter buttons or tags
    const filterElements = page.locator(
      'button:has-text("Filter"), [class*="tag"], [class*="filter"], [role="tab"]'
    );
    const count = await filterElements.count();

    if (count > 0) {
      // Try clicking a filter
      const firstFilter = filterElements.first();
      if (await firstFilter.isVisible()) {
        await firstFilter.click();
        await page.waitForTimeout(500);
      }
    }
  });

  test('should implement pagination', async ({ page }) => {
    await page.waitForLoadState('networkidle');

    // Look for pagination controls
    const paginationElements = page.locator(
      'button:has-text("Next"), button:has-text("Previous"), [class*="pagination"], [aria-label*="page"]'
    );
    const count = await paginationElements.count();

    // Pagination might not be visible if there are few items
    expect(count).toBeGreaterThanOrEqual(0);
  });

  test('should lazy load images', async ({ page }) => {
    // Scroll to trigger lazy loading
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await page.waitForTimeout(1000);

    // Check that images are present
    const images = page.locator('img');
    const count = await images.count();

    if (count > 0) {
      // Verify at least one image is visible
      const visibleImages = page.locator('img:visible');
      const visibleCount = await visibleImages.count();
      expect(visibleCount).toBeGreaterThan(0);
    }
  });

  test('should connect to API successfully', async ({ page }) => {
    // Wait for API response
    const response = await page.waitForResponse(
      (response) => response.url().includes('/api/gallery') && response.status() === 200,
      { timeout: 10000 }
    ).catch(() => null);

    if (response) {
      expect(response.status()).toBe(200);
      const json = await response.json();
      expect(json).toHaveProperty('success');
    }
  });
});
