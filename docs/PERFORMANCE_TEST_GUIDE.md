# ABADA Music Studio - 성능 테스트 가이드

**버전**: v0.3.0
**작성일**: 2026-01-19
**목표**: 웹사이트, API, 설치 프로그램 성능 최적화

---

## 목차

1. [성능 목표 및 SLA](#성능-목표-및-sla)
2. [웹사이트 성능 테스트](#웹사이트-성능-테스트)
3. [API 성능 테스트](#api-성능-테스트)
4. [번들 사이즈 분석](#번들-사이즈-분석)
5. [데이터베이스 성능](#데이터베이스-성능)
6. [로드 테스트](#로드-테스트)
7. [성능 최적화 전략](#성능-최적화-전략)

---

## 성능 목표 및 SLA

### Core Web Vitals (Google 기준)

| 메트릭 | 목표 (Good) | 경고 (Needs Improvement) | 실패 (Poor) |
|--------|------------|-------------------------|------------|
| **LCP** (Largest Contentful Paint) | < 2.5s | 2.5s - 4.0s | > 4.0s |
| **FID** (First Input Delay) | < 100ms | 100ms - 300ms | > 300ms |
| **CLS** (Cumulative Layout Shift) | < 0.1 | 0.1 - 0.25 | > 0.25 |
| **FCP** (First Contentful Paint) | < 1.8s | 1.8s - 3.0s | > 3.0s |
| **TTFB** (Time To First Byte) | < 600ms | 600ms - 1800ms | > 1800ms |
| **TBT** (Total Blocking Time) | < 200ms | 200ms - 600ms | > 600ms |

### 추가 성능 메트릭

| 메트릭 | 목표 | 측정 방법 |
|--------|------|-----------|
| **Lighthouse Score** | > 90 | Lighthouse CI |
| **Bundle Size (gzipped)** | < 500KB | webpack-bundle-analyzer |
| **API Response Time (p50)** | < 100ms | k6, Grafana |
| **API Response Time (p95)** | < 200ms | k6, Grafana |
| **API Response Time (p99)** | < 500ms | k6, Grafana |
| **Uptime** | 99.9% | Cloudflare Analytics |
| **Error Rate** | < 0.1% | Sentry, Cloudflare Logs |
| **Cache Hit Rate** | > 80% | Cloudflare Analytics |

### SLA (Service Level Agreement)

**가용성**:
- 월간 가동률: 99.9% (최대 43분 다운타임)
- 계획된 유지보수: 월 1회, 최대 2시간

**성능**:
- 웹사이트 로드 시간: 95%ile < 3s
- API 응답 시간: 95%ile < 200ms
- 다운로드 속도: > 5MB/s (CDN 기준)

**복구**:
- MTTR (Mean Time To Repair): < 1시간
- RTO (Recovery Time Objective): < 30분
- RPO (Recovery Point Objective): < 5분

---

## 웹사이트 성능 테스트

### 1. Lighthouse 성능 감사

#### 설치 및 실행

```bash
# Lighthouse CLI 설치
npm install -g lighthouse

# 단일 페이지 테스트
lighthouse https://music.abada.kr \
  --output html \
  --output json \
  --output-path ./reports/lighthouse-report \
  --chrome-flags="--headless"

# 모든 페이지 테스트
PAGES=("/" "/download" "/tutorial" "/gallery" "/faq" "/about")
for page in "${PAGES[@]}"; do
  lighthouse "https://music.abada.kr$page" \
    --output json \
    --output-path "./reports/lighthouse-$page.json"
done
```

#### Lighthouse CI 통합

```yaml
# .github/workflows/lighthouse-ci.yml
name: Lighthouse CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Build website
        run: |
          cd web
          npm run build

      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v10
        with:
          urls: |
            https://music.abada.kr/
            https://music.abada.kr/download
            https://music.abada.kr/tutorial
            https://music.abada.kr/gallery
            https://music.abada.kr/faq
            https://music.abada.kr/about
          uploadArtifacts: true
          temporaryPublicStorage: true
```

#### Lighthouse 설정 파일

```javascript
// lighthouserc.js
module.exports = {
  ci: {
    collect: {
      numberOfRuns: 5,
      startServerCommand: 'npm run serve',
      url: [
        'http://localhost:3000/',
        'http://localhost:3000/download',
        'http://localhost:3000/tutorial',
        'http://localhost:3000/gallery',
        'http://localhost:3000/faq',
        'http://localhost:3000/about',
      ],
    },
    assert: {
      preset: 'lighthouse:recommended',
      assertions: {
        'categories:performance': ['error', { minScore: 0.9 }],
        'categories:accessibility': ['error', { minScore: 0.95 }],
        'categories:best-practices': ['error', { minScore: 0.95 }],
        'categories:seo': ['error', { minScore: 0.95 }],
        'first-contentful-paint': ['error', { maxNumericValue: 1800 }],
        'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
        'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }],
        'total-blocking-time': ['error', { maxNumericValue: 200 }],
      },
    },
    upload: {
      target: 'temporary-public-storage',
    },
  },
};
```

### 2. PageSpeed Insights API

```bash
# PageSpeed Insights API 키 필요 (Google Cloud Console)
API_KEY="YOUR_API_KEY"
URL="https://music.abada.kr"

curl "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=$URL&key=$API_KEY&strategy=mobile" \
  | jq '.lighthouseResult.categories.performance.score * 100'
```

**자동화 스크립트**:

```python
# scripts/pagespeed_test.py
import requests
import json
import sys

API_KEY = "YOUR_API_KEY"
PAGES = [
    "https://music.abada.kr/",
    "https://music.abada.kr/download",
    "https://music.abada.kr/tutorial",
    "https://music.abada.kr/gallery",
    "https://music.abada.kr/faq",
    "https://music.abada.kr/about",
]

THRESHOLD = 90  # Minimum score

def test_page(url, strategy='mobile'):
    api_url = f"https://www.googleapis.com/pagespeedonline/v5/runPagespeed"
    params = {
        'url': url,
        'key': API_KEY,
        'strategy': strategy,
    }

    response = requests.get(api_url, params=params)
    data = response.json()

    if 'lighthouseResult' not in data:
        print(f"❌ Error testing {url}: {data.get('error', 'Unknown error')}")
        return None

    result = data['lighthouseResult']
    categories = result['categories']

    scores = {
        'performance': categories['performance']['score'] * 100,
        'accessibility': categories['accessibility']['score'] * 100,
        'best-practices': categories['best-practices']['score'] * 100,
        'seo': categories['seo']['score'] * 100,
    }

    audits = result['audits']
    metrics = {
        'fcp': audits['first-contentful-paint']['numericValue'],
        'lcp': audits['largest-contentful-paint']['numericValue'],
        'cls': audits['cumulative-layout-shift']['numericValue'],
        'tbt': audits['total-blocking-time']['numericValue'],
    }

    return {'scores': scores, 'metrics': metrics}

def main():
    results = {}
    failed = False

    for page in PAGES:
        print(f"Testing {page} (mobile)...")
        result = test_page(page, 'mobile')

        if result is None:
            failed = True
            continue

        results[page] = result

        # 점수 출력
        print(f"  Performance: {result['scores']['performance']:.1f}")
        print(f"  Accessibility: {result['scores']['accessibility']:.1f}")
        print(f"  Best Practices: {result['scores']['best-practices']:.1f}")
        print(f"  SEO: {result['scores']['seo']:.1f}")
        print(f"  FCP: {result['metrics']['fcp']:.0f}ms")
        print(f"  LCP: {result['metrics']['lcp']:.0f}ms")
        print(f"  CLS: {result['metrics']['cls']:.3f}")
        print(f"  TBT: {result['metrics']['tbt']:.0f}ms")

        # 임계값 확인
        if result['scores']['performance'] < THRESHOLD:
            print(f"  ❌ Performance score below threshold ({THRESHOLD})")
            failed = True
        else:
            print(f"  ✅ All scores passed")

        print()

    # 결과 저장
    with open('reports/pagespeed_results.json', 'w') as f:
        json.dump(results, f, indent=2)

    if failed:
        print("❌ Some tests failed")
        sys.exit(1)
    else:
        print("✅ All tests passed")
        sys.exit(0)

if __name__ == '__main__':
    main()
```

### 3. WebPageTest

```bash
# WebPageTest API (선택 사항)
API_KEY="YOUR_WEBPAGETEST_API_KEY"
URL="https://music.abada.kr"

curl "https://www.webpagetest.org/runtest.php?url=$URL&k=$API_KEY&f=json&location=ec2-us-east-1:Chrome&runs=3&fvonly=1" \
  | jq '.data.testId'

# 결과 조회
TEST_ID="240119_ABC123"
curl "https://www.webpagetest.org/jsonResult.php?test=$TEST_ID" \
  | jq '.data.average.firstView.loadTime'
```

**테스트 위치**:
- 북미: `ec2-us-east-1:Chrome`
- 유럽: `ec2-eu-west-1:Chrome`
- 아시아: `ec2-ap-northeast-1:Chrome` (서울)

---

## API 성능 테스트

### 1. k6 로드 테스트

#### 설치

```bash
# macOS
brew install k6

# Windows
choco install k6

# Linux
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

#### 기본 로드 테스트

```javascript
// tests/performance/load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '1m', target: 50 },   // Ramp-up to 50 users
    { duration: '3m', target: 50 },   // Stay at 50 users
    { duration: '1m', target: 100 },  // Ramp-up to 100 users
    { duration: '3m', target: 100 },  // Stay at 100 users
    { duration: '1m', target: 0 },    // Ramp-down to 0 users
  ],
  thresholds: {
    'http_req_duration': ['p(95)<200'], // 95%ile < 200ms
    'http_req_failed': ['rate<0.01'],   // Error rate < 1%
    'errors': ['rate<0.01'],
  },
};

export default function () {
  // Homepage
  let res = http.get('https://music.abada.kr/');
  check(res, {
    'homepage status is 200': (r) => r.status === 200,
    'homepage load time < 2s': (r) => r.timings.duration < 2000,
  }) || errorRate.add(1);
  sleep(1);

  // Download page
  res = http.get('https://music.abada.kr/download');
  check(res, {
    'download page status is 200': (r) => r.status === 200,
    'download page load time < 2s': (r) => r.timings.duration < 2000,
  }) || errorRate.add(1);
  sleep(2);

  // Download stats API
  const payload = JSON.stringify({
    os: 'windows',
    version: 'v1.0.0',
    timestamp: new Date().toISOString(),
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  res = http.post('https://music.abada.kr/api/download-stats', payload, params);
  check(res, {
    'API status is 201': (r) => r.status === 201,
    'API response time < 200ms': (r) => r.timings.duration < 200,
  }) || errorRate.add(1);
  sleep(1);

  // Gallery API
  res = http.get('https://music.abada.kr/api/gallery?limit=10&offset=0');
  check(res, {
    'Gallery API status is 200': (r) => r.status === 200,
    'Gallery API response time < 200ms': (r) => r.timings.duration < 200,
    'Gallery API returns items': (r) => JSON.parse(r.body).items.length > 0,
  }) || errorRate.add(1);
  sleep(1);
}
```

#### 실행 및 결과

```bash
# 로컬 실행
k6 run tests/performance/load-test.js

# 클라우드 실행 (k6 Cloud)
k6 cloud tests/performance/load-test.js

# 결과를 JSON으로 저장
k6 run --out json=reports/load-test-results.json tests/performance/load-test.js

# InfluxDB + Grafana 연동
k6 run --out influxdb=http://localhost:8086/k6 tests/performance/load-test.js
```

**출력 예시**:

```
     ✓ homepage status is 200
     ✓ homepage load time < 2s
     ✓ download page status is 200
     ✓ download page load time < 2s
     ✓ API status is 201
     ✓ API response time < 200ms
     ✓ Gallery API status is 200
     ✓ Gallery API response time < 200ms
     ✓ Gallery API returns items

     checks.........................: 100.00% ✓ 45000 ✗ 0
     data_received..................: 150 MB  500 kB/s
     data_sent......................: 30 MB   100 kB/s
     http_req_blocked...............: avg=1.2ms   min=0ms   med=1ms   max=50ms  p(90)=2ms   p(95)=3ms
     http_req_connecting............: avg=0.8ms   min=0ms   med=0.5ms max=30ms  p(90)=1.5ms p(95)=2ms
     http_req_duration..............: avg=120ms   min=50ms  med=100ms max=500ms p(90)=180ms p(95)=200ms
     http_req_failed................: 0.00%   ✓ 0     ✗ 5000
     http_req_receiving.............: avg=2ms     min=0.5ms med=1.5ms max=20ms  p(90)=3ms   p(95)=5ms
     http_req_sending...............: avg=1ms     min=0.2ms med=0.8ms max=10ms  p(90)=1.5ms p(95)=2ms
     http_req_tls_handshaking.......: avg=0.5ms   min=0ms   med=0ms   max=10ms  p(90)=1ms   p(95)=2ms
     http_req_waiting...............: avg=117ms   min=48ms  med=98ms  max=495ms p(90)=177ms p(95)=197ms
     http_reqs......................: 5000    16.67/s
     iteration_duration.............: avg=6s      min=5.5s  med=6s    max=7s    p(90)=6.2s  p(95)=6.5s
     iterations.....................: 1000    3.33/s
     vus............................: 100     min=0   max=100
     vus_max........................: 100     min=100 max=100
```

### 2. 스트레스 테스트 (Spike Test)

```javascript
// tests/performance/stress-test.js
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 100 },   // Ramp-up to 100 users
    { duration: '1m', target: 500 },    // Spike to 500 users
    { duration: '3m', target: 500 },    // Stay at 500 users
    { duration: '30s', target: 1000 },  // Spike to 1000 users
    { duration: '2m', target: 1000 },   // Stay at 1000 users
    { duration: '1m', target: 0 },      // Ramp-down
  ],
  thresholds: {
    'http_req_duration': ['p(99)<1000'], // 99%ile < 1s (더 관대한 기준)
    'http_req_failed': ['rate<0.05'],    // Error rate < 5% (스트레스 상황)
  },
};

export default function () {
  const res = http.get('https://music.abada.kr/');
  check(res, {
    'status is 200 or 503': (r) => r.status === 200 || r.status === 503,
  });
}
```

### 3. Soak Test (내구성 테스트)

```javascript
// tests/performance/soak-test.js
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  stages: [
    { duration: '5m', target: 50 },   // Ramp-up to 50 users
    { duration: '1h', target: 50 },   // Stay at 50 users for 1 hour
    { duration: '5m', target: 0 },    // Ramp-down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<200'],
    'http_req_failed': ['rate<0.01'],
  },
};

export default function () {
  http.get('https://music.abada.kr/');
  http.get('https://music.abada.kr/api/gallery?limit=10');
}
```

### 4. API 별 벤치마크

```javascript
// tests/performance/api-benchmark.js
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: {
    download_stats_post: {
      executor: 'constant-arrival-rate',
      rate: 100, // 100 RPS
      timeUnit: '1s',
      duration: '1m',
      preAllocatedVUs: 10,
      exec: 'downloadStatsPost',
    },
    download_stats_get: {
      executor: 'constant-arrival-rate',
      rate: 200, // 200 RPS
      timeUnit: '1s',
      duration: '1m',
      preAllocatedVUs: 10,
      exec: 'downloadStatsGet',
    },
    gallery_get: {
      executor: 'constant-arrival-rate',
      rate: 150, // 150 RPS
      timeUnit: '1s',
      duration: '1m',
      preAllocatedVUs: 10,
      exec: 'galleryGet',
    },
  },
  thresholds: {
    'http_req_duration{scenario:download_stats_post}': ['p(95)<200'],
    'http_req_duration{scenario:download_stats_get}': ['p(95)<100'],
    'http_req_duration{scenario:gallery_get}': ['p(95)<200'],
  },
};

export function downloadStatsPost() {
  const payload = JSON.stringify({
    os: 'windows',
    version: 'v1.0.0',
    timestamp: new Date().toISOString(),
  });

  const res = http.post('https://music.abada.kr/api/download-stats', payload, {
    headers: { 'Content-Type': 'application/json' },
  });

  check(res, {
    'status is 201': (r) => r.status === 201,
    'response time < 200ms': (r) => r.timings.duration < 200,
  });
}

export function downloadStatsGet() {
  const res = http.get('https://music.abada.kr/api/download-stats');

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 100ms': (r) => r.timings.duration < 100,
  });
}

