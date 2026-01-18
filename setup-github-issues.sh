#!/bin/bash

# GitHub Issues & Milestones 자동 설정
# ABADA Music Studio 프로젝트용

set -e

REPO="saintgo7/web-music-heartlib"
echo "🔧 GitHub Issues 설정 시작 ($REPO)"
echo ""

#═══════════════════════════════════════════════════════════
# 1. 마일스톤 생성
#═══════════════════════════════════════════════════════════

echo "📌 마일스톤 생성 중..."

# Phase 1: 설치 프로그램
gh milestone create \
  --repo="$REPO" \
  --title="Phase 1: 설치 프로그램 개발 (W1-2)" \
  --description="Windows x64/x86, macOS, Linux 설치 프로그램 개발" \
  --due-date="2026-02-01" || echo "  ⚠️  Phase 1 마일스톤 이미 존재"

# Phase 2: 웹사이트
gh milestone create \
  --repo="$REPO" \
  --title="Phase 2: 웹사이트 개발 (W3-4)" \
  --description="music.abada.kr 웹사이트 개발 및 Cloudflare Pages 배포" \
  --due-date="2026-02-15" || echo "  ⚠️  Phase 2 마일스톤 이미 존재"

# Phase 3: 통합 & 테스트
gh milestone create \
  --repo="$REPO" \
  --title="Phase 3: 통합 & 테스트 (W5-6)" \
  --description="엔드투엔드 테스트 및 배포 준비" \
  --due-date="2026-03-01" || echo "  ⚠️  Phase 3 마일스톤 이미 존재"

# Phase 4: 런칭 & 홍보
gh milestone create \
  --repo="$REPO" \
  --title="Phase 4: 런칭 & 홍보 (W7-8)" \
  --description="공식 출시 및 SNS 홍보" \
  --due-date="2026-03-15" || echo "  ⚠️  Phase 4 마일스톤 이미 존재"

echo "✅ 마일스톤 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 2. 라벨 생성
#═══════════════════════════════════════════════════════════

echo "🏷️  라벨 생성 중..."

# 우선순위
gh label create \
  --repo="$REPO" \
  --name="priority: critical" \
  --color="ff0000" \
  --description="긴급 처리 필요" || true

gh label create \
  --repo="$REPO" \
  --name="priority: high" \
  --color="ff6600" \
  --description="높은 우선순위" || true

gh label create \
  --repo="$REPO" \
  --name="priority: medium" \
  --color="ffcc00" \
  --description="중간 우선순위" || true

gh label create \
  --repo="$REPO" \
  --name="priority: low" \
  --color="00cc00" \
  --description="낮은 우선순위" || true

# 작업 타입
gh label create \
  --repo="$REPO" \
  --name="type: feature" \
  --color="0099ff" \
  --description="새로운 기능" || true

gh label create \
  --repo="$REPO" \
  --name="type: bug" \
  --color="ff0000" \
  --description="버그 수정" || true

gh label create \
  --repo="$REPO" \
  --name="type: docs" \
  --color="9966ff" \
  --description="문서 작업" || true

gh label create \
  --repo="$REPO" \
  --name="type: chore" \
  --color="cccccc" \
  --description="유지보수" || true

# 상태
gh label create \
  --repo="$REPO" \
  --name="status: in-progress" \
  --color="0099ff" \
  --description="진행 중" || true

gh label create \
  --repo="$REPO" \
  --name="status: blocked" \
  --color="ff0000" \
  --description="차단됨" || true

gh label create \
  --repo="$REPO" \
  --name="status: review" \
  --color="ffcc00" \
  --description="검토 필요" || true

# 플랫폼
gh label create \
  --repo="$REPO" \
  --name="platform: windows" \
  --color="0078d4" \
  --description="Windows" || true

gh label create \
  --repo="$REPO" \
  --name="platform: macos" \
  --color="999999" \
  --description="macOS" || true

gh label create \
  --repo="$REPO" \
  --name="platform: linux" \
  --color="ff9900" \
  --description="Linux" || true

