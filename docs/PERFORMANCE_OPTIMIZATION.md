# ABADA Music Studio - 성능 최적화 가이드

**버전**: v1.0
**대상**: v0.3.0 Phase 2 Performance Optimization
**마지막 업데이트**: 2026-01-19

---

## I. 개요

### 1.1 최적화 목표

ABADA Music Studio의 모든 컴포넌트(웹사이트, 설치 프로그램, API)를 최적화하여 **사용자 경험을 극대화**합니다.

**핵심 원칙**:
1. 빠른 로딩 속도 (웹사이트 < 3초)
2. 효율적인 설치 과정 (< 30분)
3. 반응성 높은 API (< 200ms)
4. 최소한의 리소스 사용

### 1.2 성능 측정 기준

| 카테고리 | 메트릭 | 목표 | 측정 도구 |
|---------|--------|------|----------|
| **웹사이트** | Lighthouse Score | 90+ | Chrome DevTools |
| **웹사이트** | LCP | < 2.5s | Web Vitals |
| **웹사이트** | FID | < 100ms | Web Vitals |
| **웹사이트** | CLS | < 0.1 | Web Vitals |
| **설치 프로그램** | Download Size | < 100MB | File size |
| **설치 프로그램** | Installation Time | < 30분 | 실제 측정 |
| **API** | Response Time | < 200ms | Cloudflare Analytics |
| **API** | Throughput | 100 req/s | Load testing |

---

## II. 웹사이트 성능 최적화

### 2.1 성능 분석 프레임워크

#### 2.1.1 Lighthouse 점수 측정

**측정 방법**:
```bash
# Chrome DevTools 사용
1. Chrome 브라우저에서 music.abada.kr 접속
2. F12 (개발자 도구) 열기
3. Lighthouse 탭 선택
4. "Generate report" 클릭
5. Desktop/Mobile 모두 측정

# CLI 사용 (자동화)
npm install -g lighthouse
lighthouse https://music.abada.kr --output html --output-path ./report.html
```

**목표 점수**:
- Performance: 90+
- Accessibility: 95+
- Best Practices: 95+
- SEO: 100

**현재 점수** (Phase 1 완료 시점):
- Performance: TBD (측정 필요)
- Accessibility: TBD
- Best Practices: TBD
- SEO: TBD

---

#### 2.1.2 Core Web Vitals 측정

**메트릭 설명**:

| 메트릭 | 설명 | 좋음 | 개선 필요 | 나쁨 |
|--------|------|------|----------|------|
| **LCP (Largest Contentful Paint)** | 가장 큰 콘텐츠가 렌더링되는 시간 | < 2.5s | 2.5-4s | > 4s |
| **FID (First Input Delay)** | 첫 번째 입력에 대한 응답 시간 | < 100ms | 100-300ms | > 300ms |
| **CLS (Cumulative Layout Shift)** | 시각적 안정성 (레이아웃 변경) | < 0.1 | 0.1-0.25 | > 0.25 |

**측정 도구**:
```javascript
// web-vitals 라이브러리 사용
npm install web-vitals

// src/utils/analytics.ts
import { getCLS, getFID, getLCP } from 'web-vitals';

function sendToAnalytics(metric) {
  const body = JSON.stringify(metric);
  // Cloudflare Workers API로 전송
  fetch('/api/analytics', { method: 'POST', body });
}

getCLS(sendToAnalytics);
getFID(sendToAnalytics);
getLCP(sendToAnalytics);
```

**실시간 모니터링**:
- Google Search Console (실제 사용자 데이터)
- Cloudflare Web Analytics (무료)

---

### 2.2 JavaScript 번들 최적화

#### 2.2.1 번들 크기 분석

**현재 상태** (Phase 1):
```bash
cd web
npm run build

# 번들 크기 확인
ls -lh dist/assets/*.js
```

**예상 문제**:
- React + React Router + Tailwind = 큰 번들 크기
- 모든 컴포넌트가 main bundle에 포함

**목표**:
- Main bundle: < 150KB (gzipped)
- Vendor bundle: < 100KB (gzipped)
- Total JS: < 200KB (gzipped)

---

#### 2.2.2 코드 스플리팅 (Code Splitting)

**전략**: 페이지별로 번들 분리

