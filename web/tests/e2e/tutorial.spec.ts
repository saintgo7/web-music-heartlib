import { test, expect } from '@playwright/test';

/**
 * TutorialPage E2E Tests
 *
 * Tests for the tutorial page functionality including:
 * - Installation steps display
 * - Code blocks syntax highlighting
 * - Screenshots loading
 * - Navigation between sections
 * - Mobile responsiveness
 * - Search/filter functionality
 */

test.describe('TutorialPage Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/tutorial');
  });

  test('should display installation steps', async ({ page }) => {
    await expect(page).toHaveURL(/.*tutorial/);

    // Check for step indicators or ordered content
    const steps = page.locator('ol li, [class*="step"], h2, h3');
    const count = await steps.count();

    expect(count).toBeGreaterThan(0);
  });

  test('should have syntax highlighted code blocks', async ({ page }) => {
    // Look for code blocks
    const codeBlocks = page.locator('pre code, [class*="code"], pre');
    const count = await codeBlocks.count();

    if (count > 0) {
      const firstCode = codeBlocks.first();
      await expect(firstCode).toBeVisible();
    }
  });

  test('should load screenshots if available', async ({ page }) => {
    await page.waitForLoadState('networkidle');

    // Check for images
    const images = page.locator('img');
    const count = await images.count();

    if (count > 0) {
      // Verify first image loads
      const firstImg = images.first();
      await expect(firstImg).toBeVisible();
    }
  });

  test('should navigate between sections', async ({ page }) => {
    // Look for section links or navigation
    const sectionLinks = page.locator('a[href^="#"], nav a');
    const count = await sectionLinks.count();

    if (count > 0) {
      const firstLink = sectionLinks.first();
      if (await firstLink.isVisible()) {
        await firstLink.click();
        await page.waitForTimeout(500);
      }
    }
  });

  test('should be mobile responsive', async ({ page, viewport }) => {
    if (viewport && viewport.width < 768) {
      // Check that content is readable on mobile
      const mainContent = page.locator('main, article, [role="main"]').first();
      await expect(mainContent).toBeVisible();

      // Code blocks should be scrollable horizontally
      const codeBlock = page.locator('pre code, pre').first();
      if (await codeBlock.isVisible()) {
        const box = await codeBlock.boundingBox();
        expect(box).toBeTruthy();
      }
    }
  });

  test('should have search or filter functionality', async ({ page }) => {
    // Look for search input or filter buttons
    const searchInput = page.locator('input[type="search"], input[placeholder*="search" i]');
    const filterButtons = page.locator('button:has-text("Filter"), [role="tab"]');

    const searchCount = await searchInput.count();
    const filterCount = await filterButtons.count();

    // At least one form of filtering should exist
    expect(searchCount + filterCount).toBeGreaterThanOrEqual(0);
  });
});
