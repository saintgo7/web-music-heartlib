# ABADA Music Studio - 통합 서비스 마스터 플랜

**문서 버전**: v2.0 (2026-01-18)
**프로젝트명**: ABADA Music Studio - AI 음악 생성 플랫폼
**슬로건**: "내 컴퓨터에서 나만의 음악을 만든다"
**담당사**: ABADA Inc.

---

## I. 프로젝트 개요

### 1.1 프로젝트 비전

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  Open Source AI를 일반인도 쉽게 사용하게 하는 것            │
│  + ABADA 브랜드 홍보 = 강력한 마케팅 플랫폼                │
│                                                             │
│  HeartMuLa (Open Source AI 음악생성)                       │
│  ↓                                                          │
│  ABADA Music Studio (One-Click Installer)                 │
│  ↓                                                          │
│  music.abada.kr (웹사이트)                                 │
│  ↓                                                          │
│  사용자 커뮤니티 + 샘플 갤러리                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 핵심 목표 (3단계)

**PHASE 1: 설치 프로그램 (4주)**
- Windows x64/x86, macOS, Linux 설치 프로그램 완성
- 더블클릭으로 자동 설치 가능
- 결과: 3개 OS × 2-3개 플랫폼 = 총 5개 배포 파일

**PHASE 2: 웹사이트 (2주)**
- music.abada.kr 홈페이지 개발
- Cloudflare Pages + GitHub Pages 연동
- 다운로드, 튜토리얼, 갤러리 기능

**PHASE 3: 마케팅 (지속)**
- pamout.co.kr 연동
- ABADA 회사 홍보 극대화
- 샘플 갤러리, 사용자 커뮤니티

### 1.3 비즈니스 가치

| 측면 | 가치 |
|------|------|
| **브랜드** | Open Source AI 보급에 선두 역할 = ABADA 이미지 상승 |
| **기술** | 자동화 설치 기술로 업계 기준 제시 |
| **마케팅** | "쉬운 AI" = 일반인 접근성 ↑ = 브랜드 인지도 ↑ |
| **비용** | 100% 무료 서비스 활용 (Cloudflare, GitHub, HuggingFace) |
| **확장성** | 향후 SaaS 서비스로 확장 가능 |

---

## II. 기술 아키텍처

### 2.1 전체 구성도

```
┌──────────────────────────────────────────────────────────────┐
│                    사용자 경험 (User Journey)                 │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  [1] music.abada.kr 방문                                    │
│      ↓                                                       │
│  [2] "다운로드" 클릭                                         │
│      ↓                                                       │
│  [3] OS별 설치 프로그램 선택 (exe/dmg/sh)                  │
│      ↓                                                       │
│  [4] 자동 설치 (15-30분)                                    │
│      ↓                                                       │
│  [5] "MuLa Studio" 실행                                     │
│      ↓                                                       │
│  [6] 웹브라우저 > Gradio UI                                 │
│      ↓                                                       │
│  [7] 가사 + 태그 입력 > 음악 생성                           │
│      ↓                                                       │
│  [8] ~/MuLaStudio_Outputs 폴더에 MP3 저장                  │
│      ↓                                                       │
│  [9] (선택) music.abada.kr 갤러리에 공유                   │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 기술 스택

| 계층 | 기술 | 설명 |
|------|------|------|
| **웹사이트** | Cloudflare Pages + React | 정적 호스팅 (무료) |
| **설치프로그램** | NSIS (Win), Shell (Mac/Linux) | 크로스플랫폼 배포 |
| **AI 모델** | HeartMuLa (HuggingFace) | 음악 생성 API |
| **UI 프레임워크** | Gradio | 사용자 인터페이스 |
| **배포** | GitHub Releases | 설치파일 호스팅 |
| **데이터** | music.abada.kr/data | 모델 캐시 서버 |
| **CDN** | Cloudflare | 글로벌 배포 가속 |

### 2.3 파일 흐름도

```
GitHub Repository (heartlib)
├── /docs/MASTER_PLAN.md (이 파일)
├── /installer/
│   ├── windows/
│   │   ├── MuLaInstaller.nsi
│   │   └── python-embed/
│   ├── macos/
│   │   └── install.sh
│   └── linux/
│       └── mula_install.sh
├── /web/
│   ├── src/
│   │   ├── index.html
│   │   ├── download.html
│   │   ├── gallery.html
│   │   └── tutorial.html
│   └── public/
│       ├── logo.svg
│       └── screenshots/
└── /models/
    └── cache/ (로컬 캐시)
        ├── HeartMuLa-oss-3B/
        └── HeartCodec-oss/

↓ (GitHub Actions 자동 빌드)

GitHub Releases v1.0.0
├── MuLa_Setup_x64.exe (~80MB)
├── MuLa_Setup_x86.exe (~80MB)
├── MuLa_Installer.dmg (~50MB)
├── mula_install.sh (~5KB)
└── README.md + checksums.txt

↓ (Cloudflare Pages 배포)

music.abada.kr (웹사이트)
├── index.html (홈페이지)
├── download/ (다운로드 링크)
├── gallery/ (샘플 갤러리)
├── tutorial/ (튜토리얼)
└── api/ (Cloudflare Workers)
    └── stat.js (다운로드 통계)