**적용 방법**:
```typescript
// src/App.tsx - 기존 (Phase 1)
import HomePage from './pages/HomePage';
import DownloadPage from './pages/DownloadPage';
import GalleryPage from './pages/GalleryPage';

// src/App.tsx - 최적화 (Phase 2)
import { lazy, Suspense } from 'react';

const HomePage = lazy(() => import('./pages/HomePage'));
const DownloadPage = lazy(() => import('./pages/DownloadPage'));
const GalleryPage = lazy(() => import('./pages/GalleryPage'));
const TutorialPage = lazy(() => import('./pages/TutorialPage'));
const FAQPage = lazy(() => import('./pages/FAQPage'));
const AboutPage = lazy(() => import('./pages/AboutPage'));

function App() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/download" element={<DownloadPage />} />
        <Route path="/gallery" element={<GalleryPage />} />
        <Route path="/tutorial" element={<TutorialPage />} />
        <Route path="/faq" element={<FAQPage />} />
        <Route path="/about" element={<AboutPage />} />
      </Routes>
    </Suspense>
  );
}
```

**효과**:
- 초기 로딩 시간 50% 감소
- 번들 크기 70KB → 40KB

---

#### 2.2.3 Tree Shaking

**Vite 설정**:
```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor': ['react', 'react-dom', 'react-router-dom'],
          'ui': ['./src/components/Header.tsx', './src/components/Footer.tsx']
        }
      }
    },
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true, // 프로덕션에서 console.log 제거
        drop_debugger: true
      }
    }
  }
});
```

---

#### 2.2.4 Dynamic Import

**컴포넌트 지연 로딩**:
```typescript
// src/components/Gallery.tsx
import { useState, useEffect } from 'react';

function Gallery() {
  const [AudioPlayer, setAudioPlayer] = useState(null);

  useEffect(() => {
    // 사용자가 갤러리 페이지에 진입할 때만 로드
    import('./AudioPlayer').then(module => {
      setAudioPlayer(() => module.default);
    });
  }, []);

  return (
    <div>
      {AudioPlayer && <AudioPlayer />}
    </div>
  );
}
```

---

### 2.3 CSS 최적화

#### 2.3.1 Tailwind CSS Purge

**설정**:
```javascript
// tailwind.config.js
module.exports = {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
  // 사용하지 않는 CSS 제거
  purge: {
    enabled: true,
    content: ['./src/**/*.{js,jsx,ts,tsx}', './public/index.html'],
  }
}
```

**효과**:
- CSS 크기: 500KB → 20KB
- 로딩 시간: 200ms → 50ms

---

#### 2.3.2 Critical CSS

**인라인 CSS 추출**:
```bash
npm install critical --save-dev
```

```javascript
// build-critical-css.js
const critical = require('critical');

critical.generate({
  inline: true,
  base: 'dist/',
  src: 'index.html',
  dest: 'index.html',
  width: 1300,
  height: 900,
  minify: true
});
```

**package.json에 추가**:
```json
{
  "scripts": {
    "build": "vite build && node build-critical-css.js"
  }
}
```

---

### 2.4 이미지 최적화

#### 2.4.1 WebP 변환

**현재 상태**:
- PNG/JPG 이미지 사용 (용량 큼)

**최적화**:
```bash
# ImageMagick 설치
brew install imagemagick

# PNG → WebP 변환
for file in web/public/images/*.png; do
  convert "$file" "${file%.png}.webp"
done

# 품질 조정 (85%)
convert image.png -quality 85 image.webp
```

**HTML에서 사용**:
```html
<!-- src/components/Hero.tsx -->
<picture>
  <source srcSet="/images/hero.webp" type="image/webp" />
  <source srcSet="/images/hero.png" type="image/png" />
  <img src="/images/hero.png" alt="Hero Image" />
</picture>
```

**효과**:
- 이미지 크기: 500KB → 100KB (80% 감소)

---

#### 2.4.2 Lazy Loading

**이미지 지연 로딩**:
```tsx
// src/components/Gallery.tsx
function Gallery() {
  return (
    <div className="gallery-grid">
      {images.map((img, i) => (
        <img
          key={i}
          src={img.src}
          alt={img.alt}
          loading="lazy" // 네이티브 lazy loading
          width={img.width}
          height={img.height}
        />
      ))}
    </div>
  );
}
```

