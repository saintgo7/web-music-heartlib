# ABADA Music Studio - 테스트 계획서 (Testing Plan)

**버전**: v0.3.0 (Phase 2)
**작성일**: 2026-01-19
**대상 릴리즈**: v1.0.0
**도메인**: music.abada.kr

---

## 목차

1. [테스트 전략 개요](#테스트-전략-개요)
2. [테스트 범위 및 목표](#테스트-범위-및-목표)
3. [테스트 환경 설정](#테스트-환경-설정)
4. [테스트 타임라인](#테스트-타임라인)
5. [진입/종료 기준](#진입종료-기준)
6. [리스크 분석](#리스크-분석)
7. [테스트 메트릭](#테스트-메트릭)
8. [역할 및 책임](#역할-및-책임)

---

## 테스트 전략 개요

### 테스트 피라미드

```
             /\
            /  \
          /  E2E  \         10% - End-to-End Tests
         /________\
        /          \
       / Integration \      20% - Integration Tests
      /______________\
     /                \
    /   Unit Tests     \    70% - Unit Tests
   /____________________\
```

### 테스트 레벨

| 레벨 | 범위 | 도구 | 커버리지 목표 |
|------|------|------|--------------|
| **Unit** | 개별 함수/컴포넌트 | Jest, Vitest | 80%+ |
| **Integration** | API + DB, 컴포넌트 통합 | Jest, Playwright | 60%+ |
| **E2E** | 전체 사용자 플로우 | Playwright, Cypress | 주요 시나리오 |
| **Performance** | 성능 벤치마크 | Lighthouse, k6 | 모든 페이지 |
| **Security** | 취약점 스캔 | OWASP ZAP, npm audit | 0 High/Critical |

### 테스트 유형

**기능 테스트 (Functional)**
- 설치 프로그램 기능 검증 (Windows/macOS/Linux)
- 웹사이트 UI/UX 테스트
- API 엔드포인트 검증
- 크로스 브라우저 테스트 (Chrome, Firefox, Safari, Edge)

**비기능 테스트 (Non-Functional)**
- 성능 테스트 (로드 타임, 응답 시간)
- 보안 테스트 (XSS, CSRF, SQL Injection)
- 접근성 테스트 (WCAG 2.1 AA)
- SEO 검증 (메타태그, 시맨틱 HTML)

**회귀 테스트 (Regression)**
- 기존 기능 영향 검증
- 자동화된 스모크 테스트
- 릴리즈 전 체크리스트

---

## 테스트 범위 및 목표

### 1. 설치 프로그램 테스트

#### Windows (x64, x86)

**목표**: 설치 성공률 > 95%, 평균 설치 시간 < 10분

**테스트 범위**:
- [ ] GPU 감지 로직 (NVIDIA, AMD, Intel)
- [ ] Python 3.10 임베딩 검증
- [ ] PyTorch 설치 (CUDA vs CPU)
- [ ] HuggingFace 모델 다운로드 (6GB)
- [ ] 바로가기 생성 (Desktop, Start Menu)
- [ ] 언인스톨 기능
- [ ] 관리자 권한 처리

**테스트 환경**:
- Windows 10 (21H2, 22H2)
- Windows 11 (22H2, 23H2)
- GPU: NVIDIA GTX 1060+, AMD RX 580+
- CPU-only 환경

#### macOS

**목표**: DMG 마운트 성공률 > 98%, Homebrew 의존성 자동 해결

**테스트 범위**:
- [ ] Apple Silicon (M1/M2/M3) 지원 검증
- [ ] Intel Mac 호환성
- [ ] Homebrew 자동 설치
- [ ] Python 3.10 설치 (brew)
- [ ] MPS (Metal Performance Shaders) 활성화
- [ ] 앱 서명 및 공증 (Notarization) - Phase 3

**테스트 환경**:
- macOS Monterey (12.x)
- macOS Ventura (13.x)
- macOS Sonoma (14.x)
- Apple Silicon (M1/M2) + Intel

#### Linux

**목표**: 다중 배포판 지원, 설치 성공률 > 90%

**테스트 범위**:
- [ ] Ubuntu (20.04, 22.04, 24.04)
- [ ] Fedora (38, 39)
- [ ] Arch Linux (rolling)
- [ ] 패키지 매니저 자동 감지 (apt, dnf, pacman)
- [ ] Desktop Entry 생성
- [ ] .desktop 파일 검증

**테스트 환경**:
- Docker 컨테이너 (각 배포판)
- 물리 머신 (최소 1개씩)

### 2. 웹사이트 테스트

#### 페이지별 테스트

| 페이지 | URL | 테스트 시나리오 | 목표 LCP |
|--------|-----|----------------|----------|
| 홈 | `/` | Hero 섹션, 애니메이션 | < 2.5s |
| 다운로드 | `/download` | OS 감지, 다운로드 통계 | < 2.0s |
| 튜토리얼 | `/tutorial` | 코드 블록, 이미지 | < 3.0s |
| 갤러리 | `/gallery` | 음악 재생, API 연동 | < 2.5s |
| FAQ | `/faq` | 검색 기능, 아코디언 | < 2.0s |
| 소개 | `/about` | 팀 정보, 연락처 | < 2.0s |

**반응형 테스트**:
- [ ] 모바일 (375px - iPhone SE)
- [ ] 태블릿 (768px - iPad)
- [ ] 데스크톱 (1920px - Full HD)
- [ ] 4K (3840px)

**브라우저 매트릭스**:
- [ ] Chrome 120+ (Desktop/Mobile)
- [ ] Firefox 121+ (Desktop/Mobile)
- [ ] Safari 17+ (macOS/iOS)
- [ ] Edge 120+ (Desktop)

#### SEO 검증

**메타태그 체크리스트**:
- [ ] `<title>` (50-60자)
- [ ] `<meta name="description">` (150-160자)
- [ ] Open Graph (og:title, og:description, og:image)
- [ ] Twitter Card
- [ ] Canonical URL
- [ ] Structured Data (Schema.org)

**Lighthouse 점수 목표**:
- Performance: > 90
- Accessibility: > 95
- Best Practices: > 95
- SEO: > 95

### 3. API 테스트 (Cloudflare Workers)

#### 엔드포인트별 테스트

**Download Stats API**

```http
POST /api/download-stats
Content-Type: application/json

{
  "os": "windows",
  "version": "v1.0.0",
  "timestamp": "2026-01-19T12:00:00Z"
}
```

**테스트 시나리오**:
- [ ] POST 요청 성공 (201 Created)
- [ ] GET 요청 통계 조회 (200 OK)
- [ ] 잘못된 JSON 처리 (400 Bad Request)
- [ ] CORS 헤더 검증
- [ ] Rate Limiting (100 req/min)
- [ ] KV Store 쓰기/읽기 검증

**Gallery API**

```http
GET /api/gallery?limit=10&offset=0
```

**테스트 시나리오**:
- [ ] 페이지네이션 (limit, offset)
- [ ] 정렬 (최신순, 인기순)
- [ ] 필터링 (장르, 태그)
- [ ] 404 처리 (존재하지 않는 ID)
- [ ] 캐싱 헤더 (Cache-Control)

**Analytics API**

```http
POST /api/analytics
Content-Type: application/json

{
  "event": "page_view",
  "page": "/download",
  "user_agent": "Mozilla/5.0..."
}
```

**테스트 시나리오**:
- [ ] 이벤트 추적 (page_view, download, play)
- [ ] User Agent 파싱
- [ ] 봇 필터링
- [ ] 타임스탬프 검증

#### 성능 목표

| 메트릭 | 목표 | 측정 방법 |
|--------|------|-----------|
| **응답 시간 (p50)** | < 100ms | k6 로드 테스트 |
| **응답 시간 (p95)** | < 200ms | k6 로드 테스트 |
| **응답 시간 (p99)** | < 500ms | k6 로드 테스트 |
| **동시 사용자** | 1,000 CCU | k6 스트레스 테스트 |
| **처리량** | 10,000 req/min | Cloudflare Analytics |
| **에러율** | < 0.1% | Cloudflare Logs |

---

## 테스트 환경 설정

### 로컬 개발 환경

#### 필수 소프트웨어

**공통**:
```bash
# Node.js 및 패키지 매니저
node --version  # v18.x 이상
npm --version   # v9.x 이상

# Git
git --version   # v2.30 이상

# Cloudflare Wrangler
npm install -g wrangler
wrangler --version
```

**Windows 전용**:
```powershell
# NSIS 설치
choco install nsis

# Python 3.10
choco install python310

# CUDA Toolkit (GPU 테스트용)
# https://developer.nvidia.com/cuda-downloads
```

**macOS 전용**:
```bash
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Python 3.10
brew install python@3.10

# DMG 빌드 도구
brew install create-dmg
```

**Linux 전용**:
```bash
# Docker (멀티 배포판 테스트용)
sudo apt install docker.io docker-compose

# Python 3.10
sudo apt install python3.10 python3.10-venv
```

### 테스트 데이터베이스

#### Cloudflare KV Namespaces

**Production**:
```bash
wrangler kv:namespace create DOWNLOAD_STATS
wrangler kv:namespace create GALLERY_DATA
wrangler kv:namespace create ANALYTICS_EVENTS
```

**Preview (Staging)**:
```bash
wrangler kv:namespace create DOWNLOAD_STATS --preview
wrangler kv:namespace create GALLERY_DATA --preview
wrangler kv:namespace create ANALYTICS_EVENTS --preview
```

### CI/CD 환경

#### GitHub Secrets

```bash
# Cloudflare
CLOUDFLARE_API_TOKEN
CLOUDFLARE_ACCOUNT_ID

# 코드 서명 인증서 (Phase 3)
WINDOWS_CERT_PASSWORD
APPLE_DEVELOPER_ID
```

#### GitHub Actions 러너

- **ubuntu-latest**: 웹사이트 빌드, API 테스트
- **windows-latest**: Windows 설치 프로그램 빌드
- **macos-latest**: macOS DMG 빌드
- **Self-hosted**: Linux 배포판 테스트 (Docker)

---

## 테스트 타임라인

### Week 3: 로컬 테스트 및 환경 설정 (2026-01-20 ~ 2026-01-26)

**Mon-Tue (1/20-21)**:
- [ ] 로컬 테스트 환경 구축 (Windows, macOS, Linux)
- [ ] 테스트 스크립트 실행 (`LOCAL_TEST_SETUP.sh`)
- [ ] 단위 테스트 작성 (React 컴포넌트)
- [ ] API 통합 테스트 작성

**Wed-Thu (1/22-23)**:
- [ ] Windows 설치 프로그램 물리 테스트 (GPU, CPU)
- [ ] macOS DMG 테스트 (Apple Silicon, Intel)
- [ ] Linux 멀티 배포판 테스트 (Docker)
- [ ] 버그 리스트 작성 및 우선순위 지정

**Fri (1/24)**:
- [ ] 크리티컬 버그 수정
- [ ] 회귀 테스트 재실행
- [ ] 주간 리뷰 및 리포트 작성

**Sat-Sun (1/25-26)**:
- [ ] 성능 최적화
- [ ] Lighthouse 점수 개선
- [ ] 번들 사이즈 최적화

### Week 4: Cloudflare 배포 및 E2E 테스트 (2026-01-27 ~ 2026-02-02)

**Mon-Tue (1/27-28)**:
- [ ] Cloudflare Pages 설정 (music.abada.kr)
- [ ] DNS 설정 (A, CNAME 레코드)
- [ ] SSL 인증서 활성화
- [ ] KV 네임스페이스 Production 생성

**Wed-Thu (1/29-30)**:
- [ ] API 배포 (Cloudflare Workers)
- [ ] 웹사이트 프로덕션 빌드
- [ ] E2E 테스트 실행 (Playwright)
- [ ] 크로스 브라우저 테스트

**Fri (1/31)**:
- [ ] 로드 테스트 (k6, 1,000 CCU)
- [ ] 스트레스 테스트 (10,000 req/min)
- [ ] 성능 메트릭 수집

**Sat-Sun (2/1-2)**:
- [ ] UAT (User Acceptance Testing)
- [ ] 베타 테스터 피드백 수집
- [ ] 최종 버그 수정
- [ ] v0.3.0 릴리즈 준비

---

## 진입/종료 기준

### 진입 기준 (Entry Criteria)

**Phase 1 완료 체크리스트**:
- [x] 모든 소스 코드 커밋 완료 (v0.2.0)
- [x] GitHub Actions 워크플로우 작성 완료
- [x] 설치 프로그램 스크립트 완성 (Windows/macOS/Linux)
- [x] 웹사이트 6개 페이지 구현 완료
- [x] API 4개 엔드포인트 구현 완료

**Phase 2 시작 요구사항**:
- [ ] 테스트 환경 준비 완료
- [ ] 테스트 계획서 승인
- [ ] 테스트 데이터 준비 완료
- [ ] CI/CD 파이프라인 검증 완료

### 종료 기준 (Exit Criteria)

**필수 조건 (Mandatory)**:
- [ ] 모든 크리티컬 버그 해결 (Severity: High)
- [ ] 설치 성공률 > 95% (Windows/macOS/Linux)
- [ ] Lighthouse 점수 > 90 (모든 페이지)
- [ ] API 응답 시간 < 200ms (p95)
- [ ] E2E 테스트 100% 통과
- [ ] 크로스 브라우저 테스트 통과

**권장 조건 (Recommended)**:
- [ ] 단위 테스트 커버리지 > 80%
- [ ] 통합 테스트 커버리지 > 60%
- [ ] 보안 스캔 0 High/Critical
- [ ] 접근성 점수 > 95 (WCAG 2.1 AA)
- [ ] SEO 점수 > 95

**문서화 요구사항**:
- [ ] 테스트 결과 리포트 작성
- [ ] 알려진 이슈 문서화 (TROUBLESHOOTING.md)
- [ ] 릴리즈 노트 작성
- [ ] 사용자 가이드 업데이트

---

## 리스크 분석

### 고위험 (High Risk)

| 리스크 | 영향 | 확률 | 완화 전략 |
|--------|------|------|-----------|
| **모델 다운로드 실패** | Critical | 30% | 재시도 로직, 미러 서버, CDN 캐싱 |
| **GPU 감지 오류** | High | 20% | Fallback to CPU, 상세 로깅 |
| **Cloudflare KV 장애** | High | 10% | 로컬 캐시, 우아한 성능 저하 |
| **크로스 플랫폼 버그** | Medium | 40% | Docker 테스트, 물리 머신 검증 |

### 중위험 (Medium Risk)

| 리스크 | 영향 | 확률 | 완화 전략 |
|--------|------|------|-----------|
| **성능 저하** | Medium | 30% | 번들 최적화, 코드 스플리팅 |
| **SEO 점수 미달** | Medium | 20% | 메타태그 검증, Lighthouse CI |
| **API Rate Limiting** | Medium | 15% | 캐싱, Throttling, Queue |
| **브라우저 호환성** | Low | 25% | Polyfill, 크로스 브라우저 테스트 |

### 저위험 (Low Risk)

| 리스크 | 영향 | 확률 | 완화 전략 |
|--------|------|------|-----------|
| **UI 버그** | Low | 30% | E2E 테스트, 시각적 회귀 테스트 |
| **404 에러** | Low | 10% | 라우팅 테스트, Sitemap |
| **느린 빌드 시간** | Low | 20% | 캐시 전략, 병렬 빌드 |

---

## 테스트 메트릭

### KPI (Key Performance Indicators)

**품질 메트릭**:
- **Test Coverage**: Unit (80%), Integration (60%), E2E (주요 시나리오)
- **Defect Density**: < 5 bugs/1000 LOC
- **Critical Bugs**: 0 (릴리즈 블로커)
- **Test Pass Rate**: > 95%

**성능 메트릭**:
- **Page Load Time**: FCP < 2s, LCP < 3s
- **API Response Time**: p95 < 200ms
- **Bundle Size**: Gzipped < 500KB
- **Lighthouse Score**: > 90 (모든 카테고리)

**안정성 메트릭**:
- **Uptime**: 99.9% (SLA)
- **Error Rate**: < 0.1%
- **MTTR** (Mean Time To Repair): < 1h
- **Deployment Frequency**: 주 1회

### 테스트 리포트 템플릿

```markdown
## 테스트 실행 리포트

**날짜**: YYYY-MM-DD
**버전**: vX.X.X
**테스터**: 이름

### 실행 요약
- 총 테스트 케이스: XXX
- 통과: XXX (XX%)
- 실패: XXX (XX%)
- 건너뜀: XXX (XX%)

### 크리티컬 이슈
1. [BUG-001] 설명
2. [BUG-002] 설명

### 성능 메트릭
- Lighthouse Score: XX/100
- API p95 Latency: XXXms
- Bundle Size: XXXkb

### 권장사항
- [ ] Action Item 1
- [ ] Action Item 2
```

---

## 역할 및 책임

### 테스트 팀 구성

| 역할 | 책임 | 담당자 |
|------|------|--------|
| **QA Lead** | 테스트 전략, 계획 수립 | TBD |
| **Test Engineer** | 테스트 케이스 작성, 실행 | TBD |
| **Automation Engineer** | E2E 자동화, CI/CD 통합 | TBD |
| **Performance Engineer** | 로드 테스트, 최적화 | TBD |
| **Security Tester** | 취약점 스캔, 보안 검증 | TBD |

### RACI Matrix

| 작업 | QA Lead | Test Eng | Auto Eng | Perf Eng | Dev |
|------|---------|----------|----------|----------|-----|
| 테스트 계획 | **R** | C | C | C | I |
| 단위 테스트 | I | C | C | I | **R** |
| 통합 테스트 | A | **R** | C | I | C |
| E2E 테스트 | A | C | **R** | I | C |
| 성능 테스트 | A | I | C | **R** | C |
| 버그 수정 | I | C | I | I | **R** |

**범례**: R=Responsible, A=Accountable, C=Consulted, I=Informed

---

## 부록

### 테스트 도구 스택

**프론트엔드**:
- Jest + React Testing Library (단위/통합)
- Playwright (E2E)
- Cypress (E2E, 대체)
- Lighthouse CI (성능)
- axe-core (접근성)

**백엔드/API**:
- Vitest (단위)
- k6 (로드 테스트)
- Postman/Newman (API 테스트)
- OWASP ZAP (보안)

**CI/CD**:
- GitHub Actions
- Cloudflare Pages/Workers
- Docker (격리된 환경)

### 참고 문서

- [E2E_TEST_SCENARIOS.md](./E2E_TEST_SCENARIOS.md) - 상세 테스트 시나리오
- [PERFORMANCE_TEST_GUIDE.md](./PERFORMANCE_TEST_GUIDE.md) - 성능 테스트 가이드
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - 문제 해결 가이드
- [CI_CD_VALIDATION_CHECKLIST.md](./CI_CD_VALIDATION_CHECKLIST.md) - 배포 체크리스트

---

**문서 버전**: 1.0.0
**승인자**: TBD
**다음 리뷰**: 2026-02-01