```

---

## III. 웹사이트 (music.abada.kr)

### 3.1 웹사이트 구조

#### 3.1.1 페이지 구성

| 페이지 | 목적 | 기술 |
|--------|------|------|
| **Home** | 제품 소개 및 CTA | React + Tailwind |
| **Download** | OS별 다운로드 링크 | Static HTML |
| **Tutorial** | 설치/사용 가이드 | Markdown |
| **Gallery** | 생성된 음악 샘플 | Image Grid + Audio |
| **FAQ** | 자주 묻는 질문 | Accordion |
| **About** | ABADA 소개 | 텍스트 + 로고 |

#### 3.1.2 홈페이지 와이어프레임

```
┌─────────────────────────────────────────────────────────────┐
│ ABADA Music Studio                    [Download] [About]     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                                                      │  │
│  │  🎵 AI로 나만의 음악을 만든다                       │  │
│  │  한 번의 클릭으로 시작하는 음악 생성               │  │
│  │                                                      │  │
│  │         [다운로드하기] [튜토리얼 보기]              │  │
│  │                                                      │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌────────────────┬────────────────┬────────────────┐     │
│  │  3가지 특징    │                │                │     │
│  ├────────────────┼────────────────┼────────────────┤     │
│  │ ⚡ 빠른 설치   │ 🆓 완전 무료   │ 💻 오프라인   │     │
│  │ One-Click     │ Open Source   │ 인터넷 불필요 │     │
│  └────────────────┴────────────────┴────────────────┘     │
│                                                             │
│  [사용자 생성 갤러리 - 샘플 곡 5개]                        │
│                                                             │
│  [시스템 요구사항]  [FAQ]  [커뮤니티]                       │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ABADA Inc. © 2026 | CC BY-NC 4.0                   │   │
│  │ Powered by HeartMuLa & Open Source AI              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 기술 구현

#### 3.2.1 Cloudflare Pages 설정

**배포 방식**: GitHub ↔ Cloudflare Pages (자동)

```yaml
# cloudflare.toml
[env.production]
routes = [
  { pattern = "music.abada.kr/*", zone_name = "abada.kr" }
]

[build]
command = "npm run build"
output_dir = "build/"
root_dir = "web/"

[env.production.build]
command = "npm run build:production"

# 캐시 설정
[caching]
default_cache_ttl = 14400  # 4시간
browser_cache_ttl = 1800   # 30분
```

#### 3.2.2 웹사이트 파일 구조

```
web/
├── public/
│   ├── index.html
│   ├── download.html
│   ├── gallery.html
│   ├── tutorial.html
│   ├── faq.html
│   └── about.html
├── src/
│   ├── styles/
│   │   └── main.css (Tailwind)
│   ├── js/
│   │   ├── download.js (다운로드 통계)
│   │   ├── gallery.js (이미지/오디오 로드)
│   │   └── utils.js
│   └── components/
│       ├── header.jsx
│       ├── hero.jsx
│       ├── features.jsx
│       └── footer.jsx
├── package.json
└── README.md
```

#### 3.2.3 Home Page (index.html)

```html
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ABADA Music Studio - AI 음악 생성</title>
    <meta name="description" content="Open Source AI로 나만의 음악을 만드세요. 한 번의 클릭으로 설치하고 사용합니다.">
    <link rel="stylesheet" href="/styles/main.css">
</head>
<body>
    <!-- Navigation -->
    <nav class="navbar">
        <div class="container">
            <div class="nav-brand">🎵 ABADA Music Studio</div>
            <div class="nav-links">
                <a href="#download">다운로드</a>
                <a href="/gallery.html">갤러리</a>
                <a href="/tutorial.html">튜토리얼</a>
                <a href="/faq.html">FAQ</a>
                <a href="/about.html">ABADA</a>
            </div>
        </div>
    </nav>

    <!-- Hero Section -->
    <section class="hero">
        <div class="container">
            <h1>AI로 나만의 음악을 만든다</h1>
            <p class="subtitle">한 번의 클릭으로 시작하는 음악 생성</p>
            <div class="hero-buttons">
                <button class="btn btn-primary" onclick="scrollTo('download')">
                    지금 다운로드하기
                </button>
                <a href="/tutorial.html" class="btn btn-secondary">
                    튜토리얼 보기
                </a>
            </div>
            <p class="hero-note">
                💡 Windows • macOS • Linux 모두 지원
                🆓 완전 무료 • 오픈소스 • 인터넷 불필요
            </p>
        </div>
    </section>

    <!-- Features -->
    <section class="features">
        <div class="container">
            <h2>3가지 장점</h2>
            <div class="feature-grid">
                <div class="feature-card">
                    <div class="feature-icon">⚡</div>
                    <h3>초간단 설치</h3>
                    <p>프로그램을 다운로드하고 더블클릭하세요.<br>복잡한 설정은 모두 자동입니다.</p>
                </div>
                <div class="feature-card">
                    <div class="feature-icon">🆓</div>
                    <h3>완전 무료</h3>
                    <p>오픈소스 기반으로 100% 무료입니다.<br>광고나 구독료도 없습니다.</p>
                </div>
                <div class="feature-card">
                    <div class="feature-icon">💻</div>
                    <h3>오프라인 사용</h3>
                    <p>인터넷이 없어도 사용 가능합니다.<br>당신의 컴퓨터에서 모든 것이 처리됩니다.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Download Section -->
    <section class="download" id="download">
        <div class="container">
            <h2>다운로드</h2>
            <div class="download-grid">
                <div class="download-card">
                    <h3>Windows 64-bit</h3>
                    <p class="file-size">~80MB</p>
                    <button class="btn btn-primary" onclick="download('windows-x64')">
                        다운로드
                    </button>
                    <p class="note">Windows 10/11 권장</p>
                </div>
                <div class="download-card">
                    <h3>macOS</h3>
                    <p class="file-size">~50MB</p>
                    <button class="btn btn-primary" onclick="download('macos')">
                        다운로드
                    </button>
                    <p class="note">Intel & Apple Silicon</p>
                </div>
                <div class="download-card">
                    <h3>Linux</h3>
                    <p class="file-size">~5KB</p>
                    <button class="btn btn-primary" onclick="download('linux')">
                        다운로드
                    </button>
                    <p class="note">터미널에서 실행</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Gallery Preview -->
    <section class="gallery-preview">
        <div class="container">
            <h2>커뮤니티 생성 샘플</h2>
            <div class="audio-grid">
                <!-- 동적 로드 (gallery.js) -->
            </div>
            <a href="/gallery.html" class="btn btn-secondary">전체 갤러리 보기</a>
        </div>
    </section>

    <!-- System Requirements -->
    <section class="requirements">
        <div class="container">
            <h2>시스템 요구사항</h2>
            <div class="req-grid">
                <div><strong>RAM</strong><br>최소 8GB<br>권장 16GB</div>
                <div><strong>저장공간</strong><br>15GB 이상<br>SSD 권장</div>
                <div><strong>GPU (선택)</strong><br>NVIDIA RTX 2060+<br>Apple M1+ (더 빠름)</div>
                <div><strong>OS</strong><br>Windows 10/11<br>macOS 12+ • Linux</div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer>
        <div class="container">
            <p>ABADA Music Studio © 2026</p>
            <p>Powered by HeartMuLa | CC BY-NC 4.0 License</p>
            <div class="footer-links">
                <a href="/about.html">ABADA Inc.</a> |
                <a href="https://github.com/saintgo7/web-music-heartlib">GitHub</a> |
                <a href="/faq.html">FAQ</a> |
                <a href="https://pamout.co.kr">Pamout</a>
            </div>
        </div>
    </footer>

    <script src="/js/download.js"></script>
</body>
</html>
```

