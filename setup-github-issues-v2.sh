#!/bin/bash

# GitHub Issues 자동 설정 (v2 - 수정 버전)
set -e

REPO="saintgo7/web-music-heartlib"
echo "🔧 GitHub Issues 설정 시작 ($REPO)"
echo ""

#═══════════════════════════════════════════════════════════
# 1. 라벨 생성
#═══════════════════════════════════════════════════════════

echo "🏷️  라벨 생성 중..."

# 우선순위
gh label create "priority: critical" -c "ff0000" -d "긴급 처리 필요" 2>/dev/null || true
gh label create "priority: high" -c "ff6600" -d "높은 우선순위" 2>/dev/null || true
gh label create "priority: medium" -c "ffcc00" -d "중간 우선순위" 2>/dev/null || true
gh label create "priority: low" -c "00cc00" -d "낮은 우선순위" 2>/dev/null || true

# 작업 타입
gh label create "type: feature" -c "0099ff" -d "새로운 기능" 2>/dev/null || true
gh label create "type: bug" -c "ff0000" -d "버그 수정" 2>/dev/null || true
gh label create "type: docs" -c "9966ff" -d "문서 작업" 2>/dev/null || true
gh label create "type: chore" -c "cccccc" -d "유지보수" 2>/dev/null || true

# 상태
gh label create "status: in-progress" -c "0099ff" -d "진행 중" 2>/dev/null || true
gh label create "status: blocked" -c "ff0000" -d "차단됨" 2>/dev/null || true
gh label create "status: review" -c "ffcc00" -d "검토 필요" 2>/dev/null || true

# 플랫폼
gh label create "platform: windows" -c "0078d4" -d "Windows" 2>/dev/null || true
gh label create "platform: macos" -c "999999" -d "macOS" 2>/dev/null || true
gh label create "platform: linux" -c "ff9900" -d "Linux" 2>/dev/null || true

# 영역
gh label create "area: installer" -c "ff00ff" -d "설치 프로그램" 2>/dev/null || true
gh label create "area: website" -c "00ff00" -d "웹사이트" 2>/dev/null || true
gh label create "area: ci-cd" -c "00cccc" -d "CI/CD & 배포" 2>/dev/null || true
gh label create "area: marketing" -c "ff66ff" -d "홍보 & 마케팅" 2>/dev/null || true

echo "✅ 라벨 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 2. Phase 1 이슈들 생성
#═══════════════════════════════════════════════════════════

echo "📝 Phase 1 이슈 생성 중..."

# Windows x64
gh issue create \
  --title="[Phase 1-W1] Windows x64 설치 프로그램 (NSIS)" \
  --body="## 작업 설명
Windows 64비트용 NSIS 설치 프로그램 개발

## 요구사항
- Python 3.10 embedded 통합
- GPU 자동 감지 (NVIDIA CUDA)
- PyTorch + 의존성 자동 설치
- 모델 다운로드 (6GB) 통합
- 바로가기 생성
- 제거 프로그램 지원

## 산출물
- MuLa_Setup_x64.exe (~80MB)

## 체크리스트
- [ ] NSIS 스크립트 작성
- [ ] Python embed 통합
- [ ] GPU 감지 로직
- [ ] 모델 다운로드
- [ ] 로컬 테스트
- [ ] 클린 설치 테스트
- [ ] 제거 기능 테스트

