# ABADA Music Studio - 배포 가이드

**버전**: v2.0
**대상 버전**: v0.3.0 Phase 2
**마지막 업데이트**: 2026-01-19

---

## I. 배포 개요

### 1.1 배포 아키텍처

ABADA Music Studio는 다음 3개의 독립적인 배포 단위로 구성됩니다:

```
┌─────────────────────────────────────────────────────────────┐
│                     ABADA Music Studio                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [1] 웹사이트 (Cloudflare Pages)                           │
│      └─ music.abada.kr                                     │
│                                                             │
│  [2] API (Cloudflare Workers)                              │
│      ├─ /api/download-stats                                │
│      ├─ /api/gallery                                        │
│      ├─ /api/analytics                                      │
│      └─ /api (main router)                                  │
│                                                             │
│  [3] 설치 프로그램 (GitHub Releases)                        │
│      ├─ MuLa_Setup_x64.exe (Windows)                       │
│      ├─ MuLa_Installer.dmg (macOS)                         │
│      └─ mula_install.sh (Linux)                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 배포 환경

| 컴포넌트 | 플랫폼 | 도메인/URL | 비용 |
|---------|--------|-----------|------|
| 웹사이트 | Cloudflare Pages | music.abada.kr | 무료 |
| API | Cloudflare Workers | music.abada.kr/api/* | 무료 (100k req/day) |
| KV Store | Cloudflare KV | N/A | 무료 (1GB) |
| 설치 파일 | GitHub Releases | github.com/releases | 무료 (100GB/month) |
| CI/CD | GitHub Actions | N/A | 무료 (2000 min/month) |

**총 비용**: $0/월 (완전 무료)

---

## II. 사전 준비사항

### 2.1 필수 계정

1. **GitHub 계정**
   - Repository: saintgo7/web-music-heartlib
   - 권한: Admin (Secrets 설정 필요)

2. **Cloudflare 계정**
   - 가입: https://dash.cloudflare.com/sign-up
   - 플랜: Free (무료)
   - 필요 서비스: Pages, Workers, KV

3. **도메인 (abada.kr)**
   - DNS 관리 권한 필요
   - CNAME 레코드 추가 가능

### 2.2 필수 도구

**로컬 개발 환경**:
```bash
# Node.js 18+
node --version  # v18.0.0 이상

# npm
npm --version   # 9.0.0 이상

# Git
git --version   # 2.30.0 이상

# Wrangler CLI (Cloudflare)
npm install -g wrangler
wrangler --version
```

**선택 도구**:
- NSIS (Windows 설치 프로그램 빌드)
- Docker (격리된 테스트 환경)

---

## III. Cloudflare Pages 배포

### 3.1 첫 배포 (수동)

#### Step 1: Cloudflare 대시보드 접속

```
1. https://dash.cloudflare.com 접속
2. 로그인
3. 왼쪽 메뉴에서 "Workers & Pages" 선택
4. "Create application" 클릭
5. "Pages" 탭 선택
6. "Connect to Git" 클릭
```

#### Step 2: GitHub 저장소 연결

```
1. "GitHub" 선택
2. "Add account" 클릭 (처음 사용 시)
3. 권한 승인
4. Repository 선택: saintgo7/web-music-heartlib
5. "Begin setup" 클릭
```

#### Step 3: 빌드 설정

**프로젝트 이름**: `abada-music-studio`

**빌드 설정**:
```
Production branch: main
Build command: cd web && npm ci && npm run build
Build output directory: web/dist
Root directory: (비워두기)
```

**환경 변수**:
```
NODE_VERSION=18
NODE_ENV=production
```

#### Step 4: 배포 실행

```
1. "Save and Deploy" 클릭
2. 빌드 로그 확인 (약 2-3분 소요)
3. 배포 완료 대기
4. 임시 URL 확인: https://abada-music-studio.pages.dev
```

**배포 로그 확인**:
```
Build successful!
├── Build time: 1m 23s
├── Total size: 1.2 MB
└── Deploy time: 12s