# 영역
gh label create \
  --repo="$REPO" \
  --name="area: installer" \
  --color="ff00ff" \
  --description="설치 프로그램" || true

gh label create \
  --repo="$REPO" \
  --name="area: website" \
  --color="00ff00" \
  --description="웹사이트" || true

gh label create \
  --repo="$REPO" \
  --name="area: ci-cd" \
  --color="00cccc" \
  --description="CI/CD & 배포" || true

gh label create \
  --repo="$REPO" \
  --name="area: marketing" \
  --color="ff66ff" \
  --description="홍보 & 마케팅" || true

echo "✅ 라벨 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 3. Phase 1 이슈들 생성
#═══════════════════════════════════════════════════════════

echo "📝 Phase 1 이슈 생성 중..."

# Windows x64
gh issue create \
  --repo="$REPO" \
  --title="[Phase 1] Windows x64 설치 프로그램 개발" \
  --body="## 작업 설명
Windows 64비트용 NSIS 설치 프로그램 개발

## 요구사항
- Python 3.10 embedded 통합
- GPU 자동 감지 (NVIDIA CUDA)
- PyTorch + 의존성 자동 설치
- 모델 다운로드 (6GB) 통합
- 바로가기 생성 (바탕화면, 시작메뉴)
- 제거 프로그램 지원

## 산출물
- MuLa_Setup_x64.exe (~80MB)
- 설치 마법사 UI
- 시스템 체크 기능

