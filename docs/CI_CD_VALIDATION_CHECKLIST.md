# ABADA Music Studio - CI/CD 검증 체크리스트

**버전**: v0.3.0
**작성일**: 2026-01-19
**대상**: DevOps 엔지니어, 릴리즈 관리자

---

## 목차

1. [GitHub Actions 워크플로우 검증](#github-actions-워크플로우-검증)
2. [빌드 아티팩트 검증](#빌드-아티팩트-검증)
3. [릴리즈 프로세스 체크리스트](#릴리즈-프로세스-체크리스트)
4. [배포 검증 단계](#배포-검증-단계)
5. [롤백 절차](#롤백-절차)
6. [모니터링 및 알림](#모니터링-및-알림)

---

## GitHub Actions 워크플로우 검증

### 1. Build Installers 워크플로우

**파일**: `.github/workflows/build-installers.yml`

#### Pre-deployment 체크리스트

- [ ] **워크플로우 파일 문법 확인**
  ```bash
  # GitHub CLI로 검증
  gh workflow view build-installers.yml
  ```

- [ ] **Secrets 설정 확인**
  ```bash
  gh secret list
  # 필요한 Secrets:
  # - WINDOWS_CERT_PASSWORD (Phase 3)
  # - APPLE_DEVELOPER_ID (Phase 3)
  # - GITHUB_TOKEN (자동 생성됨)
  ```

- [ ] **러너 환경 확인**
  ```yaml
  jobs:
    build-windows:
      runs-on: windows-latest  # ✓ Windows Server 2022
    build-macos:
      runs-on: macos-latest    # ✓ macOS 12+
    build-linux:
      runs-on: ubuntu-latest   # ✓ Ubuntu 22.04
  ```

- [ ] **빌드 트리거 확인**
  ```yaml
  on:
    push:
      tags:
        - 'v*.*.*'  # ✓ 태그 푸시 시 자동 실행
    workflow_dispatch:  # ✓ 수동 실행 가능
  ```

#### Build 단계 검증

**Windows 빌드**:
- [ ] NSIS 설치 확인
  ```yaml
  - name: Install NSIS
    run: choco install nsis -y
  ```
- [ ] Python 임베딩 다운로드
  ```yaml
  - name: Download Python Embedded
    run: |
      Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.10.11/python-3.10.11-embed-amd64.zip" -OutFile python.zip
  ```
- [ ] NSIS 컴파일 성공
  ```yaml
  - name: Build installer
    run: makensis installer/windows/MuLaInstaller_x64.nsi
  ```
- [ ] 아티팩트 업로드
  ```yaml
  - name: Upload artifact
    uses: actions/upload-artifact@v3
    with:
      name: MuLaInstaller-${{ github.ref_name }}-win-x64.exe
      path: installer/windows/MuLaInstaller-${{ github.ref_name }}-win-x64.exe
  ```

**macOS 빌드**:
- [ ] Homebrew 의존성 설치
  ```yaml
  - name: Install dependencies
    run: brew install create-dmg
  ```
- [ ] DMG 빌드 성공
  ```yaml
  - name: Build DMG
    run: |
      cd installer/macos
      ./build_dmg.sh
  ```
- [ ] 코드 서명 (Phase 3)
  ```yaml
  - name: Sign app (Phase 3)
    run: codesign --force --deep --sign "${{ secrets.APPLE_DEVELOPER_ID }}" MuLa.app
  ```

**Linux 빌드**:
- [ ] 스크립트 실행 권한
  ```yaml
  - name: Make script executable
    run: chmod +x installer/linux/mula_install.sh
  ```
- [ ] tar.gz 생성
  ```yaml
  - name: Create tarball
    run: |
      tar -czf MuLa-${{ github.ref_name }}-linux.tar.gz installer/linux/
  ```

#### Post-build 검증

- [ ] **아티팩트 크기 확인**
  ```bash
  # Windows: ~50MB (Python 임베딩 포함)
  # macOS: ~200MB (DMG)
  # Linux: ~10KB (스크립트만)
  ```

- [ ] **체크섬 생성**
  ```yaml
  - name: Generate checksums
    run: |
      sha256sum MuLaInstaller-*.exe > checksums.txt
      sha256sum MuLa-*.dmg >> checksums.txt
      sha256sum MuLa-*.tar.gz >> checksums.txt
  ```

- [ ] **릴리즈 노트 자동 생성**
  ```yaml
  - name: Generate release notes
    run: |
      gh release create ${{ github.ref_name }} \
        --generate-notes \
        --title "ABADA MuLa ${{ github.ref_name }}" \
        MuLaInstaller-*.exe \
        MuLa-*.dmg \
        MuLa-*.tar.gz \
        checksums.txt
  ```

---

### 2. Deploy Website 워크플로우

**파일**: `.github/workflows/deploy-website.yml`

#### Pre-deployment 체크리스트

- [ ] **Cloudflare 인증 확인**
  ```bash
  gh secret list
  # 필요한 Secrets:
  # - CLOUDFLARE_API_TOKEN
  # - CLOUDFLARE_ACCOUNT_ID
  ```

- [ ] **빌드 환경 설정**
  ```yaml
  env:
    NODE_ENV: production
    BASE_URL: https://music.abada.kr
  ```

#### Build 단계 검증

- [ ] **의존성 설치**
  ```yaml
  - name: Install dependencies
    run: |
      cd web
      npm ci
  ```

- [ ] **프로덕션 빌드**
  ```yaml
  - name: Build website
    run: |
      cd web
      npm run build
  ```

- [ ] **빌드 결과 확인**
  ```bash
  # dist/ 디렉토리 존재 확인
  # index.html, assets/ 존재 확인
  ls -la web/dist/
  ```

- [ ] **번들 사이즈 검증**
  ```yaml
  - name: Check bundle size
    run: |
      cd web
      npm run analyze
      # Gzipped < 500KB 확인
  ```

#### Deployment 단계 검증

- [ ] **Cloudflare Pages 배포**
  ```yaml
  - name: Deploy to Cloudflare Pages
    uses: cloudflare/pages-action@v1
    with:
      apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
      accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
      projectName: abada-music-studio
      directory: web/dist
      gitHubToken: ${{ secrets.GITHUB_TOKEN }}
  ```

- [ ] **배포 URL 확인**
  ```
  Production: https://music.abada.kr
  Preview: https://[commit-hash].abada-music-studio.pages.dev
  ```

#### Post-deployment 검증

- [ ] **배포 상태 확인**
  ```bash
  curl -I https://music.abada.kr
  # HTTP/2 200 확인
  ```

- [ ] **DNS 전파 확인**
  ```bash
  dig music.abada.kr
  # CNAME → abada-music-studio.pages.dev
  ```

- [ ] **SSL 인증서 확인**
  ```bash
  openssl s_client -connect music.abada.kr:443 -servername music.abada.kr
  # 인증서 유효기간 확인
  ```

- [ ] **Lighthouse 점수 확인**
  ```yaml
  - name: Run Lighthouse CI
    uses: treosh/lighthouse-ci-action@v10
    with:
      urls: |
        https://music.abada.kr/
      uploadArtifacts: true
  ```

---

### 3. Lint and Test 워크플로우

**파일**: `.github/workflows/lint-and-test.yml`

#### Pre-commit 검증

- [ ] **ESLint 검사**
  ```yaml
  - name: Run ESLint
    run: |
      cd web
      npm run lint
  ```

- [ ] **TypeScript 타입 체크**
  ```yaml
  - name: TypeScript check
    run: |
      cd web
      npx tsc --noEmit
  ```

- [ ] **Prettier 포맷 확인**
  ```yaml
  - name: Check formatting
    run: |
      cd web
      npx prettier --check "src/**/*.{js,jsx,ts,tsx,css}"
  ```

#### 테스트 실행

- [ ] **단위 테스트**
  ```yaml
  - name: Run unit tests
    run: |
      cd web
      npm run test:unit -- --coverage
  ```

- [ ] **통합 테스트**
  ```yaml
  - name: Run integration tests
    run: |
      cd web
      npm run test:integration
  ```

- [ ] **E2E 테스트** (선택 사항)
  ```yaml
  - name: Run E2E tests
    run: |
      cd web
      npx playwright test
  ```

- [ ] **커버리지 업로드**
  ```yaml
  - name: Upload coverage to Codecov
    uses: codecov/codecov-action@v3
    with:
      file: ./web/coverage/lcov.info
  ```

---

## 빌드 아티팩트 검증

### Windows Installer 검증

**파일**: `MuLaInstaller-v1.0.0-win-x64.exe`

- [ ] **파일 크기 확인**: 45-55MB
- [ ] **디지털 서명 확인** (Phase 3)
  ```powershell
  Get-AuthenticodeSignature MuLaInstaller-v1.0.0-win-x64.exe
  # Status: Valid
  # SignerCertificate: CN=ABADA
  ```

- [ ] **바이러스 스캔**
  ```bash
  # VirusTotal API
  curl --request POST \
    --url https://www.virustotal.com/api/v3/files \
    --header "x-apikey: $VIRUSTOTAL_API_KEY" \
    --form "file=@MuLaInstaller-v1.0.0-win-x64.exe"
  ```

- [ ] **설치 테스트 (가상 머신)**
  - Windows 10 (21H2)
  - Windows 11 (22H2)
  - GPU: NVIDIA GTX 1060
  - CPU-only 환경

- [ ] **언인스톨 테스트**
  - 제어판에서 제거
  - 레지스트리 정리 확인
  - 파일 완전 삭제 확인

### macOS DMG 검증

**파일**: `MuLa-v1.0.0-macos-arm64.dmg`

- [ ] **파일 크기 확인**: 180-220MB
- [ ] **코드 서명 확인** (Phase 3)
  ```bash
  codesign -dv --verbose=4 /Volumes/ABADA\ MuLa/MuLa.app
  # Authority=Developer ID Application: ABADA (TEAM_ID)
  ```

- [ ] **공증 확인** (Phase 3)
  ```bash
  spctl -a -vv /Volumes/ABADA\ MuLa/MuLa.app
  # accepted
  # source=Notarized Developer ID
  ```

- [ ] **DMG 마운트 테스트**
  ```bash
  hdiutil attach MuLa-v1.0.0-macos-arm64.dmg
  ls -la /Volumes/ABADA\ MuLa/
  # MuLa.app 존재 확인
  # Applications 심볼릭 링크 확인
  ```

- [ ] **설치 테스트 (물리 머신)**
  - macOS Monterey (Intel)
  - macOS Sonoma (Apple Silicon M1)

### Linux Tarball 검증

**파일**: `MuLa-v1.0.0-linux.tar.gz`

- [ ] **파일 크기 확인**: 8-12KB (스크립트만)
- [ ] **압축 해제 테스트**
  ```bash
  tar -xzf MuLa-v1.0.0-linux.tar.gz
  ls -la installer/linux/
  # mula_install.sh 존재 확인
  ```

- [ ] **스크립트 문법 확인**
  ```bash
  shellcheck installer/linux/mula_install.sh
  # 0 errors
  ```

- [ ] **설치 테스트 (Docker)**
  ```bash
  docker run -it ubuntu:22.04
  bash /tmp/mula_install.sh
  # 설치 성공 확인
  ```

---

## 릴리즈 프로세스 체크리스트

### Phase 1: Pre-release (릴리즈 2주 전)

- [ ] **코드 프리즈**
  - 새 기능 개발 중단
  - 버그 수정만 허용

- [ ] **릴리즈 브랜치 생성**
  ```bash
  git checkout -b release/v1.0.0 main
  git push origin release/v1.0.0
  ```

- [ ] **버전 번호 업데이트**
  ```json
  // web/package.json
  {
    "version": "1.0.0"
  }
  ```
  ```python
  # installer/app/__init__.py
  __version__ = "1.0.0"
  ```

- [ ] **CHANGELOG.md 작성**
  ```markdown
  ## [1.0.0] - 2026-03-15

  ### Added
  - Windows x64/x86 installer with GPU detection
  - macOS DMG with Apple Silicon support
  - Linux multi-distro installation script
  - React-based website with 6 pages
  - Cloudflare Workers API (download stats, gallery, analytics)

  ### Fixed
  - [BUG-001] GPU detection failure on AMD cards
  - [BUG-002] macOS Homebrew installation hang

  ### Changed
  - Improved download speed with CDN caching
  ```

- [ ] **문서 업데이트**
  - README.md
  - DEPLOYMENT.md
  - API 문서

### Phase 2: Release Candidate (RC) (1주 전)

- [ ] **RC 태그 생성**
  ```bash
  git tag -a v1.0.0-rc.1 -m "Release Candidate 1"
  git push origin v1.0.0-rc.1
  ```

- [ ] **RC 빌드 및 배포**
  - GitHub Actions 자동 빌드
  - Staging 환경 배포: `https://rc.music.abada.kr`

- [ ] **QA 테스트**
  - E2E 테스트 실행
  - 수동 테스트 (Windows/macOS/Linux)
  - 성능 테스트
  - 보안 스캔

- [ ] **베타 테스터 피드백**
  - 10-20명 베타 테스터 초대
  - 피드백 수집 (Google Forms)
  - 크리티컬 버그 수정

### Phase 3: Release (릴리즈 당일)

- [ ] **최종 태그 생성**
  ```bash
  git tag -a v1.0.0 -m "Release v1.0.0"
  git push origin v1.0.0
  ```

- [ ] **GitHub Actions 빌드 확인**
  - Windows installer 빌드 완료
  - macOS DMG 빌드 완료
  - Linux tarball 빌드 완료
  - 웹사이트 배포 완료

- [ ] **GitHub Release 생성**
  ```bash
  gh release create v1.0.0 \
    --title "ABADA MuLa v1.0.0" \
    --notes-file CHANGELOG.md \
    MuLaInstaller-v1.0.0-win-x64.exe \
    MuLa-v1.0.0-macos-arm64.dmg \
    MuLa-v1.0.0-linux.tar.gz \
    checksums.txt
  ```

- [ ] **웹사이트 프로덕션 배포**
  - `https://music.abada.kr` 업데이트
  - 캐시 무효화
  - DNS 전파 확인

- [ ] **API 배포**
  ```bash
  wrangler publish --env production
  ```

### Phase 4: Post-release (릴리즈 후)

- [ ] **모니터링**
  - Cloudflare Analytics 확인
  - 에러율 모니터링 (< 0.1%)
  - 다운로드 통계 확인

- [ ] **릴리즈 공지**
  - 블로그 포스트 (예정)
  - 소셜 미디어 (Twitter, LinkedIn)
  - Reddit r/MachineLearning

- [ ] **문서 아카이브**
  ```bash
  git tag -a docs/v1.0.0 -m "Documentation for v1.0.0"
  git push origin docs/v1.0.0
  ```

---

## 배포 검증 단계

### 1. 웹사이트 배포 검증

**Production URL**: `https://music.abada.kr`

- [ ] **페이지 로드 확인**
  ```bash
  for page in "/" "/download" "/tutorial" "/gallery" "/faq" "/about"; do
    curl -sI "https://music.abada.kr$page" | grep "HTTP/2 200"
  done
  ```

- [ ] **Lighthouse 점수 확인**
  ```bash
  lighthouse https://music.abada.kr --output json --output-path ./reports/lighthouse-prod.json
  # Performance > 90
  # SEO > 95
  ```

- [ ] **리소스 로드 확인**
  ```javascript
  // 브라우저 콘솔
  performance.getEntriesByType('resource').forEach(r => {
    console.log(`${r.name}: ${r.duration}ms`);
  });
  ```

- [ ] **모바일 테스트**
  - Chrome DevTools → Device Toolbar
  - iPhone 12 시뮬레이션
  - 반응형 레이아웃 확인

### 2. API 배포 검증

- [ ] **Download Stats API**
  ```bash
  # POST 테스트
  curl -X POST https://music.abada.kr/api/download-stats \
    -H "Content-Type: application/json" \
    -d '{"os":"windows","version":"v1.0.0","timestamp":"2026-01-19T12:00:00Z"}'
  # Expected: 201 Created

  # GET 테스트
  curl https://music.abada.kr/api/download-stats
  # Expected: {"total":X,"byOS":{...}}
  ```

- [ ] **Gallery API**
  ```bash
  curl https://music.abada.kr/api/gallery?limit=10
  # Expected: {"items":[...],"total":X}
  ```

- [ ] **Analytics API**
  ```bash
  curl -X POST https://music.abada.kr/api/analytics \
    -H "Content-Type: application/json" \
    -d '{"event":"page_view","page":"/"}'
  # Expected: 201 Created
  ```

- [ ] **CORS 확인**
  ```bash
  curl -I https://music.abada.kr/api/gallery \
    -H "Origin: https://music.abada.kr"
  # Access-Control-Allow-Origin: * 확인
  ```

### 3. CDN 캐싱 확인

- [ ] **Cache Hit Rate 확인**
  ```
  Cloudflare Dashboard → Analytics → Caching
  → Cache Hit Ratio > 80%
  ```

- [ ] **Edge 응답 시간**
  ```bash
  curl -w "@curl-format.txt" -o /dev/null -s https://music.abada.kr/
  # time_total < 1s
  ```

- [ ] **Gzip 압축 확인**
  ```bash
  curl -I https://music.abada.kr/ -H "Accept-Encoding: gzip"
  # Content-Encoding: gzip 확인
  ```

---

## 롤백 절차

### 웹사이트 롤백

**시나리오**: 프로덕션 배포 후 크리티컬 버그 발견

1. **이전 버전으로 롤백**
   ```bash
   # Cloudflare Pages Dashboard
   # Deployments → 이전 배포 선택 → "Rollback to this deployment"
   ```

2. **Git 태그로 재배포**
   ```bash
   git checkout v0.9.9  # 이전 안정 버전
   git push origin v0.9.9 --force
   # GitHub Actions 자동 재배포
   ```

3. **캐시 무효화**
   ```bash
   curl -X POST "https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/purge_cache" \
     -H "Authorization: Bearer {API_TOKEN}" \
     -H "Content-Type: application/json" \
     --data '{"purge_everything":true}'
   ```

### API 롤백

1. **Wrangler로 롤백**
   ```bash
   wrangler rollback --env production
   ```

2. **KV Store 데이터 복원** (필요 시)
   ```bash
   # 백업에서 복원
   wrangler kv:key put "stats" "$(cat backup/stats.json)" --binding=DOWNLOAD_STATS
   ```

### 설치 프로그램 롤백

1. **GitHub Release 숨김**
   ```bash
   # v1.0.0 릴리즈를 Draft로 변경
   gh release edit v1.0.0 --draft
   ```

2. **이전 버전 활성화**
   ```bash
   # v0.9.9를 Latest로 표시
   gh release edit v0.9.9 --latest
   ```

---

## 모니터링 및 알림

### Cloudflare Analytics

- [ ] **실시간 트래픽 모니터링**
  ```
  Dashboard → Analytics → Traffic
  → Requests, Bandwidth, Unique Visitors
  ```

- [ ] **에러율 모니터링**
  ```
  Dashboard → Analytics → Reliability
  → HTTP Status Codes (4xx, 5xx)
  → 목표: < 0.1%
  ```

- [ ] **성능 메트릭**
  ```
  Dashboard → Speed → Performance
  → Origin Response Time: < 200ms (p95)
  ```

### GitHub Actions 알림

- [ ] **빌드 실패 알림** (Slack/Discord)
  ```yaml
  # .github/workflows/build-installers.yml
  - name: Notify on failure
    if: failure()
    uses: 8398a7/action-slack@v3
    with:
      status: ${{ job.status }}
      webhook_url: ${{ secrets.SLACK_WEBHOOK }}
  ```

### Sentry 에러 추적 (선택 사항)

- [ ] **Sentry 통합**
  ```javascript
  // web/src/main.tsx
  import * as Sentry from "@sentry/react";

  Sentry.init({
    dsn: "https://your-dsn@sentry.io/project",
    environment: "production",
    tracesSampleRate: 0.1,
  });
  ```

- [ ] **에러 알림 설정**
  - 크리티컬 에러 → 즉시 Slack 알림
  - 에러율 > 1% → 경고

---

## 체크리스트 요약

### 릴리즈 전 (T-2주)

- [ ] 코드 프리즈
- [ ] 릴리즈 브랜치 생성
- [ ] 버전 번호 업데이트
- [ ] CHANGELOG.md 작성
- [ ] 문서 업데이트

### 릴리즈 전 (T-1주)

- [ ] RC 태그 생성
- [ ] RC 빌드 및 Staging 배포
- [ ] QA 테스트 (E2E, 성능, 보안)
- [ ] 베타 테스터 피드백
- [ ] 크리티컬 버그 수정

### 릴리즈 당일

- [ ] 최종 태그 생성 (v1.0.0)
- [ ] GitHub Actions 빌드 확인
- [ ] 아티팩트 검증 (크기, 서명, 바이러스 스캔)
- [ ] GitHub Release 생성
- [ ] 웹사이트 프로덕션 배포
- [ ] API 프로덕션 배포
- [ ] 배포 검증 (Lighthouse, API 테스트)

### 릴리즈 후

- [ ] 모니터링 (트래픽, 에러율, 성능)
- [ ] 릴리즈 공지
- [ ] 문서 아카이브
- [ ] 핫픽스 대응 준비

---

**문서 버전**: 1.0.0
**마지막 업데이트**: 2026-01-19
**다음 리뷰**: 2026-02-01
