# ABADA Music Studio - Website

> v1.0.0 | Official Release

React-based website for ABADA Music Studio - AI Music Generation Platform powered by HeartMuLa.

[Live Demo](https://music.abada.kr) | [Documentation](../RELEASE_NOTES.md) | [Changelog](../CHANGELOG.md)

---

## Tech Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| React | 19.2.0 | UI Framework |
| TypeScript | 5.9.3 | Type Safety |
| Vite | 7.2.4 | Build Tool |
| Tailwind CSS | 4.1.18 | Styling |
| React Router | 7.12.0 | Routing |
| Playwright | 1.57.0 | E2E Testing |

---

## Quick Start

### Prerequisites

- Node.js >= 18.0.0
- npm >= 9.0.0

### Installation

```bash
# Clone repository
git clone https://github.com/saintgo7/web-music-heartlib.git
cd web-music-heartlib/web

# Install dependencies
npm install

# Start development server
npm run dev
```

### Available Scripts

```bash
npm run dev          # Start development server (port 5173)
npm run build        # Build for production
npm run preview      # Preview production build (port 4173)
npm run lint         # Run ESLint
npm run typecheck    # Run TypeScript type checking
npm run test:e2e     # Run E2E tests
```

---

## Project Structure

```
web/
├── public/                 # Static assets
│   ├── favicon.svg
│   ├── apple-touch-icon.png
│   └── og-image.png
├── src/
│   ├── components/        # Reusable components
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   ├── Hero.tsx
│   │   ├── Features.tsx
│   │   ├── DownloadSection.tsx
│   │   ├── GalleryPreview.tsx
│   │   ├── SystemRequirements.tsx
│   │   ├── LazyImage.tsx
│   │   └── index.ts
│   ├── pages/             # Page components
│   │   ├── HomePage.tsx
│   │   ├── DownloadPage.tsx
│   │   ├── GalleryPage.tsx
│   │   ├── TutorialPage.tsx
│   │   ├── FAQPage.tsx
│   │   ├── AboutPage.tsx
│   │   └── index.ts
│   ├── utils/             # Utility functions
│   │   ├── performance.ts
│   │   └── serviceWorker.ts
│   ├── App.tsx            # Main application
│   ├── main.tsx           # Entry point
│   └── index.css          # Global styles
├── tests/                  # E2E tests (Playwright)
├── index.html             # HTML template
├── vite.config.ts         # Vite configuration
├── tailwind.config.js     # Tailwind configuration
├── postcss.config.js      # PostCSS configuration
├── tsconfig.json          # TypeScript configuration
├── eslint.config.js       # ESLint configuration
└── package.json           # Package manifest
```

---

## Pages

| Route | Page | Description |
|-------|------|-------------|
| `/` | Home | Landing page with hero, features, download preview |
| `/download` | Download | OS-specific download options with system requirements |
| `/gallery` | Gallery | Community-created music samples |
| `/tutorial` | Tutorial | Installation and usage guide |
| `/faq` | FAQ | Frequently asked questions |
| `/about` | About | About ABADA Inc. and HeartMuLa |

---

## Features

### Performance Optimized
- Core Web Vitals compliant (LCP < 2.5s, FID < 100ms, CLS < 0.1)
- Code splitting with lazy loading
- Optimized bundle size (< 200KB gzipped)
- Service Worker for offline support

### Accessibility
- WCAG 2.1 AA compliant
- Keyboard navigation support
- Screen reader friendly
- Skip links for navigation

### SEO Ready
- Structured data (JSON-LD)
- Open Graph meta tags
- Twitter Card support
- Sitemap and robots.txt

---

## Build Configuration

### Production Build

```bash
npm run build
```

Output directory: `build/`

### Build Optimization

The Vite configuration includes:

- **Code Splitting**: Manual chunks for React, Router
- **Minification**: Terser with console removal
- **CSS**: Code splitting and optimization
- **Assets**: Content hash for cache busting

### Environment Variables

Create `.env.local` for local development:

```bash
VITE_API_URL=https://api.example.com
VITE_GA_ID=UA-XXXXXXXXX-X
```

---

## Testing

### E2E Tests (Playwright)

```bash
# Run all tests
npm run test:e2e

# Run specific browser
npm run test:e2e:chromium
npm run test:e2e:firefox
npm run test:e2e:webkit

# Run mobile tests
npm run test:e2e:mobile

# Interactive mode
npm run test:e2e:ui

# View test report
npm run test:report
```

### Test Coverage

- Homepage rendering and navigation
- Download page platform detection
- Gallery page media playback
- Responsive design (mobile/tablet/desktop)
- Accessibility (axe-core)

---

## Deployment

### Cloudflare Pages

The website is configured for Cloudflare Pages deployment:

1. Connect GitHub repository to Cloudflare Pages
2. Configure build settings:
   - Build command: `cd web && npm install && npm run build`
   - Output directory: `web/build`
3. Add custom domain: `music.abada.kr`

### Manual Deployment

```bash
# Build
npm run build

# Deploy build/ directory to your hosting provider
```

---

## Design System

### Brand Colors

| Color | Hex | CSS Variable | Usage |
|-------|-----|--------------|-------|
| Primary | `#6366f1` | `--color-abada-primary` | Main brand color |
| Secondary | `#8b5cf6` | `--color-abada-secondary` | Secondary actions |
| Accent | `#f43f5e` | `--color-abada-accent` | Highlights |
| Dark | `#1e1b4b` | `--color-abada-dark` | Footer, dark sections |
| Light | `#e0e7ff` | `--color-abada-light` | Backgrounds |

### Typography

- **Font Family**: Pretendard (Korean optimized)
- **Headings**: Bold (700)
- **Body**: Regular (400)

### Breakpoints

| Name | Size | Usage |
|------|------|-------|
| sm | 640px | Mobile |
| md | 768px | Tablet |
| lg | 1024px | Desktop |
| xl | 1280px | Large desktop |
| 2xl | 1536px | Extra large |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please read [CONTRIBUTING.md](../CONTRIBUTING.md) for details.

---

## Related Documentation

- [Changelog](../CHANGELOG.md) - Version history
- [Release Notes](../RELEASE_NOTES.md) - v1.0.0 release details
- [Build Verification](../BUILD_VERIFICATION.md) - Build checklist
- [Upgrade Guide](../UPGRADE_GUIDE.md) - Migration instructions
- [Build Guide](../BUILD.md) - Detailed build instructions

---

## License

CC BY-NC 4.0

- For non-commercial research and educational use only
- Commercial use is strictly prohibited

---

## Links

- **Website**: [music.abada.kr](https://music.abada.kr)
- **GitHub**: [github.com/saintgo7/web-music-heartlib](https://github.com/saintgo7/web-music-heartlib)
- **ABADA Inc.**: [abada.kr](https://abada.kr)
- **HeartMuLa**: [HeartMuLa Project](https://github.com/HeartMuLa/heartlib)

---

**ABADA Music Studio v1.0.0** | 2026 ABADA Inc.