## 참고자료
- [DEV.md - Windows 설치 프로그램](./docs/DEV.md#32-windows-설치-프로그램-nsis)
- [NSIS Documentation](https://nsis.sourceforge.io/Docs)

## 체크리스트
- [ ] NSIS 스크립트 작성
- [ ] Python embed 다운로드 및 통합
- [ ] GPU 감지 로직 구현
- [ ] 모델 다운로드 통합
- [ ] 로컬 테스트 (Windows 10/11)
- [ ] 클린 설치 테스트
- [ ] 제거 기능 테스트
" \
  --milestone="Phase 1: 설치 프로그램 개발 (W1-2)" \
  --label="type: feature,platform: windows,area: installer,priority: critical" || true

# Windows x86
gh issue create \
  --repo="$REPO" \
  --title="[Phase 1] Windows x86 설치 프로그램 개발" \
  --body="## 작업 설명
Windows 32비트용 NSIS 설치 프로그램 개발

## 요구사항
- Python 3.10 embedded (32비트) 통합
- CPU 모드 전용 (CUDA 미지원)
- 성능 경고 메시지 표시
- Windows x64와 동일한 UI

## 산출물
- MuLa_Setup_x86.exe (~80MB)

## 참고자료
- [DEV.md - Windows x86](./docs/DEV.md#323-windows-x86-32비트-차이점)

## 체크리스트
- [ ] 32비트 Python embed 준비
- [ ] NSIS 스크립트 작성 (x64 기반)
- [ ] CPU 전용 설정 구현
- [ ] 로컬 테스트 (32비트 환경)
- [ ] x64 버전과 차이점 검증
" \
  --milestone="Phase 1: 설치 프로그램 개발 (W1-2)" \
  --label="type: feature,platform: windows,area: installer,priority: high" || true

# macOS
gh issue create \
  --repo="$REPO" \
  --title="[Phase 1] macOS 설치 프로그램 개발" \
  --body="## 작업 설명
macOS용 자동 설치 스크립트 및 DMG 패키지 개발

## 요구사항
- Intel Mac 지원 (CPU 모드)
- Apple Silicon (M1/M2) 지원 (MPS 가속)
- Homebrew 자동 설치
- Python 3.10 가상환경 구성
- DMG 패키지 생성

## 산출물
- MuLa_Installer.dmg (~50MB)
- install.sh 설치 스크립트
- run.command 실행 스크립트

## 참고자료
- [DEV.md - macOS 설치](./docs/DEV.md#33-macos-설치-프로그램-dmg)

## 체크리스트
- [ ] install.sh 작성
- [ ] Homebrew 통합 로직
- [ ] Intel/Apple Silicon 자동 감지
- [ ] DMG 생성 자동화
- [ ] Intel Mac 테스트
- [ ] Apple Silicon 테스트
- [ ] 앱 번들 구성 확인
" \
  --milestone="Phase 1: 설치 프로그램 개발 (W1-2)" \
  --label="type: feature,platform: macos,area: installer,priority: critical" || true

# Linux
gh issue create \
  --repo="$REPO" \
  --title="[Phase 1] Linux 설치 프로그램 개발" \
  --body="## 작업 설명
Linux용 자동 설치 쉘 스크립트 개발

## 요구사항
- Ubuntu 20.04+ 지원
- Fedora 지원
- Arch Linux 지원
- Python 3.10 설치
- Desktop Entry 생성
- PATH 환경변수 설정

## 산출물
- mula_install.sh (~5KB)
- mulastudio 명령어
- .desktop 파일

## 참고자료
- [DEV.md - Linux 설치](./docs/DEV.md#34-linux-설치-프로그램-shell-script)

## 체크리스트
- [ ] mula_install.sh 작성
- [ ] 배포판별 패키지 관리자 지원
- [ ] Ubuntu 테스트
- [ ] Fedora 테스트
- [ ] Arch 테스트
- [ ] Desktop Entry 생성
- [ ] uninstall.sh 작성
" \
  --milestone="Phase 1: 설치 프로그램 개발 (W1-2)" \
  --label="type: feature,platform: linux,area: installer,priority: critical" || true

echo "✅ Phase 1 이슈 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 4. Phase 2 이슈들 생성
#═══════════════════════════════════════════════════════════

echo "📝 Phase 2 이슈 생성 중..."

# 홈페이지
gh issue create \
  --repo="$REPO" \
  --title="[Phase 2] 홈페이지 개발 (index.html)" \
  --body="## 작업 설명
music.abada.kr 홈페이지 개발

## 요구사항
- React 기반 구현
- Hero 섹션 (메인 메시지)
- Features 섹션 (3가지 특징)
- Download 섹션 (OS별 다운로드 버튼)
- Gallery Preview (샘플 곡 미리보기)
- System Requirements
- 모바일 반응형 디자인 (Tailwind CSS)

## 산출물
- public/index.html
- src/components/Hero.jsx
- src/components/Features.jsx
- src/components/DownloadSection.jsx

## 체크리스트
- [ ] React 프로젝트 초기화
- [ ] Tailwind CSS 설정
- [ ] 홈페이지 레이아웃 구현
- [ ] 스타일링 완성
- [ ] 반응형 테스트 (모바일)
- [ ] SEO 메타 태그 추가
" \
  --milestone="Phase 2: 웹사이트 개발 (W3-4)" \
  --label="type: feature,area: website,priority: critical" || true

# 다운로드 페이지
gh issue create \
  --repo="$REPO" \
  --title="[Phase 2] 다운로드 페이지 개발 (download.html)" \
  --body="## 작업 설명
OS별 다운로드 페이지 개발

## 요구사항
- Windows x64/x86 다운로드 버튼
- macOS 다운로드 버튼
- Linux 다운로드 버튼
- 파일 크기 표시
- 시스템 요구사항 안내
- 설치 방법 간단 설명

## 산출물
- public/download.html
- src/components/DownloadButtons.jsx
- src/js/download.js (통계)

## 체크리스트
- [ ] GitHub Releases 링크 연결
- [ ] 다운로드 통계 기록
- [ ] 파일 크기 정보 표시
- [ ] 클릭 이벤트 추적
" \
  --milestone="Phase 2: 웹사이트 개발 (W3-4)" \
  --label="type: feature,area: website,priority: high" || true

# 갤러리 페이지
gh issue create \
  --repo="$REPO" \
  --title="[Phase 2] 갤러리 페이지 개발 (gallery.html)" \
  --body="## 작업 설명
사용자 생성 음악 샘플 갤러리 페이지

## 요구사항
- 샘플 곡 그리드 표시
- 오디오 플레이어 (HTML5)
- 필터링 기능 (태그별)
- 메타정보 표시 (제목, 가사, 태그)
- 동적 데이터 로드

## 산출물
- public/gallery.html
- src/components/Gallery.jsx
- src/js/gallery.js
- public/data/gallery.json

## 체크리스트
- [ ] 샘플 곡 5-10개 준비
- [ ] 갤러리 컴포넌트 구현
- [ ] 오디오 플레이어 통합
- [ ] 필터링 기능 구현
- [ ] 데이터 로드 테스트
" \
  --milestone="Phase 2: 웹사이트 개발 (W3-4)" \
  --label="type: feature,area: website,priority: high" || true

# Cloudflare Pages 배포
gh issue create \
  --repo="$REPO" \
  --title="[Phase 2] Cloudflare Pages 배포 설정" \
  --body="## 작업 설명
music.abada.kr을 Cloudflare Pages에 배포

## 요구사항
- Cloudflare Pages 프로젝트 생성
- GitHub 저장소 연동
- 자동 빌드 설정
- DNS CNAME 레코드 설정
- SSL/TLS 인증서 (자동)

## 산출물
- music.abada.kr 라이브 URL
- GitHub Actions 통합

## 체크리스트
- [ ] Cloudflare 계정 설정
- [ ] Pages 프로젝트 생성
- [ ] GitHub 연동
- [ ] 빌드 명령어 설정
- [ ] DNS 레코드 추가
- [ ] 도메인 연결 확인
- [ ] SSL 인증서 설정
" \
  --milestone="Phase 2: 웹사이트 개발 (W3-4)" \
  --label="type: feature,area: ci-cd,priority: critical" || true

echo "✅ Phase 2 이슈 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 5. Phase 3 이슈들 생성
#═══════════════════════════════════════════════════════════

echo "📝 Phase 3 이슈 생성 중..."

# 통합 테스트
gh issue create \
  --repo="$REPO" \
  --title="[Phase 3] 엔드투엔드 통합 테스트" \
  --body="## 작업 설명
모든 플랫폼에서 설치부터 실행까지 테스트

## 테스트 항목

### Windows
- [ ] Windows 10/11 x64 설치
- [ ] Windows 10/11 x86 설치
- [ ] GPU 감지 확인 (NVIDIA)
- [ ] 음악 생성 테스트 (GPU/CPU)
- [ ] 제거 프로그램 테스트

### macOS
- [ ] Intel Mac 설치
- [ ] Apple Silicon 설치
- [ ] Homebrew 설치 시뮬레이션
- [ ] 음악 생성 테스트
- [ ] MPS 가속 확인

### Linux
- [ ] Ubuntu 20.04 설치
- [ ] Ubuntu 22.04 설치
- [ ] Fedora 설치
- [ ] 음악 생성 테스트
- [ ] Desktop Entry 작동 확인

## 체크리스트
- [ ] 클린 설치 테스트 (모든 OS)
- [ ] 음악 생성 성공 (모든 OS)
- [ ] 출력 파일 저장 확인
- [ ] 에러 로그 검토
" \
  --milestone="Phase 3: 통합 & 테스트 (W5-6)" \
  --label="type: feature,priority: critical" || true

# 성능 테스트
gh issue create \
  --repo="$REPO" \
  --title="[Phase 3] 성능 테스트 및 최적화" \
  --body="## 작업 설명
설치 시간, 생성 시간 등 성능 측정

## 측정 항목
- 설치 소요 시간 (모든 OS)
- 모델 로드 시간
- 음악 생성 시간 (GPU/CPU)
- 메모리 사용량
- 디스크 사용량

## 목표
- 설치: 15-30분 (네트워크 속도에 따라)
- GPU 생성: 2-5분 (120초 음악 기준)
- CPU 생성: 30분+ (정상)

## 체크리스트
- [ ] 성능 프로파일링
- [ ] 병목 지점 분석
- [ ] 최적화 적용
- [ ] 성능 개선 측정
" \
  --milestone="Phase 3: 통합 & 테스트 (W5-6)" \
  --label="type: chore,priority: medium" || true

echo "✅ Phase 3 이슈 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 6. Phase 4 이슈들 생성
#═══════════════════════════════════════════════════════════

echo "📝 Phase 4 이슈 생성 중..."

# GitHub Releases
gh issue create \
  --repo="$REPO" \
  --title="[Phase 4] GitHub Releases v1.0.0 배포" \
  --body="## 작업 설명
공식 v1.0.0 릴리즈 생성

## 산출물
- MuLa_Setup_x64.exe
- MuLa_Setup_x86.exe
- MuLa_Installer.dmg
- mula_install.sh
- checksums.txt
- 설치 가이드

## 체크리스트
- [ ] 모든 파일 수집
- [ ] SHA256 체크섬 생성
- [ ] 릴리즈 노트 작성
- [ ] GitHub Releases 생성
- [ ] 다운로드 링크 확인
- [ ] VirusTotal 스캔 (exe/dmg)
" \
  --milestone="Phase 4: 런칭 & 홍보 (W7-8)" \
  --label="type: feature,area: ci-cd,priority: critical" || true

# SNS 홍보
gh issue create \
  --repo="$REPO" \
  --title="[Phase 4] SNS 홍보 & 커뮤니티 확산" \
  --body="## 작업 설명
공식 출시 공지 및 멀티채널 홍보

## 홍보 채널

### SNS (동시 공지)
- [ ] Twitter/X 포스팅
- [ ] LinkedIn 포스팅
- [ ] Facebook 포스팅

### 커뮤니티
- [ ] Reddit r/MachineLearning
- [ ] Reddit r/OpenSource
- [ ] HackerNews \"Show HN\"
- [ ] Product Hunt

### 기술 커뮤니티
- [ ] GitHub Trending 확인
- [ ] Awesome Lists 등록
- [ ] Hugging Face 링크

## 체크리스트
- [ ] 포스팅 템플릿 작성
- [ ] 스크린샷/GIF 준비
- [ ] 홍보 자료 제작
- [ ] 동시 포스팅 실행
- [ ] 댓글 모니터링
" \
  --milestone="Phase 4: 런칭 & 홍보 (W7-8)" \
  --label="type: feature,area: marketing,priority: high" || true

# ABADA 브랜드 통합
gh issue create \
  --repo="$REPO" \
  --title="[Phase 4] ABADA 브랜드 통합 & 링크 설정" \
  --body="## 작업 설명
ABADA 회사 홍보 극대화

## 작업 항목
- [ ] music.abada.kr 배너 추가 (ABADA 소개)
- [ ] Footer에 ABADA 링크 추가
- [ ] /about.html 작성 (ABADA 회사 소개)
- [ ] pamout.co.kr 양방향 링크 설정
- [ ] GitHub 이슈 ABADA 라벨링

## 링크 구조

```
music.abada.kr
├── home: ABADA 로고 + 링크
├── footer: ABADA Inc. © 2026
├── about: ABADA 회사 소개
│   └── 다른 서비스 (Pamout 링크)
└── Services 섹션
    ├── ABADA Music Studio (현재)
    └── Pamout (pamout.co.kr 링크)

pamout.co.kr (역방향)
├── footer: Music Studio 링크
└── Services: ABADA Music Studio 소개
```

## 체크리스트
- [ ] 배너 디자인 & 구현
- [ ] About 페이지 작성
- [ ] pamout 팀과 조율
- [ ] 양방향 링크 설정
" \
  --milestone="Phase 4: 런칭 & 홍보 (W7-8)" \
  --label="type: feature,area: marketing,priority: high" || true

echo "✅ Phase 4 이슈 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 7. CI/CD 이슈들
#═══════════════════════════════════════════════════════════

echo "📝 CI/CD 이슈 생성 중..."

# GitHub Actions 워크플로우
gh issue create \
  --repo="$REPO" \
  --title="[CI/CD] GitHub Actions 워크플로우 설정" \
  --body="## 작업 설명
자동 빌드 및 배포 파이프라인 구축

## 워크플로우 파일

### .github/workflows/build.yml
- Windows x64/x86 NSIS 빌드
- macOS DMG 빌드
- Linux sh 빌드
- 체크섬 생성
- GitHub Releases 자동 생성

### .github/workflows/deploy-pages.yml
- 웹사이트 자동 빌드
- Cloudflare Pages 배포

## 체크리스트
- [ ] build.yml 작성
- [ ] deploy-pages.yml 작성
- [ ] Secrets 설정 (API Token)
- [ ] 로컬 테스트
- [ ] 태그 기반 트리거 확인
" \
  --milestone="Phase 2: 웹사이트 개발 (W3-4)" \
  --label="type: feature,area: ci-cd,priority: critical" || true

# Git Hooks
gh issue create \
  --repo="$REPO" \
  --title="[CI/CD] Git Hooks 설정 (pre-commit, post-commit)" \
  --body="## 작업 설명
로컬 코드 품질 자동 검사

## Hooks 구현

### pre-commit
- [ ] 파일 크기 검사 (100MB 제한)
- [ ] 민감한 정보 검사 (API 키)
- [ ] NSIS 문법 검사
- [ ] Shell 문법 검사
- [ ] Markdown 린트

### post-commit
- [ ] 버전 자동 업데이트
- [ ] 커밋 메시지 보강

## 체크리스트
- [ ] pre-commit 스크립트 작성
- [ ] post-commit 스크립트 작성
- [ ] 로컬 테스트
- [ ] 팀 문서화
" \
  --milestone="Phase 1: 설치 프로그램 개발 (W1-2)" \
  --label="type: chore,area: ci-cd,priority: medium" || true

echo "✅ CI/CD 이슈 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 8. 문서 이슈들
#═══════════════════════════════════════════════════════════

echo "📝 문서 이슈 생성 중..."

# 설치 가이드
gh issue create \
  --repo="$REPO" \
  --title="[Docs] 설치 가이드 작성" \
  --body="## 작업 설명
각 OS별 설치 방법 문서 작성

## 포함 내용
- Windows 설치 (x64/x86)
- macOS 설치 (Intel/Apple Silicon)
- Linux 설치 (Ubuntu/Fedora/Arch)
- 시스템 요구사항
- 트러블슈팅

## 산출물
- docs/INSTALLATION.md
- 스크린샷 이미지

## 체크리스트
- [ ] 기본 가이드 작성
- [ ] 스크린샷 추가
- [ ] 트러블슈팅 섹션
- [ ] 영문 번역
" \
  --milestone="Phase 2: 웹사이트 개발 (W3-4)" \
  --label="type: docs,priority: high" || true

# API 문서
gh issue create \
  --repo="$REPO" \
  --title="[Docs] API 문서 작성 (Cloudflare Workers)" \
  --body="## 작업 설명
Cloudflare Workers API 문서화

## 포함 내용
- 다운로드 통계 API
- 갤러리 API
- 분석 API

## 산출물
- docs/API.md
- API 예제 코드

## 체크리스트
- [ ] 엔드포인트 문서화
- [ ] 요청/응답 예제
- [ ] 에러 처리
- [ ] 레이트 리미팅
" \
  --milestone="Phase 3: 통합 & 테스트 (W5-6)" \
  --label="type: docs,priority: medium" || true

echo "✅ 문서 이슈 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 완료
#═══════════════════════════════════════════════════════════

echo "🎉 모든 이슈 생성이 완료되었습니다!"
echo ""
echo "📊 통계:"
ISSUE_COUNT=$(gh issue list --repo="$REPO" --state=all --json=number | jq length)
echo "  총 이슈 개수: $ISSUE_COUNT개"
echo ""
echo "🔗 GitHub Issues 보기:"
echo "  https://github.com/$REPO/issues"
echo ""
echo "✅ 다음 단계:"
echo "  1. GitHub Issues 탭 확인"
echo "  2. 마일스톤별 이슈 분류 확인"
echo "  3. Phase 1부터 시작하기"
echo ""