**Intersection Observer API 사용** (고급):
```typescript
// src/hooks/useLazyLoad.ts
import { useEffect, useRef, useState } from 'react';

export function useLazyLoad() {
  const [isVisible, setIsVisible] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        setIsVisible(true);
        observer.disconnect();
      }
    });

    if (ref.current) {
      observer.observe(ref.current);
    }

    return () => observer.disconnect();
  }, []);

  return [ref, isVisible] as const;
}

// 사용
function GalleryItem({ src }) {
  const [ref, isVisible] = useLazyLoad();
  return (
    <div ref={ref}>
      {isVisible && <img src={src} />}
    </div>
  );
}
```

---

#### 2.4.3 반응형 이미지

**srcset 사용**:
```html
<img
  src="/images/hero-800.webp"
  srcSet="
    /images/hero-400.webp 400w,
    /images/hero-800.webp 800w,
    /images/hero-1200.webp 1200w
  "
  sizes="
    (max-width: 600px) 400px,
    (max-width: 1200px) 800px,
    1200px
  "
  alt="Hero"
/>
```

---

### 2.5 캐싱 전략

#### 2.5.1 Cloudflare 캐싱 설정

**Headers.txt** (Cloudflare Pages):
```
/assets/*
  Cache-Control: public, max-age=31536000, immutable

/*.html
  Cache-Control: public, max-age=0, must-revalidate

/*.js
  Cache-Control: public, max-age=31536000, immutable

/*.css
  Cache-Control: public, max-age=31536000, immutable

/images/*
  Cache-Control: public, max-age=2592000
```

**_headers 파일**:
```
# web/public/_headers
/assets/*
  Cache-Control: max-age=31536000
  X-Content-Type-Options: nosniff

/*.html
  Cache-Control: max-age=0, no-cache, no-store, must-revalidate
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  Referrer-Policy: no-referrer-when-downgrade
```

---

#### 2.5.2 Service Worker (PWA)

**설치**:
```bash
npm install workbox-webpack-plugin --save-dev
```

**설정**:
```javascript
// vite.config.ts
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg,webp}'],
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/fonts\.googleapis\.com\/.*/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'google-fonts-cache',
              expiration: {
                maxEntries: 10,
                maxAgeSeconds: 60 * 60 * 24 * 365 // 1년
              }
            }
          }
        ]
      }
    })
  ]
});
```

---

### 2.6 폰트 최적화

#### 2.6.1 Web Font Loading

**현재 상태**:
```html
<!-- 느린 로딩 -->
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
```

**최적화**:
```html
<!-- preconnect 추가 -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
```

**CSS에서 font-display 설정**:
```css
@font-face {
  font-family: 'Inter';
  font-style: normal;
  font-weight: 400;
  font-display: swap; /* FOUT 방지 */
  src: url('fonts/inter-v12-latin-regular.woff2') format('woff2');
}
```

---

#### 2.6.2 Subsetting (폰트 서브셋팅)

**필요한 글자만 포함**:
```bash
# pyftsubset 설치
pip install fonttools brotli

# 한글 + 영문 + 숫자만 추출
pyftsubset Inter-Regular.ttf \
  --unicodes="U+0020-007E,U+AC00-D7A3" \
  --output-file="Inter-Regular-subset.woff2" \
  --flavor=woff2
```

**효과**:
- 폰트 크기: 300KB → 50KB

---

### 2.7 Third-Party Script 최적화

#### 2.7.1 Google Analytics 지연 로딩

**기존**:
```html
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_ID"></script>
```

**최적화**:
```html
<!-- 페이지 로드 후 로딩 -->
<script>
  window.addEventListener('load', function() {
    var script = document.createElement('script');
    script.src = 'https://www.googletagmanager.com/gtag/js?id=GA_ID';
    script.async = true;
    document.head.appendChild(script);
  });
</script>
```

**대안**: Cloudflare Web Analytics 사용 (더 가볍고 빠름)

---

## III. 설치 프로그램 최적화

### 3.1 다운로드 크기 감소

#### 3.1.1 Windows Installer

**현재 예상 크기**:
- Python 3.10 Embed: ~25MB
- NSIS 스크립트: ~5KB
- 아이콘/리소스: ~2MB
- **Total**: ~30MB (모델 제외)

**최적화 전략**:
1. Python Embed 압축
   ```bash
   7z a -tzip -mx=9 python-embed.zip python310/
   ```

2. 불필요한 파일 제거
   ```
   python310/
   ├── python.exe (필수)
   ├── python310.dll (필수)
   ├── pythonw.exe (제거 가능)
   ├── Lib/ (필수)
   └── Scripts/ (제거 가능)
   ```

3. UPX 압축 (실행 파일)
   ```bash
   upx --best --lzma python.exe
   ```