✅ Deployment complete
URL: https://abada-music-studio.pages.dev
```

---

### 3.2 커스텀 도메인 설정

#### Step 1: Cloudflare Pages에서 도메인 추가

```
1. Pages 프로젝트 선택 (abada-music-studio)
2. "Custom domains" 탭 선택
3. "Set up a custom domain" 클릭
4. 도메인 입력: music.abada.kr
5. "Continue" 클릭
```

#### Step 2: DNS 레코드 추가

**Cloudflare가 제시하는 값**:
```
Type:  CNAME
Name:  music
Value: abada-music-studio.pages.dev
```

**DNS 설정 (abada.kr 호스팅 제공자)**:
```
# 예시: GoDaddy, Namecheap, Cloudflare 등
Type:     CNAME
Host:     music
Points to: abada-music-studio.pages.dev
TTL:      Auto (또는 3600)
```

**Cloudflare DNS를 사용하는 경우**:
```
1. Cloudflare 대시보드에서 abada.kr 도메인 선택
2. "DNS" > "Records" 선택
3. "Add record" 클릭
4. Type: CNAME
   Name: music
   Target: abada-music-studio.pages.dev
   Proxy status: Proxied (오렌지 구름)
5. "Save" 클릭
```

#### Step 3: SSL/TLS 설정

**자동 SSL 인증서 발급** (Cloudflare 자동):
```
1. Pages 프로젝트 > "Custom domains"
2. music.abada.kr 상태 확인
   ✅ Active (녹색) - 인증서 발급 완료
   ⏳ Pending - DNS 전파 대기 중
   ❌ Failed - DNS 설정 오류
```

**HTTPS 강제 리디렉션**:
```
1. Cloudflare 대시보드 > abada.kr
2. "SSL/TLS" > "Edge Certificates"
3. "Always Use HTTPS" 활성화
```

#### Step 4: 접속 확인

```bash
# DNS 전파 확인 (최대 24시간 소요)
dig music.abada.kr

# 응답 예시:
# music.abada.kr. 300 IN CNAME abada-music-studio.pages.dev.

# 웹사이트 접속
curl -I https://music.abada.kr

# HTTP/2 200 OK 확인
```

**브라우저 테스트**:
```
1. https://music.abada.kr 접속
2. 모든 페이지 로드 확인
   - / (홈)
   - /download
   - /gallery
   - /tutorial
   - /faq
   - /about
3. HTTPS 자물쇠 아이콘 확인
```

---

### 3.3 자동 배포 (GitHub Actions)

#### Step 1: GitHub Actions 워크플로우 확인

**파일**: `.github/workflows/deploy-website.yml`

```yaml
name: Deploy Website to Cloudflare Pages

on:
  push:
    branches: [main]
    paths:
      - 'web/**'
      - '.github/workflows/deploy-website.yml'
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: web/package-lock.json

      - name: Install dependencies
        run: |
          cd web
          npm ci

      - name: Build website
        run: |
          cd web
          npm run build

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: abada-music-studio
          directory: web/dist
          gitHubToken: ${{ secrets.GITHUB_TOKEN }}
```

#### Step 2: GitHub Secrets 설정

**Cloudflare API Token 발급**:
```
1. Cloudflare 대시보드 로그인
2. 우측 상단 프로필 > "API Tokens"
3. "Create Token" 클릭
4. "Edit Cloudflare Workers" 템플릿 선택
5. 권한 설정:
   - Account > Cloudflare Pages > Edit
   - Zone > DNS > Edit (선택)
6. "Continue to summary" > "Create Token"
7. 토큰 복사 (한 번만 표시됨!)
```

**GitHub Secrets 추가**:
```
1. GitHub Repository > Settings > Secrets and variables > Actions
2. "New repository secret" 클릭
3. Secrets 추가:

   Name: CLOUDFLARE_API_TOKEN
   Value: [복사한 API 토큰]

   Name: CLOUDFLARE_ACCOUNT_ID
   Value: [Cloudflare 계정 ID]