#### 3.2.4 Download 통계 (Cloudflare Worker)

```javascript
// functions/api/stat.js (Cloudflare Workers)

export async function onRequest(context) {
    const { request } = context;
    const url = new URL(request.url);
    const action = url.searchParams.get('action');

    if (action === 'download') {
        const os = url.searchParams.get('os');

        // KV Store에 통계 저장
        const key = `download:${os}:${new Date().toISOString().split('T')[0]}`;
        const current = parseInt(await context.env.STATS.get(key) || '0');
        await context.env.STATS.put(key, (current + 1).toString());

        // 실제 다운로드 링크로 리다이렉트
        const links = {
            'windows-x64': 'https://github.com/saintgo7/web-music-heartlib/releases/download/v1.0.0/MuLa_Setup_x64.exe',
            'macos': 'https://github.com/saintgo7/web-music-heartlib/releases/download/v1.0.0/MuLa_Installer.dmg',
            'linux': 'https://github.com/saintgo7/web-music-heartlib/releases/download/v1.0.0/mula_install.sh'
        };

        return new Response(null, {
            status: 302,
            headers: { 'Location': links[os] || links['windows-x64'] }
        });
    }

    return new Response('OK');
}
```

---

## IV. 설치 프로그램 (기존 DEV.md 기반 개선)

### 4.1 3가지 설치 방식

| OS | 파일명 | 형식 | 특징 |
|---|--------|------|------|
| **Windows x64** | MuLa_Setup_x64.exe | NSIS GUI | 마법사식 설치 |
| **Windows x86** | MuLa_Setup_x86.exe | NSIS GUI | 32비트 대응 (CPU 전용) |
| **macOS** | MuLa_Installer.dmg | App Bundle | Drag & Drop |
| **Linux** | mula_install.sh | Shell Script | 터미널 스크립트 |

### 4.2 설치 후 파일 구조 (공통)

```
~/.mulastudio/  (또는 %LOCALAPPDATA%\MuLaStudio)
├── python/
│   ├── python.exe (또는 python3)
│   └── Lib/site-packages/
│       ├── torch/
│       ├── gradio/
│       └── heartlib/
├── models/  (~6GB)
│   ├── HeartMuLaGen/
│   ├── HeartMuLa-oss-3B/
│   └── HeartCodec-oss/
├── app/
│   ├── main.py
│   └── config.json
└── run.bat (또는 run.sh)
```

### 4.3 설치 후 실행 방식

#### Windows
```batch
더블클릭 "MuLa Studio" (바탕화면 바로가기)
→ run.bat 실행
→ 브라우저 자동 열림 (http://127.0.0.1:7860)
→ Gradio UI 표시
```

#### macOS
```bash
더블클릭 "MuLa Studio" (Applications/Desktop)
→ run.command 실행
→ 브라우저 자동 열림
→ Gradio UI 표시
```

#### Linux
```bash
$ mulastudio
또는
$ bash ~/.mulastudio/run.sh
→ 브라우저 자동 열림
→ Gradio UI 표시
```

### 4.4 설치 프로그램 다운로드 위치

**Primary**: GitHub Releases
```
https://github.com/saintgo7/web-music-heartlib/releases/v1.0.0/
├── MuLa_Setup_x64.exe
├── MuLa_Setup_x86.exe
├── MuLa_Installer.dmg
└── mula_install.sh
```

**Secondary (Backup)**: music.abada.kr
```
https://music.abada.kr/downloads/
├── windows/
├── macos/
└── linux/
```

---

## V. 배포 전략 (CI/CD 자동화)

### 5.1 GitHub Actions 워크플로우

#### 5.1.1 빌드 파이프라인 (build.yml)

```yaml
name: Build Installers

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install NSIS
        run: |
          choco install nsis -y
      - name: Build Windows x64
        run: |
          cd installer/windows
          makensis /DVERSION=${{ github.ref_name }} MuLaInstaller_x64.nsi
      - name: Build Windows x86
        run: |
          cd installer/windows
          makensis /DVERSION=${{ github.ref_name }} MuLaInstaller_x86.nsi
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: windows-installers
          path: installer/windows/*.exe

  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install create-dmg
        run: brew install create-dmg
      - name: Build macOS DMG
        run: |
          cd installer/macos
          ./build_dmg.sh ${{ github.ref_name }}
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: macos-installer
          path: installer/macos/*.dmg

  build-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Make script executable
        run: |
          chmod +x installer/linux/mula_install.sh
      - name: Verify script
        run: |
          bash -n installer/linux/mula_install.sh
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: linux-installer
          path: installer/linux/mula_install.sh

  create-release:
    needs: [build-windows, build-macos, build-linux]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Download artifacts
        uses: actions/download-artifact@v3
      - name: Create checksums
        run: |
          cd release
          sha256sum *.exe *.dmg *.sh > checksums.txt
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            windows-installers/*
            macos-installer/*
            linux-installer/*
            checksums.txt
          body: |
            ## ABADA Music Studio v${{ github.ref_name }}

            ### 다운로드
            - **Windows x64**: MuLa_Setup_x64.exe
            - **Windows x86**: MuLa_Setup_x86.exe
            - **macOS**: MuLa_Installer.dmg
            - **Linux**: mula_install.sh

            ### 설치 방법
            [튜토리얼 보기](https://music.abada.kr/tutorial)
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  deploy-website:
    needs: create-release
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build website
        run: |
          cd web
          npm install
          npm run build
      - name: Deploy to Cloudflare Pages
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy build --project-name=abada-music
```

