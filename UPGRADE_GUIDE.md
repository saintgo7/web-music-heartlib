# Upgrade Guide - ABADA Music Studio

This guide provides instructions for upgrading ABADA Music Studio from previous versions to v1.0.0.

---

## Table of Contents

- [Upgrade Paths](#upgrade-paths)
- [From v0.4.0 to v1.0.0](#from-v040-to-v100)
- [From v0.3.0 to v1.0.0](#from-v030-to-v100)
- [From v0.2.0 to v1.0.0](#from-v020-to-v100)
- [From v0.1.0 to v1.0.0](#from-v010-to-v100)
- [Breaking Changes](#breaking-changes)
- [New Features to Try](#new-features-to-try)
- [Configuration Changes](#configuration-changes)
- [Troubleshooting](#troubleshooting)

---

## Upgrade Paths

| Current Version | Target Version | Difficulty | Estimated Time |
|-----------------|----------------|------------|----------------|
| v0.4.0 | v1.0.0 | Easy | 5 minutes |
| v0.3.0 | v1.0.0 | Easy | 10 minutes |
| v0.2.0 | v1.0.0 | Moderate | 15 minutes |
| v0.1.0 | v1.0.0 | Moderate | 20 minutes |

---

## From v0.4.0 to v1.0.0

### Prerequisites

- Node.js >= 18.0.0
- npm >= 9.0.0
- Git

### Steps

1. **Backup Your Current Installation**

   ```bash
   # Create a backup branch
   git checkout -b backup-v0.4.0
   git push origin backup-v0.4.0
   git checkout main
   ```

2. **Pull Latest Changes**

   ```bash
   git pull origin main
   ```

3. **Update Dependencies**

   ```bash
   cd web
   rm -rf node_modules package-lock.json
   npm install
   ```

4. **Verify Installation**

   ```bash
   npm run typecheck
   npm run lint
   npm run build
   ```

5. **Test Locally**

   ```bash
   npm run preview
   # Open http://localhost:4173
   ```

### What's Changed

- Package version updated to 1.0.0
- Added comprehensive documentation
- Minor bug fixes and polish

---

## From v0.3.0 to v1.0.0

### Prerequisites

Same as v0.4.0 upgrade.

### Steps

1. Follow steps 1-3 from v0.4.0 upgrade

2. **Rebuild Service Worker**

   The service worker configuration may have changed. Clear your browser cache:

   ```bash
   # In browser DevTools > Application > Clear storage
   ```

3. Continue with steps 4-5 from v0.4.0 upgrade

### What's Changed

- Performance optimizations
- Service worker improvements
- Core Web Vitals monitoring

---

## From v0.2.0 to v1.0.0

### Prerequisites

Same as v0.4.0 upgrade.

### Steps

1. Follow steps 1-3 from v0.4.0 upgrade

2. **Update CI/CD Configuration** (if self-hosting)

   If you have a custom CI/CD setup, update your workflow files:

   ```yaml
   # .github/workflows/ci.yml
   - uses: actions/setup-node@v4
     with:
       node-version: '20'  # Updated from 18
   ```

3. **Update Cloudflare Configuration** (if applicable)

   - Review `wrangler.toml` for any deprecated settings
   - Update environment variables if changed

4. Continue with steps 4-5 from v0.4.0 upgrade

### What's Changed

- E2E testing suite (Playwright)
- Accessibility tests
- Performance tests

---

## From v0.1.0 to v1.0.0

### Prerequisites

Same as v0.4.0 upgrade, plus:

- Review all custom modifications you may have made

### Steps

1. **Document Your Customizations**

   Before upgrading, note any custom changes:
   - Modified components
   - Custom styles
   - Configuration changes

2. Follow steps 1-3 from v0.4.0 upgrade

3. **Re-apply Customizations**

   If you had custom changes, carefully re-apply them to the new codebase.

4. **Update Environment Variables**

   Create or update your `.env` file:

   ```bash
   # .env.local
   VITE_API_URL=your_api_url
   VITE_GA_ID=your_analytics_id  # Optional
   ```

5. Continue with steps 4-5 from v0.4.0 upgrade

### What's Changed

- Complete CI/CD pipeline
- Testing infrastructure
- Performance optimizations
- All v0.2.0, v0.3.0, v0.4.0 changes

---

## Breaking Changes

### v1.0.0

**No breaking changes in v1.0.0.**

All existing functionality from v0.x versions is preserved. The upgrade is fully backward compatible.

### Future Considerations

While v1.0.0 has no breaking changes, future versions may include:

- API changes (v1.1.0+)
- Database schema changes (if applicable)
- Configuration format changes

Always check the [CHANGELOG.md](./CHANGELOG.md) before upgrading.

---

## New Features to Try

### v1.0.0 Highlights

1. **Improved Documentation**
   - Comprehensive CHANGELOG
   - Detailed release notes
   - Build verification checklist

2. **Production-Ready Build**
   - Optimized bundle sizes
   - Enhanced caching
   - Better error handling

3. **Quality Assurance**
   - Complete E2E test coverage
   - Accessibility compliance
   - Performance benchmarks

### Quick Feature Tour

1. **Visit the Homepage**
   - Notice faster load times
   - Check the responsive design

2. **Try the Download Page**
   - Platform auto-detection
   - Clear installation instructions

3. **Explore the Gallery**
   - Sample music tracks
   - Playback controls

4. **Read the Tutorial**
   - Getting started guide
   - Best practices

---

## Configuration Changes

### package.json Updates

```json
{
  "version": "1.0.0",  // Updated from "0.4.0"
  "description": "ABADA Music Studio - AI Music Generation Platform...",
  "keywords": [...],
  "homepage": "https://music.abada.kr",
  "repository": {...},
  "license": "CC-BY-NC-4.0",
  "author": "ABADA Inc. <contact@abada.kr>"
}
```

### index.html Updates

```html
<!-- New meta tags -->
<meta name="generator" content="ABADA Music Studio v1.0.0" />
<meta name="version" content="1.0.0" />
```

### vite.config.ts

No changes required. Configuration remains compatible.

---

## Troubleshooting

### Common Issues

#### 1. Build Fails After Upgrade

**Symptom**: `npm run build` fails with TypeScript errors.

**Solution**:
```bash
# Clear TypeScript cache
rm -rf node_modules/.cache
rm -rf web/.tsbuildinfo

# Reinstall dependencies
npm clean-install
```

#### 2. Service Worker Not Updating

**Symptom**: Old cached content still appearing.

**Solution**:
```bash
# In browser DevTools:
# 1. Open Application tab
# 2. Click "Clear storage"
# 3. Unregister service workers
# 4. Refresh the page
```

#### 3. Styles Not Loading

**Symptom**: Tailwind CSS styles missing after upgrade.

**Solution**:
```bash
# Rebuild CSS
npm run build

# If still failing, check PostCSS config
cat postcss.config.js
```

#### 4. Tests Failing

**Symptom**: E2E tests fail after upgrade.

**Solution**:
```bash
# Update Playwright browsers
npx playwright install

# Run tests with debug info
npm run test:e2e:debug
```

### Getting Help

If you encounter issues not covered here:

1. **Check GitHub Issues**
   - [Open Issues](https://github.com/saintgo7/web-music-heartlib/issues)

2. **Create a New Issue**
   - Use the bug report template
   - Include version numbers
   - Attach error logs

3. **Contact Support**
   - Email: contact@abada.kr
   - Discord: [ABADA Community](https://discord.gg/abada)

---

## Rollback Instructions

If you need to rollback to a previous version:

```bash
# Option 1: Use backup branch
git checkout backup-v0.4.0

# Option 2: Checkout specific version tag
git checkout v0.4.0

# Reinstall dependencies
cd web
npm install

# Rebuild
npm run build
```

---

## Post-Upgrade Checklist

After completing the upgrade, verify:

- [ ] Application builds without errors
- [ ] All pages load correctly
- [ ] Navigation works as expected
- [ ] No console errors in browser
- [ ] Service worker registers correctly
- [ ] Performance is acceptable
- [ ] E2E tests pass (if applicable)

---

*Last updated: January 19, 2026*
*Version: v1.0.0*