```

**Cloudflare Account ID 확인**:
```
1. Cloudflare 대시보드
2. 우측 사이드바 > "Account ID" 확인
3. 복사 (32자리 hex 문자열)

예시: 1234567890abcdef1234567890abcdef
```

#### Step 3: 자동 배포 테스트

```bash
# 로컬에서 변경사항 커밋
cd web
echo "<!-- Test -->" >> public/index.html
git add .
git commit -m "test: trigger automatic deployment"
git push origin main

# GitHub Actions 확인
# 1. GitHub Repository > Actions 탭
# 2. "Deploy Website to Cloudflare Pages" 워크플로우 확인
# 3. 녹색 체크 확인 (성공)
```

---

## IV. Cloudflare Workers API 배포

### 4.1 KV 네임스페이스 생성

#### Step 1: Wrangler 로그인

```bash
# Wrangler CLI 설치 (이미 설치된 경우 생략)
npm install -g wrangler

# Cloudflare 로그인
wrangler login
```

**브라우저 열림** → Cloudflare 로그인 → 권한 승인

#### Step 2: KV 네임스페이스 생성

```bash
# Production 환경용
wrangler kv:namespace create "DOWNLOAD_STATS"
wrangler kv:namespace create "GALLERY_ITEMS"
wrangler kv:namespace create "ANALYTICS_LOGS"

# 출력 예시:
# ✨ Success!
# Add the following to your wrangler.toml:
# [[kv_namespaces]]
# binding = "DOWNLOAD_STATS"
# id = "abc123..."
```

**wrangler.toml 업데이트**:
```toml
# functions/wrangler.toml
name = "abada-music-api"
main = "api/index.js"
compatibility_date = "2024-01-01"

[[kv_namespaces]]
binding = "DOWNLOAD_STATS"
id = "abc123..." # 위에서 생성된 ID

[[kv_namespaces]]
binding = "GALLERY_ITEMS"
id = "def456..."

[[kv_namespaces]]
binding = "ANALYTICS_LOGS"
id = "ghi789..."

[env.production]
name = "abada-music-api"
route = "music.abada.kr/api/*"
```

---

### 4.2 Workers 배포

#### Step 1: 로컬 테스트

```bash
cd functions

# 개발 서버 실행
wrangler dev

# 출력:
# ⎔ Starting local server...
# ⎔ Listening on http://localhost:8787
```

**API 테스트**:
```bash
# 다운로드 통계 조회
curl http://localhost:8787/api/download-stats

# 응답 예시:
# {"windows_x64":0,"windows_x86":0,"macos":0,"linux":0}

# 다운로드 통계 증가
curl -X POST http://localhost:8787/api/download-stats \
  -H "Content-Type: application/json" \
  -d '{"platform":"windows_x64"}'
```

#### Step 2: Production 배포

```bash
# Production 환경으로 배포
wrangler deploy

# 출력:
# ⎔ Building...
# ✨ Success!
# Deployed to https://abada-music-api.workers.dev
# Custom route: music.abada.kr/api/*
```

**배포 확인**:
```bash
# API 엔드포인트 테스트
curl https://music.abada.kr/api/download-stats
curl https://music.abada.kr/api/gallery
curl https://music.abada.kr/api/analytics