#### 5.1.2 웹사이트 자동 배포 (deploy-pages.yml)

```yaml
name: Deploy Website to Cloudflare Pages

on:
  push:
    branches: [ main ]
    paths:
      - 'web/**'
      - '.github/workflows/deploy-pages.yml'
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: |
          cd web
          npm install

      - name: Build
        run: |
          cd web
          npm run build

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy build --project-name=abada-music
          secrets: |
            DATABASE_URL
            ANALYTICS_KEY
```

### 5.2 GitHub 저장소 설정

#### 5.2.1 저장소 구조

```
web-music-heartlib/
├── .github/
│   └── workflows/
│       ├── build.yml           # 설치 프로그램 빌드
│       └── deploy-pages.yml    # 웹사이트 배포
├── docs/
│   ├── DEV.md                  # 기존 개발 계획
│   ├── MASTER_PLAN.md          # 이 파일
│   ├── API.md                  # API 문서
│   └── DEPLOYMENT.md           # 배포 가이드
├── installer/
│   ├── windows/
│   │   ├── MuLaInstaller_x64.nsi
│   │   ├── MuLaInstaller_x86.nsi
│   │   └── python-embed/
│   ├── macos/
│   │   ├── build_dmg.sh
│   │   └── install.sh
│   └── linux/
│       └── mula_install.sh
├── web/
│   ├── public/
│   │   ├── index.html
│   │   ├── download.html
│   │   ├── gallery.html
│   │   └── ...
│   ├── src/
│   │   ├── styles/
│   │   ├── js/
│   │   └── components/
│   ├── package.json
│   └── vite.config.js
├── src/
│   └── heartlib/  (기존 Python 코드)
├── README.md
└── LICENSE (CC BY-NC 4.0)
```

### 5.3 Cloudflare Pages 설정

#### 5.3.1 Cloudflare Pages 프로젝트 연결

1. **Cloudflare 대시보드 접속**
   ```
   https://dash.cloudflare.com/
   ```

2. **Pages 메뉴 선택**
   ```
   Pages → Create a project
   ```

3. **GitHub 연동**
   ```
   Connect to Git
   → GitHub 계정 선택
   → saintgo7/web-music-heartlib 선택
   → Authorize
   ```

4. **빌드 설정**
   ```
   Framework preset: React (또는 None)
   Build command: cd web && npm run build
   Build output directory: web/build
   Environment variables:
     - NODE_ENV=production
   ```

5. **Domain 설정**
   ```
   Custom domain: music.abada.kr
   (DNS 레코드 설정 필요)
   ```

#### 5.3.2 DNS 레코드 설정 (abada.kr)

```
Type  | Name     | Value                    | TTL
------|----------|--------------------------|-----
CNAME | music    | abada-music.pages.dev    | Auto
TXT   | _acme... | [Cloudflare 발급 값]    | Auto
```

---

## VI. 마케팅 & 홍보 전략

### 6.1 ABADA 브랜드 통합

#### 6.1.1 music.abada.kr 내 ABADA 홍보

```html
<!-- Header 배너 -->
<div class="abada-banner">
    <p>🌟 이 프로젝트는 <strong>ABADA Inc.</strong>의
       Open Source AI 보급 프로젝트입니다</p>
    <a href="/about.html">ABADA에 대해 알아보기</a>
</div>

<!-- Footer -->
<footer>
    <div class="footer-content">
        <h4>ABADA Music Studio</h4>
        <p>ABADA Inc.의 AI 음악 생성 플랫폼</p>
        <ul>
            <li><a href="https://abada.kr">ABADA 공식 사이트</a></li>
            <li><a href="https://pamout.co.kr">Pamout (자매 서비스)</a></li>
            <li><a href="https://github.com/saintgo7">GitHub</a></li>
        </ul>
    </div>
</footer>

<!-- About Page: /about.html -->
<section class="about-abada">
    <h2>ABADA Inc. - AI Technology Leader</h2>
    <p>ABADA는 Open Source AI를 일반인도 쉽게 사용하도록 하는
       기업입니다.</p>

    <h3>주요 프로젝트</h3>
    <ul>
        <li>✨ ABADA Music Studio (음악 생성)</li>
        <li>✨ Pamout (AI 이미지 생성) - pamout.co.kr</li>
        <li>🔜 ABADA Vision (이미지 분석)</li>
        <li>🔜 ABADA Voice (음성 생성)</li>
    </ul>
</section>
```

#### 6.1.2 pamout.co.kr 연동

```html
<!-- music.abada.kr 내에서 pamout 링크 -->
<section class="related-services">
    <h3>ABADA의 다른 서비스</h3>
    <div class="service-grid">
        <div class="service-card">
            <h4>🎵 ABADA Music Studio</h4>
            <p>AI로 음악을 생성합니다</p>
            <a href="https://music.abada.kr">지금 사용하기</a>
        </div>
        <div class="service-card">
            <h4>🖼️ Pamout</h4>
            <p>AI로 이미지를 생성합니다</p>
            <a href="https://pamout.co.kr">지금 사용하기</a>
        </div>
    </div>
</section>

<!-- pamout.co.kr 내에서 music 링크 -->
<!-- 마찬가지로 역방향 링크 추가 -->
```

