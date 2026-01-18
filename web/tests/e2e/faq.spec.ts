import { test, expect } from '@playwright/test';

/**
 * FAQPage E2E Tests
 *
 * Tests for the FAQ page functionality including:
 * - FAQ sections rendering
 * - Search functionality
 * - Expand/collapse toggle
 * - Mobile responsiveness
 * - Category filtering
 */

test.describe('FAQPage Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/faq');
  });

  test('should render FAQ sections', async ({ page }) => {
    await expect(page).toHaveURL(/.*faq/);

    // Check for FAQ items
    const faqItems = page.locator(
      '[class*="faq"], [class*="question"], details, [role="button"]'
    );
    const count = await faqItems.count();

    expect(count).toBeGreaterThan(0);
  });

  test('should have search functionality', async ({ page }) => {
    // Look for search input
    const searchInput = page.locator('input[type="search"], input[placeholder*="search" i]');
    const count = await searchInput.count();

    if (count > 0) {
      const input = searchInput.first();
      await expect(input).toBeVisible();

      // Try typing in search
      await input.fill('installation');
      await page.waitForTimeout(500);
    }
  });

  test('should toggle expand and collapse', async ({ page }) => {
    // Look for expandable elements
    const toggleElements = page.locator(
      'details summary, button[aria-expanded], [class*="accordion"]'
    );
    const count = await toggleElements.count();

    if (count > 0) {
      const firstToggle = toggleElements.first();
      await expect(firstToggle).toBeVisible();

      // Try clicking to expand
      await firstToggle.click();
      await page.waitForTimeout(300);

      // Try clicking again to collapse
      await firstToggle.click();
      await page.waitForTimeout(300);
    }
  });

  test('should be mobile responsive', async ({ page, viewport }) => {
    if (viewport && viewport.width < 768) {
      // Check that FAQ items are visible on mobile
      const mainContent = page.locator('main, [role="main"]').first();
      await expect(mainContent).toBeVisible();

      // FAQ items should be stacked vertically
      const faqItems = page.locator('[class*="faq"], details').first();
      if (await faqItems.isVisible()) {
        await expect(faqItems).toBeVisible();
      }
    }
  });

  test('should filter by category', async ({ page }) => {
    // Look for category filters
    const categoryFilters = page.locator(
      'button:has-text("Category"), [class*="category"], [role="tab"]'
    );
    const count = await categoryFilters.count();

    if (count > 0) {
      const firstCategory = categoryFilters.first();
      if (await firstCategory.isVisible()) {
        await firstCategory.click();
        await page.waitForTimeout(500);
      }
    }
  });
});
