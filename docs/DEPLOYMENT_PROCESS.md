# ABADA Music Studio - 배포 프로세스 가이드

**버전**: 1.0.0
**최종 업데이트**: 2026-01-21
**상태**: Production Ready

---

## 목차

1. [배포 아키텍처 개요](#1-배포-아키텍처-개요)
2. [설치 프로그램 배포](#2-설치-프로그램-배포)
3. [웹사이트 배포](#3-웹사이트-배포)
4. [Cloudflare 인프라](#4-cloudflare-인프라)
5. [환경별 설정](#5-환경별-설정)
6. [배포 명령어](#6-배포-명령어)
7. [초기 설정 가이드](#7-초기-설정-가이드)
8. [트러블슈팅](#8-트러블슈팅)

---

## 1. 배포 아키텍처 개요

### 1.1 시스템 구성도

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          GitHub Repository                              │
│                    saintgo7/web-music-heartlib                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
            ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
            │ Tag Push     │ │ main Push    │ │ Manual       │
            │ (v*.*.*)     │ │ (web/func)   │ │ Dispatch     │
            └──────────────┘ └──────────────┘ └──────────────┘
                    │               │               │
                    ▼               ▼               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     GitHub Actions Workflows                            │
├─────────────────────────────────────────────────────────────────────────┤
│  build-installers.yml          deploy-website.yml                       │
│  ┌───────────────────┐         ┌───────────────────┐                   │
│  │ Windows x64/x86   │         │ Build Website     │                   │
│  │ macOS Universal   │         │ Deploy Pages      │                   │
│  │ Linux Script      │         │ Deploy Workers    │                   │
│  │ GitHub Release    │         │ Health Checks     │                   │
│  └───────────────────┘         │ Auto-Rollback     │                   │
│                                └───────────────────┘                   │
└─────────────────────────────────────────────────────────────────────────┘
                    │                       │
                    ▼                       ▼
    ┌───────────────────────┐   ┌───────────────────────────────────┐
    │   GitHub Releases     │   │        Cloudflare                 │
    │  ┌─────────────────┐  │   │  ┌─────────────┐ ┌─────────────┐  │
    │  │ MuLa_Setup_x64  │  │   │  │   Pages     │ │  Workers    │  │
    │  │ MuLa_Setup_x86  │  │   │  │ (Website)   │ │  (API)      │  │
    │  │ MuLa_Installer  │  │   │  └─────────────┘ └─────────────┘  │
    │  │ mula_install.sh │  │   │         │               │         │
    │  └─────────────────┘  │   │         ▼               ▼         │
    └───────────────────────┘   │  ┌─────────────────────────────┐  │
                                │  │    music.abada.kr           │  │
                                │  │    (Production Domain)      │  │
                                │  └─────────────────────────────┘  │
                                └───────────────────────────────────┘
```

### 1.2 배포 흐름 요약

| 트리거 | 워크플로우 | 결과물 | 배포 대상 |
|--------|------------|--------|-----------|
| `v*.*.*` 태그 푸시 | build-installers.yml | 설치 프로그램 4종 | GitHub Releases |
| main 브랜치 푸시 (web/) | deploy-website.yml | 정적 웹사이트 | Cloudflare Pages |
| main 브랜치 푸시 (functions/) | deploy-website.yml | Workers API | Cloudflare Workers |
| 수동 실행 | 선택 가능 | 선택 가능 | 선택 가능 |

### 1.3 GitHub Actions 워크플로우 목록

| 파일명 | 용도 | 트리거 |
|--------|------|--------|
| `build-installers.yml` | 멀티 OS 설치 프로그램 빌드 | 태그 푸시, 수동 |
| `deploy-website.yml` | 웹사이트 및 API 배포 | main 푸시, 수동 |
| `lint-and-test.yml` | 코드 품질 검증 | PR, 푸시 |
| `e2e-tests.yml` | E2E 테스트 | PR, 수동 |
| `security-scan.yml` | 보안 스캔 | 예약, 수동 |
| `health-check.yml` | 프로덕션 헬스체크 | 예약 |
| `backup.yml` | 데이터 백업 | 예약 |

---

## 2. 설치 프로그램 배포

### 2.1 빌드 매트릭스

| 플랫폼 | 러너 | 도구 | 출력물 | 비고 |
|--------|------|------|--------|------|
| Windows x64 | windows-latest | NSIS 3.x | `MuLa_Setup_x64.exe` | GPU 지원 (CUDA) |
| Windows x86 | windows-latest | NSIS 3.x | `MuLa_Setup_x86.exe` | CPU 전용 |
| macOS | macos-latest | create-dmg | `MuLa_Installer.dmg` | Universal (Intel + Apple Silicon) |
| Linux | ubuntu-latest | Shell | `mula_install.sh` | Ubuntu, Fedora, Arch 지원 |

### 2.2 Windows 빌드 프로세스

```
┌─────────────────────────────────────────────────────────────────┐
│                    Windows x64 Build Flow                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Checkout Repository                                         │
│           │                                                     │
│           ▼                                                     │
│  2. Install NSIS (via Chocolatey)                              │
│           │                                                     │
│           ▼                                                     │
│  3. Download Python 3.10 Embedded (amd64)                      │
│           │                                                     │
│           ▼                                                     │
│  4. Extract Python to build/python/                            │
│           │                                                     │
│           ▼                                                     │
│  5. Modify NSIS Script (pre-extracted Python)                  │
│           │                                                     │
│           ▼                                                     │
│  6. Build NSIS Installer                                        │
│      makensis /DVERSION=x.x.x MuLaInstaller_x64.nsi            │
│           │                                                     │
│           ▼                                                     │
│  7. Upload Artifact (MuLa_Setup_x64.exe)                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 NSIS 설치 프로그램 기능

```nsi
; MuLaInstaller_x64.nsi 주요 기능

1. 시스템 요구사항 검증
   - 64비트 Windows 확인
   - 디스크 공간 확인 (15GB)
   - RAM 확인 (8GB 권장)

2. GPU 감지
   - nvidia-smi 실행
   - CUDA 지원 GPU 감지
   - GPU 없으면 CPU 모드

3. Python 환경 설정
   - Python 3.10 embed 설치
   - pip 설치
   - 가상환경 불필요 (embed)

4. PyTorch 설치
   - GPU 감지 결과에 따라:
     - CUDA: torch+cu118
     - CPU: torch+cpu

5. 모델 다운로드
   - HeartMuLaGen (~2GB)
   - HeartMuLa-oss-3B (~3GB)
   - HeartCodec-oss (~1GB)

6. 바로가기 생성
   - Desktop
   - Start Menu

7. 언인스톨러 생성
```

### 2.4 macOS 빌드 프로세스

```
1. install.sh 검증 (bash -n)
2. App Bundle 구조 생성
   MuLa Installer.app/
   ├── Contents/
   │   ├── MacOS/
   │   │   └── install (launcher)
   │   ├── Resources/
   │   │   ├── install.sh
   │   │   ├── main.py
   │   │   └── download_models.py
   │   └── Info.plist
3. Ad-hoc Code Signing (codesign --sign -)
4. DMG 생성 (create-dmg)
5. DMG Signing
```

### 2.5 Linux 설치 스크립트 기능

```bash
# mula_install.sh 주요 기능

1. 시스템 검사
   - x86_64 아키텍처 확인
   - Python 3.10+ 확인
   - nvidia-smi로 GPU 감지
   - 디스크 공간 확인 (15GB)

2. 가상환경 생성
   - ~/.mulastudio/venv

3. PyTorch 설치
   - CUDA 또는 CPU 버전

4. 의존성 설치
   - gradio, huggingface_hub, tqdm

5. 모델 다운로드
   - HuggingFace Hub 사용

6. 런처 생성
   - ~/.local/bin/mulastudio
   - Desktop Entry (.desktop)

7. 언인스톨러 생성
   - ~/.mulastudio/uninstall.sh
```

### 2.6 GitHub Release 생성

태그 푸시 시 자동으로 Release 생성:

```yaml
# 릴리스 에셋
dist/
├── MuLa_Setup_x64.exe    # Windows 64-bit
├── MuLa_Setup_x86.exe    # Windows 32-bit
├── MuLa_Installer.dmg    # macOS Universal
├── mula_install.sh       # Linux
└── checksums.txt         # SHA256 체크섬
```

---

## 3. 웹사이트 배포

### 3.1 배포 파이프라인

```
┌─────────────────────────────────────────────────────────────────┐
│                  Website Deployment Pipeline                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐                                              │
│  │ Pre-deploy   │ ─── 변경 감지, 버전 추출, Secrets 검증        │
│  └──────┬───────┘                                              │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                              │
│  │ Build        │ ─── npm ci, vite build, artifact upload      │
│  └──────┬───────┘                                              │
│         │                                                       │
│         ├─────────────────────┐                                │
│         ▼                     ▼                                │
│  ┌──────────────┐      ┌──────────────┐                        │
│  │ Deploy Pages │      │ Deploy       │                        │
│  │ (Website)    │      │ Workers(API) │                        │
│  └──────┬───────┘      └──────┬───────┘                        │
│         │                     │                                │
│         └─────────┬───────────┘                                │
│                   ▼                                            │
│  ┌──────────────────────────────┐                              │
│  │ Health Checks                │                              │
│  │ - Website accessibility      │                              │
│  │ - API health (/api/health)   │                              │
│  │ - Critical pages check       │                              │
│  └──────────────┬───────────────┘                              │
│                 │                                              │
│        ┌────────┴────────┐                                     │
│        ▼                 ▼                                     │
│  ┌──────────┐      ┌──────────┐                                │
│  │ Success  │      │ Failure  │                                │
│  │ Summary  │      │ Rollback │                                │
│  └──────────┘      └──────────┘                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 웹사이트 빌드 설정

```javascript
// vite.config.ts
export default defineConfig({
  build: {
    outDir: 'dist',
    sourcemap: false,
    minify: 'terser',
  },
  // Environment Variables
  // VITE_APP_VERSION: package.json version
  // VITE_API_URL: https://music.abada.kr/api
});
```

### 3.3 Cloudflare Pages 설정

| 항목 | 값 |
|------|-----|
| 프로젝트 이름 | `abada-music` |
| 빌드 출력 | `web/dist` |
| 프로덕션 브랜치 | `main` |
| 프로덕션 URL | `https://music.abada.kr` |
| Pages URL | `https://abada-music.pages.dev` |

### 3.4 Health Check 항목

```yaml
Health Checks:
  Website Accessibility:
    - https://abada-music.pages.dev (200 OK)
    - https://music.abada.kr (200 OK)

  API Health:
    - https://music.abada.kr/api/health
    - Expected: {"status":"ok"}

  Critical Pages:
    - / (Home)
    - /download
    - /gallery
    - /tutorial
    - /faq
    - /about
```

### 3.5 Auto-Rollback 조건

Health Check 실패 시:
1. Cloudflare Workers 자동 롤백
2. Slack 알림 (설정 시)
3. GitHub Summary에 기록
4. Pages는 수동 롤백 필요 (Dashboard)

---

## 4. Cloudflare 인프라

### 4.1 Workers API 구조

```
functions/api/
├── index.js          # 메인 라우터
├── download-stats.js # 다운로드 통계 API
├── gallery.js        # 갤러리 API
└── analytics.js      # 분석 API
```

### 4.2 KV Namespaces

| Binding | 용도 | TTL |
|---------|------|-----|
| `STATS` | 다운로드 통계 | 300초 (5분) |
| `GALLERY` | 음악 샘플 메타데이터 | 3600초 (1시간) |
| `ANALYTICS` | 사용자 분석 이벤트 | - |

### 4.3 API 엔드포인트

```
GET  /api/health           # 헬스체크
GET  /api/stats            # 다운로드 통계
POST /api/stats/increment  # 통계 증가
GET  /api/gallery          # 갤러리 목록
GET  /api/gallery/:id      # 갤러리 상세
POST /api/analytics        # 분석 이벤트 기록
```

### 4.4 wrangler.toml 주요 설정

```toml
name = "abada-music-api"
main = "functions/api/index.js"
compatibility_date = "2024-01-01"
compatibility_flags = ["nodejs_compat"]

# KV Namespaces
[[kv_namespaces]]
binding = "STATS"
id = "YOUR_STATS_KV_ID"

[[kv_namespaces]]
binding = "GALLERY"
id = "YOUR_GALLERY_KV_ID"

[[kv_namespaces]]
binding = "ANALYTICS"
id = "YOUR_ANALYTICS_KV_ID"

# Environment Variables
[vars]
ENVIRONMENT = "production"
APP_NAME = "ABADA Music Studio"
WEBSITE_URL = "https://music.abada.kr"
RATE_LIMIT_REQUESTS = "100"
RATE_LIMIT_WINDOW = "60"
```

---

## 5. 환경별 설정

### 5.1 환경 비교

| 항목 | Development | Staging | Production |
|------|-------------|---------|------------|
| Worker 이름 | abada-music-api-dev | abada-music-api-staging | abada-music-api |
| LOG_LEVEL | debug | debug | warn |
| CORS | 전체 허용 | 전체 허용 | 제한 |
| Analytics | 비활성화 | 활성화 | 활성화 |
| Rate Limit | 없음 | 100/분 | 100/분 |
| URL | localhost:5173 | staging.music.abada.kr | music.abada.kr |

### 5.2 배포 명령어 (환경별)

```bash
# Development (로컬)
wrangler dev

# Staging
wrangler deploy --env staging

# Production
wrangler deploy --env production
# 또는
wrangler deploy  # 기본값
```

---

## 6. 배포 명령어

### 6.1 로컬 개발

```bash
# 웹사이트 개발 서버
cd web
npm install
npm run dev
# http://localhost:5173

# API 개발 서버
wrangler dev
# http://localhost:8787
```

### 6.2 빌드

```bash
# 웹사이트 빌드
cd web
npm run build
# 출력: web/dist/

# Windows 설치 프로그램 (NSIS 필요)
cd installer/windows
makensis /DVERSION=1.0.0 MuLaInstaller_x64.nsi
```

### 6.3 배포

```bash
# 웹사이트 배포 (자동 - GitHub Actions)
git push origin main

# 릴리스 배포 (자동 - GitHub Actions)
git tag v1.0.0
git push origin v1.0.0

# Workers 수동 배포
wrangler deploy

# Pages 수동 배포
wrangler pages deploy web/dist --project-name=abada-music
```

### 6.4 모니터링

```bash
# Workers 로그 실시간 확인
wrangler tail
wrangler tail --format=json

# 배포 목록 확인
wrangler deployments list

# 특정 배포 상세
wrangler deployments view <deployment-id>

# 롤백
wrangler rollback
```

### 6.5 KV 관리

```bash
# 키 목록
wrangler kv:key list --namespace-id=YOUR_KV_ID

# 키 조회
wrangler kv:key get --namespace-id=YOUR_KV_ID "key"

# 키 설정
wrangler kv:key put --namespace-id=YOUR_KV_ID "key" "value"

# 키 삭제
wrangler kv:key delete --namespace-id=YOUR_KV_ID "key"
```

---

## 7. 초기 설정 가이드

### 7.1 사전 요구사항

- GitHub 계정 (저장소 접근 권한)
- Cloudflare 계정 (Free 플랜 이상)
- Node.js 20+ (로컬 개발)
- Wrangler CLI (`npm install -g wrangler`)

### 7.2 Cloudflare 설정

#### Step 1: API Token 생성

```
1. Cloudflare Dashboard > My Profile > API Tokens
2. Create Token > Create Custom Token
3. 권한 설정:
   - Account > Cloudflare Pages > Edit
   - Account > Workers Scripts > Edit
   - Account > Workers KV Storage > Edit
4. Token 저장 (한 번만 표시됨)
```

#### Step 2: KV Namespaces 생성

```bash
# STATS namespace
wrangler kv:namespace create "STATS"
wrangler kv:namespace create "STATS" --preview

# GALLERY namespace
wrangler kv:namespace create "GALLERY"
wrangler kv:namespace create "GALLERY" --preview

# ANALYTICS namespace
wrangler kv:namespace create "ANALYTICS"
wrangler kv:namespace create "ANALYTICS" --preview
```

#### Step 3: wrangler.toml 업데이트

생성된 namespace ID를 `wrangler.toml`에 입력:

```toml
[[kv_namespaces]]
binding = "STATS"
id = "생성된_STATS_ID"
preview_id = "생성된_STATS_PREVIEW_ID"
```

#### Step 4: Pages 프로젝트 생성

```bash
# 방법 1: CLI
wrangler pages project create abada-music

# 방법 2: Dashboard
# Cloudflare Dashboard > Pages > Create a project
# Direct Upload 선택
```

#### Step 5: DNS 설정 (Custom Domain)

```
1. Cloudflare Dashboard > DNS
2. Add Record:
   - Type: CNAME
   - Name: music
   - Target: abada-music.pages.dev
   - Proxy: On
```

### 7.3 GitHub Secrets 설정

```
Repository > Settings > Secrets and variables > Actions

필수 Secrets:
- CLOUDFLARE_API_TOKEN: Cloudflare API Token
- CLOUDFLARE_ACCOUNT_ID: Cloudflare Account ID

선택 Secrets:
- SLACK_WEBHOOK_URL: Slack 알림용 Webhook URL
- ADMIN_API_KEY: 관리자 API 키
```

### 7.4 첫 배포 테스트

```bash
# 1. 웹사이트 배포 테스트
git checkout main
echo "test" >> test.txt
git add test.txt
git commit -m "test: deployment trigger"
git push origin main
# GitHub Actions 확인

# 2. 릴리스 배포 테스트
git tag v0.1.0-test
git push origin v0.1.0-test
# GitHub Releases 확인

# 3. 테스트 정리
git push origin --delete v0.1.0-test
```

---

## 8. 트러블슈팅

### 8.1 일반적인 문제

#### Workers 배포 실패

```
Error: Authentication error

해결:
1. CLOUDFLARE_API_TOKEN 확인
2. Token 권한 확인 (Workers Scripts Edit)
3. Account ID 확인
```

#### KV Namespace 오류

```
Error: KV namespace not found

해결:
1. wrangler.toml의 namespace ID 확인
2. namespace 생성 여부 확인:
   wrangler kv:namespace list
```

#### Pages 배포 실패

```
Error: Project not found

해결:
1. Pages 프로젝트 이름 확인 (abada-music)
2. 프로젝트 생성:
   wrangler pages project create abada-music
```

### 8.2 빌드 실패

#### NSIS 빌드 오류

```
Error: makensis not found

해결 (Windows):
choco install nsis -y

해결 (macOS):
brew install makensis
```

#### npm 빌드 오류

```
Error: Cannot find module

해결:
cd web
rm -rf node_modules package-lock.json
npm install
npm run build
```

### 8.3 Health Check 실패

```
Health check failed: API

확인사항:
1. Workers 배포 상태
2. KV namespace 연결
3. 환경 변수 설정
4. 로그 확인: wrangler tail
```

### 8.4 롤백 방법

```bash
# Workers 롤백
wrangler rollback

# 특정 버전으로 롤백
wrangler deployments list
wrangler rollback --deployment-id=<id>

# Pages 롤백
# Cloudflare Dashboard > Pages > Deployments > Rollback
```

---

## 부록

### A. 파일 구조

```
.github/workflows/
├── build-installers.yml    # 설치 프로그램 빌드
├── deploy-website.yml      # 웹사이트/API 배포
├── lint-and-test.yml       # 코드 품질
├── e2e-tests.yml           # E2E 테스트
├── security-scan.yml       # 보안 스캔
├── health-check.yml        # 헬스체크
└── backup.yml              # 백업

installer/
├── windows/
│   ├── MuLaInstaller_x64.nsi
│   └── build_windows.bat
├── macos/
│   ├── install.sh
│   └── build_dmg.sh
├── linux/
│   └── mula_install.sh
└── app/
    ├── main.py
    └── download_models.py

functions/api/
├── index.js
├── download-stats.js
├── gallery.js
└── analytics.js

web/
├── src/
├── public/
├── package.json
├── vite.config.ts
└── tailwind.config.js

wrangler.toml
```

### B. 관련 문서

- [MASTER_PLAN.md](./MASTER_PLAN.md) - 전체 개발 계획
- [DEPLOYMENT.md](./DEPLOYMENT.md) - 배포 가이드 (v1)
- [PROJECT_STATUS.md](../PROJECT_STATUS.md) - 프로젝트 상태
- [ROADMAP.md](../ROADMAP.md) - 로드맵

### C. 외부 링크

- [Cloudflare Workers 문서](https://developers.cloudflare.com/workers/)
- [Cloudflare Pages 문서](https://developers.cloudflare.com/pages/)
- [Wrangler CLI 문서](https://developers.cloudflare.com/workers/wrangler/)
- [NSIS 문서](https://nsis.sourceforge.io/Docs/)
- [GitHub Actions 문서](https://docs.github.com/en/actions)

---

**문서 작성**: Claude Code
**최종 검토**: 2026-01-21