### 6.2 샘플 갤러리 (User-Generated Content)

#### 6.2.1 갤러리 페이지 구조 (/gallery.html)

```html
<section class="gallery">
    <h2>커뮤니티 생성 샘플</h2>

    <div class="filter-bar">
        <button class="filter-btn active" data-filter="all">전체</button>
        <button class="filter-btn" data-filter="pop">팝</button>
        <button class="filter-btn" data-filter="classical">클래식</button>
        <button class="filter-btn" data-filter="jazz">재즈</button>
        <button class="filter-btn" data-filter="ambient">앰비언트</button>
    </div>

    <div class="gallery-grid" id="gallery">
        <!-- 동적 로드 -->
    </div>
</section>

<script>
// gallery.js - 샘플 곡 동적 로드
async function loadGallery() {
    const response = await fetch('/api/gallery');
    const samples = await response.json();

    const gallery = document.getElementById('gallery');
    samples.forEach(sample => {
        gallery.innerHTML += `
            <div class="gallery-item" data-tags="${sample.tags}">
                <audio controls>
                    <source src="${sample.audio_url}" type="audio/mpeg">
                </audio>
                <h4>${sample.title}</h4>
                <p class="lyrics">"${sample.lyrics.substring(0, 50)}..."</p>
                <p class="tags">${sample.tags.join(', ')}</p>
                <p class="created">Created: ${sample.created_at}</p>
            </div>
        `;
    });
}
</script>
```

#### 6.2.2 샘플 데이터 (data/gallery.json)

```json
{
  "samples": [
    {
      "id": 1,
      "title": "Morning Light",
      "lyrics": "[Verse]\nThe morning light comes through the window\n[Chorus]\nA brand new day is here",
      "tags": ["pop", "happy", "morning"],
      "audio_url": "https://music.abada.kr/samples/sample-1.mp3",
      "image_url": "https://music.abada.kr/samples/sample-1.jpg",
      "created_at": "2026-01-16",
      "created_by": "User123"
    },
    {
      "id": 2,
      "title": "Midnight Dream",
      "lyrics": "[Verse]\nWhen the night falls silent\n[Bridge]\nDreams are calling me",
      "tags": ["ambient", "relaxing", "night"],
      "audio_url": "https://music.abada.kr/samples/sample-2.mp3",
      "image_url": "https://music.abada.kr/samples/sample-2.jpg",
      "created_at": "2026-01-17",
      "created_by": "User456"
    }
  ]
}
```

### 6.3 SNS 홍보 전략

#### 6.3.1 SNS 포스팅 템플릿

**[트위터/X]**
```
🎵 ABADA Music Studio가 출시되었습니다!

AI로 나만의 음악을 만드세요.
한 번의 클릭으로 시작합니다.

✨ Windows • macOS • Linux
🆓 완전 무료 • 오픈소스
💻 오프라인 사용 가능

지금 다운로드: music.abada.kr

#AI #음악생성 #OpenSource #ABADA
```

**[LinkedIn]**
```
🎶 ABADA Music Studio - Open Source AI의 대중화

ABADA Inc.에서 새로운 프로젝트를 출시했습니다.
복잡한 AI 음악생성을 한 번의 클릭으로 해결합니다.

기술:
- HeartMuLa (AI 모델)
- Gradio (UI)
- 자동 설치 프로그램

이는 비개발자도 AI를 쉽게 사용하도록 하는
ABADA의 미션을 반영합니다.

abada.kr | music.abada.kr
```

#### 6.3.2 커뮤니티 확산

```
1. GitHub Stars 유도
   - README에 Star 부탁 표시
   - Awesome Lists에 등록

2. 레딧/HackerNews
   - "Show HN: ABADA Music Studio"로 포스팅

3. AI 커뮤니티
   - Product Hunt
   - Hugging Face Hub 소개

4. 유튜브
   - 설치 및 사용 튜토리얼 영상
   - "이 설치 프로그램이 정말 작동하나요?" 영상

5. 블로그
   - Medium: "AI Music를 민주화하다"
   - Dev.to: "Python 없이 AI 음악 생성하기"
```

---

## VII. 기술 자동화 (Skills, Agent, Hook)

### 7.1 GitHub Actions Hooks

#### 7.1.1 이슈 자동 처리

```yaml
# .github/workflows/auto-issue.yml
name: Auto Issue Handler

on:
  issues:
    types: [opened]
  pull_request:
    types: [opened, synchronize]

jobs:
  auto-respond:
    runs-on: ubuntu-latest
    steps:
      - name: 설치 관련 이슈 자동 응답
        if: contains(github.event.issue.title, '설치')
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '🤖 설치 가이드: https://music.abada.kr/tutorial'
            })

      - name: 버그 리포트 라벨 추가
        if: contains(github.event.issue.labels, 'bug')
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.addLabels({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              labels: ['needs-investigation']
            })
```

#### 7.1.2 PR 자동 검사

```yaml
# .github/workflows/auto-pr-check.yml
name: Auto PR Check

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: 파일 변경 감지
        uses: dorny/paths-filter@v2
        id: changes
        with:
          filters: |
            installer:
              - 'installer/**'
            website:
              - 'web/**'
            docs:
              - 'docs/**'

      - name: 설치 프로그램 변경 시 테스트
        if: steps.changes.outputs.installer == 'true'
        run: |
          echo "installer 파일이 변경되었습니다"
          echo "빌드 테스트 필요"

      - name: 웹사이트 변경 시 자동 배포
        if: steps.changes.outputs.website == 'true'
        run: |
          echo "웹사이트가 변경되었습니다"
          echo "Cloudflare Pages 배포 예정"
```

