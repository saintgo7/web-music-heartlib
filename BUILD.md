# Build Guide - ABADA Music Studio

This document provides detailed instructions for building ABADA Music Studio for production deployment.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Build](#quick-build)
- [Development Build](#development-build)
- [Production Build](#production-build)
- [Build Configuration](#build-configuration)
- [Bundle Analysis](#bundle-analysis)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

| Software | Minimum Version | Recommended |
|----------|-----------------|-------------|
| Node.js | 18.0.0 | 20.x LTS |
| npm | 9.0.0 | Latest |
| Git | 2.30+ | Latest |

### Verify Installation

```bash
# Check Node.js version
node --version
# Expected: v20.x.x or v18.x.x

# Check npm version
npm --version
# Expected: 9.x.x or higher

# Check Git version
git --version
# Expected: 2.30.0 or higher
```

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 4 GB | 8 GB |
| Disk Space | 1 GB | 2 GB |
| CPU | 2 cores | 4 cores |

---

## Quick Build

For a quick production build:

```bash
# Clone repository
git clone https://github.com/saintgo7/web-music-heartlib.git
cd web-music-heartlib/web

# Install dependencies
npm ci

# Build for production
npm run build

# Output is in build/ directory
ls -la build/
```

---

## Development Build

### Start Development Server

```bash
cd web

# Install dependencies (first time only)
npm install

# Start development server
npm run dev
```

The development server will start at `http://localhost:5173` with:

- Hot Module Replacement (HMR)
- Source maps for debugging
- Development error overlay
- Fast refresh for React components

### Development Commands

```bash
# Start dev server
npm run dev

# Run type checking
npm run typecheck

# Run linting
npm run lint

# Run E2E tests
npm run test:e2e
```

---

## Production Build

### Standard Build

```bash
cd web

# Clean install dependencies
npm ci

# Build for production
npm run build
```

### Build Output

The build process generates files in the `build/` directory:

```
build/
├── index.html              # Main HTML file
├── assets/
│   ├── index-[hash].js    # Main bundle
│   ├── index-[hash].css   # Styles
│   ├── react-vendor-[hash].js
│   ├── router-[hash].js
│   └── [page]-[hash].js   # Lazy-loaded pages
├── favicon.svg
├── apple-touch-icon.png
└── og-image.png
```

### Build Steps Explained

1. **TypeScript Compilation**
   ```bash
   tsc -b
   ```
   - Compiles TypeScript to JavaScript
   - Generates type declarations
   - Performs type checking

2. **Vite Build**
   ```bash
   vite build
   ```
   - Bundles JavaScript modules
   - Processes CSS (Tailwind, PostCSS)
   - Optimizes assets
   - Generates source maps (if enabled)

3. **Minification**
   - Terser minifies JavaScript
   - CSS is minified and optimized
   - Console logs removed in production

### Verify Build

```bash
# Check build output
ls -la build/

# Check bundle sizes
du -sh build/assets/*.js

# Preview production build locally
npm run preview
```

---

## Build Configuration

### Vite Configuration (`vite.config.ts`)

```typescript
export default defineConfig({
  plugins: [react()],

  build: {
    outDir: 'build',
    sourcemap: false,
    minify: 'terser',
    target: 'es2020',

    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
      },
    },

    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom'],
          'router': ['react-router-dom'],
        },
      },
    },

    chunkSizeWarningLimit: 200,
    cssCodeSplit: true,
    assetsInlineLimit: 4096,
  },
});
```

### Key Configuration Options

| Option | Value | Description |
|--------|-------|-------------|
| `outDir` | `'build'` | Output directory |
| `sourcemap` | `false` | Disable source maps for production |
| `minify` | `'terser'` | Use Terser for minification |
| `target` | `'es2020'` | Target modern browsers |
| `drop_console` | `true` | Remove console.log in production |
| `chunkSizeWarningLimit` | `200` | Warn for chunks > 200KB |

### Environment Variables

Create `.env.production` for production-specific variables:

```bash
# .env.production
VITE_APP_VERSION=1.0.0
VITE_API_URL=https://api.abada.kr
```

Access in code:
```typescript
const version = import.meta.env.VITE_APP_VERSION;
```

---

## Bundle Analysis

### Analyze Bundle Size

```bash
# Build with analysis
npm run build:analyze
```

This generates a visual representation of the bundle.

### Manual Size Check

```bash
# Total build size
du -sh build/

# Individual chunk sizes
du -sh build/assets/*.js | sort -h

# Gzipped size estimate
gzip -c build/assets/index-*.js | wc -c | awk '{print $1/1024 " KB"}'
```

### Target Bundle Sizes

| Chunk | Target Size (gzipped) |
|-------|----------------------|
| Main | < 50 KB |
| React Vendor | < 45 KB |
| Router | < 15 KB |
| Total | < 200 KB |

---

## Deployment

### Cloudflare Pages

```bash
# The build directory is ready for Cloudflare Pages
# Configure in Cloudflare dashboard:
# - Build command: cd web && npm install && npm run build
# - Build output directory: web/build
```

### Static Hosting

The `build/` directory contains static files that can be served by any web server:

```bash
# Using serve
npx serve build

# Using Python
cd build && python -m http.server 8080

# Using nginx (example config)
location / {
    root /path/to/build;
    try_files $uri $uri/ /index.html;
}
```

### Docker

```dockerfile
# Dockerfile example
FROM node:20-alpine as builder
WORKDIR /app
COPY web/package*.json ./
RUN npm ci
COPY web/ ./
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## Troubleshooting

### Common Issues

#### 1. Node.js Version Mismatch

**Error**: `The engine "node" is incompatible with this module`

**Solution**:
```bash
# Use nvm to switch Node version
nvm install 20
nvm use 20
```

#### 2. Out of Memory

**Error**: `FATAL ERROR: Ineffective mark-compacts near heap limit`

**Solution**:
```bash
# Increase Node.js memory limit
export NODE_OPTIONS="--max-old-space-size=4096"
npm run build
```

#### 3. TypeScript Errors

**Error**: Type errors during build

**Solution**:
```bash
# Check for type errors
npm run typecheck

# Fix errors before building
```

#### 4. Missing Dependencies

**Error**: `Cannot find module 'xxx'`

**Solution**:
```bash
# Clean and reinstall
rm -rf node_modules package-lock.json
npm install
```

#### 5. Build Hangs

**Symptom**: Build process seems stuck

**Solution**:
```bash
# Clear cache and rebuild
rm -rf node_modules/.cache
rm -rf node_modules/.vite
npm run build
```

### Getting Help

If you encounter issues not covered here:

1. Check [GitHub Issues](https://github.com/saintgo7/web-music-heartlib/issues)
2. Create a new issue with:
   - Node.js and npm versions
   - Operating system
   - Full error message
   - Steps to reproduce

---

## Continuous Integration

### GitHub Actions Example

```yaml
name: Build

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: web/package-lock.json

      - name: Install dependencies
        working-directory: web
        run: npm ci

      - name: Build
        working-directory: web
        run: npm run build

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: build
          path: web/build/
```

---

## Performance Tips

1. **Use `npm ci` instead of `npm install`** for faster, reproducible builds

2. **Enable caching** in your CI/CD pipeline

3. **Use parallel builds** when possible

4. **Monitor bundle size** with each release

5. **Keep dependencies updated** for performance improvements

---

*Last updated: January 19, 2026*
*Version: v1.0.0*
