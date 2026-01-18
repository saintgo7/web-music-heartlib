# ABADA Music Studio - Phase 2 요구사항 명세서

**버전**: v1.0
**대상 버전**: v0.3.0 (Phase 2 - Testing & Cloudflare Setup)
**마지막 업데이트**: 2026-01-19

---

## I. 문서 개요

### 1.1 목적

본 문서는 ABADA Music Studio Phase 2의 **기능 요구사항**, **비기능 요구사항**, **품질 기준**, **테스트 요구사항**을 명시합니다.

### 1.2 범위

**Phase 2 범위**:
- Phase 1에서 개발한 코드의 검증 및 테스트
- Cloudflare 인프라 구성 및 배포
- 성능 최적화
- 문서화 완료

**Phase 2 제외**:
- 새로운 기능 개발
- 디자인 변경
- 커뮤니티 기능 (Phase 3로 연기)

### 1.3 이해관계자

| 역할 | 책임 | 승인 권한 |
|------|------|----------|
| **Project Manager** | 전체 일정 관리 | 최종 승인 |
| **Backend Developer** | 설치 프로그램 테스트 | 기술 승인 |
| **Frontend Developer** | 웹사이트 최적화 | UI/UX 승인 |
| **DevOps Lead** | 배포 및 인프라 | 인프라 승인 |
| **QA Lead** | 품질 검증 | 테스트 승인 |
| **Technical Writer** | 문서 작성 | 문서 승인 |

---

## II. 기능 요구사항 (Functional Requirements)

### 2.1 설치 프로그램 요구사항

#### FR-INS-001: Windows x64 설치 프로그램

**설명**: Windows 10/11 x64에서 설치 프로그램이 정상 작동해야 함

**세부 요구사항**:
- [x] GPU 자동 감지 (nvidia-smi)
- [x] Python 3.10 임베딩 설치
- [x] PyTorch CUDA/CPU 자동 선택
- [ ] HuggingFace 모델 다운로드 (6GB)
- [ ] Desktop 바로가기 생성
- [ ] Start Menu 엔트리 생성
- [ ] Uninstaller 제공

**우선순위**: P0 (Critical)
**담당**: backend-developer
**테스트**: Day 1-2 (Windows VM)

---

#### FR-INS-002: macOS 설치 프로그램

**설명**: macOS 12+ (Intel/Apple Silicon)에서 설치 스크립트가 정상 작동해야 함

**세부 요구사항**:
- [x] Homebrew 자동 감지 및 설치
- [x] Apple Silicon (MPS) vs Intel 감지
- [ ] Python venv 생성
- [ ] PyTorch MPS/CPU 자동 선택
- [ ] 모델 다운로드
- [ ] Desktop 바로가기 생성
- [ ] Uninstaller 제공

**우선순위**: P0 (Critical)
**담당**: backend-developer
**테스트**: Day 3-4 (macOS 실제 머신)

---

#### FR-INS-003: Linux 설치 프로그램

**설명**: Ubuntu 22.04+, Fedora 38+, Arch Linux에서 설치 스크립트가 정상 작동해야 함

**세부 요구사항**:
- [x] 배포판 자동 감지 (apt, dnf, pacman)
- [x] Python 3.10 설치
- [ ] venv 생성
- [ ] PyTorch CPU 설치
- [ ] 모델 다운로드
- [ ] Desktop Entry 생성
- [ ] Uninstaller 제공

**우선순위**: P1 (High)
**담당**: backend-developer
**테스트**: Day 5-6 (Ubuntu VM)

---

### 2.2 웹사이트 요구사항

#### FR-WEB-001: 페이지 로딩

**설명**: 모든 페이지가 3초 이내에 로드되어야 함

**세부 요구사항**:
- [ ] 홈페이지 (/) 로드 시간 < 2s
- [ ] 다운로드 페이지 (/download) 로드 시간 < 2s
- [ ] 갤러리 페이지 (/gallery) 로드 시간 < 3s
- [ ] 튜토리얼 페이지 (/tutorial) 로드 시간 < 2s
- [ ] FAQ 페이지 (/faq) 로드 시간 < 2s
- [ ] 소개 페이지 (/about) 로드 시간 < 2s