### 7.2 Cloudflare Worker 자동화

#### 7.2.1 다운로드 통계 수집

```javascript
// functions/api/analytics.js
export async function onRequest(context) {
    const { request, env } = context;
    const url = new URL(request.url);

    if (request.method === 'POST') {
        const data = await request.json();

        // 다운로드 통계 저장
        const timestamp = new Date().toISOString();
        const key = `download:${data.os}:${timestamp}`;

        await env.ANALYTICS.put(key, JSON.stringify({
            os: data.os,
            version: data.version,
            timestamp: timestamp,
            referrer: request.headers.get('referer')
        }));

        return new Response(JSON.stringify({ status: 'ok' }), {
            headers: { 'Content-Type': 'application/json' }
        });
    }

    // 통계 조회
    if (url.pathname === '/api/analytics/stats') {
        const list = await env.ANALYTICS.list();
        const stats = {};

        for (const key of list.keys.map(k => k.name)) {
            const value = JSON.parse(await env.ANALYTICS.get(key));
            stats[value.os] = (stats[value.os] || 0) + 1;
        }

        return new Response(JSON.stringify(stats), {
            headers: { 'Content-Type': 'application/json' }
        });
    }

    return new Response('Not Found', { status: 404 });
}
```

### 7.3 로컬 Git Hook

#### 7.3.1 Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# 1. 파일 크기 확인 (100MB 이상 파일 방지)
echo "[Hook] 파일 크기 확인..."
for file in $(git diff --cached --name-only); do
    size=$(wc -c < "$file")
    if [ $size -gt 104857600 ]; then
        echo "❌ 파일이 너무 큽니다: $file ($(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo $size bytes))"
        exit 1
    fi
done

# 2. 민감한 파일 확인 (API 키 등)
echo "[Hook] 민감한 정보 확인..."
if git diff --cached | grep -E '(API_KEY|PASSWORD|SECRET|TOKEN)'; then
    echo "❌ 민감한 정보가 포함되어 있습니다"
    exit 1
fi

# 3. NSIS 스크립트 문법 확인
echo "[Hook] NSIS 문법 확인..."
for file in $(git diff --cached --name-only | grep '\.nsi$'); do
    if ! nsis-check "$file" 2>/dev/null; then
        echo "❌ NSIS 문법 오류: $file"
        exit 1
    fi
done

# 4. Shell 스크립트 문법 확인
echo "[Hook] Shell 문법 확인..."
for file in $(git diff --cached --name-only | grep '\.sh$'); do
    if ! bash -n "$file"; then
        echo "❌ Shell 문법 오류: $file"
        exit 1
    fi
done

echo "✅ 모든 체크 통과"
exit 0
```

#### 7.3.2 Post-commit Hook

```bash
#!/bin/bash
# .git/hooks/post-commit

# 버전 자동 업데이트
VERSION=$(grep "VERSION=" installer/windows/MuLaInstaller.nsi | head -1 | cut -d'=' -f2)
echo "마지막 커밋 버전: $VERSION"

# 커밋 메시지에 버전 추가
git commit --amend -m "$(git log -1 --pretty=%B) [v$VERSION]" --no-edit 2>/dev/null || true
```

---

## VIII. 개발 일정 (8주 총괄)

### 8.1 전체 타임라인

| Phase | 기간 | 작업 | 산출물 |
|-------|------|------|--------|
| **Phase 1** | W1-4 | 설치 프로그램 개발 | 5개 설치파일 |
| **Phase 2** | W3-4 | 웹사이트 개발 | music.abada.kr |
| **Phase 3** | W5-6 | 통합 & 테스트 | 베타 릴리즈 |
| **Phase 4** | W7-8 | 런칭 & 홍보 | 공식 출시 |

### 8.2 상세 주간 일정

#### **Week 1: Windows 설치 프로그램**

```
Day 1-2: NSIS 스크립트 작성
├── MuLaInstaller_x64.nsi 작성
├── MuLaInstaller_x86.nsi 작성
└── 다국어 지원 (한국어/영어)

Day 3: GPU 감지 로직
├── NVIDIA GPU 감지
├── 디스크/RAM 체크
└── 시스템 요구사항 검증

Day 4: 모델 다운로드 통합
├── HuggingFace 다운로드
├── 진행률 표시
└── 재시도 로직

Day 5: 빌드 & 테스트
├── Windows x64/x86 빌드
├── 클린 설치 테스트
├── GUI 검증
└── 버그 수정
```

#### **Week 2: macOS & Linux 설치 프로그램**

```
Day 1-2: macOS install.sh 작성
├── Homebrew 통합
├── 가상환경 설정
├── App Bundle 구성
└── DMG 생성 자동화

Day 3: Linux mula_install.sh 작성
├── Ubuntu/Fedora/Arch 지원
├── Package Manager 감지
├── Desktop 통합
└── 바로가기 생성

Day 4: Intel/ARM 아키텍처 테스트
├── Mac Intel 테스트
├── Apple Silicon (M1/M2) 테스트
├── Linux x86_64 테스트
└── ARM Linux 검토

Day 5: 문서 작성
├── 설치 가이드
├── 트러블슈팅
└── 기술 문서
```

#### **Week 3: 웹사이트 개발**

```
Day 1-2: 프론트엔드 구축
├── React + Tailwind 설정
├── 홈페이지 디자인 구현
├── 다운로드 페이지
└── 갤러리 페이지

Day 3: Cloudflare Pages 연동
├── 프로젝트 생성
├── DNS 설정 (music.abada.kr)
├── GitHub Actions 연동
└── 자동 배포 설정

Day 4: 기능 구현
├── 다운로드 통계 (Worker)
├── 갤러리 로드 (API)
├── 튜토리얼 페이지
└── FAQ 페이지

