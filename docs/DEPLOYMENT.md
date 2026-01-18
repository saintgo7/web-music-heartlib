# ABADA Music Studio - 배포 & 런칭 가이드

---

## Part 1: Cloudflare Pages 설정

### Step 1: Cloudflare 대시보드 접속

```
1. https://dash.cloudflare.com 방문
2. 로그인 (없으면 가입)
3. "Pages" 메뉴 선택 → "프로젝트 만들기"
```

### Step 2: GitHub 연동

```
1. "Git에 연결" 선택
2. GitHub 계정 연결
3. 저장소: saintgo7/web-music-heartlib 선택
4. 권한 승인
```

### Step 3: 빌드 설정

```
Framework preset: React (또는 None)
Build command: cd web && npm install && npm run build
Build output directory: web/build
Root directory: (비워두기)

Environment variables:
  NODE_ENV: production
```

### Step 4: 커스텀 도메인 연결

```
1. Pages 프로젝트 선택
2. "설정" → "커스텀 도메인"
3. "커스텀 도메인 설정" 클릭
4. music.abada.kr 입력
```

### Step 5: DNS 설정 (abada.kr 호스팅 사이트)

```
Cloudflare 에서 제시한 CNAME 값을 abada.kr DNS에 추가:

Type:  CNAME
Name:  music
Value: [cloudflare-pages-cname].pages.dev
TTL:   Auto

예시:
Name:  music
Value: abada-music.pages.dev
```

---

## Part 2: GitHub Actions 설정

### Step 1: Secrets 설정

```
GitHub Repository Settings → Secrets and variables → Actions

추가할 Secrets:
  CLOUDFLARE_API_TOKEN: [발급받은 API 토큰]
  CLOUDFLARE_ACCOUNT_ID: [Cloudflare 계정 ID]
```

**Cloudflare API Token 발급 방법:**

```
1. Cloudflare Dashboard → Account → API Tokens
2. "Create Token" 클릭
3. "Edit Cloudflare Workers" 템플릿 선택
4. 권한 설정:
   - Account > Cloudflare Workers > Edit
   - Account > Pages > Admin
5. "Continue to summary" → "Create Token"
6. 토큰 복사하여 GitHub Secrets에 저장
```

### Step 2: 워크플로우 파일 작성