export function galleryGet() {
  const res = http.get('https://music.abada.kr/api/gallery?limit=10&offset=0');

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
    'returns items': (r) => JSON.parse(r.body).items.length > 0,
  });
}
```

---

## 번들 사이즈 분석

### 1. webpack-bundle-analyzer

```bash
# 설치
cd web
npm install --save-dev webpack-bundle-analyzer

# package.json에 스크립트 추가
# "analyze": "vite-bundle-visualizer"
npm install --save-dev vite-bundle-visualizer

# 실행
npm run build
npx vite-bundle-visualizer
```

**Vite 설정**:

```javascript
// web/vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig({
  plugins: [
    react(),
    visualizer({
      filename: './dist/stats.html',
      open: true,
      gzipSize: true,
      brotliSize: true,
    }),
  ],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor-react': ['react', 'react-dom', 'react-router-dom'],
          'vendor-ui': ['tailwindcss'],
        },
      },
    },
  },
});
```

### 2. Bundle Size 목표

| 리소스 | Gzipped | Uncompressed | 우선순위 |
|--------|---------|--------------|---------|
| **Main JS** | < 150KB | < 500KB | High |
| **Vendor JS** | < 200KB | < 800KB | High |
| **CSS** | < 50KB | < 200KB | Medium |
| **Total** | < 500KB | < 2MB | High |

### 3. Code Splitting 전략

```javascript
// web/src/App.tsx
import React, { lazy, Suspense } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';