**우선순위**: P0 (Critical)
**담당**: frontend-developer
**측정**: Lighthouse, Chrome DevTools

---

#### FR-WEB-002: 반응형 디자인

**설명**: 모바일/태블릿/데스크톱에서 정상 표시되어야 함

**세부 요구사항**:
- [ ] 모바일 (< 640px) 레이아웃 정상
- [ ] 태블릿 (640px - 1024px) 레이아웃 정상
- [ ] 데스크톱 (> 1024px) 레이아웃 정상
- [ ] 터치 스크린 지원
- [ ] 가로/세로 모드 지원

**우선순위**: P0 (Critical)
**담당**: frontend-developer
**테스트**: Chrome DevTools Device Mode

---

#### FR-WEB-003: SEO 최적화

**설명**: 검색 엔진 최적화가 적용되어야 함

**세부 요구사항**:
- [x] 메타 태그 (title, description, keywords)
- [x] Open Graph 태그 (Facebook, Twitter)
- [ ] Sitemap.xml 생성
- [ ] Robots.txt 설정
- [ ] Structured Data (JSON-LD)
- [ ] Canonical URL 설정

**우선순위**: P1 (High)
**담당**: frontend-developer
**측정**: Lighthouse SEO 점수 100

---

### 2.3 API 요구사항

#### FR-API-001: 다운로드 통계 API

**설명**: 다운로드 통계를 조회하고 증가시킬 수 있어야 함

**엔드포인트**: `GET /api/download-stats`

**요청**:
```http
GET /api/download-stats HTTP/1.1
Host: music.abada.kr
```

**응답**:
```json
{
  "total": 1234,
  "by_platform": {
    "windows_x64": 500,
    "windows_x86": 100,
    "macos": 400,
    "linux": 234
  },
  "last_updated": "2026-01-19T12:00:00Z"
}
```

**엔드포인트**: `POST /api/download-stats`

**요청**:
```http
POST /api/download-stats HTTP/1.1
Host: music.abada.kr
Content-Type: application/json

{
  "platform": "windows_x64"
}
```

**응답**:
```json
{
  "success": true,
  "new_count": 501
}
```

**우선순위**: P0 (Critical)
**담당**: backend-developer
**테스트**: Day 10 (API 테스트)

---

#### FR-API-002: 갤러리 API

**설명**: 음악 샘플 목록을 조회할 수 있어야 함

**엔드포인트**: `GET /api/gallery`

**요청**:
```http
GET /api/gallery?limit=10&offset=0 HTTP/1.1
Host: music.abada.kr
```

**응답**:
```json
{
  "items": [
    {
      "id": "sample-001",
      "title": "Ordinary Magic",
      "audio_url": "https://cdn.example.com/sample-001.mp3",
      "duration": 180,
      "tags": ["piano", "happy", "wedding"],
      "created_at": "2026-01-15T10:00:00Z"
    }
  ],
  "total": 50,
  "limit": 10,
  "offset": 0
}
```

**우선순위**: P1 (High)
**담당**: backend-developer
**테스트**: Day 10

---

#### FR-API-003: 분석 API

**설명**: 웹사이트 분석 데이터를 수집할 수 있어야 함

**엔드포인트**: `POST /api/analytics`

**요청**:
```http
POST /api/analytics HTTP/1.1
Host: music.abada.kr
Content-Type: application/json

{
  "event": "page_view",
  "page": "/download",
  "referrer": "https://google.com",
  "user_agent": "Mozilla/5.0...",
  "timestamp": 1705660800000
}
```

**응답**:
```json
{
  "success": true,
  "event_id": "evt_123456"
}
```

**우선순위**: P2 (Medium)
**담당**: backend-developer
**테스트**: Day 10

---

### 2.4 배포 요구사항

#### FR-DEP-001: Cloudflare Pages 배포

