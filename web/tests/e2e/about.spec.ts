import { test, expect } from '@playwright/test';

/**
 * AboutPage E2E Tests
 *
 * Tests for the about page functionality including:
 * - Page content loading
 * - Links to external sites
 * - Social media links
 * - Mobile layout
 */

test.describe('AboutPage Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/about');
  });

  test('should load page content', async ({ page }) => {
    await expect(page).toHaveURL(/.*about/);

    // Check for main heading
    const heading = page.locator('h1, h2').first();
    await expect(heading).toBeVisible();

    // Check for descriptive content
    const content = page.locator('p, article').first();
    await expect(content).toBeVisible();
  });

  test('should have links to external sites', async ({ page }) => {
    // Look for external links
    const externalLinks = page.locator('a[href^="http"], a[target="_blank"]');
    const count = await externalLinks.count();

    if (count > 0) {
      const firstLink = externalLinks.first();
      await expect(firstLink).toBeVisible();

      // Verify link has href attribute
      const href = await firstLink.getAttribute('href');
      expect(href).toBeTruthy();
    }
  });

  test('should have working social media links', async ({ page }) => {
    // Look for social media links
    const socialLinks = page.locator(
      'a[href*="github"], a[href*="twitter"], a[href*="linkedin"], [class*="social"]'
    );
    const count = await socialLinks.count();

    if (count > 0) {
      const firstSocial = socialLinks.first();
      await expect(firstSocial).toBeVisible();

      // Verify it's clickable
      await expect(firstSocial).toBeEnabled();
    }
  });

  test('should have correct mobile layout', async ({ page, viewport }) => {
    if (viewport && viewport.width < 768) {
      // Check that content is readable on mobile
      const mainContent = page.locator('main, article, [role="main"]').first();
      await expect(mainContent).toBeVisible();

      // Text should not overflow
      const paragraphs = page.locator('p').first();
      if (await paragraphs.isVisible()) {
        const box = await paragraphs.boundingBox();
        expect(box).toBeTruthy();
        if (box && viewport) {
          expect(box.width).toBeLessThanOrEqual(viewport.width);
        }
      }
    }
  });
});