## 참고
- [DEV.md - Windows 설치](./docs/DEV.md#32-windows-설치-프로그램-nsis)
- [NSIS Docs](https://nsis.sourceforge.io/Docs)
" \
  --label="type: feature,platform: windows,area: installer,priority: critical" 2>/dev/null || true

# Windows x86
gh issue create \
  --title="[Phase 1-W1] Windows x86 설치 프로그램 (NSIS)" \
  --body="## 작업 설명
Windows 32비트용 NSIS 설치 프로그램 개발

## 요구사항
- Python 3.10 embedded (32비트) 통합
- CPU 모드 전용 (CUDA 미지원)
- 성능 경고 메시지 표시

## 산출물
- MuLa_Setup_x86.exe (~80MB)

## 체크리스트
- [ ] 32비트 Python embed 준비
- [ ] NSIS 스크립트 작성
- [ ] CPU 설정 구현
- [ ] 32비트 환경 테스트

## 참고
- [DEV.md - Windows x86](./docs/DEV.md#323-windows-x86-32비트-차이점)
" \
  --label="type: feature,platform: windows,area: installer,priority: high" 2>/dev/null || true

# macOS
gh issue create \
  --title="[Phase 1-W2] macOS 설치 프로그램 (DMG + Shell)" \
  --body="## 작업 설명
macOS용 자동 설치 스크립트 및 DMG 패키지 개발

## 요구사항
- Intel Mac 지원 (CPU 모드)
- Apple Silicon (M1/M2) 지원 (MPS 가속)
- Homebrew 자동 설치
- Python 3.10 가상환경
- DMG 패키지 생성

## 산출물
- MuLa_Installer.dmg (~50MB)
- install.sh
- run.command

## 체크리스트
- [ ] install.sh 작성
- [ ] Homebrew 통합
- [ ] Intel/ARM 자동 감지
- [ ] DMG 생성 자동화
- [ ] Intel Mac 테스트
- [ ] Apple Silicon 테스트

## 참고
- [DEV.md - macOS](./docs/DEV.md#33-macos-설치-프로그램-dmg)
" \
  --label="type: feature,platform: macos,area: installer,priority: critical" 2>/dev/null || true

# Linux
gh issue create \
  --title="[Phase 1-W2] Linux 설치 프로그램 (Shell Script)" \
  --body="## 작업 설명
Linux용 자동 설치 쉘 스크립트 개발

## 요구사항
- Ubuntu 20.04+ 지원
- Fedora 지원
- Arch Linux 지원
- Desktop Entry 생성
- PATH 설정

## 산출물
- mula_install.sh (~5KB)
- uninstall.sh

## 체크리스트
- [ ] install.sh 작성
- [ ] 배포판별 지원
- [ ] Ubuntu 테스트
- [ ] Fedora 테스트
- [ ] Arch 테스트
- [ ] Desktop Entry
- [ ] uninstall.sh

## 참고
- [DEV.md - Linux](./docs/DEV.md#34-linux-설치-프로그램-shell-script)
" \
  --label="type: feature,platform: linux,area: installer,priority: critical" 2>/dev/null || true

echo "✅ Phase 1 이슈 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 3. Phase 2 이슈들 생성
#═══════════════════════════════════════════════════════════

echo "📝 Phase 2 이슈 생성 중..."

# 홈페이지
gh issue create \
  --title="[Phase 2-W3] 홈페이지 개발 (index.html)" \
  --body="## 작업 설명
music.abada.kr 홈페이지 개발

## 요구사항
- React 기반
- Hero 섹션 (메인 메시지)
- Features 섹션
- Download 섹션
- Gallery Preview
- System Requirements
- 모바일 반응형 (Tailwind)

## 산출물
- public/index.html
- src/components/Hero.jsx
- src/components/Features.jsx

## 체크리스트
- [ ] React 프로젝트 초기화
- [ ] Tailwind CSS 설정
- [ ] 레이아웃 구현
- [ ] 스타일링
- [ ] 반응형 테스트
- [ ] SEO 메타 태그
" \
  --label="type: feature,area: website,priority: critical" 2>/dev/null || true

# 다운로드 페이지
gh issue create \
  --title="[Phase 2-W3] 다운로드 페이지 (download.html)" \
  --body="## 작업 설명
OS별 다운로드 페이지 개발

## 요구사항
- Windows x64/x86 버튼
- macOS 버튼
- Linux 버튼
- 파일 크기 표시
- 설치 방법 안내

## 산출물
- public/download.html
- src/js/download.js

## 체크리스트
- [ ] GitHub Releases 링크
- [ ] 다운로드 통계
- [ ] 클릭 이벤트 추적
" \
  --label="type: feature,area: website,priority: high" 2>/dev/null || true

# 갤러리
gh issue create \
  --title="[Phase 2-W3] 갤러리 페이지 (gallery.html)" \
  --body="## 작업 설명
사용자 생성 음악 샘플 갤러리

## 요구사항
- 샘플 곡 그리드
- 오디오 플레이어 (HTML5)
- 필터링 (태그별)
- 메타정보 표시

## 산출물
- public/gallery.html
- src/components/Gallery.jsx
- public/data/gallery.json

## 체크리스트
- [ ] 샘플 곡 5-10개 준비
- [ ] Gallery 컴포넌트
- [ ] 오디오 플레이어
- [ ] 필터링 기능
" \
  --label="type: feature,area: website,priority: high" 2>/dev/null || true

# Cloudflare Pages
gh issue create \
  --title="[Phase 2-W4] Cloudflare Pages 배포 설정" \
  --body="## 작업 설명
music.abada.kr을 Cloudflare Pages에 배포

## 요구사항
- Cloudflare Pages 프로젝트 생성
- GitHub 저장소 연동
- 자동 빌드 설정
- DNS CNAME 레코드
- SSL/TLS 인증서

## 산출물
- music.abada.kr 라이브

## 체크리스트
- [ ] Cloudflare 계정 설정
- [ ] Pages 프로젝트 생성
- [ ] GitHub 연동
- [ ] 빌드 명령어 설정
- [ ] DNS 레코드 추가
- [ ] 도메인 연결 확인
- [ ] SSL 설정
" \
  --label="type: feature,area: ci-cd,priority: critical" 2>/dev/null || true

echo "✅ Phase 2 이슈 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 4. Phase 3 이슈들 생성
#═══════════════════════════════════════════════════════════

echo "📝 Phase 3 이슈 생성 중..."

# 통합 테스트
gh issue create \
  --title="[Phase 3-W5] 엔드투엔드 통합 테스트" \
  --body="## 작업 설명
모든 플랫폼에서 설치부터 실행까지 테스트

## 테스트 항목

### Windows
- [ ] Windows 10/11 x64 설치
- [ ] Windows 10/11 x86 설치
- [ ] 음악 생성 테스트 (GPU/CPU)
- [ ] 제거 테스트

### macOS
- [ ] Intel Mac 설치
- [ ] Apple Silicon 설치
- [ ] 음악 생성 테스트

### Linux
- [ ] Ubuntu 설치
- [ ] Fedora 설치
- [ ] 음악 생성 테스트

## 체크리스트
- [ ] 클린 설치 (모든 OS)
- [ ] 음악 생성 성공
- [ ] 출력 파일 저장 확인
- [ ] 에러 로그 검토
" \
  --label="type: feature,priority: critical" 2>/dev/null || true

# 성능 최적화
gh issue create \
  --title="[Phase 3-W5] 성능 테스트 및 최적화" \
  --body="## 작업 설명
설치 시간, 생성 시간 등 성능 측정

## 측정 항목
- 설치 소요 시간
- 모델 로드 시간
- 음악 생성 시간 (GPU/CPU)
- 메모리 사용량

## 목표
- 설치: 15-30분
- GPU 생성: 2-5분
- CPU 생성: 30분+

## 체크리스트
- [ ] 성능 프로파일링
- [ ] 병목 지점 분석
- [ ] 최적화 적용
- [ ] 개선 측정
" \
  --label="type: chore,priority: medium" 2>/dev/null || true

echo "✅ Phase 3 이슈 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 5. Phase 4 이슈들 생성
#═══════════════════════════════════════════════════════════

echo "📝 Phase 4 이슈 생성 중..."

# 공식 릴리즈
gh issue create \
  --title="[Phase 4-W7] GitHub Releases v1.0.0 배포" \
  --body="## 작업 설명
공식 v1.0.0 릴리즈 생성

## 산출물
- MuLa_Setup_x64.exe
- MuLa_Setup_x86.exe
- MuLa_Installer.dmg
- mula_install.sh
- checksums.txt

## 체크리스트
- [ ] 모든 파일 수집
- [ ] SHA256 체크섬 생성
- [ ] 릴리즈 노트 작성
- [ ] GitHub Releases 생성
- [ ] 링크 확인
- [ ] VirusTotal 스캔
" \
  --label="type: feature,area: ci-cd,priority: critical" 2>/dev/null || true

# SNS 홍보
gh issue create \
  --title="[Phase 4-W7] SNS 홍보 & 커뮤니티 확산" \
  --body="## 작업 설명
공식 출시 공지 및 멀티채널 홍보

## 홍보 채널
- [ ] Twitter/X
- [ ] LinkedIn
- [ ] Facebook
- [ ] Reddit r/MachineLearning
- [ ] HackerNews \"Show HN\"
- [ ] Product Hunt
- [ ] GitHub Trending

## 체크리스트
- [ ] 포스팅 템플릿
- [ ] 스크린샷/GIF 준비
- [ ] 동시 포스팅
- [ ] 댓글 모니터링
" \
  --label="type: feature,area: marketing,priority: high" 2>/dev/null || true

# ABADA 브랜드 통합
gh issue create \
  --title="[Phase 4-W7] ABADA 브랜드 통합" \
  --body="## 작업 설명
ABADA 회사 홍보 극대화

## 작업 항목
- [ ] music.abada.kr 배너 추가
- [ ] About ABADA 페이지 작성
- [ ] Footer ABADA 링크 추가
- [ ] pamout.co.kr 양방향 링크

## 링크 구조
- music.abada.kr → ABADA 소개
- pamout.co.kr → Music Studio 링크 (역방향)

## 체크리스트
- [ ] 배너 디자인
- [ ] About 페이지
- [ ] pamout 팀 조율
- [ ] 양방향 링크
" \
  --label="type: feature,area: marketing,priority: high" 2>/dev/null || true

echo "✅ Phase 4 이슈 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 6. CI/CD 이슈들
#═══════════════════════════════════════════════════════════

echo "📝 CI/CD 이슈 생성 중..."

# GitHub Actions
gh issue create \
  --title="[CI/CD] GitHub Actions 워크플로우 설정" \
  --body="## 작업 설명
자동 빌드 및 배포 파이프라인

## 파일
- .github/workflows/build.yml (설치파일 빌드)
- .github/workflows/deploy-pages.yml (웹사이트 배포)

## 포함 내용
- Windows x64/x86 빌드
- macOS DMG 빌드
- Linux sh 빌드
- 체크섬 생성
- GitHub Releases 생성
- Cloudflare Pages 배포

## 체크리스트
- [ ] build.yml 작성
- [ ] deploy-pages.yml 작성
- [ ] Secrets 설정
- [ ] 로컬 테스트
- [ ] 태그 트리거 확인
" \
  --label="type: feature,area: ci-cd,priority: critical" 2>/dev/null || true

# Git Hooks
gh issue create \
  --title="[CI/CD] Git Hooks 설정" \
  --body="## 작업 설명
로컬 코드 품질 자동 검사

## Hooks
- pre-commit: 파일 검사, 문법 검사
- post-commit: 버전 업데이트

## 체크리스트
- [ ] pre-commit 스크립트
- [ ] post-commit 스크립트
- [ ] 로컬 테스트
- [ ] 팀 문서화
" \
  --label="type: chore,area: ci-cd,priority: medium" 2>/dev/null || true

echo "✅ CI/CD 이슈 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 7. 문서 이슈들
#═══════════════════════════════════════════════════════════

echo "📝 문서 이슈 생성 중..."

# 설치 가이드
gh issue create \
  --title="[Docs] 설치 가이드 작성" \
  --body="## 작업 설명
각 OS별 설치 방법 문서

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
- [ ] 기본 가이드
- [ ] 스크린샷
- [ ] 트러블슈팅
- [ ] 영문 번역
" \
  --label="type: docs,priority: high" 2>/dev/null || true

# API 문서
gh issue create \
  --title="[Docs] API 문서 작성 (Cloudflare Workers)" \
  --body="## 작업 설명
Cloudflare Workers API 문서

## 포함 내용
- 다운로드 통계 API
- 갤러리 API
- 분석 API

## 산출물
- docs/API.md
- 예제 코드

## 체크리스트
- [ ] 엔드포인트 문서
- [ ] 요청/응답 예제
- [ ] 에러 처리
- [ ] 레이트 리미팅
" \
  --label="type: docs,priority: medium" 2>/dev/null || true

echo "✅ 문서 이슈 생성 완료"
echo ""

#═══════════════════════════════════════════════════════════
# 완료
#═══════════════════════════════════════════════════════════

echo "🎉 모든 이슈 생성이 완료되었습니다!"
echo ""
echo "🔗 GitHub Issues 보기:"
echo "  https://github.com/$REPO/issues"
echo ""
echo "✅ 다음 단계:"
echo "  1. GitHub Issues 탭 확인"
echo "  2. 이슈별 체크리스트 작성"
echo "  3. Phase 1부터 시작"
echo ""