// Lazy load pages
const HomePage = lazy(() => import('./pages/HomePage'));
const DownloadPage = lazy(() => import('./pages/DownloadPage'));
const TutorialPage = lazy(() => import('./pages/TutorialPage'));
const GalleryPage = lazy(() => import('./pages/GalleryPage'));
const FAQPage = lazy(() => import('./pages/FAQPage'));
const AboutPage = lazy(() => import('./pages/AboutPage'));

function App() {
  return (
    <BrowserRouter>
      <Suspense fallback={<div>Loading...</div>}>
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/download" element={<DownloadPage />} />
          <Route path="/tutorial" element={<TutorialPage />} />
          <Route path="/gallery" element={<GalleryPage />} />
          <Route path="/faq" element={<FAQPage />} />
          <Route path="/about" element={<AboutPage />} />
        </Routes>
      </Suspense>
    </BrowserRouter>
  );
}

export default App;
```

### 4. Tree Shaking 확인

```bash
# Build production bundle
npm run build

# Analyze bundle size
du -sh dist/*

# Check for unused code
npx webpack-bundle-analyzer dist/stats.json
```

### 5. 번들 사이즈 모니터링 (CI/CD)

```yaml
# .github/workflows/bundle-size.yml
name: Bundle Size Check

on:
  pull_request:
    branches: [main]

jobs:
  check-bundle-size:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install dependencies
        run: |
          cd web
          npm ci

      - name: Build
        run: |
          cd web
          npm run build

      - name: Check bundle size
        uses: andresz1/size-limit-action@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          directory: web
          skip_step: install
```

**size-limit 설정**:

```json
// web/package.json
{
  "size-limit": [
    {
      "name": "Main Bundle",
      "path": "dist/assets/index-*.js",
      "limit": "150 KB",
      "gzip": true
    },
    {
      "name": "Vendor Bundle",
      "path": "dist/assets/vendor-*.js",
      "limit": "200 KB",
      "gzip": true
    },
    {
      "name": "CSS Bundle",
      "path": "dist/assets/index-*.css",
      "limit": "50 KB",
      "gzip": true
    }
  ]
}
```

---

## 데이터베이스 성능

### 1. Cloudflare KV Store 벤치마크

```javascript
// tests/performance/kv-benchmark.js
export default {
  async fetch(request, env, ctx) {
    const start = Date.now();

    // Write test
    const writes = [];
    for (let i = 0; i < 100; i++) {
      writes.push(
        env.DOWNLOAD_STATS.put(`test-${i}`, JSON.stringify({
          os: 'windows',
          version: 'v1.0.0',
          timestamp: new Date().toISOString(),
        }))
      );
    }
    await Promise.all(writes);
    const writeTime = Date.now() - start;

    // Read test
    const readStart = Date.now();
    const reads = [];
    for (let i = 0; i < 100; i++) {
      reads.push(env.DOWNLOAD_STATS.get(`test-${i}`));
    }
    await Promise.all(reads);
    const readTime = Date.now() - readStart;

    // Cleanup
    const deletes = [];
    for (let i = 0; i < 100; i++) {
      deletes.push(env.DOWNLOAD_STATS.delete(`test-${i}`));
    }
    await Promise.all(deletes);

    return new Response(JSON.stringify({
      writeTime,
      readTime,
      avgWriteTime: writeTime / 100,
      avgReadTime: readTime / 100,
    }), {
      headers: { 'Content-Type': 'application/json' },
    });
  },
};
```

**예상 결과**:
- 평균 쓰기 시간: < 50ms
- 평균 읽기 시간: < 10ms (캐싱)
- 동시 쓰기: 100개 < 500ms

### 2. KV Store 캐싱 전략

```javascript
// functions/api/gallery.js
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const cacheKey = url.pathname + url.search;

    // Check cache first
    const cache = caches.default;
    let response = await cache.match(cacheKey);

    if (response) {
      console.log('Cache hit');
      return response;
    }

    console.log('Cache miss');

    // Query KV Store
    const data = await env.GALLERY_DATA.get('items', { type: 'json' });

    // Create response
    response = new Response(JSON.stringify(data), {
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=3600', // 1 hour
        'CDN-Cache-Control': 'public, max-age=86400', // 24 hours
      },
    });

    // Store in cache
    ctx.waitUntil(cache.put(cacheKey, response.clone()));

    return response;
  },
};
```

---

## 로드 테스트

### 1. 시나리오 기반 테스트

```javascript
// tests/performance/user-journey-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    typical_user: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 100 },
        { duration: '5m', target: 100 },
        { duration: '2m', target: 0 },
      ],
      gracefulRampDown: '30s',
    },
  },
};

export default function () {
  // 1. Visit homepage
  let res = http.get('https://music.abada.kr/');
  check(res, { 'homepage loaded': (r) => r.status === 200 });
  sleep(3); // User reads content

  // 2. Navigate to download page
  res = http.get('https://music.abada.kr/download');
  check(res, { 'download page loaded': (r) => r.status === 200 });
  sleep(5); // User reads instructions

  // 3. Record download intent (but not actual download)
  res = http.post(
    'https://music.abada.kr/api/download-stats',
    JSON.stringify({
      os: 'windows',
      version: 'v1.0.0',
      timestamp: new Date().toISOString(),
    }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  check(res, { 'download recorded': (r) => r.status === 201 });
  sleep(2);

  // 4. Browse gallery
  res = http.get('https://music.abada.kr/gallery');
  check(res, { 'gallery loaded': (r) => r.status === 200 });
  sleep(10); // User listens to music

  // 5. Load more gallery items
  res = http.get('https://music.abada.kr/api/gallery?limit=12&offset=12');
  check(res, { 'gallery API responded': (r) => r.status === 200 });
  sleep(5);

  // 6. Check FAQ
  res = http.get('https://music.abada.kr/faq');
  check(res, { 'faq loaded': (r) => r.status === 200 });
  sleep(3);
}
```

### 2. 릴리즈 당일 시뮬레이션

```javascript
// tests/performance/release-day-test.js
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: {
    release_spike: {
      executor: 'ramping-arrival-rate',
      startRate: 10,
      timeUnit: '1s',
      preAllocatedVUs: 50,
      maxVUs: 1000,
      stages: [
        { duration: '5m', target: 50 },    // 50 RPS
        { duration: '10m', target: 200 },  // 200 RPS (Spike)
        { duration: '30m', target: 100 },  // 100 RPS (Sustained)
        { duration: '10m', target: 20 },   // 20 RPS (Cool down)
      ],
    },
  },
  thresholds: {
    'http_req_duration': ['p(99)<1000'],
    'http_req_failed': ['rate<0.05'],
  },
};

export default function () {
  // Most users go to homepage or download page
  const pages = [
    'https://music.abada.kr/',
    'https://music.abada.kr/download',
  ];
  const page = pages[Math.floor(Math.random() * pages.length)];

  const res = http.get(page);
  check(res, {
    'status is 200 or cached': (r) => r.status === 200 || r.status === 304,
  });
}
```

### 3. Cloudflare Workers 부하 테스트

```javascript
// tests/performance/workers-stress-test.js
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: {
    api_stress: {
      executor: 'constant-arrival-rate',
      rate: 1000, // 1000 RPS
      timeUnit: '1s',
      duration: '5m',
      preAllocatedVUs: 100,
      maxVUs: 500,
    },
  },
  thresholds: {
    'http_req_duration': ['p(95)<200', 'p(99)<500'],
    'http_req_failed': ['rate<0.01'],
  },
};

const API_ENDPOINTS = [
  'https://music.abada.kr/api/download-stats',
  'https://music.abada.kr/api/gallery',
  'https://music.abada.kr/api/analytics',
];

export default function () {
  const endpoint = API_ENDPOINTS[Math.floor(Math.random() * API_ENDPOINTS.length)];

  let res;
  if (endpoint.includes('download-stats') || endpoint.includes('analytics')) {
    // POST request
    res = http.post(
      endpoint,
      JSON.stringify({
        os: 'windows',
        version: 'v1.0.0',
        timestamp: new Date().toISOString(),
      }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } else {
    // GET request
    res = http.get(endpoint);
  }

  check(res, {
    'status is 2xx': (r) => r.status >= 200 && r.status < 300,
    'response time acceptable': (r) => r.timings.duration < 500,
  });
}
```

---

## 성능 최적화 전략

### 1. 프론트엔드 최적화

#### 이미지 최적화

```javascript
// web/vite.config.ts
import imagemin from 'vite-plugin-imagemin';

export default defineConfig({
  plugins: [
    imagemin({
      gifsicle: { optimizationLevel: 7 },
      optipng: { optimizationLevel: 7 },
      mozjpeg: { quality: 80 },
      pngquant: { quality: [0.8, 0.9], speed: 4 },
      svgo: {
        plugins: [
          { name: 'removeViewBox', active: false },
          { name: 'removeEmptyAttrs', active: true },
        ],
      },
    }),
  ],
});
```

**WebP 변환**:

```bash
# Install cwebp
brew install webp  # macOS
sudo apt install webp  # Ubuntu

# Convert images
for img in public/images/*.jpg; do
  cwebp -q 80 "$img" -o "${img%.jpg}.webp"
done
```

#### Lazy Loading

```javascript
// web/src/components/GalleryItem.tsx
import React from 'react';

function GalleryItem({ item }) {
  return (
    <div className="gallery-item">
      <img
        src={item.thumbnailUrl}
        alt={item.title}
        loading="lazy"
        decoding="async"
        width="300"
        height="200"
      />
    </div>
  );
}
```

#### 폰트 최적화

```html
<!-- web/index.html -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link
  href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap"
  rel="stylesheet"
>

<!-- Or self-host fonts -->
<link rel="preload" href="/fonts/Inter-Regular.woff2" as="font" type="font/woff2" crossorigin>
```

#### CSS 최적화

```bash
# Remove unused CSS with PurgeCSS
npm install --save-dev @fullhuman/postcss-purgecss

# PostCSS config
# web/postcss.config.js
module.exports = {
  plugins: [
    require('tailwindcss'),
    require('autoprefixer'),
    ...(process.env.NODE_ENV === 'production'
      ? [
          require('@fullhuman/postcss-purgecss')({
            content: ['./src/**/*.{js,jsx,ts,tsx}', './index.html'],
            defaultExtractor: content => content.match(/[\w-/:]+(?<!:)/g) || [],
          }),
        ]
      : []),
  ],
};
```

### 2. 백엔드 최적화 (Cloudflare Workers)

#### 응답 압축

```javascript
// functions/api/gallery.js
import { gzip } from 'pako';