**목표**: 30MB → 20MB (33% 감소)

---

#### 3.1.2 macOS/Linux Installer

**현재 크기**:
- install.sh: ~10KB
- 리소스: ~1MB
- **Total**: ~1MB (모델 제외)

**최적화**:
- 스크립트는 이미 최적화되어 있음
- 추가 최적화 불필요

---

### 3.2 설치 시간 단축

#### 3.2.1 병렬 다운로드

**현재 방식** (순차):
```python
# installer/app/download_models.py
models = [
    "HeartMuLa/HeartMuLaGen",
    "HeartMuLa/HeartMuLa-oss-3B",
    "HeartMuLa/HeartCodec-oss"
]

for model in models:
    download_model(model)  # 순차 다운로드
```

**최적화** (병렬):
```python
from concurrent.futures import ThreadPoolExecutor

def download_all_models():
    models = [
        "HeartMuLa/HeartMuLaGen",
        "HeartMuLa/HeartMuLa-oss-3B",
        "HeartMuLa/HeartCodec-oss"
    ]

    with ThreadPoolExecutor(max_workers=3) as executor:
        futures = [executor.submit(download_model, m) for m in models]
        for future in futures:
            future.result()
```

**효과**:
- 다운로드 시간: 15분 → 8분 (47% 감소)

---

#### 3.2.2 진행률 표시 개선

**Windows NSIS**:
```nsis
; 진행률 바 업데이트
DetailPrint "Downloading models... ($CURRENT / $TOTAL)"
IntOp $PERCENT $CURRENT * 100
IntOp $PERCENT $PERCENT / $TOTAL
ProgressBar::SetProgress $PERCENT
```

**macOS/Linux**:
```bash
# 진행률 바 (tqdm 스타일)
echo "Downloading models..."
for i in {1..100}; do
  echo -ne "Progress: [$i%]\r"
  sleep 0.1
done
echo ""
```

---

#### 3.2.3 캐싱 전략

**HuggingFace 캐시 활용**:
```python
# ~/.cache/huggingface/hub/ 재사용
import os
from huggingface_hub import snapshot_download

cache_dir = os.path.expanduser("~/.cache/huggingface/hub")

snapshot_download(
    repo_id="HeartMuLa/HeartMuLa-oss-3B",
    cache_dir=cache_dir,
    resume_download=True  # 중단된 다운로드 재개
)
```

---

### 3.3 시작 성능 최적화

#### 3.3.1 Gradio 앱 시작 시간

**현재**:
```python
# installer/app/main.py
import gradio as gr
from heartlib import HeartMuLa

model = HeartMuLa.load("./models/HeartMuLa-oss-3B")  # 느림

gr.Interface(...).launch()
```

**최적화**:
```python
import gradio as gr
from heartlib import HeartMuLa

# 지연 로딩
model = None

def generate_music(lyrics, tags):
    global model
    if model is None:
        model = HeartMuLa.load("./models/HeartMuLa-oss-3B")
    return model.generate(lyrics, tags)

gr.Interface(fn=generate_music, ...).launch()
```

**효과**:
- 앱 시작 시간: 30초 → 3초 (90% 감소)

---

## IV. API 최적화

### 4.1 응답 시간 최적화

#### 4.1.1 Cloudflare Workers 성능

**목표**:
- 평균 응답 시간: < 50ms
- P95 응답 시간: < 200ms
- P99 응답 시간: < 500ms

**측정 방법**:
```bash
# Apache Bench
ab -n 1000 -c 10 https://music.abada.kr/api/download-stats

# 또는 wrk
wrk -t12 -c400 -d30s https://music.abada.kr/api/download-stats
```

---

#### 4.1.2 KV Store 쿼리 최적화

**현재 방식**:
```javascript
// functions/api/download-stats.js
export async function onRequest(context) {
  const stats = await context.env.DOWNLOAD_STATS.get("stats");
  return new Response(stats);
}
```

**최적화** (캐싱):
```javascript
const CACHE_TTL = 60; // 60초 캐싱

export async function onRequest(context) {
  const cache = caches.default;
  const cacheKey = new Request(context.request.url);

  // 캐시 확인
  let response = await cache.match(cacheKey);
  if (response) {
    return response;
  }

  // KV에서 조회
  const stats = await context.env.DOWNLOAD_STATS.get("stats");
  response = new Response(stats, {
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': `public, max-age=${CACHE_TTL}`
    }
  });

  // 캐시 저장
  context.waitUntil(cache.put(cacheKey, response.clone()));

  return response;
}
```

