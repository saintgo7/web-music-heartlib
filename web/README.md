# ABADA Music Studio - Website

React-based website for ABADA Music Studio - AI Music Generation Platform.

## Tech Stack

- **Framework**: React 18 + TypeScript
- **Build Tool**: Vite 7
- **Styling**: Tailwind CSS 4
- **Routing**: React Router DOM 7

## Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn

### Installation

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

### Development Server

```bash
npm run dev
```

The development server will start at `http://localhost:5173`

## Project Structure

```
web/
├── public/
│   └── favicon.svg
├── src/
│   ├── components/
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   ├── Hero.tsx
│   │   ├── Features.tsx
│   │   ├── DownloadSection.tsx
│   │   ├── GalleryPreview.tsx
│   │   └── SystemRequirements.tsx
│   ├── pages/
│   │   ├── HomePage.tsx
│   │   ├── DownloadPage.tsx
│   │   ├── GalleryPage.tsx
│   │   ├── TutorialPage.tsx
│   │   ├── FAQPage.tsx
│   │   └── AboutPage.tsx
│   ├── App.tsx
│   ├── main.tsx
│   └── index.css
├── index.html
├── package.json
├── vite.config.ts
├── tailwind.config.js
├── postcss.config.js
└── tsconfig.json
```

## Pages

| Route | Page | Description |
|-------|------|-------------|
| `/` | Home | Landing page with hero, features, download preview |
| `/download` | Download | OS-specific download options |
| `/gallery` | Gallery | Community-created music samples |
| `/tutorial` | Tutorial | Installation and usage guide |
| `/faq` | FAQ | Frequently asked questions |
| `/about` | About | About ABADA Inc. |

## Build

```bash
npm run build
```

Output will be in the `build/` directory, ready for deployment to Cloudflare Pages.

## Deployment

The website is configured to deploy to Cloudflare Pages:

1. Connect GitHub repository to Cloudflare Pages
2. Set build command: `cd web && npm install && npm run build`
3. Set output directory: `web/build`
4. Add custom domain: `music.abada.kr`

## Brand Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | `#6366f1` | Main brand color (Indigo) |
| Secondary | `#8b5cf6` | Secondary actions (Purple) |
| Accent | `#f43f5e` | Highlights (Rose) |
| Dark | `#1e1b4b` | Footer, dark sections |
| Light | `#e0e7ff` | Backgrounds, hover states |

## License

CC BY-NC 4.0

---

**ABADA Inc.** | [abada.kr](https://abada.kr) | [GitHub](https://github.com/saintgo7)