# 상태 코드 200 확인
```

---

### 4.3 Routes 설정

#### Step 1: Cloudflare Workers Routes 추가

```
1. Cloudflare 대시보드
2. abada.kr 도메인 선택
3. "Workers Routes" 선택
4. "Add route" 클릭
5. Route 설정:
   - Route: music.abada.kr/api/*
   - Worker: abada-music-api
6. "Save" 클릭
```

**wrangler.toml에서 자동 설정** (권장):
```toml
[env.production]
routes = [
  { pattern = "music.abada.kr/api/*", zone_name = "abada.kr" }
]
```

---

### 4.4 CORS 설정

**functions/api/index.js**:
```javascript
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Max-Age': '86400',
};

export default {
  async fetch(request, env) {
    // OPTIONS 요청 처리 (Preflight)
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }

    // 실제 요청 처리
    const url = new URL(request.url);
    let response;

    if (url.pathname.startsWith('/api/download-stats')) {
      response = await handleDownloadStats(request, env);
    } else if (url.pathname.startsWith('/api/gallery')) {
      response = await handleGallery(request, env);
    } else if (url.pathname.startsWith('/api/analytics')) {
      response = await handleAnalytics(request, env);
    } else {
      response = new Response('Not Found', { status: 404 });
    }

    // CORS 헤더 추가
    Object.entries(CORS_HEADERS).forEach(([key, value]) => {
      response.headers.set(key, value);
    });

    return response;
  }
};
```

---

## V. GitHub Releases 배포

### 5.1 설치 프로그램 빌드

#### Step 1: Windows 설치 프로그램 빌드

**로컬 Windows 머신 또는 VM**:
```bash
# NSIS 설치 (https://nsis.sourceforge.io/)
# 또는 Chocolatey로 설치
choco install nsis

# 빌드 실행
cd installer/windows
makensis MuLaInstaller_x64.nsi

# 출력:
# Processing config:
# Output: "MuLa_Setup_x64.exe"
# Install: 3 pages (License, Directory, InstFiles)
# NSIS: 100% - Done
```

**생성된 파일**:
```
installer/build/
└── MuLa_Setup_x64.exe (~30MB)
```

#### Step 2: macOS 설치 프로그램 빌드 (선택)

**macOS 머신**:
```bash
# create-dmg 설치
brew install create-dmg

# DMG 생성
cd installer/macos
./build_dmg.sh

# 출력:
# Creating DMG...
# Success! DMG created at:
# installer/build/MuLa_Installer.dmg
```

#### Step 3: Linux 스크립트 준비

```bash
# 실행 권한 부여
chmod +x installer/linux/mula_install.sh

# installer/build로 복사
cp installer/linux/mula_install.sh installer/build/
```

---

### 5.2 GitHub Release 생성

#### Step 1: 버전 태깅

```bash
# Git 태그 생성
git tag -a v0.3.0 -m "Release v0.3.0 - Phase 2 Complete"

# 태그 푸시
git push origin v0.3.0
```

#### Step 2: GitHub Release 생성 (수동)

```
1. GitHub Repository > Releases
2. "Draft a new release" 클릭
3. 릴리스 정보 입력:

   Tag: v0.3.0
   Title: ABADA Music Studio v0.3.0 - Phase 2 Complete
   Description:
   ---
   ## What's New in v0.3.0

   ### 🚀 Features
   - One-click installer for Windows/macOS/Linux
   - AI music generation powered by HeartMuLa
   - Web-based Gradio UI
   - Offline operation (no internet required after installation)

   ### 🐛 Bug Fixes
   - Fixed GPU detection on Windows
   - Improved model download stability
   - Enhanced error messages

   ### 📦 Downloads
   - **Windows x64**: MuLa_Setup_x64.exe
   - **macOS**: MuLa_Installer.dmg
   - **Linux**: mula_install.sh

   ### 📋 System Requirements
   - Windows 10/11, macOS 12+, or Linux
   - 15GB free disk space
   - 8GB RAM (16GB recommended for GPU)
   - NVIDIA GPU (optional, for faster generation)

   ### 🔗 Links
   - Website: https://music.abada.kr
   - Documentation: https://github.com/saintgo7/web-music-heartlib/docs
   - Issues: https://github.com/saintgo7/web-music-heartlib/issues
   ---

4. 파일 첨부:
   - MuLa_Setup_x64.exe
   - MuLa_Installer.dmg
   - mula_install.sh

5. "Publish release" 클릭
```

#### Step 3: GitHub Actions 자동 릴리스

**워크플로우**: `.github/workflows/build-installers.yml`

```yaml
name: Build & Release Installers

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install NSIS
        run: |
          choco install nsis -y

      - name: Build Windows Installer
        run: |
          cd installer/windows
          makensis MuLaInstaller_x64.nsi

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: windows-installer
          path: installer/build/MuLa_Setup_x64.exe

  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build macOS DMG
        run: |
          brew install create-dmg
          cd installer/macos
          ./build_dmg.sh

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: macos-installer
          path: installer/build/MuLa_Installer.dmg

  create-release:
    needs: [build-windows, build-macos]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Download artifacts
        uses: actions/download-artifact@v4

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            windows-installer/MuLa_Setup_x64.exe
            macos-installer/MuLa_Installer.dmg
            installer/linux/mula_install.sh
          body_path: CHANGELOG.md
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**트리거**:
```bash
# 태그 푸시하면 자동 실행
git tag v0.3.0
git push origin v0.3.0

# 또는 수동 트리거
# GitHub Repository > Actions > Build & Release > Run workflow
```

---

## VI. 배포 검증

### 6.1 웹사이트 검증

**체크리스트**:
- [ ] https://music.abada.kr 접속 성공
- [ ] HTTPS 자물쇠 아이콘 표시
- [ ] 모든 페이지 로드 (6개)
- [ ] 이미지 및 CSS 정상 로드
- [ ] 반응형 디자인 (모바일/태블릿/데스크톱)
- [ ] 404 페이지 처리
- [ ] 콘솔 에러 없음

**자동 테스트**:
```bash
# Lighthouse 점수
lighthouse https://music.abada.kr --output html

# 응답 시간
curl -w "@curl-format.txt" -o /dev/null -s https://music.abada.kr

# curl-format.txt:
# time_namelookup:  %{time_namelookup}\n
# time_connect:     %{time_connect}\n
# time_starttransfer: %{time_starttransfer}\n
# time_total:       %{time_total}\n
```

---

### 6.2 API 검증

**체크리스트**:
- [ ] /api/download-stats (GET) 응답
- [ ] /api/download-stats (POST) 정상 작동
- [ ] /api/gallery (GET) 응답
- [ ] /api/analytics (POST) 정상 작동
- [ ] CORS 헤더 존재
- [ ] 에러 처리 (404, 500)
- [ ] Rate limiting 작동

**테스트 스크립트**:
```bash
#!/bin/bash
# test-api.sh

BASE_URL="https://music.abada.kr"

echo "Testing Download Stats API..."
curl -s "$BASE_URL/api/download-stats" | jq .

echo "Testing Gallery API..."
curl -s "$BASE_URL/api/gallery" | jq .

echo "Testing Analytics API..."
curl -X POST "$BASE_URL/api/analytics" \
  -H "Content-Type: application/json" \
  -d '{"event":"page_view","page":"/"}' \
  | jq .

echo "Testing CORS..."
curl -I -X OPTIONS "$BASE_URL/api/download-stats"

echo "All tests passed!"
```

---

### 6.3 설치 프로그램 검증

**Windows**:
```
1. MuLa_Setup_x64.exe 다운로드
2. 더블클릭 실행
3. 설치 프로세스 완료 대기 (20-30분)
4. "MuLa Studio" 바로가기 실행
5. 브라우저에서 Gradio UI 열림 확인
6. 테스트 음악 생성
```

**macOS**:
```
1. MuLa_Installer.dmg 다운로드
2. DMG 마운트
3. install.sh 실행
4. 설치 완료 대기
5. Desktop에서 "MuLa Studio" 더블클릭
6. 테스트 음악 생성
```

**Linux**:
```bash
# Ubuntu/Debian
wget https://github.com/saintgo7/web-music-heartlib/releases/download/v0.3.0/mula_install.sh
chmod +x mula_install.sh
./mula_install.sh

# 설치 완료 후
~/.mulastudio/run.sh
```

---

## VII. 롤백 절차

### 7.1 웹사이트 롤백

**Cloudflare Pages에서 이전 버전으로 롤백**:
```
1. Cloudflare 대시보드 > Pages > abada-music-studio
2. "Deployments" 탭
3. 이전 배포 선택
4. "Rollback to this deployment" 클릭
5. 확인
```

**Git 롤백**:
```bash
# 이전 커밋으로 되돌리기
git revert HEAD
git push origin main

# 특정 커밋으로 롤백
git reset --hard <commit-hash>
git push origin main --force
```

---

### 7.2 Workers 롤백

**이전 버전 배포**:
```bash
# 버전 리스트 확인
wrangler deployments list

# 특정 버전으로 롤백
wrangler rollback --message "Rollback to previous version"
```

---

### 7.3 Release 롤백

**GitHub Release 삭제**:
```
1. GitHub Repository > Releases
2. 문제가 있는 릴리스 선택
3. "Delete" 클릭
4. 태그도 삭제:
   git tag -d v0.3.0
   git push origin :refs/tags/v0.3.0
```

**이전 버전 다시 게시**:
```
1. 이전 릴리스 선택
2. "Edit release"
3. "Update release" (Latest 체크)
```

---

## VIII. 모니터링 및 유지보수

### 8.1 실시간 모니터링

**Cloudflare Analytics**:
```
1. Cloudflare 대시보드 > Analytics
2. 확인 항목:
   - Total Requests
   - Bandwidth
   - Error Rate (4xx, 5xx)
   - Response Time
```

**GitHub Actions 모니터링**:
```
1. GitHub Repository > Actions
2. 워크플로우 실행 이력 확인
3. 실패한 워크플로우 디버깅
```

---

### 8.2 로그 확인

**Cloudflare Workers 로그**:
```bash
# 실시간 로그 확인
wrangler tail

# 출력:
# [2026-01-19 12:00:00] GET /api/download-stats - 200 OK (10ms)
# [2026-01-19 12:00:05] POST /api/analytics - 200 OK (5ms)
```

**GitHub Actions 로그**:
```
1. GitHub Repository > Actions
2. 워크플로우 선택
3. Job 선택
4. Step별 로그 확인
```

---

### 8.3 정기 점검

**주간 점검** (매주 월요일):
- [ ] 웹사이트 접속 확인
- [ ] API 응답 시간 확인
- [ ] GitHub Actions 성공률 확인
- [ ] 다운로드 통계 리뷰

**월간 점검** (매월 1일):
- [ ] Cloudflare 사용량 확인
- [ ] GitHub Actions 사용량 확인
- [ ] 성능 리포트 작성
- [ ] 보안 업데이트 적용

---

## IX. 긴급 대응

### 9.1 웹사이트 다운

**증상**: music.abada.kr 접속 불가

**대응**:
```
1. Cloudflare Status 확인 (https://www.cloudflarestatus.com/)
2. DNS 전파 확인 (dig music.abada.kr)
3. Cloudflare Pages 배포 상태 확인
4. 최근 배포 롤백
5. GitHub Issues 등록
```

---

### 9.2 API 오류

**증상**: API 응답 500 에러

**대응**:
```bash
# Workers 로그 확인
wrangler tail

# KV 네임스페이스 확인
wrangler kv:key list --namespace-id=<NAMESPACE_ID>

# 긴급 수정 및 재배포
wrangler deploy
```

---

### 9.3 설치 프로그램 문제

**증상**: 설치 실패 보고

**대응**:
```
1. GitHub Issues 확인
2. 로그 파일 요청
3. 재현 환경 구축 (VM)
4. 버그 수정
5. 핫픽스 릴리스 (v0.3.1)
```

---

## X. 배포 체크리스트

### 10.1 사전 배포 체크리스트

**코드 준비**:
- [ ] 모든 테스트 통과
- [ ] 코드 리뷰 완료
- [ ] CHANGELOG.md 업데이트
- [ ] 버전 번호 업데이트

**환경 준비**:
- [ ] Cloudflare API Token 유효
- [ ] GitHub Secrets 설정
- [ ] DNS 설정 확인
- [ ] SSL 인증서 유효

**문서 준비**:
- [ ] README.md 업데이트
- [ ] 릴리스 노트 작성
- [ ] 사용자 가이드 업데이트

---

### 10.2 배포 중 체크리스트

**웹사이트 배포**:
- [ ] Cloudflare Pages 빌드 성공
- [ ] 배포 완료 확인
- [ ] 커스텀 도메인 활성화
- [ ] SSL 인증서 발급

**API 배포**:
- [ ] KV 네임스페이스 생성
- [ ] Workers 배포 성공
- [ ] Routes 설정 완료
- [ ] CORS 검증

**설치 프로그램 배포**:
- [ ] Windows 빌드 성공
- [ ] macOS 빌드 성공 (선택)
- [ ] Linux 스크립트 준비
- [ ] GitHub Release 생성

---

### 10.3 배포 후 체크리스트

**검증**:
- [ ] 웹사이트 접속 확인
- [ ] API 응답 확인
- [ ] 설치 프로그램 다운로드 확인
- [ ] 모든 기능 테스트

**모니터링**:
- [ ] Cloudflare Analytics 활성화
- [ ] 에러 로그 모니터링
- [ ] 성능 지표 확인

**공지**:
- [ ] 사용자 공지 (선택)
- [ ] 소셜 미디어 포스팅 (선택)
- [ ] 팀 공유

---

## XI. 부록

### A. 환경 변수 목록

**GitHub Actions Secrets**:
```
CLOUDFLARE_API_TOKEN     # Cloudflare API 토큰
CLOUDFLARE_ACCOUNT_ID    # Cloudflare 계정 ID
GITHUB_TOKEN             # GitHub 자동 생성 (별도 설정 불필요)
```

**Cloudflare Workers Environment**:
```
NODE_ENV=production
```

---

### B. 유용한 명령어

**Cloudflare Pages**:
```bash
# 배포 이력 확인
wrangler pages deployment list --project-name=abada-music-studio

# 특정 배포 롤백
wrangler pages deployment rollback <deployment-id>
```

**Cloudflare Workers**:
```bash
# Workers 리스트
wrangler list

# Workers 로그 (실시간)
wrangler tail abada-music-api

# Workers 삭제
wrangler delete abada-music-api
```

**Cloudflare KV**:
```bash
# KV 리스트
wrangler kv:namespace list

# KV 키 조회
wrangler kv:key list --namespace-id=<ID>

# KV 값 조회
wrangler kv:key get "stats" --namespace-id=<ID>

# KV 값 설정
wrangler kv:key put "stats" '{"total":0}' --namespace-id=<ID>
```

---

### C. 트러블슈팅

**문제**: DNS 전파 안 됨
```bash
# DNS 전파 확인
dig music.abada.kr @8.8.8.8
dig music.abada.kr @1.1.1.1

# TTL 확인 (낮출수록 빠름)
dig music.abada.kr +noall +answer
```

**문제**: SSL 인증서 발급 실패
```
1. Cloudflare > SSL/TLS > Edge Certificates
2. "Universal SSL" 활성화 확인
3. DNS Proxy (오렌지 구름) 활성화
4. 24시간 대기
```

**문제**: Workers 배포 실패
```bash
# 로그 확인
wrangler deploy --verbose

# wrangler.toml 검증
wrangler validate

# 캐시 삭제 후 재시도
rm -rf node_modules .wrangler
npm install
wrangler deploy
```

---

### D. 연락처

**기술 지원**:
- GitHub Issues: https://github.com/saintgo7/web-music-heartlib/issues
- Email: heartmula.ai@gmail.com

**Cloudflare 지원**:
- 문서: https://developers.cloudflare.com/
- 커뮤니티: https://community.cloudflare.com/

**GitHub 지원**:
- 문서: https://docs.github.com/
- 지원: https://support.github.com/

---

**문서 버전**: v2.0
**작성자**: technical-writer (AI Agent)
**다음 업데이트**: 실제 배포 완료 후 (2026-01-29)