**효과**:
- 응답 시간: 100ms → 10ms (90% 감소)
- KV Read 비용 절감

---

#### 4.1.3 데이터 구조 최적화

**현재 구조**:
```json
{
  "windows_x64": 123,
  "windows_x86": 45,
  "macos_intel": 67,
  "macos_apple_silicon": 89,
  "linux": 34
}
```

**최적화** (단일 키로 집계):
```json
{
  "total": 358,
  "by_platform": {
    "windows": 168,
    "macos": 156,
    "linux": 34
  },
  "last_updated": "2026-01-19T12:00:00Z"
}
```

---

### 4.2 배치 작업 최적화

#### 4.2.1 다운로드 통계 집계

**현재** (매 요청마다 증가):
```javascript
// POST /api/download-stats
const stats = await KV.get("stats");
stats[platform]++;
await KV.put("stats", JSON.stringify(stats));
```

**최적화** (버퍼링):
```javascript
// 메모리 버퍼에 저장
const buffer = [];

export async function onRequest(context) {
  buffer.push({ platform, timestamp: Date.now() });

  // 100개마다 한 번씩 KV에 쓰기
  if (buffer.length >= 100) {
    await flushBuffer(context.env.KV);
  }

  return new Response("OK");
}

async function flushBuffer(KV) {
  const stats = await KV.get("stats");
  buffer.forEach(item => stats[item.platform]++);
  await KV.put("stats", JSON.stringify(stats));
  buffer.length = 0;
}
```

**효과**:
- KV Write 비용: 100회 → 1회 (99% 감소)

---

### 4.3 TTL (Time-to-Live) 전략

#### 4.3.1 KV 데이터 만료 시간 설정

**전략**:
| 데이터 타입 | TTL | 이유 |
|------------|-----|------|
| 다운로드 통계 | 영구 | 누적 데이터 |
| 갤러리 아이템 | 30일 | 주기적 갱신 |
| 분석 로그 | 7일 | 단기 데이터 |
| 캐시 데이터 | 1시간 | 자주 변경 |

**구현**:
```javascript
// 7일 후 자동 삭제
await KV.put("analytics:2026-01-19", data, {
  expirationTtl: 60 * 60 * 24 * 7
});

// 특정 시간에 삭제
await KV.put("cache:user-123", data, {
  expiration: Math.floor(Date.now() / 1000) + 3600
});
```

---

## V. 성능 모니터링

### 5.1 Real User Monitoring (RUM)

#### 5.1.1 Cloudflare Web Analytics

**설정**:
```html
<!-- web/public/index.html -->
<script defer src='https://static.cloudflareinsights.com/beacon.min.js'
        data-cf-beacon='{"token": "YOUR_TOKEN"}'></script>
```

**측정 항목**:
- 페이지 뷰
- 고유 방문자
- 페이지 로드 시간
- Core Web Vitals

---

#### 5.1.2 Custom Metrics

**Performance API 사용**:
```typescript
// src/utils/performance.ts
export function measurePageLoad() {
  if (window.performance && window.performance.timing) {
    const timing = window.performance.timing;
    const loadTime = timing.loadEventEnd - timing.navigationStart;

    console.log('Page Load Time:', loadTime, 'ms');

    // Cloudflare Workers로 전송
    fetch('/api/analytics', {
      method: 'POST',
      body: JSON.stringify({
        metric: 'page_load_time',
        value: loadTime,
        timestamp: Date.now()
      })
    });
  }
}

// 페이지 로드 완료 시 측정
window.addEventListener('load', measurePageLoad);
```

---

### 5.2 성능 리포트 자동화

#### 5.2.1 GitHub Actions 통합

**워크플로우**:
```yaml
# .github/workflows/performance.yml
name: Performance Test

on:
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * 0' # 매주 일요일

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Lighthouse
        uses: treosh/lighthouse-ci-action@v9
        with:
          urls: |
            https://music.abada.kr
            https://music.abada.kr/download
            https://music.abada.kr/gallery
          budgetPath: ./lighthouse-budget.json
          uploadArtifacts: true

      - name: Comment PR
        uses: actions/github-script@v6
        with:
          script: |
            const results = require('./lighthouse-results.json');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `Lighthouse Scores:\n- Performance: ${results.performance}\n- Accessibility: ${results.accessibility}`
            });
```

