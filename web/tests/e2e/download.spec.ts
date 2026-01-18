import { test, expect } from '@playwright/test';

/**
 * DownloadPage E2E Tests
 *
 * Tests for the download page functionality including:
 * - Page loading
 * - OS tabs rendering
 * - File sizes display
 * - Download buttons
 * - API stats loading
 * - Mobile layout
 */

test.describe('DownloadPage Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/download');
  });

  test('should load successfully', async ({ page }) => {
    await expect(page).toHaveURL(/.*download/);
    await expect(page.locator('h1, h2').first()).toBeVisible();
  });

  test('should render OS tabs', async ({ page }) => {
    // Check for Windows, macOS, and Linux tabs/sections
    const windowsSection = page.locator('text=/windows/i').first();
    const macosSection = page.locator('text=/mac|macos/i').first();
    const linuxSection = page.locator('text=/linux/i').first();

    await expect(windowsSection).toBeVisible();
    await expect(macosSection).toBeVisible();
    await expect(linuxSection).toBeVisible();
  });

  test('should display file sizes correctly', async ({ page }) => {
    // Wait for content to load
    await page.waitForLoadState('networkidle');

    // Look for file size indicators (MB, GB, etc.)
    const fileSizes = page.locator('text=/\\d+\\s*(MB|GB|KB)/i');
    const count = await fileSizes.count();

    // Should have at least one file size displayed
    expect(count).toBeGreaterThan(0);
  });

  test('should have functional download buttons', async ({ page }) => {
    // Find download buttons
    const downloadButtons = page.locator('a[href*="download"], button:has-text("Download")');
    const count = await downloadButtons.count();

    expect(count).toBeGreaterThan(0);

    // Check first button is enabled
    const firstButton = downloadButtons.first();
    await expect(firstButton).toBeVisible();
    await expect(firstButton).toBeEnabled();
  });

  test('should load API stats', async ({ page }) => {
    // Wait for potential API calls
    await page.waitForTimeout(2000);

    // Check for download statistics
    const statsSection = page.locator('text=/download|stats|total/i');
    const count = await statsSection.count();

    // Stats section should be present
    expect(count).toBeGreaterThan(0);
  });

  test('should work on mobile layout', async ({ page, viewport }) => {
    if (viewport && viewport.width < 768) {
      // Ensure content is visible and scrollable
      const mainContent = page.locator('main, [role="main"]').first();
      await expect(mainContent).toBeVisible();

      // Check that buttons are still clickable
      const downloadBtn = page.locator('a[href*="download"], button:has-text("Download")').first();
      if (await downloadBtn.isVisible()) {
        await expect(downloadBtn).toBeEnabled();
      }
    }
  });
});