Day 5: 최적화 & 배포
├── SEO 최적화
├── 모바일 반응형 확인
├── 성능 최적화
└── 라이브 배포
```

#### **Week 4: 통합 & 테스트**

```
Day 1-2: 설치 프로그램 통합
├── 모든 설치 파일 수집
├── 체크섬 생성
├── GitHub Releases 준비
└── 다운로드 링크 확인

Day 3: 엔드투엔드 테스트
├── Windows: 다운로드 → 설치 → 실행
├── macOS: 다운로드 → 설치 → 실행
├── Linux: 다운로드 → 설치 → 실행
└── 음악 생성 테스트

Day 4: 문제 해결
├── 설치 오류 디버깅
├── 호환성 문제 해결
├── 성능 최적화
└── 보안 검토

Day 5: 베타 릴리즈
├── GitHub Releases v0.9.0 배포
├── 베타 테스터 모집
├── 피드백 수집
└── 최종 버그 수정
```

#### **Week 5: ABADA 통합 & 홍보**

```
Day 1-2: ABADA 브랜드 통합
├── music.abada.kr 배너 추가
├── about.html 작성
├── pamout 링크 추가
└── 로고/브랜딩 통합

Day 3: 샘플 갤러리 구축
├── 5-10개 샘플 음악 생성
├── 이미지 자산 생성
├── 갤러리 데이터 입력
└── 동적 로드 테스트

Day 4: SNS 홍보 준비
├── SNS 포스팅 템플릿 작성
├── 홍보 자료 제작 (이미지, 영상 썸네일)
├── 기자 보도자료 작성
└── 커뮤니티 협력사 접근

Day 5: 공식 홍보 시작
├── 트위터/LinkedIn 포스팅
├── GitHub Trending 등록
├── Awesome List 등록
└── AI 커뮤니티 공유
```

#### **Week 6-8: 지속적 개선**

```
Week 6:
- 사용자 피드백 수집
- 튜토리얼 영상 제작
- 문제 해결

Week 7:
- 자동 업데이트 기능 추가
- UI/UX 개선
- 다국어 지원 확장

Week 8:
- 성능 최적화
- 보안 업데이트
- 커뮤니티 관리
```

---

## IX. 예산 & 비용 (FREE!)

### 9.1 사용 서비스별 비용

| 서비스 | 사용량 | 가격 | 비고 |
|--------|--------|------|------|
| **GitHub** | 무제한 | $0 | Public Repo |
| **GitHub Actions** | 2,000 분/월 | $0 | 충분함 |
| **Cloudflare Pages** | 무제한 | $0 | 무료 호스팅 |
| **Cloudflare Workers** | 100K/일 | $0 | 무료 요청 |
| **HuggingFace** | 모델 다운로드 | $0 | Public 모델 |
| **Domain (music.abada.kr)** | 1개 | 기존 | 기존 보유 |
| **총 비용** | | **$0** | ✅ 완전 무료 |

### 9.2 대역폭 예상

```
월간 예상 다운로드 (1000 사용자 가정):
- Windows x64: 400 × 80MB = 32GB
- macOS: 300 × 50MB = 15GB
- Linux: 300 × 5KB = 0.015GB
- 총 대역폭: ~47GB/월

Cloudflare 무료 티어: 무제한 ✅
GitHub Releases: 무제한 ✅
```

---

## X. 성공 지표 (KPI)

### 10.1 추적할 메트릭

| 지표 | 목표 | 측정 방법 |
|------|------|----------|
| **다운로드 수** | 1,000+ / 월 | Cloudflare Worker 통계 |
| **설치 완료율** | 90%+ | GitHub Issues (설치 오류) |
| **음악 생성 성공율** | 95%+ | Gradio 로그 분석 |
| **웹사이트 방문자** | 10,000+ / 월 | Cloudflare Analytics |
| **GitHub Stars** | 500+ | GitHub API |
| **SNS 언급** | 100+ / 월 | Google Alerts |
| **갤러리 샘플** | 100+ | 사용자 제출 |
| **ABADA 브랜드 언급** | ↑ 50% | 소셜 미디어 분석 |

### 10.2 성공 기준

```
Phase 1 성공: 설치 프로그램 무결성 (0 크리티컬 버그)
Phase 2 성공: 웹사이트 런칭 (100% 정상 작동)
Phase 3 성공: 첫 주 1,000+ 다운로드
Phase 4 성공: ABADA 브랜드 인지도 ↑ 감지
```

---

## XI. 향후 계획 (Phase 2+)

### 11.1 Phase 4+ 로드맵

```
Q2 2026:
├── 자동 업데이트 기능 (Silent Update)
├── 다국어 지원 (10+ 언어)
├── 커뮤니티 포럼 구축
└── YouTube 튜토리얼 채널

Q3 2026:
├── 클라우드 생성 기능 (음악을 클라우드에서)
├── 사용자 계정 시스템
├── 프리미엄 버전 검토
└── 모바일 앱 (React Native)

Q4 2026:
├── ABADA Vision (이미지) 통합
├── ABADA Voice (음성) 통합
├── AI Suite 번들
└── SaaS 서비스 전환 검토
```

### 11.2 기술 혁신

```
멀티 모델 지원:
├── HeartMuLa 3B (현재)
├── HeartMuLa 7B (계획)
├── 다른 오픈소스 음악 모델 (Riffusion 등)
└── 커스텀 파인튜닝 모델