export default {
  async fetch(request, env, ctx) {
    const data = await env.GALLERY_DATA.get('items', { type: 'json' });
    const jsonStr = JSON.stringify(data);

    // Compress response
    const compressed = gzip(jsonStr);

    return new Response(compressed, {
      headers: {
        'Content-Type': 'application/json',
        'Content-Encoding': 'gzip',
        'Cache-Control': 'public, max-age=3600',
      },
    });
  },
};
```

#### Edge Caching

```javascript
// functions/api/download-stats.js
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // GET requests can be cached
    if (request.method === 'GET') {
      const cacheKey = new Request(url.toString(), request);
      const cache = caches.default;

      let response = await cache.match(cacheKey);
      if (response) {
        return response;
      }

      // Fetch from KV
      const stats = await env.DOWNLOAD_STATS.get('stats', { type: 'json' });
      response = new Response(JSON.stringify(stats), {
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'public, max-age=300', // 5 minutes
        },
      });

      ctx.waitUntil(cache.put(cacheKey, response.clone()));
      return response;
    }

    // POST requests...
  },
};
```

#### Rate Limiting

```javascript
// functions/api/_middleware.js
export async function onRequest(context) {
  const { request, env } = context;
  const ip = request.headers.get('CF-Connecting-IP');

  // Check rate limit (100 req/min per IP)
  const key = `ratelimit:${ip}`;
  const count = await env.RATE_LIMIT.get(key);

  if (count && parseInt(count) > 100) {
    return new Response('Too Many Requests', {
      status: 429,
      headers: {
        'Retry-After': '60',
      },
    });
  }

  // Increment counter
  await env.RATE_LIMIT.put(key, (parseInt(count || 0) + 1).toString(), {
    expirationTtl: 60,
  });

  return context.next();
}
```

### 3. CDN 최적화

#### Cloudflare Page Rules

```yaml
# Cloudflare 설정 (Dashboard)
Page Rules:
  - URL: music.abada.kr/assets/*
    Cache Level: Cache Everything
    Edge Cache TTL: 1 month

  - URL: music.abada.kr/api/*
    Cache Level: Bypass
    Browser Cache TTL: Respect Existing Headers

  - URL: music.abada.kr/*
    Cache Level: Standard
    Browser Cache TTL: 4 hours
```

#### 캐시 무효화

```bash
# Purge cache via API
curl -X POST "https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/purge_cache" \
  -H "Authorization: Bearer {API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}'

# Purge specific files
curl -X POST "https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/purge_cache" \
  -H "Authorization: Bearer {API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"files":["https://music.abada.kr/assets/main.js"]}'
```

---

## 성능 모니터링 대시보드

### 1. Grafana + InfluxDB

```yaml
# docker-compose.yml
version: '3.8'
services:
  influxdb:
    image: influxdb:2.7
    ports:
      - "8086:8086"
    volumes:
      - influxdb-data:/var/lib/influxdb2
    environment:
      - DOCKER_INFLUXDB_INIT_MODE=setup
      - DOCKER_INFLUXDB_INIT_USERNAME=admin
      - DOCKER_INFLUXDB_INIT_PASSWORD=password
      - DOCKER_INFLUXDB_INIT_ORG=abada
      - DOCKER_INFLUXDB_INIT_BUCKET=k6

  grafana:
    image: grafana/grafana:10.2.0
    ports:
      - "3001:3000"
    volumes:
      - grafana-data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    depends_on:
      - influxdb

volumes:
  influxdb-data:
  grafana-data:
```

**k6 → InfluxDB 연동**:

```bash
k6 run --out influxdb=http://localhost:8086/k6 tests/performance/load-test.js
```

### 2. Cloudflare Analytics

```javascript
// Cloudflare Analytics API
const ZONE_ID = 'YOUR_ZONE_ID';
const API_TOKEN = 'YOUR_API_TOKEN';

const query = `
  query {
    viewer {
      zones(filter: {zoneTag: "${ZONE_ID}"}) {
        httpRequests1dGroups(limit: 30, filter: {datetime_gt: "2026-01-01T00:00:00Z"}) {
          sum {
            requests
            bytes
            cachedBytes
            threats
          }
          dimensions {
            date
          }
        }
      }
    }
  }
`;

const response = await fetch('https://api.cloudflare.com/client/v4/graphql', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${API_TOKEN}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ query }),
});

const data = await response.json();
console.log(data);
```

---

**문서 버전**: 1.0.0
**마지막 업데이트**: 2026-01-19
**다음 리뷰**: 2026-02-01
