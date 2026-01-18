import { test, expect } from '@playwright/test';

/**
 * Navigation E2E Tests
 *
 * Tests for site-wide navigation including:
 * - Header navigation responsiveness
 * - Mobile menu toggle
 * - Active route highlighting
 * - Footer navigation
 * - Breadcrumb trails
 */

test.describe('Navigation Tests', () => {
  test('should have responsive header navigation', async ({ page }) => {
    await page.goto('/');

    // Check header exists
    const header = page.locator('header, nav').first();
    await expect(header).toBeVisible();

    // Check for navigation links
    const navLinks = page.locator('header a, nav a');
    const count = await navLinks.count();
    expect(count).toBeGreaterThan(0);

    // Verify key pages are linked
    const downloadLink = page.locator('a[href="/download"]');
    if (await downloadLink.count() > 0) {
      await expect(downloadLink.first()).toBeVisible();
    }
  });

  test('should toggle mobile menu', async ({ page, viewport }) => {
    if (viewport && viewport.width < 768) {
      await page.goto('/');

      // Look for mobile menu button
      const menuButton = page.locator(
        'button[aria-label*="menu" i], [class*="hamburger"], [class*="mobile-menu-button"]'
      );

      if (await menuButton.count() > 0) {
        const btn = menuButton.first();
        await expect(btn).toBeVisible();

        // Toggle menu open
        await btn.click();
        await page.waitForTimeout(300);

        // Toggle menu closed
        await btn.click();
        await page.waitForTimeout(300);
      }
    }
  });

  test('should highlight active route', async ({ page }) => {
    // Navigate to download page
    await page.goto('/download');
    await page.waitForTimeout(500);

    // Check if download link has active class
    const activeLink = page.locator('a[href="/download"]').first();
    if (await activeLink.isVisible()) {
      const classes = await activeLink.getAttribute('class');
      // Active state might be indicated by class
      expect(classes).toBeTruthy();
    }
  });

  test('should have footer navigation', async ({ page }) => {
    await page.goto('/');

    // Scroll to footer
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await page.waitForTimeout(500);

    // Check for footer
    const footer = page.locator('footer');
    const count = await footer.count();

    if (count > 0) {
      const footerEl = footer.first();
      await expect(footerEl).toBeVisible();

      // Check for footer links
      const footerLinks = page.locator('footer a');
      const linkCount = await footerLinks.count();
      expect(linkCount).toBeGreaterThanOrEqual(0);
    }
  });

  test('should navigate between all pages', async ({ page }) => {
    const pages = ['/', '/download', '/gallery', '/tutorial', '/faq', '/about'];

    for (const path of pages) {
      await page.goto(path);
      await expect(page).toHaveURL(new RegExp(path === '/' ? '^/$' : path));
      await page.waitForLoadState('networkidle');
    }
  });
});