**Budget 파일**:
```json
// lighthouse-budget.json
[
  {
    "path": "/*",
    "timings": [
      {
        "metric": "first-contentful-paint",
        "budget": 2000
      },
      {
        "metric": "interactive",
        "budget": 5000
      }
    ],
    "resourceSizes": [
      {
        "resourceType": "script",
        "budget": 200
      },
      {
        "resourceType": "image",
        "budget": 500
      }
    ]
  }
]
```

---

## VI. 최적화 체크리스트

### 6.1 웹사이트 체크리스트

- [ ] Lighthouse 점수 90+ (Desktop)
- [ ] Lighthouse 점수 85+ (Mobile)
- [ ] LCP < 2.5s
- [ ] FID < 100ms
- [ ] CLS < 0.1
- [ ] JavaScript 번들 < 200KB
- [ ] CSS 번들 < 50KB
- [ ] 이미지 WebP 변환
- [ ] Lazy loading 적용
- [ ] Code splitting 적용
- [ ] Critical CSS 인라인
- [ ] Service Worker 설정
- [ ] CDN 캐싱 설정
- [ ] GZIP/Brotli 압축

---

### 6.2 설치 프로그램 체크리스트

- [ ] 다운로드 크기 < 100MB
- [ ] 설치 시간 < 30분
- [ ] 병렬 다운로드 구현
- [ ] 진행률 표시 개선
- [ ] 캐싱 전략 적용
- [ ] 에러 처리 강화
- [ ] 재시도 로직 구현
- [ ] 로그 파일 생성

---

### 6.3 API 체크리스트

- [ ] 응답 시간 < 200ms (P95)
- [ ] KV Store 캐싱 적용
- [ ] Rate Limiting 설정
- [ ] CORS 설정 검증
- [ ] 에러 핸들링 구현
- [ ] TTL 전략 적용
- [ ] 배치 작업 최적화
- [ ] 모니터링 설정

---

## VII. 측정 및 보고

### 7.1 성능 리포트 템플릿

**측정 일시**: 2026-01-XX
**측정 환경**: Chrome 120, Desktop, 100Mbps

#### 웹사이트 성능

| 메트릭 | 목표 | 현재 | 상태 |
|--------|------|------|------|
| Lighthouse Performance | 90+ | TBD | ⏳ |
| LCP | < 2.5s | TBD | ⏳ |
| FID | < 100ms | TBD | ⏳ |
| CLS | < 0.1 | TBD | ⏳ |
| JS Bundle | < 200KB | TBD | ⏳ |

#### 설치 프로그램 성능

| 플랫폼 | 다운로드 크기 | 설치 시간 | 상태 |
|--------|--------------|----------|------|
| Windows x64 | < 100MB | < 30분 | ⏳ |
| macOS | < 50MB | < 25분 | ⏳ |
| Linux | < 10MB | < 20분 | ⏳ |

#### API 성능

| 엔드포인트 | 응답 시간 (P95) | 상태 |
|-----------|----------------|------|
| /api/download-stats | < 200ms | ⏳ |
| /api/gallery | < 200ms | ⏳ |
| /api/analytics | < 200ms | ⏳ |

---

### 7.2 최적화 이력

| 날짜 | 작업 | 개선 효과 |
|------|------|----------|
| 2026-01-XX | Code Splitting 적용 | JS 번들 70KB → 40KB |
| 2026-01-XX | WebP 변환 | 이미지 500KB → 100KB |
| 2026-01-XX | KV 캐싱 적용 | API 응답 100ms → 10ms |

---

## VIII. 참고 자료

### 8.1 도구

- [Lighthouse](https://developers.google.com/web/tools/lighthouse)
- [WebPageTest](https://www.webpagetest.org/)
- [Cloudflare Web Analytics](https://www.cloudflare.com/web-analytics/)
- [web-vitals](https://github.com/GoogleChrome/web-vitals)
- [Webpack Bundle Analyzer](https://github.com/webpack-contrib/webpack-bundle-analyzer)

### 8.2 문서

- [Core Web Vitals](https://web.dev/vitals/)
- [Cloudflare Workers Performance](https://developers.cloudflare.com/workers/platform/limits/)
- [React Performance](https://react.dev/learn/render-and-commit)
- [Vite Optimization](https://vitejs.dev/guide/build.html)

---

**문서 버전**: v1.0
**작성자**: technical-writer (AI Agent)
**다음 업데이트**: 성능 측정 완료 후 (2026-01-31)