**설명**: 웹사이트가 Cloudflare Pages에 자동 배포되어야 함

**세부 요구사항**:
- [ ] main 브랜치 push 시 자동 배포
- [ ] 빌드 성공 시에만 배포
- [ ] 배포 이력 관리
- [ ] 롤백 가능

**우선순위**: P0 (Critical)
**담당**: devops-lead
**테스트**: Day 8-9

---

#### FR-DEP-002: Cloudflare Workers 배포

**설명**: API가 Cloudflare Workers에 배포되어야 함

**세부 요구사항**:
- [ ] wrangler deploy 명령으로 배포
- [ ] KV 네임스페이스 바인딩
- [ ] Custom Route 설정 (music.abada.kr/api/*)
- [ ] 버전 관리

**우선순위**: P0 (Critical)
**담당**: devops-lead
**테스트**: Day 10

---

#### FR-DEP-003: GitHub Release 생성

**설명**: 설치 프로그램이 GitHub Release로 배포되어야 함

**세부 요구사항**:
- [ ] 버전 태그 생성 시 자동 빌드
- [ ] Windows/macOS/Linux 파일 첨부
- [ ] Release Notes 자동 생성
- [ ] Checksums 제공

**우선순위**: P0 (Critical)
**담당**: devops-lead
**테스트**: Day 11

---

## III. 비기능 요구사항 (Non-Functional Requirements)

### 3.1 성능 요구사항

#### NFR-PERF-001: 웹사이트 로딩 시간

**요구사항**: 모든 페이지가 3초 이내에 로드되어야 함

**측정 기준**:
| 메트릭 | 목표 | 측정 도구 |
|--------|------|----------|
| LCP (Largest Contentful Paint) | < 2.5s | Web Vitals |
| FID (First Input Delay) | < 100ms | Web Vitals |
| CLS (Cumulative Layout Shift) | < 0.1 | Web Vitals |
| TTI (Time to Interactive) | < 5s | Lighthouse |

**우선순위**: P0 (Critical)

---

#### NFR-PERF-002: API 응답 시간

**요구사항**: API가 200ms 이내에 응답해야 함

**측정 기준**:
| 엔드포인트 | P50 | P95 | P99 |
|-----------|-----|-----|-----|
| /api/download-stats | < 50ms | < 200ms | < 500ms |
| /api/gallery | < 100ms | < 300ms | < 1s |
| /api/analytics | < 50ms | < 200ms | < 500ms |

**우선순위**: P0 (Critical)

---

#### NFR-PERF-003: 설치 시간

**요구사항**: 설치 프로그램이 30분 이내에 완료되어야 함

**측정 기준**:
| 플랫폼 | 다운로드 | 설치 | 총 시간 |
|--------|---------|------|---------|
| Windows x64 | < 5분 | < 25분 | < 30분 |
| macOS | < 3분 | < 22분 | < 25분 |
| Linux | < 2분 | < 18분 | < 20분 |

**우선순위**: P1 (High)

---

### 3.2 확장성 요구사항

#### NFR-SCAL-001: 동시 사용자

**요구사항**: 웹사이트가 1000명의 동시 사용자를 처리할 수 있어야 함

**측정 기준**:
- 동시 접속자: 1000명
- 평균 응답 시간: < 500ms
- 에러율: < 1%

**우선순위**: P1 (High)

---

#### NFR-SCAL-002: API Throughput

**요구사항**: API가 초당 100개의 요청을 처리할 수 있어야 함

**측정 기준**:
- RPS (Requests Per Second): 100+
- 평균 응답 시간: < 200ms
- 에러율: < 0.1%

**우선순위**: P1 (High)

---

### 3.3 보안 요구사항

#### NFR-SEC-001: HTTPS 강제

**요구사항**: 모든 HTTP 요청이 HTTPS로 리디렉션되어야 함

**검증 방법**:
```bash
curl -I http://music.abada.kr
# HTTP/1.1 301 Moved Permanently
# Location: https://music.abada.kr/
```

**우선순위**: P0 (Critical)

---

#### NFR-SEC-002: CORS 설정

**요구사항**: API가 적절한 CORS 헤더를 반환해야 함

**검증 방법**:
```bash
curl -I https://music.abada.kr/api/download-stats
# Access-Control-Allow-Origin: *
# Access-Control-Allow-Methods: GET, POST, OPTIONS
```

**우선순위**: P0 (Critical)

---

#### NFR-SEC-003: Rate Limiting

**요구사항**: API가 분당 100개 요청으로 제한되어야 함

**검증 방법**:
```bash
# 100개 요청 후
curl -I https://music.abada.kr/api/analytics
# HTTP/1.1 429 Too Many Requests
```

**우선순위**: P1 (High)

---

### 3.4 가용성 요구사항

#### NFR-AVAIL-001: Uptime

**요구사항**: 웹사이트와 API의 가동률이 99.9% 이상이어야 함

**측정 기준**:
- Monthly Uptime: 99.9% (43분 다운타임 허용)
- Yearly Uptime: 99.9% (8.76시간 다운타임 허용)

**우선순위**: P0 (Critical)

---

#### NFR-AVAIL-002: 복구 시간

**요구사항**: 장애 발생 시 30분 이내에 복구되어야 함

**측정 기준**:
- MTTR (Mean Time To Repair): < 30분
- RTO (Recovery Time Objective): < 1시간

**우선순위**: P1 (High)

---

### 3.5 호환성 요구사항

#### NFR-COMP-001: 브라우저 호환성

**요구사항**: 주요 브라우저에서 정상 작동해야 함

**지원 브라우저**:
- Chrome 100+ (Desktop/Mobile)
- Firefox 100+ (Desktop/Mobile)
- Safari 15+ (Desktop/Mobile)
- Edge 100+ (Desktop)

**우선순위**: P0 (Critical)

---

#### NFR-COMP-002: OS 호환성

**요구사항**: 설치 프로그램이 주요 OS에서 작동해야 함

**지원 OS**:
- Windows 10 (21H2 이상), Windows 11
- macOS 12 (Monterey) 이상
- Ubuntu 22.04 LTS 이상
- Fedora 38 이상
- Arch Linux (rolling release)

**우선순위**: P0 (Critical)

---

### 3.6 접근성 요구사항

#### NFR-ACCESS-001: WCAG 2.1 Level AA

**요구사항**: 웹사이트가 WCAG 2.1 Level AA 기준을 충족해야 함

**검증 방법**:
- Lighthouse Accessibility 점수 95+
- 스크린 리더 호환성 (NVDA, JAWS)
- 키보드 네비게이션 가능

**우선순위**: P1 (High)

---

## IV. 품질 기준 (Quality Criteria)

### 4.1 코드 품질

#### QC-CODE-001: ESLint 통과

**기준**: 모든 JavaScript/TypeScript 코드가 ESLint 규칙을 통과해야 함

**검증**:
```bash
cd web
npm run lint
# 0 errors, 0 warnings
```

**우선순위**: P1 (High)

---

#### QC-CODE-002: Prettier 포맷팅

**기준**: 모든 코드가 Prettier 포맷팅 규칙을 준수해야 함

**검증**:
```bash
cd web
npm run format:check
# All files formatted
```

**우선순위**: P2 (Medium)

---

### 4.2 테스트 커버리지

#### QC-TEST-001: 단위 테스트 커버리지

**기준**: 코드 커버리지가 80% 이상이어야 함

**측정**:
```bash
cd web
npm run test:coverage
# Statements: 80%+
# Branches: 75%+
# Functions: 80%+
# Lines: 80%+
```

**우선순위**: P1 (High)
**현재 상태**: Phase 2에서 구현 예정

---

#### QC-TEST-002: E2E 테스트

**기준**: 모든 주요 사용자 플로우에 대한 E2E 테스트가 통과해야 함

**테스트 케이스**:
- [ ] 홈페이지 → 다운로드 페이지 → 파일 다운로드
- [ ] 갤러리 페이지 → 음악 재생
- [ ] FAQ 페이지 → 검색 기능

**우선순위**: P2 (Medium)
**현재 상태**: Phase 2에서 구현 예정

---

### 4.3 성능 기준

#### QC-PERF-001: Lighthouse 점수

**기준**: Lighthouse 점수가 다음 기준을 충족해야 함

| 카테고리 | 목표 (Desktop) | 목표 (Mobile) |
|---------|---------------|--------------|
| Performance | 90+ | 85+ |
| Accessibility | 95+ | 95+ |
| Best Practices | 95+ | 95+ |
| SEO | 100 | 100 |

**우선순위**: P0 (Critical)

---

#### QC-PERF-002: Bundle Size

**기준**: JavaScript 번들 크기가 다음 기준 이하여야 함

| 번들 | 목표 (gzipped) |
|------|----------------|
| Main bundle | < 150KB |
| Vendor bundle | < 100KB |
| Total JS | < 200KB |

**우선순위**: P1 (High)

---

## V. 테스트 요구사항 (Testing Requirements)

### 5.1 설치 프로그램 테스트

#### TEST-INS-001: Windows 설치 테스트

**테스트 환경**:
- Windows 10 21H2 (VM)
- Windows 11 (실제 머신)
- GPU: NVIDIA GTX 1060 (선택)
- CPU: Intel Core i5 이상

**테스트 시나리오**:
1. **기본 설치**
   - [ ] 설치 파일 다운로드 (< 100MB)
   - [ ] 더블클릭 실행
   - [ ] 라이선스 동의
   - [ ] 설치 경로 선택
   - [ ] GPU 감지 로그 확인
   - [ ] Python 3.10 설치 확인
   - [ ] PyTorch 설치 확인 (CUDA/CPU)
   - [ ] 모델 다운로드 (6GB)
   - [ ] 바로가기 생성 확인
   - [ ] 설치 완료 (< 30분)

2. **앱 실행**
   - [ ] "MuLa Studio" 바로가기 더블클릭
   - [ ] 브라우저에서 Gradio UI 열림 (localhost:7860)
   - [ ] 모델 로딩 확인

3. **음악 생성**
   - [ ] 가사 입력
   - [ ] 태그 입력
   - [ ] "Generate" 버튼 클릭
   - [ ] 진행률 표시 확인
   - [ ] 음악 생성 완료 (< 5분, GPU)
   - [ ] 출력 파일 저장 (~/Documents/MuLaStudio_Outputs/)
   - [ ] 음악 재생 확인

4. **언인스톨**
   - [ ] "Uninstall" 실행
   - [ ] 모든 파일 삭제 확인
   - [ ] 레지스트리 정리 확인

**예상 시간**: 2시간
**담당**: backend-developer

---

#### TEST-INS-002: macOS 설치 테스트

**테스트 환경**:
- macOS 12 (Monterey) Intel
- macOS 14 (Sonoma) Apple Silicon M2
- 16GB RAM

**테스트 시나리오**:
1. **기본 설치**
   - [ ] install.sh 다운로드
   - [ ] 실행 권한 부여 (chmod +x)
   - [ ] 스크립트 실행
   - [ ] Homebrew 설치 확인 (또는 자동 설치)
   - [ ] Python venv 생성 확인
   - [ ] PyTorch MPS/CPU 설치 확인
   - [ ] 모델 다운로드
   - [ ] Desktop 바로가기 생성
   - [ ] 설치 완료 (< 25분)

2. **Gatekeeper 처리**
   - [ ] "Unidentified Developer" 경고
   - [ ] System Preferences > Security 해제
   - [ ] 재실행

3. **앱 실행 및 테스트**
   - [ ] "MuLa Studio" 더블클릭
   - [ ] Gradio UI 열림
   - [ ] 음악 생성 테스트

4. **언인스톨**
   - [ ] uninstall.sh 실행
   - [ ] 파일 삭제 확인

**예상 시간**: 2시간
**담당**: backend-developer

---

#### TEST-INS-003: Linux 설치 테스트

**테스트 환경**:
- Ubuntu 22.04 LTS (VM)
- Fedora 38 (VM, 선택)

**테스트 시나리오**:
1. **기본 설치**
   - [ ] mula_install.sh 다운로드
   - [ ] 실행 권한 부여
   - [ ] 스크립트 실행
   - [ ] apt 패키지 설치 확인
   - [ ] Python venv 생성
   - [ ] PyTorch CPU 설치
   - [ ] 모델 다운로드
   - [ ] Desktop Entry 생성
   - [ ] 설치 완료 (< 20분)

2. **앱 실행 및 테스트**
   - [ ] Applications > MuLa Studio 실행
   - [ ] Gradio UI 열림
   - [ ] 음악 생성 테스트

3. **언인스톨**
   - [ ] uninstall.sh 실행

**예상 시간**: 1.5시간
**담당**: backend-developer

---

### 5.2 웹사이트 테스트

#### TEST-WEB-001: 기능 테스트

**테스트 시나리오**:
1. **페이지 로딩**
   - [ ] 홈페이지 (/) 로드
   - [ ] 다운로드 페이지 (/download) 로드
   - [ ] 갤러리 페이지 (/gallery) 로드
   - [ ] 튜토리얼 페이지 (/tutorial) 로드
   - [ ] FAQ 페이지 (/faq) 로드
   - [ ] 소개 페이지 (/about) 로드

2. **네비게이션**
   - [ ] Header 메뉴 클릭
   - [ ] Footer 링크 클릭
   - [ ] 브라우저 뒤로가기/앞으로가기

3. **다운로드 기능**
   - [ ] OS 자동 감지
   - [ ] 다운로드 버튼 클릭
   - [ ] 다운로드 통계 증가

4. **갤러리 기능**
   - [ ] 음악 샘플 로드
   - [ ] 음악 재생
   - [ ] 페이지네이션

5. **FAQ 검색**
   - [ ] 검색어 입력
   - [ ] 결과 필터링
   - [ ] 검색 결과 하이라이팅

**예상 시간**: 1시간
**담당**: frontend-developer

---

#### TEST-WEB-002: 반응형 테스트

**테스트 환경**:
- Chrome DevTools Device Mode
- 실제 모바일 디바이스 (iPhone, Android)

**테스트 시나리오**:
1. **모바일 (< 640px)**
   - [ ] 레이아웃 정상
   - [ ] 햄버거 메뉴 작동
   - [ ] 터치 스크린 지원

2. **태블릿 (640px - 1024px)**
   - [ ] 레이아웃 정상
   - [ ] 두 칼럼 레이아웃

3. **데스크톱 (> 1024px)**
   - [ ] 레이아웃 정상
   - [ ] 세 칼럼 레이아웃

**예상 시간**: 30분
**담당**: frontend-developer

---

#### TEST-WEB-003: 브라우저 호환성 테스트

**테스트 브라우저**:
- Chrome 120+
- Firefox 120+
- Safari 17+
- Edge 120+

**테스트 시나리오**:
- [ ] 모든 페이지 로드 확인
- [ ] CSS 렌더링 확인
- [ ] JavaScript 기능 확인
- [ ] 콘솔 에러 없음

**예상 시간**: 1시간
**담당**: qa-lead

---

### 5.3 API 테스트

#### TEST-API-001: 기능 테스트

**테스트 도구**: curl, Postman, Jest

**테스트 시나리오**:
1. **GET /api/download-stats**
   - [ ] 200 OK 응답
   - [ ] JSON 형식 응답
   - [ ] 올바른 데이터 구조

2. **POST /api/download-stats**
   - [ ] 200 OK 응답
   - [ ] 통계 증가 확인
   - [ ] Invalid platform 처리 (400 Bad Request)

3. **GET /api/gallery**
   - [ ] 200 OK 응답
   - [ ] 페이지네이션 (limit, offset)
   - [ ] 빈 결과 처리

4. **POST /api/analytics**
   - [ ] 200 OK 응답
   - [ ] 이벤트 저장 확인

**예상 시간**: 1시간
**담당**: backend-developer

---

#### TEST-API-002: 성능 테스트

**테스트 도구**: Apache Bench, wrk

**테스트 시나리오**:
1. **부하 테스트**
   ```bash
   ab -n 1000 -c 10 https://music.abada.kr/api/download-stats
   ```
   - [ ] 평균 응답 시간 < 200ms
   - [ ] 에러율 < 1%

2. **스트레스 테스트**
   ```bash
   wrk -t12 -c400 -d30s https://music.abada.kr/api/download-stats
   ```
   - [ ] RPS > 100
   - [ ] P95 응답 시간 < 500ms

**예상 시간**: 30분
**담당**: qa-lead

---

#### TEST-API-003: 보안 테스트

**테스트 시나리오**:
1. **CORS 검증**
   - [ ] OPTIONS 요청 처리
   - [ ] CORS 헤더 존재

2. **Rate Limiting**
   - [ ] 100회 요청 후 429 응답

3. **입력 검증**
   - [ ] SQL Injection 방어
   - [ ] XSS 방어

**예상 시간**: 30분
**담당**: qa-lead

---

## VI. 승인 기준 (Acceptance Criteria)

### 6.1 Phase 2 완료 기준

Phase 2는 다음 **모든** 조건을 충족해야 완료됩니다:

**설치 프로그램**:
- [ ] Windows/macOS/Linux 설치 성공률 100%
- [ ] Critical 버그 0건
- [ ] 설치 시간 < 30분

**웹사이트**:
- [ ] music.abada.kr 접속 가능
- [ ] Lighthouse 점수 90+ (Desktop)
- [ ] 모든 페이지 로드 시간 < 3초
- [ ] 브라우저 호환성 100%

**API**:
- [ ] 4개 API 모두 정상 응답
- [ ] 응답 시간 < 200ms (P95)
- [ ] Rate Limiting 작동

**배포**:
- [ ] Cloudflare Pages 배포 성공
- [ ] Cloudflare Workers 배포 성공
- [ ] GitHub Release v0.3.0 생성

**문서**:
- [ ] 모든 문서 작성 완료 (6개)
- [ ] CHANGELOG.md 업데이트
- [ ] 사용자 가이드 검증

**성능**:
- [ ] 성능 목표 달성 (Lighthouse 90+)
- [ ] 성능 리포트 작성

---

### 6.2 승인 프로세스

1. **자체 검증** (담당 Agent)
   - 각 Agent가 자신의 작업 검증
   - 체크리스트 완료

2. **QA 검증** (qa-lead)
   - 전체 테스트 실행
   - 버그 리포트 작성

3. **기술 승인** (backend-developer, frontend-developer, devops-lead)
   - 코드 리뷰
   - 기술적 검증

4. **최종 승인** (project-manager)
   - 모든 체크리스트 확인
   - v0.3.0 릴리스 승인

---

## VII. 참고 자료

### 7.1 관련 문서

- [PHASE2_PLAN.md](./PHASE2_PLAN.md) - Phase 2 마스터 플랜
- [PERFORMANCE_OPTIMIZATION.md](./PERFORMANCE_OPTIMIZATION.md) - 성능 최적화 가이드
- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - 배포 가이드
- [MASTER_PLAN.md](./MASTER_PLAN.md) - 전체 8주 계획

### 7.2 외부 표준

- [WCAG 2.1](https://www.w3.org/WAI/WCAG21/quickref/) - 웹 접근성 가이드라인
- [Web Vitals](https://web.dev/vitals/) - Google 성능 메트릭
- [Lighthouse](https://developers.google.com/web/tools/lighthouse) - 성능 측정 도구

---

**문서 버전**: v1.0
**작성자**: technical-writer (AI Agent)
**승인자**: project-manager
**다음 리뷰**: 2026-01-26 (Week 1 종료 시)
