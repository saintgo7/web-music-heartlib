import { test, expect } from '@playwright/test';

/**
 * HomePage E2E Tests
 *
 * Tests for the home page functionality including:
 * - Page loading
 * - Hero section visibility
 * - Features section
 * - Gallery preview
 * - CTA buttons
 * - Mobile responsiveness
 * - Navigation
 */

test.describe('HomePage Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should load successfully', async ({ page }) => {
    await expect(page).toHaveTitle(/ABADA Music Studio|MuLa/i);
    await expect(page.locator('body')).toBeVisible();
  });

  test('should display hero section', async ({ page }) => {
    const hero = page.locator('section').first();
    await expect(hero).toBeVisible();

    // Check for main heading
    const heading = page.locator('h1').first();
    await expect(heading).toBeVisible();
    await expect(heading).toContainText(/music/i);
  });

  test('should display features section', async ({ page }) => {
    // Wait for features section to load
    const features = page.locator('section').nth(1);
    await expect(features).toBeVisible();

    // Check for multiple feature items
    const featureItems = page.locator('[class*="feature"], [class*="card"]').first();
    await expect(featureItems).toBeVisible();
  });

  test('should display gallery preview', async ({ page }) => {
    // Check if gallery preview section exists
    const gallerySection = page.locator('text=/gallery|samples|music/i').first();
    await expect(gallerySection).toBeVisible();
  });

  test('should have clickable CTA buttons', async ({ page }) => {
    // Find download button
    const downloadBtn = page.locator('a[href*="/download"], button:has-text("download")', { hasText: /download/i }).first();

    if (await downloadBtn.isVisible()) {
      await expect(downloadBtn).toBeEnabled();

      // Click and verify navigation or action
      await downloadBtn.click();
      await page.waitForLoadState('networkidle');
    }
  });

  test('should be mobile responsive', async ({ page, viewport }) => {
    // Test with mobile viewport
    if (viewport && viewport.width < 768) {
      // Check that content is visible on mobile
      await expect(page.locator('h1').first()).toBeVisible();

      // Check for mobile menu if it exists
      const mobileMenu = page.locator('[aria-label*="menu"], [class*="mobile-menu"]').first();
      if (await mobileMenu.count() > 0) {
        await expect(mobileMenu).toBeVisible();
      }
    }
  });

  test('should have working navigation links', async ({ page }) => {
    // Check header navigation
    const nav = page.locator('nav, header').first();
    await expect(nav).toBeVisible();

    // Find and test a navigation link
    const downloadLink = page.locator('a[href="/download"]').first();
    if (await downloadLink.isVisible()) {
      await downloadLink.click();
      await expect(page).toHaveURL(/.*download/);
    }
  });

  test('should render without console errors', async ({ page }) => {
    const errors: string[] = [];
    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Allow certain expected errors (like 404 for optional resources)
    const criticalErrors = errors.filter(
      (error) => !error.includes('favicon') && !error.includes('404')
    );

    expect(criticalErrors.length).toBe(0);
  });
});