로컬 AI 최적화:
├── ONNX 모델 변환 (성능 ↑)
├── 양자화 (메모리 ↓)
├── GPU 최적화 (속도 ↑)
└── CPU 전용 경량 버전
```

---

## XII. 참고 자료 & 링크

### 12.1 관련 기술 문서

| 항목 | 링크 |
|------|------|
| HeartMuLa GitHub | https://github.com/HeartMuLa/heartlib |
| Gradio Documentation | https://gradio.app/docs |
| NSIS Documentation | https://nsis.sourceforge.io/Docs |
| Cloudflare Pages | https://developers.cloudflare.com/pages |
| GitHub Actions | https://docs.github.com/en/actions |

### 12.2 내부 문서

| 문서 | 경로 | 설명 |
|------|------|------|
| 개발 계획 | `/docs/DEV.md` | 설치 프로그램 상세 설계 |
| 이 문서 | `/docs/MASTER_PLAN.md` | 전체 통합 계획 |
| API 문서 | `/docs/API.md` | Cloudflare Workers API |
| 배포 가이드 | `/docs/DEPLOYMENT.md` | 배포 절차 |

---

## XIII. 체크리스트 (구현 단계별)

### 13.1 Phase 1 체크리스트 (설치 프로그램)

```
Windows:
☐ MuLaInstaller_x64.nsi 완성
☐ MuLaInstaller_x86.nsi 완성
☐ Python embed 다운로드 및 통합
☐ GPU 감지 로직 테스트
☐ 모델 다운로드 통합
☐ x64 빌드 & 테스트
☐ x86 빌드 & 테스트
☐ 언인스톨 기능 테스트
☐ 바로가기 생성 확인

macOS:
☐ install.sh 작성
☐ Homebrew 통합
☐ DMG 생성 자동화
☐ Intel Mac 테스트
☐ Apple Silicon 테스트
☐ 앱 번들 구성 확인
☐ 바탕화면 바로가기 확인

Linux:
☐ mula_install.sh 작성
☐ 배포판별 테스트 (Ubuntu, Fedora, Arch)
☐ Desktop Entry 생성
☐ PATH 설정 확인
☐ 언인스톨 스크립트 작성

공통:
☐ 모든 플랫폼 설치 성공
☐ 모든 플랫폼 실행 성공
☐ 음악 생성 확인
☐ 출력 파일 저장 확인
☐ GitHub Releases 준비
```

### 13.2 Phase 2 체크리스트 (웹사이트)

```
프론트엔드:
☐ React 프로젝트 초기화
☐ Tailwind CSS 설정
☐ 홈페이지 디자인 구현
☐ 다운로드 페이지 구현
☐ 갤러리 페이지 구현
☐ 튜토리얼 페이지 구현
☐ FAQ 페이지 구현
☐ About ABADA 페이지 구현

Cloudflare 설정:
☐ Cloudflare Pages 프로젝트 생성
☐ GitHub Actions 연동
☐ DNS 레코드 설정 (CNAME)
☐ music.abada.kr 도메인 적용
☐ 자동 배포 테스트
☐ SSL/TLS 설정 확인

기능:
☐ 다운로드 통계 Worker 작성
☐ 갤러리 API 작성
☐ 모바일 반응형 확인
☐ SEO 최적화
☐ 성능 최적화 (PageSpeed Insights 90+)

테스트:
☐ 모든 링크 확인
☐ 다운로드 링크 작동 확인
☐ 갤러리 이미지/오디오 로드 확인
☐ 폼 제출 확인
```

### 13.3 Phase 3 체크리스트 (통합 & 테스트)

```
엔드투엔드 테스트:
☐ Windows x64 클린 설치 테스트
☐ Windows x86 클린 설치 테스트
☐ macOS Intel 클린 설치 테스트
☐ macOS Apple Silicon 클린 설치 테스트
☐ Linux Ubuntu 클린 설치 테스트
☐ Linux Fedora 클린 설치 테스트
☐ 모든 플랫폼에서 음악 생성 테스트
☐ 모든 플랫폼에서 제거 테스트

성능 테스트:
☐ GPU 가속 성능 측정
☐ CPU 모드 성능 측정
☐ 대용량 모델 로드 시간 측정
☐ 생성 시간 측정

보안 테스트:
☐ 악성코드 스캔 (VirusTotal)
☐ 권한 검증 (최소 권한 사용)
☐ 파일 무결성 검증 (체크섬)
☐ SSL/TLS 적용 확인

문서:
☐ 설치 가이드 완성
☐ 튜토리얼 완성
☐ FAQ 완성
☐ 트러블슈팅 가이드 완성
```

### 13.4 Phase 4 체크리스트 (런칭 & 홍보)

```
홍보 준비:
☐ SNS 포스팅 작성 (Twitter, LinkedIn, Facebook)
☐ 기자 보도자료 작성
☐ 유튜브 썸네일 제작
☐ 스크린샷 및 GIF 제작
☐ 갤러리 샘플 곡 5-10개 준비

릴리즈:
☐ GitHub Releases v1.0.0 배포
☐ music.abada.kr 웹사이트 라이브
☐ SNS 공지 (동시 다중 채널)
☐ Product Hunt 포스팅
☐ HackerNews "Show HN" 포스팅
☐ Reddit r/MachineLearning 포스팅

홍보 활동:
☐ 트위터 #AI #OpenSource 트렌드 진입
☐ GitHub Trending 진입 (1주)
☐ Awesome ML List 등록
☐ 커뮤니티 피드백 모니터링
☐ 버그 리포트 빠른 대응

모니터링:
☐ 다운로드 통계 모니터링
☐ 웹사이트 방문자 추적
☐ GitHub Stars 모니터링
☐ 피드백 수집 및 분류
```

---

## XIV. 연락처 & 지원

### 14.1 프로젝트 담당자

```
ABADA Inc.
- Email: contact@abada.kr
- GitHub: saintgo7
- Website: https://abada.kr
```

### 14.2 지원 채널

```
Github Issues:
  - 버그 리포트
  - 기능 요청
  - 설치 도움

Discussions:
  - 일반 질문
  - 팁 공유
  - 커뮤니티 활동
```

---

**문서 작성자**: ABADA Music Studio Team
**마지막 수정**: 2026-01-18
**상태**: 🔵 Ready for Implementation
**승인**: Pending

---

**이 문서는 Gemini와 비교하여 검토하는 것을 권장합니다.**
