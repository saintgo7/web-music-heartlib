# ABADA Music Studio - E2E 테스트 시나리오

**버전**: v0.3.0
**작성일**: 2026-01-19
**테스트 도구**: Playwright, Cypress, Manual Testing
**타겟 환경**: Windows, macOS, Linux, Web

---

## 목차

1. [Windows 설치 플로우](#windows-설치-플로우)
2. [macOS 설치 플로우](#macos-설치-플로우)
3. [Linux 설치 플로우](#linux-설치-플로우)
4. [웹사이트 테스트](#웹사이트-테스트)
5. [API 테스트](#api-테스트)
6. [통합 시나리오](#통합-시나리오)

---

## Windows 설치 플로우

### TC-WIN-001: GPU 감지 및 CUDA 설치 (정상 경로)

**전제 조건**:
- Windows 10/11 (64-bit)
- NVIDIA GPU 장착 (GTX 1060 이상)
- nvidia-smi 실행 가능

**테스트 단계**:

1. **설치 프로그램 실행**
   ```powershell
   # 다운로드 경로에서 실행
   .\MuLaInstaller_x64.exe
   ```
   - [ ] UAC 프롬프트 표시
   - [ ] 관리자 권한 승인 요청

2. **GPU 감지 확인**
   ```nsis
   # NSIS 스크립트 내부 로직
   ExecWait "nvidia-smi --query-gpu=name --format=csv,noheader"
   ```
   - [ ] nvidia-smi 명령 실행 성공
   - [ ] GPU 모델명 파싱 (예: "NVIDIA GeForce RTX 3060")
   - [ ] 로그 파일 기록: `C:\Program Files\ABADA\MuLa\install.log`

3. **Python 3.10 임베딩 설치**
   ```
   C:\Program Files\ABADA\MuLa\python\
   ├── python.exe
   ├── python310.dll
   ├── DLLs/
   ├── Lib/
   └── Scripts/
   ```
   - [ ] 임베딩 파일 압축 해제 (약 50MB)
   - [ ] python.exe 실행 가능 확인
   - [ ] 버전 확인: `python.exe --version` → `Python 3.10.x`

4. **PyTorch CUDA 버전 설치**
   ```batch
   python.exe -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
   ```
   - [ ] pip 설치 시작 (진행률 표시)
   - [ ] torch 2.x.x+cu118 다운로드
   - [ ] 설치 완료 확인 (약 2GB)
   - [ ] CUDA 사용 가능 검증:
     ```python
     import torch
     print(torch.cuda.is_available())  # True
     print(torch.cuda.device_count())  # 1 이상
     ```

5. **HuggingFace 모델 다운로드**
   ```batch
   python.exe download_models.py
   ```
   - [ ] HeartMuLa-oss-3B 다운로드 시작
   - [ ] 진행률 표시 (0% → 100%)
   - [ ] 체크섬 검증
   - [ ] 저장 경로: `C:\Users\{USER}\.cache\huggingface\hub\`
   - [ ] 총 용량: 약 6GB

6. **바로가기 생성**
   - [ ] 데스크톱 바로가기: `C:\Users\{USER}\Desktop\ABADA MuLa.lnk`
   - [ ] 시작 메뉴: `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\ABADA\MuLa.lnk`
   - [ ] 아이콘 검증: `icon.ico` 표시

7. **애플리케이션 실행**
   ```powershell
   & "C:\Program Files\ABADA\MuLa\MuLa.exe"
   ```
   - [ ] GUI 윈도우 표시 (1024x768)
   - [ ] CUDA 디바이스 인식: "Using GPU: NVIDIA GeForce RTX 3060"
   - [ ] 모델 로드 성공 (약 10초)

**예상 결과**:
- 총 설치 시간: 5-10분 (인터넷 속도 의존)
- 디스크 사용: 약 12GB
- 설치 성공 메시지 표시

**실패 시 롤백**:
- [ ] 임시 파일 삭제
- [ ] 레지스트리 항목 제거
- [ ] 에러 로그 저장: `%TEMP%\mula_install_error.log`

---

### TC-WIN-002: CPU-Only 환경 (GPU 없음)

**전제 조건**:
- Windows 10/11 (64-bit)
- NVIDIA GPU 없음 또는 nvidia-smi 실패

**테스트 단계**:

1. **GPU 감지 실패 처리**
   ```nsis
   ExecWait "nvidia-smi" $0
   ${If} $0 != 0
     MessageBox MB_ICONINFORMATION "GPU가 감지되지 않았습니다. CPU 버전으로 설치합니다."
   ${EndIf}
   ```
   - [ ] nvidia-smi 명령 실패 감지 (Exit Code != 0)
   - [ ] 사용자 알림 메시지 박스 표시
   - [ ] CPU 설치 모드로 전환

2. **PyTorch CPU 버전 설치**
   ```batch
   python.exe -m pip install torch torchvision torchaudio
   ```
   - [ ] CPU 전용 torch 설치 (약 800MB)
   - [ ] CUDA 의존성 없음 확인

3. **성능 경고**
   ```
   [경고] CPU 모드로 실행됩니다.
   음악 생성 시간이 GPU 대비 5-10배 느릴 수 있습니다.
   권장: NVIDIA GPU (GTX 1060 이상)
   ```
   - [ ] 경고 메시지 표시
   - [ ] 설치 계속 진행 가능

**예상 결과**:
- 설치 성공
- 애플리케이션 실행 시 "Using CPU" 표시
- 음악 생성 테스트 (1분 음악 → 약 5-10분 소요)

---

### TC-WIN-003: 언인스톨 테스트

**테스트 단계**:

1. **제어판에서 제거**
   ```
   제어판 → 프로그램 추가/제거 → ABADA MuLa
   ```
   - [ ] 프로그램 목록에 표시
   - [ ] 언인스톨 버튼 클릭

2. **파일 삭제 확인**
   - [ ] `C:\Program Files\ABADA\MuLa\` 폴더 삭제
   - [ ] 바로가기 삭제 (Desktop, Start Menu)
   - [ ] 사용자 데이터 보존 옵션:
     ```
     [체크박스] 생성된 음악 파일 유지 (C:\Users\{USER}\MuLa\outputs\)
     ```

3. **레지스트리 정리**
   - [ ] `HKLM\SOFTWARE\ABADA\MuLa` 제거
   - [ ] 언인스톨 항목 제거

**예상 결과**:
- 완전한 제거 (약 12GB 디스크 공간 복구)
- 사용자 선택 시 생성된 음악 보존

---

### TC-WIN-004: 업그레이드 시나리오

**전제 조건**:
- 기존 v1.0.0 설치됨

**테스트 단계**:

1. **기존 버전 감지**
   ```nsis
   ReadRegStr $0 HKLM "SOFTWARE\ABADA\MuLa" "Version"
   ${If} $0 != ""
     MessageBox MB_YESNO "기존 버전 $0이 설치되어 있습니다. 업그레이드하시겠습니까?" IDYES upgrade IDNO cancel
   ${EndIf}
   ```
   - [ ] 레지스트리에서 기존 버전 읽기
   - [ ] 업그레이드 확인 대화상자

2. **데이터 백업**
   - [ ] 설정 파일 백업: `config.json`
   - [ ] 사용자 모델 백업 (커스텀 파인튜닝 있을 경우)

3. **In-place 업그레이드**
   - [ ] 기존 바이너리 덮어쓰기
   - [ ] Python 패키지 업데이트
   - [ ] 모델 재다운로드 (필요 시)

4. **설정 복원**
   - [ ] `config.json` 마이그레이션
   - [ ] 사용자 데이터 유지

**예상 결과**:
- 다운타임 최소화 (5분 이내)
- 기존 설정 및 데이터 보존

---

## macOS 설치 플로우

### TC-MAC-001: Apple Silicon (M1/M2) 설치

**전제 조건**:
- macOS Sonoma 14.x
- Apple Silicon (M1/M2/M3)
- 관리자 권한

**테스트 단계**:

1. **DMG 마운트**
   ```bash
   hdiutil attach MuLa-v1.0.0-macos-arm64.dmg
   ```
   - [ ] DMG 파일 더블 클릭
   - [ ] 볼륨 마운트: `/Volumes/ABADA MuLa/`
   - [ ] Finder 윈도우 표시

2. **애플리케이션 드래그 앤 드롭**
   ```
   MuLa.app → /Applications/
   ```
   - [ ] 드래그 앤 드롭 UI 표시
   - [ ] 복사 진행 (약 200MB)
   - [ ] 복사 완료 확인

3. **Homebrew 의존성 설치**
   ```bash
   # 설치 스크립트 실행
   /Applications/MuLa.app/Contents/Resources/install.sh
   ```
   - [ ] Homebrew 설치 여부 확인
     ```bash
     which brew
     ```
   - [ ] 없으면 Homebrew 설치 프롬프트:
     ```bash
     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
     ```
   - [ ] Python 3.10 설치:
     ```bash
     brew install python@3.10
     ```

4. **PyTorch MPS 버전 설치**
   ```bash
   python3.10 -m pip install torch torchvision torchaudio
   ```
   - [ ] MPS (Metal Performance Shaders) 지원 확인:
     ```python
     import torch
     print(torch.backends.mps.is_available())  # True
     print(torch.backends.mps.is_built())      # True
     ```

5. **앱 서명 검증** (Phase 3)
   ```bash
   codesign -dv --verbose=4 /Applications/MuLa.app
   ```
   - [ ] 개발자 서명 확인: "Developer ID Application: ABADA (TEAM_ID)"
   - [ ] 공증(Notarization) 확인

6. **첫 실행**
   ```bash
   open /Applications/MuLa.app
   ```
   - [ ] Gatekeeper 경고 (첫 실행 시):
     ```
     "MuLa.app"은(는) 인터넷에서 다운로드한 앱입니다. 열시겠습니까?
     ```
   - [ ] "열기" 클릭
   - [ ] 앱 실행 성공
   - [ ] MPS 디바이스 인식: "Using MPS (Metal)"

**예상 결과**:
- 총 설치 시간: 5-8분
- 디스크 사용: 약 10GB
- 음악 생성 성능: GPU 대비 70-80% (MPS 가속)

---

### TC-MAC-002: Intel Mac 설치

**전제 조건**:
- macOS Monterey 12.x 이상
- Intel CPU

**테스트 단계**:

1. **CPU 아키텍처 감지**
   ```bash
   uname -m
   # x86_64 (Intel)
   # arm64 (Apple Silicon)
   ```
   - [ ] 설치 스크립트에서 아키텍처 자동 감지
   - [ ] 적절한 바이너리 선택

2. **Intel 전용 의존성 설치**
   ```bash
   brew install python@3.10
   arch -x86_64 python3.10 -m pip install torch torchvision torchaudio
   ```
   - [ ] x86_64 아키텍처 강제
   - [ ] MPS 미지원 → CPU 모드

3. **Rosetta 2 호환성** (Apple Silicon에서 Intel 앱 실행 시)
   ```bash
   softwareupdate --install-rosetta --agree-to-license
   ```
   - [ ] Rosetta 2 설치 프롬프트
   - [ ] 자동 설치 진행

**예상 결과**:
- Intel Mac: CPU 모드 실행
- Apple Silicon에서 Intel 앱: Rosetta 2 경고 후 실행

---

### TC-MAC-003: DMG 빌드 검증

**전제 조건**:
- macOS 개발 환경
- `create-dmg` 설치됨

**테스트 단계**:

1. **DMG 빌드 스크립트 실행**
   ```bash
   cd installer/macos
   ./build_dmg.sh
   ```
   - [ ] 앱 번들 생성: `MuLa.app`
   - [ ] DMG 생성: `MuLa-v1.0.0-macos-arm64.dmg`
   - [ ] 배경 이미지 삽입
   - [ ] 윈도우 크기/위치 설정

2. **DMG 내부 구조 검증**
   ```bash
   hdiutil attach MuLa-v1.0.0-macos-arm64.dmg
   ls -la /Volumes/ABADA\ MuLa/
   ```
   - [ ] `MuLa.app` 존재
   - [ ] `Applications` 심볼릭 링크 존재
   - [ ] `.background/` 폴더 (배경 이미지)

3. **체크섬 생성**
   ```bash
   shasum -a 256 MuLa-v1.0.0-macos-arm64.dmg
   ```
   - [ ] SHA-256 해시 출력
   - [ ] `checksums.txt`에 기록

**예상 결과**:
- DMG 파일 크기: 약 200MB (압축)
- 마운트 시 사용자 친화적 UI

---

## Linux 설치 플로우

### TC-LIN-001: Ubuntu 22.04 (apt)

**전제 조건**:
- Ubuntu 22.04 LTS (64-bit)
- sudo 권한

**테스트 단계**:

1. **설치 스크립트 다운로드**
   ```bash
   curl -fsSL https://music.abada.kr/install/linux.sh -o mula_install.sh
   chmod +x mula_install.sh
   ```
   - [ ] HTTPS 연결 성공
   - [ ] 스크립트 다운로드 (약 20KB)
   - [ ] 실행 권한 부여

2. **OS 감지**
   ```bash
   if [ -f /etc/os-release ]; then
     . /etc/os-release
     OS=$ID
     VER=$VERSION_ID
   fi
   ```
   - [ ] OS 식별: `ubuntu`
   - [ ] 버전 확인: `22.04`
   - [ ] 패키지 매니저 선택: `apt`

3. **시스템 의존성 설치**
   ```bash
   sudo apt update
   sudo apt install -y python3.10 python3.10-venv python3-pip git
   ```
   - [ ] apt 저장소 업데이트
   - [ ] Python 3.10 설치
   - [ ] venv 모듈 설치

4. **가상 환경 생성**
   ```bash
   python3.10 -m venv ~/.local/share/mula/venv
   source ~/.local/share/mula/venv/bin/activate
   ```
   - [ ] venv 생성 성공
   - [ ] 활성화 확인: `which python` → `~/.local/share/mula/venv/bin/python`

5. **PyTorch 설치 (CUDA vs CPU)**
   ```bash
   # CUDA 감지
   if command -v nvidia-smi &> /dev/null; then
     pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
   else
     pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
   fi
   ```
   - [ ] nvidia-smi 존재 확인
   - [ ] GPU 있으면 CUDA 버전 설치
   - [ ] 없으면 CPU 버전 설치

6. **Desktop Entry 생성**
   ```bash
   cat > ~/.local/share/applications/mula.desktop <<EOF
   [Desktop Entry]
   Name=ABADA MuLa
   Comment=AI Music Generation Studio
   Exec=/home/{USER}/.local/share/mula/venv/bin/python /home/{USER}/.local/share/mula/main.py
   Icon=/home/{USER}/.local/share/mula/icon.png
   Terminal=false
   Type=Application
   Categories=AudioVideo;Audio;
   EOF

   update-desktop-database ~/.local/share/applications/
   ```
   - [ ] .desktop 파일 생성
   - [ ] 아이콘 경로 설정
   - [ ] MIME 타입 등록

7. **애플리케이션 실행**
   ```bash
   python ~/.local/share/mula/main.py
   ```
   - [ ] GUI 윈도우 표시 (GTK/Qt)
   - [ ] 디바이스 인식: "Using CUDA" 또는 "Using CPU"

**예상 결과**:
- 총 설치 시간: 5-10분
- 디스크 사용: 약 10GB
- 데스크톱 환경에서 앱 아이콘 표시

---

### TC-LIN-002: Fedora 39 (dnf)

**테스트 단계**:

1. **OS 감지**
   ```bash
   OS=fedora
   VER=39
   PKG_MANAGER=dnf
   ```

2. **시스템 의존성 설치**
   ```bash
   sudo dnf install -y python3.10 python3-virtualenv git
   ```
   - [ ] DNF 저장소 확인
   - [ ] Python 3.10 설치

3. **SELinux 컨텍스트 설정**
   ```bash
   restorecon -Rv ~/.local/share/mula/
   ```
   - [ ] SELinux 활성화 확인
   - [ ] 컨텍스트 복원

**예상 결과**:
- Fedora 특화 패키지 설치 성공
- SELinux 정책 준수

---

### TC-LIN-003: Arch Linux (pacman)

**테스트 단계**:

1. **OS 감지**
   ```bash
   OS=arch
   PKG_MANAGER=pacman
   ```

2. **시스템 의존성 설치**
   ```bash
   sudo pacman -Syu --noconfirm python python-pip git
   ```
   - [ ] Pacman 동기화
   - [ ] Python 최신 버전 설치 (rolling release)

3. **AUR 패키지 설치** (선택 사항)
   ```bash
   yay -S python-pytorch-cuda
   ```
   - [ ] AUR 헬퍼 (yay) 사용
   - [ ] CUDA 최적화 패키지

**예상 결과**:
- Rolling release 특성상 최신 패키지
- AUR 통한 GPU 가속 최적화

---

### TC-LIN-004: 멀티 배포판 Docker 테스트

**테스트 단계**:

1. **Docker Compose 설정**
   ```yaml
   version: '3.8'
   services:
     ubuntu-20:
       image: ubuntu:20.04
       volumes:
         - ./mula_install.sh:/tmp/install.sh
       command: bash /tmp/install.sh

     ubuntu-22:
       image: ubuntu:22.04
       volumes:
         - ./mula_install.sh:/tmp/install.sh
       command: bash /tmp/install.sh

     fedora-38:
       image: fedora:38
       volumes:
         - ./mula_install.sh:/tmp/install.sh
       command: bash /tmp/install.sh

     archlinux:
       image: archlinux:latest
       volumes:
         - ./mula_install.sh:/tmp/install.sh
       command: bash /tmp/install.sh
   ```

2. **병렬 테스트 실행**
   ```bash
   docker-compose up --abort-on-container-exit
   ```
   - [ ] 4개 컨테이너 동시 실행
   - [ ] 각 배포판 설치 성공 확인
   - [ ] 로그 수집

**예상 결과**:
- 모든 배포판 설치 성공 (4/4)
- 에러 로그 0건

---

## 웹사이트 테스트

### TC-WEB-001: 홈페이지 로드 및 인터랙션

**URL**: `https://music.abada.kr/`

**테스트 단계**:

1. **페이지 로드**
   ```javascript
   // Playwright 테스트 코드
   const { test, expect } = require('@playwright/test');

   test('홈페이지 로드 성공', async ({ page }) => {
     await page.goto('https://music.abada.kr');

     // 타이틀 확인
     await expect(page).toHaveTitle(/ABADA Music Studio/);

     // Hero 섹션 표시 확인
     const hero = page.locator('.hero-section');
     await expect(hero).toBeVisible();
   });
   ```
   - [ ] 페이지 로드 시간 < 2초
   - [ ] Hero 섹션 표시
   - [ ] CTA 버튼 표시: "Download Now"

2. **네비게이션 테스트**
   ```javascript
   test('네비게이션 메뉴 동작', async ({ page }) => {
     await page.goto('https://music.abada.kr');

     // 다운로드 페이지로 이동
     await page.click('a[href="/download"]');
     await expect(page).toHaveURL(/.*download/);
   });
   ```
   - [ ] 헤더 네비게이션 표시
   - [ ] 모든 링크 동작 (Home, Download, Tutorial, Gallery, FAQ, About)
   - [ ] 모바일 햄버거 메뉴 (< 768px)

3. **Hero 애니메이션**
   ```javascript
   test('Hero 섹션 애니메이션', async ({ page }) => {
     await page.goto('https://music.abada.kr');

     const heroTitle = page.locator('.hero-title');
     await expect(heroTitle).toHaveCSS('opacity', '1'); // 페이드인 완료
   });
   ```
   - [ ] Fade-in 애니메이션 (0.5초)
   - [ ] Scroll reveal 효과
   - [ ] 부드러운 전환 (ease-in-out)

4. **Features 섹션**
   ```javascript
   test('Features 카드 표시', async ({ page }) => {
     await page.goto('https://music.abada.kr');

     const features = page.locator('.feature-card');
     await expect(features).toHaveCount(4); // 4개 기능 카드
   });
   ```
   - [ ] 4개 Feature 카드 렌더링
   - [ ] 아이콘 표시
   - [ ] 설명 텍스트 가독성

5. **Gallery 미리보기**
   ```javascript
   test('Gallery 미리보기 섹션', async ({ page }) => {
     await page.goto('https://music.abada.kr');

     const gallery = page.locator('.gallery-preview');
     await expect(gallery).toBeVisible();

     // "View More" 버튼 클릭
     await page.click('a[href="/gallery"]');
     await expect(page).toHaveURL(/.*gallery/);
   });
   ```
   - [ ] 3개 샘플 음악 표시
   - [ ] "View More" 버튼 동작
   - [ ] 갤러리 페이지로 이동

**성능 메트릭**:
- FCP (First Contentful Paint): < 1.5s
- LCP (Largest Contentful Paint): < 2.5s
- CLS (Cumulative Layout Shift): < 0.1
- TBT (Total Blocking Time): < 200ms

---

### TC-WEB-002: 다운로드 페이지 (OS 감지)

**URL**: `https://music.abada.kr/download`

**테스트 단계**:

1. **OS 자동 감지**
   ```javascript
   test('OS 감지 및 추천', async ({ page, browserName }) => {
     await page.goto('https://music.abada.kr/download');

     // User-Agent 기반 OS 감지
     const recommendedOS = page.locator('.recommended-download');
     await expect(recommendedOS).toBeVisible();

     // 예: Windows에서 접속 시 Windows 버전 하이라이트
     if (process.platform === 'win32') {
       await expect(recommendedOS).toContainText('Windows');
     }
   });
   ```
   - [ ] User-Agent 파싱
   - [ ] Windows/macOS/Linux 자동 감지
   - [ ] 추천 다운로드 하이라이트

2. **다운로드 버튼 동작**
   ```javascript
   test('다운로드 버튼 클릭', async ({ page }) => {
     await page.goto('https://music.abada.kr/download');

     // 다운로드 시작 이벤트 감지
     const [download] = await Promise.all([
       page.waitForEvent('download'),
       page.click('.download-windows-x64')
     ]);

     // 파일명 검증
     expect(download.suggestedFilename()).toMatch(/MuLaInstaller.*\.exe/);
   });
   ```
   - [ ] 클릭 시 다운로드 시작
   - [ ] 파일명 형식: `MuLaInstaller-v1.0.0-win-x64.exe`
   - [ ] GitHub Releases에서 다운로드

3. **다운로드 통계 API 호출**
   ```javascript
   test('다운로드 통계 기록', async ({ page }) => {
     // API 모킹
     await page.route('**/api/download-stats', route => {
       route.fulfill({
         status: 201,
         contentType: 'application/json',
         body: JSON.stringify({ success: true })
       });
     });

     await page.goto('https://music.abada.kr/download');
     await page.click('.download-windows-x64');

     // API 호출 검증 (다음 섹션에서 상세)
   });
   ```
   - [ ] POST `/api/download-stats` 호출
   - [ ] Payload: `{ os, version, timestamp }`
   - [ ] 응답 성공 (201 Created)

4. **플랫폼별 설치 가이드**
   ```javascript
   test('플랫폼별 가이드 표시', async ({ page }) => {
     await page.goto('https://music.abada.kr/download');

     // 탭 전환
     await page.click('button[data-tab="windows"]');
     const windowsGuide = page.locator('.install-guide-windows');
     await expect(windowsGuide).toBeVisible();

     await page.click('button[data-tab="macos"]');
     const macosGuide = page.locator('.install-guide-macos');
     await expect(macosGuide).toBeVisible();
   });
   ```
   - [ ] Windows 가이드 (GPU 요구사항)
   - [ ] macOS 가이드 (Homebrew 설치)
   - [ ] Linux 가이드 (배포판별 명령)

**성능 메트릭**:
- LCP: < 2.0s
- 다운로드 버튼 응답: < 100ms

---

### TC-WEB-003: 튜토리얼 페이지 (코드 블록 렌더링)

**URL**: `https://music.abada.kr/tutorial`

**테스트 단계**:

1. **목차 네비게이션**
   ```javascript
   test('목차 자동 생성', async ({ page }) => {
     await page.goto('https://music.abada.kr/tutorial');

     const toc = page.locator('.table-of-contents');
     await expect(toc).toBeVisible();

     // H2, H3 헤딩 기반 목차
     const tocItems = toc.locator('li');
     await expect(tocItems).toHaveCountGreaterThan(5);
   });
   ```
   - [ ] 목차 자동 생성 (H2, H3)
   - [ ] 클릭 시 스크롤 이동
   - [ ] 현재 섹션 하이라이트

2. **코드 블록 하이라이팅**
   ```javascript
   test('Syntax Highlighting', async ({ page }) => {
     await page.goto('https://music.abada.kr/tutorial');

     const codeBlock = page.locator('pre code.language-python');
     await expect(codeBlock).toBeVisible();

     // Prism.js 또는 Highlight.js 확인
     await expect(codeBlock).toHaveClass(/language-python/);
   });
   ```
   - [ ] Python 코드 하이라이팅
   - [ ] Bash 명령어 하이라이팅
   - [ ] 복사 버튼 표시

3. **복사 버튼 기능**
   ```javascript
   test('코드 복사 버튼', async ({ page }) => {
     await page.goto('https://music.abada.kr/tutorial');

     const copyButton = page.locator('.copy-code-button').first();
     await copyButton.click();

     // 클립보드 확인 (권한 필요)
     const clipboardText = await page.evaluate(() => navigator.clipboard.readText());
     expect(clipboardText).toContain('python');
   });
   ```
   - [ ] 클릭 시 클립보드 복사
   - [ ] 피드백 메시지: "Copied!"
   - [ ] 2초 후 원래 텍스트로 복귀

4. **이미지 레이지 로딩**
   ```javascript
   test('이미지 Lazy Loading', async ({ page }) => {
     await page.goto('https://music.abada.kr/tutorial');

     const images = page.locator('img[loading="lazy"]');
     await expect(images.first()).toHaveAttribute('loading', 'lazy');
   });
   ```
   - [ ] `loading="lazy"` 속성
   - [ ] 뷰포트 진입 시 로드
   - [ ] Placeholder 표시

**성능 메트릭**:
- LCP: < 3.0s (이미지 많음)
- 코드 블록 렌더링: < 500ms

---

### TC-WEB-004: 갤러리 페이지 (음악 재생 API)

**URL**: `https://music.abada.kr/gallery`

**테스트 단계**:

1. **갤러리 그리드 렌더링**
   ```javascript
   test('갤러리 그리드 표시', async ({ page }) => {
     await page.goto('https://music.abada.kr/gallery');

     // API에서 데이터 로드
     await page.waitForSelector('.gallery-item');

     const items = page.locator('.gallery-item');
     await expect(items).toHaveCountGreaterThan(0);
   });
   ```
   - [ ] API 호출: GET `/api/gallery?limit=12`
   - [ ] 그리드 레이아웃 (3열, 반응형)
   - [ ] 썸네일 이미지 표시

2. **음악 재생 기능**
   ```javascript
   test('음악 재생', async ({ page }) => {
     await page.goto('https://music.abada.kr/gallery');

     const firstItem = page.locator('.gallery-item').first();
     const playButton = firstItem.locator('.play-button');
     await playButton.click();

     // Audio 요소 확인
     const audio = page.locator('audio');
     await expect(audio).toHaveAttribute('src', /.+\.mp3/);

     // 재생 상태 확인
     const isPlaying = await audio.evaluate(node => !node.paused);
     expect(isPlaying).toBe(true);
   });
   ```
   - [ ] 재생 버튼 클릭
   - [ ] HTML5 `<audio>` 요소 표시
   - [ ] 재생/일시정지 토글
   - [ ] 진행률 바 업데이트

3. **페이지네이션**
   ```javascript
   test('페이지네이션', async ({ page }) => {
     await page.goto('https://music.abada.kr/gallery');

     // "Load More" 버튼
     const loadMore = page.locator('.load-more-button');
     await loadMore.click();

     // API 재호출 확인
     await page.waitForResponse(response =>
       response.url().includes('/api/gallery') &&
       response.url().includes('offset=12')
     );
   });
   ```
   - [ ] "Load More" 버튼 표시
   - [ ] 클릭 시 추가 데이터 로드 (offset 증가)
   - [ ] 무한 스크롤 대신 버튼 방식

4. **필터링 (장르, 태그)**
   ```javascript
   test('장르 필터링', async ({ page }) => {
     await page.goto('https://music.abada.kr/gallery');

     // 장르 선택
     await page.click('button[data-genre="pop"]');

     // API 재호출 확인
     await page.waitForResponse(response =>
       response.url().includes('/api/gallery') &&
       response.url().includes('genre=pop')
     );

     // 결과 확인
     const items = page.locator('.gallery-item');
     await expect(items.first()).toContainText('Pop');
   });
   ```
   - [ ] 장르 필터: Pop, Rock, Jazz, Classical, etc.
   - [ ] 태그 필터: Happy, Sad, Energetic, etc.
   - [ ] 복수 선택 가능 (OR 조건)

**성능 메트릭**:
- LCP: < 2.5s
- 음악 재생 지연: < 500ms
- API 응답: < 200ms

---

### TC-WEB-005: FAQ 페이지 (검색 및 아코디언)

**URL**: `https://music.abada.kr/faq`

**테스트 단계**:

1. **FAQ 아코디언**
   ```javascript
   test('아코디언 토글', async ({ page }) => {
     await page.goto('https://music.abada.kr/faq');

     const firstQuestion = page.locator('.faq-item').first();
     const answer = firstQuestion.locator('.faq-answer');

     // 초기 상태: 닫힘
     await expect(answer).toBeHidden();

     // 클릭: 열림
     await firstQuestion.click();
     await expect(answer).toBeVisible();

     // 재클릭: 닫힘
     await firstQuestion.click();
     await expect(answer).toBeHidden();
   });
   ```
   - [ ] 초기 상태: 모두 닫힘
   - [ ] 클릭 시 열기/닫기 토글
   - [ ] 애니메이션: slide-down (0.3초)

2. **검색 기능**
   ```javascript
   test('FAQ 검색', async ({ page }) => {
     await page.goto('https://music.abada.kr/faq');

     const searchInput = page.locator('input[type="search"]');
     await searchInput.fill('GPU');

     // 필터링 결과
     const visibleItems = page.locator('.faq-item:visible');
     await expect(visibleItems).toHaveCountGreaterThan(0);

     const firstItem = visibleItems.first();
     await expect(firstItem).toContainText('GPU', { ignoreCase: true });
   });
   ```
   - [ ] 실시간 검색 (debounce 300ms)
   - [ ] 질문 + 답변 텍스트에서 검색
   - [ ] 대소문자 무시
   - [ ] 하이라이팅 (검색어 강조)

3. **카테고리 탭**
   ```javascript
   test('카테고리 필터', async ({ page }) => {
     await page.goto('https://music.abada.kr/faq');

     // "Installation" 카테고리 선택
     await page.click('button[data-category="installation"]');

     const visibleItems = page.locator('.faq-item:visible');
     const categories = await visibleItems.evaluateAll(items =>
       items.map(item => item.dataset.category)
     );

     expect(categories.every(cat => cat === 'installation')).toBe(true);
   });
   ```
   - [ ] 카테고리: Installation, Usage, Troubleshooting, General
   - [ ] 탭 전환 시 필터링
   - [ ] "All" 탭: 모든 항목 표시

**성능 메트릭**:
- LCP: < 2.0s
- 검색 응답: < 100ms (debounce 후)

---

### TC-WEB-006: 소개 페이지 (About)

**URL**: `https://music.abada.kr/about`

**테스트 단계**:

1. **팀 정보 표시**
   ```javascript
   test('팀 정보 렌더링', async ({ page }) => {
     await page.goto('https://music.abada.kr/about');

     const teamSection = page.locator('.team-section');
     await expect(teamSection).toBeVisible();

     const teamMembers = page.locator('.team-member');
     await expect(teamMembers).toHaveCountGreaterThan(0);
   });
   ```
   - [ ] 팀 소개 섹션
   - [ ] 멤버 카드 (이름, 역할, 사진)
   - [ ] 소셜 링크 (GitHub, LinkedIn)

2. **연락처 폼**
   ```javascript
   test('연락처 폼 제출', async ({ page }) => {
     await page.goto('https://music.abada.kr/about');

     await page.fill('input[name="name"]', 'John Doe');
     await page.fill('input[name="email"]', 'john@example.com');
     await page.fill('textarea[name="message"]', 'Hello!');

     await page.click('button[type="submit"]');

     // 성공 메시지
     const successMsg = page.locator('.success-message');
     await expect(successMsg).toBeVisible();
     await expect(successMsg).toContainText('Thank you');
   });
   ```
   - [ ] 입력 검증 (이름, 이메일 필수)
   - [ ] 이메일 형식 검증
   - [ ] 제출 시 API 호출 (또는 이메일 전송)
   - [ ] 성공/실패 메시지

**성능 메트릭**:
- LCP: < 2.0s

---

### TC-WEB-007: 반응형 테스트 (모바일, 태블릿, 데스크톱)

**테스트 단계**:

1. **모바일 (375px - iPhone SE)**
   ```javascript
   test('모바일 레이아웃', async ({ page }) => {
     await page.setViewportSize({ width: 375, height: 667 });
     await page.goto('https://music.abada.kr');

     // 햄버거 메뉴 표시
     const hamburger = page.locator('.hamburger-menu');
     await expect(hamburger).toBeVisible();

     // 데스크톱 메뉴 숨김
     const desktopNav = page.locator('.desktop-nav');
     await expect(desktopNav).toBeHidden();
   });
   ```
   - [ ] 햄버거 메뉴 표시
   - [ ] 1열 그리드 레이아웃
   - [ ] 터치 친화적 버튼 크기 (44x44px 이상)

2. **태블릿 (768px - iPad)**
   ```javascript
   test('태블릿 레이아웃', async ({ page }) => {
     await page.setViewportSize({ width: 768, height: 1024 });
     await page.goto('https://music.abada.kr');

     // 2열 그리드
     const galleryGrid = page.locator('.gallery-grid');
     const columns = await galleryGrid.evaluate(node =>
       window.getComputedStyle(node).getPropertyValue('grid-template-columns')
     );
     expect(columns).toContain('2'); // 2 columns
   });
   ```
   - [ ] 2열 그리드 레이아웃
   - [ ] 축약된 네비게이션

3. **데스크톱 (1920px - Full HD)**
   ```javascript
   test('데스크톱 레이아웃', async ({ page }) => {
     await page.setViewportSize({ width: 1920, height: 1080 });
     await page.goto('https://music.abada.kr');

     // 전체 네비게이션 표시
     const desktopNav = page.locator('.desktop-nav');
     await expect(desktopNav).toBeVisible();

     // 3열 그리드
     const galleryGrid = page.locator('.gallery-grid');
     const columns = await galleryGrid.evaluate(node =>
       window.getComputedStyle(node).getPropertyValue('grid-template-columns')
     );
     expect(columns).toContain('3'); // 3 columns
   });
   ```
   - [ ] 3열 그리드 레이아웃
   - [ ] 전체 네비게이션 메뉴
   - [ ] 사이드바 표시

**성능 메트릭** (모든 뷰포트):
- LCP < 2.5s
- CLS < 0.1

---

### TC-WEB-008: 크로스 브라우저 테스트

**브라우저 매트릭스**:

| 브라우저 | 데스크톱 | 모바일 | 우선순위 |
|---------|---------|--------|---------|
| Chrome 120+ | ✅ | ✅ | High |
| Firefox 121+ | ✅ | ✅ | High |
| Safari 17+ | ✅ (macOS) | ✅ (iOS) | High |
| Edge 120+ | ✅ | N/A | Medium |
| Opera | ✅ | N/A | Low |

**테스트 시나리오** (각 브라우저):
```javascript
test.describe('크로스 브라우저 테스트', () => {
  test.use({ browserName: 'chromium' });
  test('Chrome 호환성', async ({ page }) => { /* ... */ });

  test.use({ browserName: 'firefox' });
  test('Firefox 호환성', async ({ page }) => { /* ... */ });

  test.use({ browserName: 'webkit' });
  test('Safari 호환성', async ({ page }) => { /* ... */ });
});
```

**검증 항목**:
- [ ] CSS 렌더링 일관성
- [ ] JavaScript 기능 동작
- [ ] Flexbox/Grid 레이아웃
- [ ] Web API (Clipboard, Audio)

---

### TC-WEB-009: SEO 검증

**메타태그 체크리스트**:

```javascript
test('SEO 메타태그', async ({ page }) => {
  await page.goto('https://music.abada.kr');

  // Title (50-60자)
  const title = await page.title();
  expect(title.length).toBeGreaterThan(30);
  expect(title.length).toBeLessThan(60);

  // Meta Description (150-160자)
  const description = await page.locator('meta[name="description"]').getAttribute('content');
  expect(description.length).toBeGreaterThan(120);
  expect(description.length).toBeLessThan(160);

  // Open Graph
  const ogTitle = await page.locator('meta[property="og:title"]').getAttribute('content');
  expect(ogTitle).toBeTruthy();

  const ogImage = await page.locator('meta[property="og:image"]').getAttribute('content');
  expect(ogImage).toMatch(/^https?:\/\//);

  // Canonical URL
  const canonical = await page.locator('link[rel="canonical"]').getAttribute('href');
  expect(canonical).toBe('https://music.abada.kr/');
});
```

**Structured Data (Schema.org)**:
```javascript
test('Structured Data', async ({ page }) => {
  await page.goto('https://music.abada.kr');

  const jsonLd = await page.locator('script[type="application/ld+json"]').textContent();
  const data = JSON.parse(jsonLd);

  expect(data['@type']).toBe('WebSite');
  expect(data.name).toBe('ABADA Music Studio');
  expect(data.url).toBe('https://music.abada.kr');
});
```

**Lighthouse SEO 검사**:
```bash
lighthouse https://music.abada.kr --only-categories=seo --output json --output-path ./seo-report.json
```
- [ ] SEO 점수 > 95
- [ ] `<title>` 존재
- [ ] Meta description 존재
- [ ] 크롤 가능한 링크
- [ ] 이미지 alt 속성

---

## API 테스트

### TC-API-001: Download Stats API (POST)

**엔드포인트**: `POST /api/download-stats`

**테스트 단계**:

1. **정상 요청**
   ```bash
   curl -X POST https://music.abada.kr/api/download-stats \
     -H "Content-Type: application/json" \
     -d '{
       "os": "windows",
       "version": "v1.0.0",
       "timestamp": "2026-01-19T12:00:00Z"
     }'
   ```
   - [ ] 응답 코드: 201 Created
   - [ ] 응답 본문: `{ "success": true, "id": "uuid" }`
   - [ ] KV Store 저장 확인

2. **잘못된 JSON**
   ```bash
   curl -X POST https://music.abada.kr/api/download-stats \
     -H "Content-Type: application/json" \
     -d '{ invalid json'
   ```
   - [ ] 응답 코드: 400 Bad Request
   - [ ] 응답 본문: `{ "error": "Invalid JSON" }`

3. **필수 필드 누락**
   ```bash
   curl -X POST https://music.abada.kr/api/download-stats \
     -H "Content-Type: application/json" \
     -d '{
       "version": "v1.0.0"
     }'
   ```
   - [ ] 응답 코드: 400 Bad Request
   - [ ] 응답 본문: `{ "error": "Missing required field: os" }`

4. **CORS 헤더**
   ```bash
   curl -X OPTIONS https://music.abada.kr/api/download-stats \
     -H "Origin: https://music.abada.kr"
   ```
   - [ ] `Access-Control-Allow-Origin: *` (또는 특정 도메인)
   - [ ] `Access-Control-Allow-Methods: GET, POST, OPTIONS`
   - [ ] `Access-Control-Allow-Headers: Content-Type`

5. **Rate Limiting**
   ```bash
   # 100회 반복 요청
   for i in {1..100}; do
     curl -X POST https://music.abada.kr/api/download-stats \
       -H "Content-Type: application/json" \
       -d '{ "os": "windows", "version": "v1.0.0", "timestamp": "2026-01-19T12:00:00Z" }'
   done
   ```
   - [ ] 100번째 요청: 429 Too Many Requests
   - [ ] `Retry-After` 헤더 존재

**성능 테스트** (k6):
```javascript
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  vus: 100, // 100 concurrent users
  duration: '1m',
};

export default function () {
  let payload = JSON.stringify({
    os: 'windows',
    version: 'v1.0.0',
    timestamp: new Date().toISOString(),
  });

  let res = http.post('https://music.abada.kr/api/download-stats', payload, {
    headers: { 'Content-Type': 'application/json' },
  });

  check(res, {
    'status is 201': (r) => r.status === 201,
    'response time < 200ms': (r) => r.timings.duration < 200,
  });
}
```

**예상 결과**:
- p95 응답 시간: < 200ms
- 처리량: > 1,000 req/min
- 에러율: < 0.1%

---

### TC-API-002: Download Stats API (GET)

**엔드포인트**: `GET /api/download-stats`

**테스트 단계**:

1. **전체 통계 조회**
   ```bash
   curl https://music.abada.kr/api/download-stats
   ```
   - [ ] 응답 코드: 200 OK
   - [ ] 응답 본문:
     ```json
     {
       "total": 12345,
       "byOS": {
         "windows": 6789,
         "macos": 3456,
         "linux": 2100
       },
       "byVersion": {
         "v1.0.0": 12345
       }
     }
     ```

2. **특정 OS 필터**
   ```bash
   curl https://music.abada.kr/api/download-stats?os=windows
   ```
   - [ ] 응답: Windows 다운로드만 반환
   - [ ] 필터링 정확도 검증

3. **날짜 범위 필터**
   ```bash
   curl "https://music.abada.kr/api/download-stats?start=2026-01-01&end=2026-01-31"
   ```
   - [ ] 2026년 1월 데이터만 반환
   - [ ] ISO 8601 날짜 형식

4. **캐싱 헤더**
   ```bash
   curl -I https://music.abada.kr/api/download-stats
   ```
   - [ ] `Cache-Control: public, max-age=3600` (1시간 캐싱)
   - [ ] `ETag` 헤더 존재

**성능**:
- p95 응답 시간: < 100ms (캐싱)

---

### TC-API-003: Gallery API (GET)

**엔드포인트**: `GET /api/gallery`

**테스트 단계**:

1. **페이지네이션**
   ```bash
   curl "https://music.abada.kr/api/gallery?limit=10&offset=0"
   ```
   - [ ] 응답 코드: 200 OK
   - [ ] 응답 본문:
     ```json
     {
       "items": [
         {
           "id": "uuid",
           "title": "Song Title",
           "artist": "Artist Name",
           "genre": "Pop",
           "tags": ["happy", "wedding"],
           "audioUrl": "https://cdn.abada.kr/audio/uuid.mp3",
           "thumbnailUrl": "https://cdn.abada.kr/thumb/uuid.jpg",
           "createdAt": "2026-01-19T12:00:00Z"
         }
       ],
       "total": 100,
       "limit": 10,
       "offset": 0
     }
     ```

2. **정렬 (최신순, 인기순)**
   ```bash
   curl "https://music.abada.kr/api/gallery?sort=popular"
   curl "https://music.abada.kr/api/gallery?sort=recent"
   ```
   - [ ] `sort=popular`: 조회수/재생수 기준 내림차순
   - [ ] `sort=recent`: createdAt 기준 내림차순

3. **필터링 (장르, 태그)**
   ```bash
   curl "https://music.abada.kr/api/gallery?genre=pop&tags=happy,wedding"
   ```
   - [ ] AND 조건: genre=pop AND (tags IN ['happy', 'wedding'])
   - [ ] 정확한 필터링 결과

4. **404 처리 (존재하지 않는 ID)**
   ```bash
   curl https://music.abada.kr/api/gallery/invalid-uuid
   ```
   - [ ] 응답 코드: 404 Not Found
   - [ ] 응답 본문: `{ "error": "Item not found" }`

**성능**:
- p95 응답 시간: < 200ms

---

### TC-API-004: Gallery API (POST) - 관리자 전용

**엔드포인트**: `POST /api/gallery`

**테스트 단계**:

1. **인증 없이 요청**
   ```bash
   curl -X POST https://music.abada.kr/api/gallery \
     -H "Content-Type: application/json" \
     -d '{ "title": "New Song" }'
   ```
   - [ ] 응답 코드: 401 Unauthorized
   - [ ] 응답 본문: `{ "error": "Authentication required" }`

2. **유효한 인증 토큰**
   ```bash
   curl -X POST https://music.abada.kr/api/gallery \
     -H "Authorization: Bearer ADMIN_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "title": "New Song",
       "artist": "Artist Name",
       "genre": "Pop",
       "tags": ["happy", "wedding"],
       "audioUrl": "https://cdn.abada.kr/audio/new.mp3"
     }'
   ```
   - [ ] 응답 코드: 201 Created
   - [ ] 응답 본문: `{ "success": true, "id": "uuid" }`

**보안**:
- [ ] JWT 토큰 검증
- [ ] 만료된 토큰 거부 (401)
- [ ] 잘못된 서명 거부 (401)

---

### TC-API-005: Analytics API (POST)

**엔드포인트**: `POST /api/analytics`

**테스트 단계**:

1. **페이지 뷰 이벤트**
   ```bash
   curl -X POST https://music.abada.kr/api/analytics \
     -H "Content-Type: application/json" \
     -d '{
       "event": "page_view",
       "page": "/download",
       "userAgent": "Mozilla/5.0...",
       "timestamp": "2026-01-19T12:00:00Z"
     }'
   ```
   - [ ] 응답 코드: 201 Created
   - [ ] KV Store에 저장

2. **다운로드 이벤트**
   ```bash
   curl -X POST https://music.abada.kr/api/analytics \
     -H "Content-Type: application/json" \
     -d '{
       "event": "download",
       "os": "windows",
       "version": "v1.0.0",
       "timestamp": "2026-01-19T12:00:00Z"
     }'
   ```
   - [ ] 응답 코드: 201 Created

3. **음악 재생 이벤트**
   ```bash
   curl -X POST https://music.abada.kr/api/analytics \
     -H "Content-Type: application/json" \
     -d '{
       "event": "play",
       "itemId": "uuid",
       "duration": 180,
       "timestamp": "2026-01-19T12:00:00Z"
     }'
   ```
   - [ ] 응답 코드: 201 Created

4. **봇 필터링**
   ```bash
   curl -X POST https://music.abada.kr/api/analytics \
     -H "Content-Type: application/json" \
     -H "User-Agent: Googlebot/2.1" \
     -d '{ "event": "page_view", "page": "/" }'
   ```
   - [ ] 봇 감지: Googlebot, Bingbot, etc.
   - [ ] 응답 코드: 200 OK (기록하지 않음)
   - [ ] 응답 본문: `{ "success": true, "filtered": true }`

**성능**:
- p95 응답 시간: < 100ms (비동기 처리)

---

### TC-API-006: 에러 처리 및 복원력

**테스트 시나리오**:

1. **KV Store 장애 시뮬레이션**
   ```javascript
   // Cloudflare Workers 내부 로직
   try {
     await KV.put(key, value);
   } catch (error) {
     // Fallback: 로컬 캐시 또는 우아한 성능 저하
     console.error('KV Store error:', error);
     return new Response('Service temporarily unavailable', { status: 503 });
   }
   ```
   - [ ] 503 Service Unavailable 반환
   - [ ] `Retry-After: 60` 헤더

2. **타임아웃 처리**
   ```javascript
   const controller = new AbortController();
   const timeout = setTimeout(() => controller.abort(), 5000); // 5초

   try {
     const response = await fetch(url, { signal: controller.signal });
   } catch (error) {
     if (error.name === 'AbortError') {
       return new Response('Request timeout', { status: 504 });
     }
   } finally {
     clearTimeout(timeout);
   }
   ```
   - [ ] 5초 후 타임아웃
   - [ ] 504 Gateway Timeout 반환

3. **Circuit Breaker 패턴**
   ```javascript
   let failureCount = 0;
   const FAILURE_THRESHOLD = 5;

   if (failureCount >= FAILURE_THRESHOLD) {
     return new Response('Circuit breaker open', { status: 503 });
   }

   try {
     // API 호출
     failureCount = 0; // 성공 시 리셋
   } catch (error) {
     failureCount++;
   }
   ```
   - [ ] 연속 5회 실패 시 Circuit Open
   - [ ] 30초 후 Half-Open 시도

---

## 통합 시나리오

### TC-INT-001: 완전한 사용자 여정 (End-to-End)

**시나리오**: 신규 사용자가 웹사이트 방문 → 다운로드 → 설치 → 음악 생성

**테스트 단계**:

1. **웹사이트 발견 (SEO)**
   - [ ] Google 검색: "AI music generation"
   - [ ] music.abada.kr 검색 결과 표시 (상위 10위 내)
   - [ ] 메타 description 클릭 유도

2. **홈페이지 방문**
   - [ ] Hero 섹션 로드 (< 2초)
   - [ ] "Download Now" CTA 클릭
   - [ ] `/download` 페이지로 이동

3. **다운로드**
   - [ ] OS 자동 감지 (Windows)
   - [ ] "Download for Windows x64" 클릭
   - [ ] GitHub Releases에서 파일 다운로드
   - [ ] Analytics API 호출 (download 이벤트)

4. **설치 (Windows)**
   - [ ] MuLaInstaller_x64.exe 실행
   - [ ] GPU 감지 성공 (NVIDIA GTX 1060)
   - [ ] Python 3.10 임베딩 설치
   - [ ] PyTorch CUDA 설치
   - [ ] HuggingFace 모델 다운로드 (6GB)
   - [ ] 바로가기 생성
   - [ ] 총 설치 시간: 8분

5. **첫 실행**
   - [ ] Desktop 바로가기 더블 클릭
   - [ ] 애플리케이션 윈도우 표시
   - [ ] GPU 인식: "Using GPU: NVIDIA GeForce GTX 1060"
   - [ ] 모델 로드 (10초)

6. **음악 생성**
   - [ ] Lyrics 입력:
     ```
     [Verse]
     The sun creeps in across the floor
     I hear the traffic outside the door
     ```
   - [ ] Tags 선택: `piano,happy,wedding`
   - [ ] "Generate" 버튼 클릭
   - [ ] 진행률 표시 (0% → 100%)
   - [ ] 생성 시간: 약 2분 (1분 음악)
   - [ ] 재생 성공

7. **갤러리 공유 (선택)**
   - [ ] "Share to Gallery" 버튼 클릭
   - [ ] 업로드 성공
   - [ ] music.abada.kr/gallery에 표시

**예상 결과**:
- 전체 여정 시간: 약 15분 (다운로드 + 설치 + 첫 생성)
- 각 단계 성공률: > 95%

---

### TC-INT-002: 크로스 플랫폼 일관성

**시나리오**: 동일한 음악을 Windows, macOS, Linux에서 생성

**테스트 단계**:

1. **동일한 입력 사용**
   ```python
   lyrics = open('assets/lyrics.txt').read()
   tags = open('assets/tags.txt').read()
   ```
   - [ ] Windows, macOS, Linux 모두 동일한 파일 사용

2. **생성 및 비교**
   ```bash
   # Windows (CUDA)
   python main.py --lyrics assets/lyrics.txt --tags assets/tags.txt --save output_windows.mp3

   # macOS (MPS)
   python main.py --lyrics assets/lyrics.txt --tags assets/tags.txt --save output_macos.mp3

   # Linux (CPU)
   python main.py --lyrics assets/lyrics.txt --tags assets/tags.txt --save output_linux.mp3
   ```
   - [ ] 3개 플랫폼 모두 생성 성공

3. **음악 파일 분석**
   ```python
   import librosa

   y_win, sr_win = librosa.load('output_windows.mp3')
   y_mac, sr_mac = librosa.load('output_macos.mp3')
   y_lin, sr_lin = librosa.load('output_linux.mp3')

   # 길이 비교 (±5% 허용)
   assert abs(len(y_win) - len(y_mac)) / len(y_win) < 0.05
   assert abs(len(y_win) - len(y_lin)) / len(y_win) < 0.05

   # 스펙트럼 유사도 (MFCC)
   mfcc_win = librosa.feature.mfcc(y=y_win, sr=sr_win)
   mfcc_mac = librosa.feature.mfcc(y=y_mac, sr=sr_mac)

   similarity = cosine_similarity(mfcc_win.flatten(), mfcc_mac.flatten())
   assert similarity > 0.9  # 90% 이상 유사
   ```
   - [ ] 길이 유사 (±5%)
   - [ ] 스펙트럼 유사도 > 90%
   - [ ] 음질 검증 (SNR, THD)

**예상 결과**:
- 크로스 플랫폼 일관성 > 90%
- 사용자 체감 품질 동일

---

### TC-INT-003: 고부하 시나리오 (1,000 동시 사용자)

**시나리오**: 릴리즈 당일 트래픽 폭주

**테스트 단계**:

1. **로드 테스트 설정 (k6)**
   ```javascript
   import http from 'k6/http';
   import { sleep } from 'k6';

   export let options = {
     stages: [
       { duration: '2m', target: 100 },  // Ramp-up to 100 users
       { duration: '5m', target: 1000 }, // Spike to 1000 users
       { duration: '5m', target: 1000 }, // Sustained load
       { duration: '2m', target: 0 },    // Ramp-down
     ],
   };

   export default function () {
     // 페이지 방문
     http.get('https://music.abada.kr/');
     sleep(1);

     // 다운로드 페이지
     http.get('https://music.abada.kr/download');
     sleep(2);

     // 다운로드 통계 기록
     http.post('https://music.abada.kr/api/download-stats', JSON.stringify({
       os: 'windows',
       version: 'v1.0.0',
       timestamp: new Date().toISOString(),
     }), {
       headers: { 'Content-Type': 'application/json' },
     });
     sleep(1);
   }
   ```

2. **실행 및 모니터링**
   ```bash
   k6 run --out cloud load-test.js
   ```
   - [ ] 1,000 CCU 달성
   - [ ] p95 응답 시간 < 200ms 유지
   - [ ] 에러율 < 0.1%
   - [ ] Cloudflare 대시보드 모니터링

3. **데이터베이스 부하 확인**
   ```bash
   # KV Store 쓰기/읽기 성능
   wrangler kv:key list --binding=DOWNLOAD_STATS
   ```
   - [ ] KV Store 처리량 > 10,000 req/min
   - [ ] 쓰기 지연 < 50ms

**예상 결과**:
- 1,000 CCU 안정적 처리
- Cloudflare CDN 캐싱 효과 (80% 캐시 히트율)
- Origin 서버 부하 최소화

---

## 부록

### 테스트 자동화 스크립트

**Playwright 설정**:
```javascript
// playwright.config.js
module.exports = {
  testDir: './tests/e2e',
  timeout: 30000,
  retries: 2,
  use: {
    baseURL: 'https://music.abada.kr',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } },
    { name: 'firefox', use: { browserName: 'firefox' } },
    { name: 'webkit', use: { browserName: 'webkit' } },
  ],
};
```

**CI/CD 통합**:
```yaml
# .github/workflows/e2e-tests.yml
name: E2E Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright
        run: npx playwright install --with-deps

      - name: Run E2E tests
        run: npx playwright test

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: playwright-report/
```

---

**문서 버전**: 1.0.0
**마지막 업데이트**: 2026-01-19
**다음 리뷰**: 2026-02-01
