# ABADA Music Studio - Cloudflare 설정 가이드

이 문서는 ABADA Music Studio 웹사이트를 Cloudflare Pages에 배포하고 Cloudflare Workers API를 설정하는 방법을 설명합니다.

---

## 목차

1. [사전 준비](#1-사전-준비)
2. [Cloudflare 계정 설정](#2-cloudflare-계정-설정)
3. [Cloudflare Pages 설정](#3-cloudflare-pages-설정)
4. [DNS 설정 (CNAME)](#4-dns-설정-cname)
5. [Cloudflare Workers 설정](#5-cloudflare-workers-설정)
6. [KV Namespace 설정](#6-kv-namespace-설정)
7. [환경 변수 설정](#7-환경-변수-설정)
8. [GitHub Actions Secrets 설정](#8-github-actions-secrets-설정)
9. [배포 테스트](#9-배포-테스트)
10. [트러블슈팅](#10-트러블슈팅)

---

## 1. 사전 준비

### 필수 요구사항

| 항목 | 설명 |
|------|------|
| Cloudflare 계정 | [cloudflare.com](https://cloudflare.com)에서 무료 가입 |
| GitHub 계정 | 저장소 접근 권한 필요 |
| Node.js 18+ | 로컬 개발 및 테스트용 |
| Wrangler CLI | Cloudflare Workers 배포 도구 |

### Wrangler CLI 설치

```bash
# npm으로 설치
npm install -g wrangler

# 또는 pnpm으로 설치
pnpm add -g wrangler

# 설치 확인
wrangler --version
```

### Wrangler 로그인

```bash
# Cloudflare 계정으로 로그인
wrangler login

# 로그인 확인
wrangler whoami
```

---

## 2. Cloudflare 계정 설정

### Account ID 확인

1. [Cloudflare Dashboard](https://dash.cloudflare.com) 접속
2. 좌측 메뉴에서 **Workers & Pages** 선택
3. 우측 사이드바에서 **Account ID** 확인
4. 복사하여 안전한 곳에 저장

```
Account ID 위치:
Dashboard > Workers & Pages > Overview (우측 하단)

예시: 1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p
```

### API Token 발급

1. [API Tokens](https://dash.cloudflare.com/profile/api-tokens) 페이지 이동
2. **Create Token** 클릭
3. **Edit Cloudflare Workers** 템플릿 선택
4. 권한 설정:

```yaml
# 필요한 권한
Account:
  - Cloudflare Workers Scripts: Edit
  - Workers KV Storage: Edit
  - Cloudflare Pages: Edit

Zone (Optional - 커스텀 도메인 사용시):
  - DNS: Edit
  - Zone: Read
```

5. **Continue to summary** 클릭
6. **Create Token** 클릭
7. 토큰을 **즉시 복사** (다시 볼 수 없음)

```
API Token 형식:
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx_xxxxxxxx

예시: abCDeFgHiJkLmNoPqRsTuVwXyZ1234567890_AbCdEf
```

---

## 3. Cloudflare Pages 설정

### 3.1 Pages 프로젝트 생성

#### 방법 A: 대시보드에서 생성

1. [Cloudflare Dashboard](https://dash.cloudflare.com) 접속
2. **Workers & Pages** 메뉴 선택
3. **Create** 버튼 클릭
4. **Pages** 탭 선택
5. **Connect to Git** 클릭

#### 방법 B: Wrangler CLI로 생성

```bash
# 프로젝트 디렉토리로 이동
cd /path/to/web-music-heartlib

# 웹사이트 빌드
cd web && npm install && npm run build && cd ..

# Pages 프로젝트 생성 및 배포
wrangler pages project create abada-music

# 첫 배포
wrangler pages deploy web/build --project-name=abada-music
```

### 3.2 GitHub 연동

1. Pages 프로젝트 설정에서 **Connect to Git** 선택
2. **GitHub** 선택 후 권한 승인
3. 저장소 선택: `saintgo7/web-music-heartlib`
4. 빌드 설정:

```yaml
# Production branch
Branch: main

# Build settings
Framework preset: None
Build command: cd web && npm install && npm run build
Build output directory: web/build
Root directory: (empty)

# Environment variables
NODE_ENV: production
```

### 3.3 빌드 설정 상세

| 항목 | 값 | 설명 |
|------|-----|------|
| Production branch | `main` | 프로덕션 배포 브랜치 |
| Preview branches | `*` | 모든 브랜치 미리보기 |
| Build command | `cd web && npm install && npm run build` | 빌드 명령어 |
| Build output | `web/build` | 빌드 결과물 경로 |
| Root directory | (empty) | 루트 디렉토리 |

---

## 4. DNS 설정 (CNAME)

### 4.1 Cloudflare에서 제공하는 Pages URL 확인

배포 후 다음 형식의 URL이 생성됩니다:

```
https://abada-music.pages.dev
```

### 4.2 커스텀 도메인 설정 (music.abada.kr)

#### Cloudflare Pages에서 설정

1. Pages 프로젝트 선택
2. **Settings** > **Custom domains** 이동
3. **Set up a custom domain** 클릭
4. `music.abada.kr` 입력

#### DNS 레코드 추가

**abada.kr 도메인이 Cloudflare에서 관리되는 경우:**

Cloudflare가 자동으로 DNS 레코드를 추가합니다.

**abada.kr 도메인이 다른 DNS 공급자에서 관리되는 경우:**

해당 DNS 공급자 (예: 가비아, 카페24, AWS Route53)에서 다음 레코드 추가:

```dns
# CNAME 레코드 추가
Type:    CNAME
Name:    music
Target:  abada-music.pages.dev
TTL:     Auto (또는 3600)
Proxy:   No (또는 DNS only)
```

### 4.3 SSL/TLS 인증서

Cloudflare Pages는 자동으로 SSL 인증서를 발급합니다:

- Let's Encrypt 인증서 자동 발급
- HTTPS 자동 리다이렉트
- 인증서 자동 갱신

**주의**: DNS 변경 후 인증서 발급까지 최대 24시간 소요될 수 있습니다.

### 4.4 DNS 전파 확인

```bash
# DNS 전파 확인
dig music.abada.kr CNAME

# 또는 nslookup 사용
nslookup music.abada.kr

# 웹 브라우저에서 확인
curl -I https://music.abada.kr
```

---

## 5. Cloudflare Workers 설정

### 5.1 Workers 프로젝트 구조

```
web-music-heartlib/
├── functions/
│   └── api/
│       ├── index.js          # Main router
│       ├── download-stats.js # Download statistics
│       ├── gallery.js        # Gallery management
│       └── analytics.js      # Analytics recording
├── wrangler.toml             # Workers configuration
└── .env.example              # Environment template
```

### 5.2 wrangler.toml 설정

```toml
# wrangler.toml
name = "abada-music-api"
main = "functions/api/index.js"
compatibility_date = "2024-01-01"

# KV Namespaces
[[kv_namespaces]]
binding = "STATS"
id = "YOUR_STATS_KV_ID"
preview_id = "YOUR_STATS_KV_PREVIEW_ID"

[[kv_namespaces]]
binding = "GALLERY"
id = "YOUR_GALLERY_KV_ID"
preview_id = "YOUR_GALLERY_KV_PREVIEW_ID"

# Environment variables
[vars]
ENVIRONMENT = "production"
APP_NAME = "ABADA Music Studio"
WEBSITE_URL = "https://music.abada.kr"
GITHUB_RELEASES_URL = "https://github.com/saintgo7/web-music-heartlib/releases"
```

### 5.3 Workers 배포

```bash
# 로컬 개발 서버 실행
wrangler dev

# 프로덕션 배포
wrangler deploy

# 환경별 배포
wrangler deploy --env staging
wrangler deploy --env production
```

### 5.4 Workers 라우트 설정 (Optional)

커스텀 도메인에서 API를 사용하려면:

```toml
# wrangler.toml에 추가
routes = [
  { pattern = "music.abada.kr/api/*", zone_name = "abada.kr" }
]
```

또는 Cloudflare Dashboard에서:

1. **Workers & Pages** > **abada-music-api** 선택
2. **Triggers** 탭 이동
3. **Add Route** 클릭
4. Route: `music.abada.kr/api/*`
5. Zone: `abada.kr` 선택

---

## 6. KV Namespace 설정

### 6.1 KV Namespace 생성

```bash
# STATS namespace 생성 (Production)
wrangler kv:namespace create "STATS"
# 출력 예시: id = "1a2b3c4d5e6f7g8h9i0j"

# STATS namespace 생성 (Preview/Development)
wrangler kv:namespace create "STATS" --preview
# 출력 예시: preview_id = "abcdef123456789"

# GALLERY namespace 생성 (Production)
wrangler kv:namespace create "GALLERY"

# GALLERY namespace 생성 (Preview/Development)
wrangler kv:namespace create "GALLERY" --preview
```

### 6.2 wrangler.toml에 KV ID 업데이트

생성된 ID를 wrangler.toml에 복사:

```toml
[[kv_namespaces]]
binding = "STATS"
id = "1a2b3c4d5e6f7g8h9i0j"           # 실제 ID로 교체
preview_id = "abcdef123456789"         # 실제 preview ID로 교체

[[kv_namespaces]]
binding = "GALLERY"
id = "xyz789012345678"                 # 실제 ID로 교체
preview_id = "preview_xyz789"          # 실제 preview ID로 교체
```

### 6.3 KV 데이터 관리

```bash
# 데이터 조회
wrangler kv:key list --namespace-id=YOUR_NAMESPACE_ID

# 데이터 추가
wrangler kv:key put --namespace-id=YOUR_NAMESPACE_ID "key" "value"

# 데이터 삭제
wrangler kv:key delete --namespace-id=YOUR_NAMESPACE_ID "key"

# 대량 데이터 업로드
wrangler kv:bulk put --namespace-id=YOUR_NAMESPACE_ID data.json
```

### 6.4 초기 데이터 설정

갤러리 샘플 데이터 초기화:

```bash
# gallery-init.json 파일 생성 후
wrangler kv:bulk put --namespace-id=YOUR_GALLERY_KV_ID gallery-init.json
```

---

## 7. 환경 변수 설정

### 7.1 Cloudflare Dashboard에서 설정

1. **Workers & Pages** > **abada-music-api** 선택
2. **Settings** > **Variables** 이동
3. **Environment Variables** 섹션에서 추가:

| 변수명 | 값 | 암호화 |
|--------|-----|-------|
| ENVIRONMENT | production | No |
| APP_NAME | ABADA Music Studio | No |
| WEBSITE_URL | https://music.abada.kr | No |
| GITHUB_RELEASES_URL | https://github.com/saintgo7/web-music-heartlib/releases | No |
| ADMIN_API_KEY | [secret key] | Yes |

### 7.2 Wrangler CLI로 Secret 설정

```bash
# Secret 추가 (암호화됨)
wrangler secret put ADMIN_API_KEY
# 프롬프트에서 값 입력

# Secret 삭제
wrangler secret delete ADMIN_API_KEY

# Secret 목록 확인
wrangler secret list
```

### 7.3 환경별 변수 설정

```toml
# wrangler.toml
[vars]
ENVIRONMENT = "production"

[env.development]
vars = { ENVIRONMENT = "development" }

[env.staging]
vars = { ENVIRONMENT = "staging" }

[env.production]
vars = { ENVIRONMENT = "production" }
```

---

## 8. GitHub Actions Secrets 설정

### 8.1 필요한 Secrets 목록

| Secret 이름 | 설명 | 필수 |
|------------|------|------|
| CLOUDFLARE_API_TOKEN | Cloudflare API 토큰 | Yes |
| CLOUDFLARE_ACCOUNT_ID | Cloudflare 계정 ID | Yes |

### 8.2 GitHub Secrets 추가 방법

1. GitHub 저장소로 이동
2. **Settings** 탭 클릭
3. 좌측 메뉴에서 **Secrets and variables** > **Actions** 선택
4. **New repository secret** 클릭

#### CLOUDFLARE_API_TOKEN 추가

```yaml
Name: CLOUDFLARE_API_TOKEN
Value: [2단계에서 발급받은 API 토큰]
```

#### CLOUDFLARE_ACCOUNT_ID 추가

```yaml
Name: CLOUDFLARE_ACCOUNT_ID
Value: [2단계에서 확인한 Account ID]
```

### 8.3 Secrets 확인

Secrets가 올바르게 설정되었는지 확인:

```yaml
# .github/workflows/test-secrets.yml (테스트용)
name: Test Secrets
on: workflow_dispatch
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Check secrets
        run: |
          if [ -n "${{ secrets.CLOUDFLARE_API_TOKEN }}" ]; then
            echo "CLOUDFLARE_API_TOKEN is set"
          else
            echo "CLOUDFLARE_API_TOKEN is NOT set"
          fi
          if [ -n "${{ secrets.CLOUDFLARE_ACCOUNT_ID }}" ]; then
            echo "CLOUDFLARE_ACCOUNT_ID is set"
          else
            echo "CLOUDFLARE_ACCOUNT_ID is NOT set"
          fi
```

### 8.4 GitHub Actions 워크플로우 수동 실행

```bash
# GitHub CLI로 워크플로우 실행
gh workflow run deploy-website.yml

# 또는 GitHub 웹에서
# Actions 탭 > Deploy Website > Run workflow
```

---

## 9. 배포 테스트

### 9.1 로컬 테스트

```bash
# 웹사이트 빌드 테스트
cd web
npm install
npm run build
npm run preview

# Workers 로컬 실행
cd ..
wrangler dev

# API 테스트
curl http://localhost:8787/api/health
```

### 9.2 배포 후 확인

```bash
# 웹사이트 확인
curl -I https://music.abada.kr

# API Health Check
curl https://music.abada.kr/api/health

# Download Stats API
curl https://music.abada.kr/api/stats

# Gallery API
curl https://music.abada.kr/api/gallery
```

### 9.3 배포 체크리스트

- [ ] Cloudflare Pages 배포 완료
- [ ] Cloudflare Workers 배포 완료
- [ ] DNS CNAME 레코드 설정 완료
- [ ] SSL 인증서 발급 확인
- [ ] GitHub Actions Secrets 설정 완료
- [ ] KV Namespace 생성 및 연결 완료
- [ ] API Health Check 정상
- [ ] 웹사이트 로딩 정상

---

## 10. 트러블슈팅

### 문제: Pages 빌드 실패

**증상**: `Build failed` 에러

**해결**:
```bash
# 1. 로컬에서 빌드 테스트
cd web && npm install && npm run build

# 2. Node.js 버전 확인
node --version  # 18+ 필요

# 3. package-lock.json 재생성
rm -rf node_modules package-lock.json
npm install

# 4. Cloudflare에서 Node 버전 지정
# Environment variables에 추가:
# NODE_VERSION: 20
```

### 문제: DNS CNAME 미적용

**증상**: `DNS_PROBE_FINISHED_NXDOMAIN` 에러

**해결**:
```bash
# 1. DNS 전파 확인 (최대 24-48시간)
dig music.abada.kr

# 2. CNAME 레코드 올바른지 확인
# Target: abada-music.pages.dev

# 3. DNS 캐시 삭제
# Windows: ipconfig /flushdns
# macOS: sudo dscacheutil -flushcache
# Linux: sudo systemctl restart systemd-resolved
```

### 문제: Workers 배포 실패

**증상**: `Authentication error` 또는 `Unauthorized`

**해결**:
```bash
# 1. Wrangler 재로그인
wrangler logout
wrangler login

# 2. API 토큰 권한 확인
# - Workers Scripts: Edit
# - Workers KV Storage: Edit

# 3. Account ID 확인
wrangler whoami
```

### 문제: KV Namespace 연결 오류

**증상**: `KV namespace not found`

**해결**:
```bash
# 1. Namespace 목록 확인
wrangler kv:namespace list

# 2. wrangler.toml ID 확인
# id와 preview_id가 올바른지 체크

# 3. Namespace 재생성
wrangler kv:namespace delete "STATS"
wrangler kv:namespace create "STATS"
```

### 문제: CORS 에러

**증상**: `Access-Control-Allow-Origin` 에러

**해결**:
```javascript
// functions/api/index.js에서 CORS 헤더 확인
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};
```

### 문제: SSL 인증서 오류

**증상**: `SSL_ERROR_NO_CYPHER_OVERLAP`

**해결**:
```
1. DNS 설정 확인 (Proxy 상태)
2. Cloudflare SSL/TLS 설정 > Full (strict) 선택
3. 24시간 대기 (인증서 발급 시간)
4. Edge Certificate 상태 확인
```

### 문제: GitHub Actions 실패

**증상**: `Error: secretAccessKey is invalid`

**해결**:
```
1. GitHub Secrets 재확인
   - CLOUDFLARE_API_TOKEN 값 검증
   - CLOUDFLARE_ACCOUNT_ID 값 검증

2. Secrets 이름 정확히 입력 (대소문자 구분)

3. API Token 만료 확인 및 재발급
```

---

## 참고 자료

### 공식 문서

- [Cloudflare Pages Docs](https://developers.cloudflare.com/pages)
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers)
- [Wrangler CLI Docs](https://developers.cloudflare.com/workers/wrangler)
- [Workers KV Docs](https://developers.cloudflare.com/kv)

### 유용한 링크

- [Cloudflare Dashboard](https://dash.cloudflare.com)
- [API Tokens](https://dash.cloudflare.com/profile/api-tokens)
- [GitHub Actions for Cloudflare](https://github.com/cloudflare/wrangler-action)

---

**문서 버전**: v1.0.0
**최종 수정**: 2026-01-19
**작성자**: ABADA Inc.