**`.github/workflows/build.yml`** (설치 프로그램 빌드)

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
      - uses: actions/checkout@v3

      - name: Install NSIS
        run: choco install nsis -y

      - name: Build x64
        run: |
          cd installer/windows
          makensis /DVERSION=${{ github.ref_name }} MuLaInstaller_x64.nsi

      - name: Build x86
        run: |
          cd installer/windows
          makensis /DVERSION=${{ github.ref_name }} MuLaInstaller_x86.nsi

      - name: Upload
        uses: actions/upload-artifact@v3
        with:
          name: windows-exe
          path: installer/windows/*.exe

  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install tools
        run: brew install create-dmg

      - name: Build DMG
        run: |
          cd installer/macos
          chmod +x build_dmg.sh
          ./build_dmg.sh ${{ github.ref_name }}

      - name: Upload
        uses: actions/upload-artifact@v3
        with:
          name: macos-dmg
          path: installer/macos/*.dmg

  build-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Make executable
        run: chmod +x installer/linux/mula_install.sh

      - name: Verify
        run: bash -n installer/linux/mula_install.sh

      - name: Upload
        uses: actions/upload-artifact@v3
        with:
          name: linux-sh
          path: installer/linux/mula_install.sh

  release:
    needs: [build-windows, build-macos, build-linux]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Download all
        uses: actions/download-artifact@v3

      - name: Checksums
        run: |
          mkdir release
          cd release
          cp ../windows-exe/* . 2>/dev/null || true
          cp ../macos-dmg/* . 2>/dev/null || true
          cp ../linux-sh/* . 2>/dev/null || true
          sha256sum * > checksums.txt

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: release/*
          body: |
            # ABADA Music Studio ${{ github.ref_name }}

            ## 다운로드
            - Windows x64: `MuLa_Setup_x64.exe`
            - Windows x86: `MuLa_Setup_x86.exe`
            - macOS: `MuLa_Installer.dmg`
            - Linux: `mula_install.sh`

            ## 설치 방법
            자세한 가이드: https://music.abada.kr/tutorial
```

**`.github/workflows/deploy-pages.yml`** (웹사이트 배포)

```yaml
name: Deploy to Cloudflare Pages

on:
  push:
    branches: [main]
    paths:
      - 'web/**'
      - '.github/workflows/deploy-pages.yml'
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install deps
        run: |
          cd web
          npm install

      - name: Build
        run: |
          cd web
          npm run build

      - name: Deploy
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy build --project-name=abada-music
```

### Step 3: 태그를 통한 자동 릴리즈

```bash
# 로컬에서 버전 태그 생성
git tag -a v1.0.0 -m "ABADA Music Studio v1.0.0"

# GitHub에 푸시 (GitHub Actions 자동 실행)
git push origin v1.0.0

# Actions 탭에서 진행 상황 확인
```

---

## Part 3: 웹사이트 개발

### 프로젝트 초기화

```bash
cd web

# Node 프로젝트 시작
npm init -y

# 필수 패키지 설치
npm install react react-dom
npm install -D vite @vitejs/plugin-react
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

### 구조

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
│   ├── App.jsx
│   ├── styles/
│   │   └── main.css
│   ├── components/
│   │   ├── Header.jsx
│   │   ├── Hero.jsx
│   │   ├── Features.jsx
│   │   └── Footer.jsx
│   └── js/
│       ├── download.js
│       └── gallery.js
├── vite.config.js
├── tailwind.config.js
└── package.json
```

### 빌드 및 테스트

```bash
# 개발 서버 실행 (http://localhost:5173)
npm run dev

# 빌드 (production)
npm run build

# 미리보기
npm run preview
```

---

## Part 4: 설치 프로그램 빌드

### Windows (로컬 빌드)

```bash
# NSIS 설치 필요
# https://nsis.sourceforge.io/Download

# x64 버전 빌드
cd installer/windows
makensis /DVERSION=1.0.0 MuLaInstaller_x64.nsi
# 결과: MuLa_Setup_x64.exe

# x86 버전 빌드
makensis /DVERSION=1.0.0 MuLaInstaller_x86.nsi
# 결과: MuLa_Setup_x86.exe
```

### macOS

```bash
# create-dmg 설치
brew install create-dmg

# 빌드
cd installer/macos
chmod +x build_dmg.sh
./build_dmg.sh 1.0.0

# 결과: MuLa_Installer.dmg
```

### Linux

```bash
# 실행 권한 설정
chmod +x installer/linux/mula_install.sh

# 테스트 (문법 검사)
bash -n installer/linux/mula_install.sh

# 실제 사용자는 다운로드 후 실행:
# chmod +x mula_install.sh
# ./mula_install.sh
```

---

## Part 5: 배포 체크리스트

### 배포 전 확인

- [ ] 모든 파일이 `web-music-heartlib` 저장소에 푸시됨
- [ ] GitHub Actions Secrets 설정 완료
  - [ ] `CLOUDFLARE_API_TOKEN`
  - [ ] `CLOUDFLARE_ACCOUNT_ID`
- [ ] Cloudflare Pages 프로젝트 생성
- [ ] DNS 레코드 설정 완료 (music.abada.kr)
- [ ] `.github/workflows/` 파일들 저장소에 포함됨

### 배포 단계

```
Step 1: 웹사이트 배포 (자동)
  └─ main 브랜치에 web/ 폴더 변경 push
     → GitHub Actions 자동 실행
     → music.abada.kr 자동 배포

Step 2: 설치 프로그램 배포 (수동 or 자동)
  └─ git tag -a v1.0.0 push
     → GitHub Actions 자동 빌드
     → GitHub Releases에 자동 생성

Step 3: 최종 확인
  └─ https://music.abada.kr 접속 확인
  └─ GitHub Releases에 파일 확인
  └─ 각 OS별 다운로드 테스트
```

---

## Part 6: 런칭 홍보 가이드

### 사전 준비 (배포 전)

```
1주일 전:
  [ ] SNS 계정 확인 (Twitter, LinkedIn, Facebook)
  [ ] 기자 보도자료 작성
  [ ] 유튜브 썸네일 준비

3일 전:
  [ ] Product Hunt 계정 설정
  [ ] 갤러리 샘플 곡 준비 (5-10개)
  [ ] 스크린샷 및 GIF 준비

1일 전:
  [ ] 모든 링크 최종 확인
  [ ] 배포 스크립트 테스트
```

### 배포 당일 (동시 다중 채널)

```
Step 1: 공식 배포 (10:00 AM)
  [ ] GitHub Releases v1.0.0 생성
  [ ] music.abada.kr 라이브 (Cloudflare Pages)
  [ ] README.md 업데이트

Step 2: SNS 공지 (10:05 AM)
  [ ] Twitter/X 포스팅
  [ ] LinkedIn 포스팅
  [ ] Facebook 포스팅

Step 3: 커뮤니티 공지 (10:15 AM)
  [ ] Reddit r/MachineLearning
  [ ] Reddit r/OpenSource
  [ ] HackerNews "Show HN"
  [ ] Product Hunt

Step 4: 기술 커뮤니티 (10:30 AM)
  [ ] GitHub Trending 페이지 확인
  [ ] Awesome Lists 추가 신청
  [ ] Hugging Face 모델 페이지 링크
```

### SNS 포스팅 템플릿

**[Twitter/X]**
```
🎵 ABADA Music Studio 출시!

AI로 음악을 만드세요.
한 번의 클릭으로 설치합니다.

✨ Windows • macOS • Linux
🆓 완전 무료 • 오픈소스
💻 인터넷 불필요 • 오프라인 사용

지금 다운로드: https://music.abada.kr

#AI #OpenSource #MusicGeneration #ABADA
```

**[LinkedIn]**
```
🎶 ABADA Music Studio - Open Source AI의 대중화

ABADA Inc.에서 새로운 프로젝트를 출시했습니다.
복잡한 AI 음악생성을 한 번의 클릭으로 해결합니다.

💡 기술
- HeartMuLa: 최고 수준의 AI 음악 생성 모델
- Gradio: 사용자 친화적 UI
- One-Click Installer: 개발자 없이도 설치 가능

🎯 미션
비개발자도 AI를 쉽게 사용하도록
Open Source를 대중화합니다.

더 알아보기: https://music.abada.kr
GitHub: https://github.com/saintgo7/web-music-heartlib
```

---

## Part 7: 배포 후 모니터링

### 매일 확인

```
[ ] 다운로드 통계 확인
    - Windows: __개
    - macOS: __개
    - Linux: __개

[ ] GitHub Issues 확인 및 대응

[ ] 웹사이트 접근성 확인
    - Cloudflare Analytics
    - 방문자 수
    - 평균 체류 시간

[ ] 에러 로그 확인
```

### 주간 확인

```
[ ] GitHub Stars 추이
[ ] SNS 언급 수
[ ] 갤러리 제출 현황
[ ] 성능 분석 (PageSpeed Insights)
```

### 월간 확인

```
[ ] 누적 다운로드
[ ] 사용자 피드백 분석
[ ] 버그 리포트 분류
[ ] 성능 최적화
[ ] 향후 계획 수립
```

---

## Part 8: 트러블슈팅

### Cloudflare Pages 배포 오류

```
문제: "build command failed"
해결:
  1. web/package.json 확인
  2. 빌드 명령어 검증 (로컬 테스트)
  3. Node 버전 확인
  4. 의존성 설치 재확인

문제: "domain not found"
해결:
  1. DNS CNAME 레코드 확인
  2. TTL 값 확인 (재전파 대기)
  3. Cloudflare DNS 설정 재확인
```

### GitHub Actions 빌드 오류

```
문제: "makensis not found (Windows)"
해결:
  1. NSIS 설치 여부 확인
  2. 환경변수 설정 확인
  3. Windows Runner 이미지 확인

문제: "Permission denied (Linux/Mac)"
해결:
  1. chmod +x 실행 확인
  2. 파일 경로 확인
  3. 스크립트 문법 검사 (bash -n)
```

---

## Part 9: 보안 체크리스트

배포 전 필수 확인:

```
[ ] API 키/토큰이 소스에 없음
[ ] .env.example만 제공 (실제 .env는 .gitignore)
[ ] GitHub Secrets 올바르게 설정
[ ] SSL/TLS 인증서 유효 (Cloudflare 자동)
[ ] 악성코드 스캔 (VirusTotal)
    - Windows EXE 파일들
    - 체크섬 검증
```

---

## 빠른 배포 명령어

### 로컬 빌드 테스트

```bash
# 웹사이트 빌드
cd web
npm install
npm run build

# Windows EXE 빌드 (Windows만)
cd installer/windows
makensis MuLaInstaller_x64.nsi

# macOS DMG 빌드 (macOS만)
cd installer/macos
./build_dmg.sh

# Linux 스크립트 문법 검사
bash -n installer/linux/mula_install.sh
```

### GitHub 태그를 통한 자동 배포

```bash
# 현재 변경사항 커밋
git add .
git commit -m "Release v1.0.0"

# 태그 생성 및 푸시
git tag -a v1.0.0 -m "ABADA Music Studio v1.0.0"
git push origin main
git push origin v1.0.0

# Actions 탭에서 진행 상황 확인
# https://github.com/saintgo7/web-music-heartlib/actions
```

---

## 참고 자료

- **Cloudflare Pages Docs**: https://developers.cloudflare.com/pages
- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **NSIS Documentation**: https://nsis.sourceforge.io/Docs
- **Vite Documentation**: https://vitejs.dev
- **Tailwind CSS**: https://tailwindcss.com

---

**작성일**: 2026-01-18
**상태**: 🔵 Ready for Deployment

