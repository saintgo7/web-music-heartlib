# HeartMuLa 원클릭 설치 프로그램 개발 계획서

---

## 1. 프로젝트 개요

### 1.1 프로젝트명
**MuLa Installer** - HeartMuLa AI 음악 생성 환경 원클릭 설치 프로그램

### 1.2 핵심 목표

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   비개발자가 더블클릭 한 번으로                             │
│   HeartMuLa AI 음악 생성 환경을 자신의 PC에 설치            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 문제 정의

**현재 HeartMuLa 설치 과정 (개발자용):**
```
1. Python 3.10 설치
2. CUDA / cuDNN 설치 (NVIDIA GPU 사용 시)
3. 가상환경 생성: python -m venv venv
4. PyTorch 설치: pip install torch torchvision torchaudio
5. HeartMuLa 설치: pip install git+https://github.com/HeartMuLa/heartlib.git
6. 모델 다운로드: huggingface-cli download HeartMuLa/HeartMuLa-oss-3B
7. 실행 스크립트 작성
```

**문제점:**
- 비개발자에게는 불가능한 과정
- 환경 변수, 경로 설정 등 복잡함
- OS별 설치 방법 상이
- 의존성 충돌 가능성

### 1.4 해결책: 원클릭 설치 프로그램

```
사용자 행동:
  [다운로드] → [더블클릭] → [완료]

설치 프로그램이 자동 처리:
  ▷ Python 환경 내장 (별도 설치 불필요)
  ▷ PyTorch + 의존성 자동 설치
  ▷ GPU 자동 감지 (CUDA/MPS/CPU)
  ▷ 모델 체크포인트 다운로드
  ▷ 실행 바로가기 생성
```

---

## 2. 산출물 정의

### 2.1 최종 산출물

| OS | 파일명 | 형식 | 용량 |
|----|--------|------|------|
| Windows x64 | MuLa_Setup_x64.exe | NSIS 설치 마법사 | ~80MB |
| Windows x86 | MuLa_Setup_x86.exe | NSIS 설치 마법사 | ~80MB |
| macOS Universal | MuLa_Installer.dmg | DMG + 앱 번들 | ~50MB |
| Linux x86_64 | mula_install.sh | Shell 스크립트 | ~5KB |

### 2.2 설치 프로그램이 설치하는 것

```
설치 완료 후 사용자 PC 구성:

~/.mulastudio/ (또는 %LOCALAPPDATA%\MuLaStudio)
├── python/                    # 내장 Python 3.10
│   ├── python.exe (또는 python3)
│   └── Lib/site-packages/
│       ├── torch/             # PyTorch
│       ├── gradio/            # Gradio UI
│       └── heartlib/          # HeartMuLa
├── models/                    # AI 모델 (~6GB)
│   ├── HeartMuLa-oss-3B/
│   └── HeartCodec-oss/
├── app/
│   └── main.py                # 실행 스크립트
└── run.bat (또는 run.sh)      # 실행 파일
```

---

## 3. 설치 프로그램 상세 설계

### 3.1 공통 설치 로직

```
┌─────────────────────────────────────────────────────────────┐
│                    설치 프로세스 플로우                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [STEP 1] 시스템 체크                                       │
│      ├── OS 버전 확인                                       │
│      ├── 아키텍처 확인 (x64/x86/arm64)                      │
│      ├── 디스크 공간 확인 (최소 15GB)                       │
│      ├── RAM 확인 (최소 8GB, 권장 16GB)                     │
│      └── GPU 감지 (NVIDIA/Apple Silicon/None)              │
│                                                             │
│  [STEP 2] Python 환경 설치                                  │
│      ├── Embedded Python 압축 해제                         │
│      ├── pip 설치 (ensurepip)                              │
│      └── 경로 설정                                          │
│                                                             │
│  [STEP 3] 의존성 설치                                       │
│      ├── GPU 유형에 따른 PyTorch 설치                       │
│      │   ├── NVIDIA → CUDA 버전                            │
│      │   ├── Apple Silicon → MPS 버전                      │
│      │   └── None → CPU 버전                               │
│      ├── Gradio 설치                                        │
│      └── HeartMuLa (heartlib) 설치                         │
│                                                             │
│  [STEP 4] 모델 다운로드                                     │
│      ├── HeartMuLa-oss-3B (~4GB)                           │
│      ├── HeartCodec-oss (~2GB)                             │
│      └── 진행률 표시                                        │
│                                                             │
│  [STEP 5] 실행 환경 구성                                    │
│      ├── 실행 스크립트 생성                                 │
│      ├── 바탕화면 바로가기 생성                             │
│      └── 시작 메뉴 등록 (Windows)                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

### 3.2 Windows 설치 프로그램 (NSIS)

#### 3.2.1 설치 마법사 화면

```
┌─────────────────────────────────────────┐
│  MuLa Studio Setup                      │
├─────────────────────────────────────────┤
│                                         │
│  [화면 1] 환영                          │
│    "MuLa Studio 설치를 시작합니다"      │
│                                         │
│  [화면 2] 시스템 체크 결과              │
│    ✓ Windows 11 x64                    │
│    ✓ RAM: 32GB                         │
│    ✓ 디스크: 50GB 여유                 │
│    ✓ GPU: NVIDIA RTX 3080 감지         │
│      → CUDA 가속 모드로 설치됩니다     │
│                                         │
│  [화면 3] 설치 진행                     │
│    ████████████░░░░░░░░ 60%            │
│    "PyTorch 설치 중..."                │
│                                         │
│  [화면 4] 모델 다운로드                 │
│    ████████░░░░░░░░░░░░ 40%            │
│    "HeartMuLa-oss-3B (2.1/4.2GB)"      │
│                                         │
│  [화면 5] 완료                          │
│    ✓ 설치 완료!                        │
│    □ 바탕화면 바로가기 만들기          │
│    □ 지금 실행                         │
│                                         │
│         [< 이전] [다음 >] [취소]        │
└─────────────────────────────────────────┘
```

#### 3.2.2 NSIS 스크립트 핵심 코드

```nsis
; MuLaInstaller.nsi

!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "LogicLib.nsh"

Name "MuLa Studio"
OutFile "MuLa_Setup_x64.exe"
InstallDir "$LOCALAPPDATA\MuLaStudio"
RequestExecutionLevel user

; 변수
Var GPU_TYPE      ; "cuda", "cpu"
Var TOTAL_RAM
Var FREE_DISK

;─────────────────────────────────────────
; 페이지 정의
;─────────────────────────────────────────
!insertmacro MUI_PAGE_WELCOME
Page custom SystemCheckPage SystemCheckPageLeave
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "Korean"

;─────────────────────────────────────────
; 시스템 체크 페이지
;─────────────────────────────────────────
Function SystemCheckPage
    nsDialogs::Create 1018
    Pop $0
    
    ; GPU 감지
    nsExec::ExecToStack 'cmd /c "nvidia-smi --query-gpu=name --format=csv,noheader 2>nul"'
    Pop $0
    Pop $1
    ${If} $0 == 0
        StrCpy $GPU_TYPE "cuda"
        ${NSD_CreateLabel} 0 0 100% 12u "✓ NVIDIA GPU 감지: $1"
    ${Else}
        StrCpy $GPU_TYPE "cpu"
        ${NSD_CreateLabel} 0 0 100% 12u "⚠ GPU 미감지 - CPU 모드 (느림)"
    ${EndIf}
    
    ; RAM 체크
    System::Alloc 64
    Pop $0
    System::Call 'kernel32::GlobalMemoryStatusEx(p r0)'
    System::Call '*$0(i, i, l .r1, l, l, l, l, l, l)'
    System::Free $0
    IntOp $TOTAL_RAM $1 / 1073741824  ; bytes to GB
    ${NSD_CreateLabel} 0 20u 100% 12u "RAM: $TOTAL_RAM GB"
    
    ; 디스크 공간
    ${GetRoot} "$INSTDIR" $0
    System::Call 'kernel32::GetDiskFreeSpaceEx(t r0, *l .r1, *l, *l)'
    IntOp $FREE_DISK $1 / 1073741824
    ${NSD_CreateLabel} 0 40u 100% 12u "여유 공간: $FREE_DISK GB"
    
    ${If} $FREE_DISK < 15
        ${NSD_CreateLabel} 0 60u 100% 12u "⚠ 최소 15GB 필요합니다!"
        GetDlgItem $0 $HWNDPARENT 1  ; Next 버튼
        EnableWindow $0 0
    ${EndIf}
    
    nsDialogs::Show
FunctionEnd

Function SystemCheckPageLeave
FunctionEnd

;─────────────────────────────────────────
; 메인 설치 섹션
;─────────────────────────────────────────
Section "Install"
    SetOutPath "$INSTDIR"
    
    ;─────────────────────────────────
    ; Step 1: Python 환경 설치
    ;─────────────────────────────────
    DetailPrint "Python 환경 설치 중..."
    SetOutPath "$INSTDIR\python"
    File /r "python-3.10-embed-amd64\*.*"
    
    ; pip 설치
    DetailPrint "pip 설치 중..."
    nsExec::ExecToLog '"$INSTDIR\python\python.exe" -m ensurepip --upgrade'
    
    ; pip.ini 설정 (타임아웃 증가)
    FileOpen $0 "$INSTDIR\python\pip.ini" w
    FileWrite $0 "[global]$\r$\n"
    FileWrite $0 "timeout = 120$\r$\n"
    FileClose $0
    
    ;─────────────────────────────────
    ; Step 2: PyTorch 설치
    ;─────────────────────────────────
    DetailPrint "PyTorch 설치 중... (몇 분 소요)"
    
    ${If} $GPU_TYPE == "cuda"
        nsExec::ExecToLog '"$INSTDIR\python\python.exe" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118'
    ${Else}
        nsExec::ExecToLog '"$INSTDIR\python\python.exe" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu'
    ${EndIf}
    
    ;─────────────────────────────────
    ; Step 3: 의존성 설치
    ;─────────────────────────────────
    DetailPrint "의존성 설치 중..."
    nsExec::ExecToLog '"$INSTDIR\python\python.exe" -m pip install gradio huggingface_hub tqdm'
    nsExec::ExecToLog '"$INSTDIR\python\python.exe" -m pip install git+https://github.com/HeartMuLa/heartlib.git'
    
    ;─────────────────────────────────
    ; Step 4: 앱 파일 복사
    ;─────────────────────────────────
    SetOutPath "$INSTDIR\app"
    File "app\main.py"
    File "app\download_models.py"
    
    ;─────────────────────────────────
    ; Step 5: 모델 다운로드
    ;─────────────────────────────────
    DetailPrint "AI 모델 다운로드 중... (약 6GB, 10-30분 소요)"
    nsExec::ExecToLog '"$INSTDIR\python\python.exe" "$INSTDIR\app\download_models.py" "$INSTDIR\models"'
    
    ;─────────────────────────────────
    ; Step 6: 실행 파일 생성
    ;─────────────────────────────────
    FileOpen $0 "$INSTDIR\run.bat" w
    FileWrite $0 '@echo off$\r$\n'
    FileWrite $0 'cd /d "$INSTDIR"$\r$\n'
    FileWrite $0 'start "" http://127.0.0.1:7860$\r$\n'
    FileWrite $0 '"$INSTDIR\python\python.exe" "$INSTDIR\app\main.py"$\r$\n'
    FileClose $0
    
    ;─────────────────────────────────
    ; Step 7: 바로가기 생성
    ;─────────────────────────────────
    CreateShortCut "$DESKTOP\MuLa Studio.lnk" "$INSTDIR\run.bat" "" "$INSTDIR\icon.ico"
    
    CreateDirectory "$SMPROGRAMS\MuLa Studio"
    CreateShortCut "$SMPROGRAMS\MuLa Studio\MuLa Studio.lnk" "$INSTDIR\run.bat" "" "$INSTDIR\icon.ico"
    CreateShortCut "$SMPROGRAMS\MuLa Studio\제거.lnk" "$INSTDIR\Uninstall.exe"
    
    ;─────────────────────────────────
    ; 제거 프로그램
    ;─────────────────────────────────
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    
    ; 프로그램 추가/제거 등록
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio" \
                     "DisplayName" "MuLa Studio"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio" \
                     "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio" \
                     "DisplayIcon" "$INSTDIR\icon.ico"
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio" \
                     "EstimatedSize" 7340032  ; ~7GB in KB
SectionEnd

;─────────────────────────────────────────
; 제거 섹션
;─────────────────────────────────────────
Section "Uninstall"
    RMDir /r "$INSTDIR"
    Delete "$DESKTOP\MuLa Studio.lnk"
    RMDir /r "$SMPROGRAMS\MuLa Studio"
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio"
SectionEnd
```

#### 3.2.3 Windows x86 (32비트) 차이점

```nsis
; 32비트 버전 차이점

OutFile "MuLa_Setup_x86.exe"
InstallDir "$PROGRAMFILES\MuLaStudio"  ; 32비트 경로

; Python 32비트 버전 사용
File /r "python-3.10-embed-win32\*.*"

; PyTorch CPU 전용 (32비트는 CUDA 미지원)
nsExec::ExecToLog '"$INSTDIR\python\python.exe" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu'

; 경고 메시지
DetailPrint "⚠ 32비트 시스템은 CPU 전용입니다. 생성 속도가 매우 느립니다."
```

---

### 3.3 macOS 설치 프로그램 (DMG)

#### 3.3.1 앱 번들 구조

```
MuLa Installer.app/
├── Contents/
│   ├── Info.plist
│   ├── MacOS/
│   │   └── install              # 설치 스크립트 (실행 파일)
│   ├── Resources/
│   │   ├── icon.icns
│   │   ├── install.sh           # 실제 설치 로직
│   │   └── requirements.txt
│   └── Frameworks/
└── README.txt
```

#### 3.3.2 install.sh (macOS 설치 스크립트)

```bash
#!/bin/bash
#
# MuLa Studio Installer for macOS
# 지원: macOS 12+ (Intel & Apple Silicon)
#

set -e

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="$HOME/.mulastudio"
MODEL_DIR="$INSTALL_DIR/models"

log() { echo -e "${GREEN}[설치]${NC} $1"; }
warn() { echo -e "${YELLOW}[경고]${NC} $1"; }
error() { echo -e "${RED}[오류]${NC} $1"; exit 1; }

# GUI 알림
notify() {
    osascript -e "display notification \"$1\" with title \"MuLa Studio\""
}

dialog() {
    osascript -e "display dialog \"$1\" with title \"MuLa Studio\" buttons {\"$2\"} default button 1"
}

progress_dialog() {
    osascript << EOF
tell application "System Events"
    display dialog "$1" with title "MuLa Studio 설치" buttons {"설치 중..."} giving up after 1
end tell
EOF
}

#─────────────────────────────────────────
# 시스템 체크
#─────────────────────────────────────────
check_system() {
    log "시스템 확인 중..."
    
    # macOS 버전
    OS_VERSION=$(sw_vers -productVersion)
    log "macOS 버전: $OS_VERSION"
    
    # 아키텍처 (Intel vs Apple Silicon)
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        log "Apple Silicon 감지 (MPS 가속 사용)"
        GPU_MODE="mps"
    else
        log "Intel Mac 감지 (CPU 모드)"
        GPU_MODE="cpu"
    fi
    
    # 디스크 공간
    FREE_SPACE=$(df -g "$HOME" | awk 'NR==2 {print $4}')
    if [[ "$FREE_SPACE" -lt 15 ]]; then
        dialog "디스크 공간이 부족합니다.\n최소 15GB 필요 (현재: ${FREE_SPACE}GB)" "확인"
        exit 1
    fi
    log "여유 공간: ${FREE_SPACE}GB"
    
    # RAM
    RAM_GB=$(sysctl -n hw.memsize | awk '{print int($1/1073741824)}')
    log "RAM: ${RAM_GB}GB"
    if [[ "$RAM_GB" -lt 8 ]]; then
        warn "RAM이 8GB 미만입니다. 성능이 제한될 수 있습니다."
    fi
}

#─────────────────────────────────────────
# Python 환경 설치
#─────────────────────────────────────────
install_python() {
    log "Python 환경 구성 중..."
    
    # Homebrew Python 확인
    if ! command -v python3 &> /dev/null; then
        dialog "Python3가 필요합니다.\n\nHomebrew로 설치하시겠습니까?" "설치"
        
        # Homebrew 설치
        if ! command -v brew &> /dev/null; then
            log "Homebrew 설치 중..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        log "Python 설치 중..."
        brew install python@3.10
    fi
    
    # 가상환경 생성
    log "가상환경 생성 중..."
    mkdir -p "$INSTALL_DIR"
    python3 -m venv "$INSTALL_DIR/venv"
    source "$INSTALL_DIR/venv/bin/activate"
    
    pip install --upgrade pip wheel
}

#─────────────────────────────────────────
# PyTorch 및 의존성 설치
#─────────────────────────────────────────
install_dependencies() {
    source "$INSTALL_DIR/venv/bin/activate"
    
    log "PyTorch 설치 중... (몇 분 소요)"
    
    # Apple Silicon vs Intel
    if [[ "$GPU_MODE" == "mps" ]]; then
        pip install torch torchvision torchaudio
    else
        pip install torch torchvision torchaudio
    fi
    
    log "의존성 설치 중..."
    pip install gradio huggingface_hub tqdm
    pip install git+https://github.com/HeartMuLa/heartlib.git
}

#─────────────────────────────────────────
# 모델 다운로드
#─────────────────────────────────────────
download_models() {
    source "$INSTALL_DIR/venv/bin/activate"
    
    log "AI 모델 다운로드 중... (약 6GB)"
    notify "모델 다운로드 중... 10-30분 소요됩니다."
    
    mkdir -p "$MODEL_DIR"
    
    python3 << EOF
from huggingface_hub import snapshot_download
import os

model_dir = "$MODEL_DIR"

print("  [1/3] HeartMuLaGen...")
snapshot_download('HeartMuLa/HeartMuLaGen', local_dir=model_dir)

print("  [2/3] HeartMuLa-oss-3B...")
snapshot_download('HeartMuLa/HeartMuLa-oss-3B', 
                  local_dir=os.path.join(model_dir, 'HeartMuLa-oss-3B'))

print("  [3/3] HeartCodec-oss...")
snapshot_download('HeartMuLa/HeartCodec-oss', 
                  local_dir=os.path.join(model_dir, 'HeartCodec-oss'))

print("  ✓ 완료!")
EOF
}

#─────────────────────────────────────────
# 앱 파일 및 실행 스크립트 생성
#─────────────────────────────────────────
create_app() {
    log "앱 파일 생성 중..."
    
    mkdir -p "$INSTALL_DIR/app"
    
    # main.py 복사 (리소스에서)
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [[ -f "$SCRIPT_DIR/../Resources/main.py" ]]; then
        cp "$SCRIPT_DIR/../Resources/main.py" "$INSTALL_DIR/app/"
    else
        # 인라인으로 생성 (간단한 Gradio 앱)
        create_main_py
    fi
    
    # 실행 스크립트
    cat > "$INSTALL_DIR/run.command" << 'RUNEOF'
#!/bin/bash
cd "$HOME/.mulastudio"
source venv/bin/activate
open "http://127.0.0.1:7860"
python app/main.py
RUNEOF
    chmod +x "$INSTALL_DIR/run.command"
    
    # 바탕화면 바로가기 (Alias)
    if [[ -d "$HOME/Desktop" ]]; then
        ln -sf "$INSTALL_DIR/run.command" "$HOME/Desktop/MuLa Studio"
    fi
}

create_main_py() {
    cat > "$INSTALL_DIR/app/main.py" << 'PYEOF'
#!/usr/bin/env python3
import gradio as gr
import torch
import os
from pathlib import Path

MODEL_DIR = Path.home() / ".mulastudio" / "models"
OUTPUT_DIR = Path.home() / "Documents" / "MuLaStudio_Outputs"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# 디바이스
if torch.backends.mps.is_available():
    DEVICE = "mps"
    DEVICE_NAME = "Apple Silicon (MPS)"
elif torch.cuda.is_available():
    DEVICE = "cuda"
    DEVICE_NAME = torch.cuda.get_device_name(0)
else:
    DEVICE = "cpu"
    DEVICE_NAME = "CPU"

model = None

def load_model():
    global model
    if model is None:
        from heartlib import HeartMuLaInfer
        model = HeartMuLaInfer(model_path=str(MODEL_DIR), version="3B")
    return model

def generate(lyrics, tags, length, temp, cfg):
    from datetime import datetime
    m = load_model()
    
    output_path = OUTPUT_DIR / f"music_{datetime.now():%Y%m%d_%H%M%S}.mp3"
    
    m.generate(
        lyrics=lyrics,
        tags=tags,
        max_audio_length_ms=int(length * 1000),
        temperature=temp,
        cfg_scale=cfg,
        save_path=str(output_path)
    )
    
    return str(output_path), f"완료: {output_path.name}"

with gr.Blocks(title="MuLa Studio") as app:
    gr.Markdown(f"# MuLa Studio\n실행 환경: {DEVICE_NAME}")
    
    with gr.Row():
        lyrics = gr.Textbox(label="가사", lines=10, value="[Verse]\nHello world")
        with gr.Column():
            tags = gr.Textbox(label="태그", value="piano, happy")
            length = gr.Slider(30, 240, 120, label="길이(초)")
            temp = gr.Slider(0.5, 1.5, 1.0, label="Temperature")
            cfg = gr.Slider(1.0, 3.0, 1.5, label="CFG Scale")
            btn = gr.Button("생성", variant="primary")
    
    status = gr.Textbox(label="상태")
    audio = gr.Audio(label="결과", type="filepath")
    
    btn.click(generate, [lyrics, tags, length, temp, cfg], [audio, status])

app.launch(server_name="127.0.0.1", server_port=7860, inbrowser=True)
PYEOF
}

#─────────────────────────────────────────
# 메인
#─────────────────────────────────────────
main() {
    dialog "MuLa Studio를 설치합니다.\n\n약 15-30분이 소요됩니다." "설치 시작"
    
    check_system
    install_python
    install_dependencies
    download_models
    create_app
    
    notify "설치 완료!"
    dialog "설치가 완료되었습니다!\n\n바탕화면의 'MuLa Studio'를 실행하세요." "확인"
    
    # 바로 실행 옵션
    osascript -e 'display dialog "지금 바로 실행하시겠습니까?" buttons {"나중에", "실행"} default button "실행"' && \
        open "$INSTALL_DIR/run.command"
}

main "$@"
```

---

### 3.4 Linux 설치 프로그램 (Shell Script)

#### 3.4.1 mula_install.sh

```bash
#!/bin/bash
#
# MuLa Studio Installer for Linux
# 지원: Ubuntu 20.04+, Debian 11+, Fedora 35+, Arch
#

set -e

VERSION="1.0.0"
INSTALL_DIR="$HOME/.mulastudio"
MODEL_DIR="$INSTALL_DIR/models"
BIN_DIR="$HOME/.local/bin"

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         MuLa Studio Installer v${VERSION}                     ║"
echo "║         HeartMuLa AI 음악 생성 환경 설치                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
step() { echo -e "\n${BLUE}[STEP]${NC} ${BOLD}$1${NC}"; }

#─────────────────────────────────────────
# 시스템 체크
#─────────────────────────────────────────
check_system() {
    step "시스템 확인"
    
    # 아키텍처
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" ]]; then
        error "x86_64 아키텍처만 지원합니다. (현재: $ARCH)"
    fi
    log "아키텍처: $ARCH"
    
    # 배포판
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        log "OS: $NAME $VERSION_ID"
    fi
    
    # Python 확인
    if ! command -v python3 &> /dev/null; then
        warn "Python3가 설치되어 있지 않습니다."
        echo ""
        echo "  설치 명령:"
        echo "    Ubuntu/Debian: sudo apt install python3 python3-pip python3-venv"
        echo "    Fedora:        sudo dnf install python3 python3-pip"
        echo "    Arch:          sudo pacman -S python python-pip"
        echo ""
        read -p "계속하시겠습니까? (Python이 설치되어 있다면 y) [y/N] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    else
        PYTHON_VER=$(python3 --version)
        log "Python: $PYTHON_VER"
    fi
    
    # GPU 확인
    if command -v nvidia-smi &> /dev/null; then
        GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
        GPU_MEM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1)
        log "GPU: $GPU_NAME ($GPU_MEM)"
        GPU_MODE="cuda"
    else
        warn "NVIDIA GPU 미감지 → CPU 모드 (매우 느림)"
        GPU_MODE="cpu"
    fi
    
    # 디스크 공간
    FREE_GB=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | tr -d 'G')
    if [[ "$FREE_GB" -lt 15 ]]; then
        error "디스크 공간 부족! 최소 15GB 필요 (현재: ${FREE_GB}GB)"
    fi
    log "여유 공간: ${FREE_GB}GB"
    
    # RAM
    RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
    log "RAM: ${RAM_GB}GB"
    if [[ "$RAM_GB" -lt 8 ]]; then
        warn "RAM이 8GB 미만입니다."
    fi
}

#─────────────────────────────────────────
# Python 환경 설치
#─────────────────────────────────────────
install_python_env() {
    step "Python 가상환경 생성"
    
    mkdir -p "$INSTALL_DIR"
    python3 -m venv "$INSTALL_DIR/venv"
    source "$INSTALL_DIR/venv/bin/activate"
    
    pip install --upgrade pip wheel setuptools
    log "가상환경 생성 완료"
}

#─────────────────────────────────────────
# 의존성 설치
#─────────────────────────────────────────
install_dependencies() {
    step "의존성 설치"
    
    source "$INSTALL_DIR/venv/bin/activate"
    
    echo -e "  PyTorch 설치 중... (${GPU_MODE} 모드)"
    if [[ "$GPU_MODE" == "cuda" ]]; then
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    else
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    fi
    log "PyTorch 설치 완료"
    
    echo "  추가 패키지 설치 중..."
    pip install gradio huggingface_hub tqdm requests
    pip install git+https://github.com/HeartMuLa/heartlib.git
    log "의존성 설치 완료"
}

#─────────────────────────────────────────
# 모델 다운로드
#─────────────────────────────────────────
download_models() {
    step "AI 모델 다운로드 (약 6GB)"
    
    source "$INSTALL_DIR/venv/bin/activate"
    mkdir -p "$MODEL_DIR"
    
    python3 << EOF
from huggingface_hub import snapshot_download
import os

model_dir = "$MODEL_DIR"

print("  [1/3] HeartMuLaGen 다운로드...")
snapshot_download('HeartMuLa/HeartMuLaGen', local_dir=model_dir)

print("  [2/3] HeartMuLa-oss-3B 다운로드...")
snapshot_download('HeartMuLa/HeartMuLa-oss-3B', 
                  local_dir=os.path.join(model_dir, 'HeartMuLa-oss-3B'))

print("  [3/3] HeartCodec-oss 다운로드...")
snapshot_download('HeartMuLa/HeartCodec-oss', 
                  local_dir=os.path.join(model_dir, 'HeartCodec-oss'))
EOF
    
    log "모델 다운로드 완료"
}

#─────────────────────────────────────────
# 앱 파일 생성
#─────────────────────────────────────────
create_app() {
    step "앱 파일 생성"
    
    mkdir -p "$INSTALL_DIR/app"
    
    # main.py 생성 (간단한 Gradio 앱)
    cat > "$INSTALL_DIR/app/main.py" << 'PYEOF'
#!/usr/bin/env python3
import gradio as gr
import torch
import os
from pathlib import Path
from datetime import datetime

MODEL_DIR = Path.home() / ".mulastudio" / "models"
OUTPUT_DIR = Path.home() / "MuLaStudio_Outputs"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

if torch.cuda.is_available():
    DEVICE = "cuda"
    DEVICE_NAME = torch.cuda.get_device_name(0)
else:
    DEVICE = "cpu"
    DEVICE_NAME = "CPU"

model = None

def load_model():
    global model
    if model is None:
        import sys
        sys.path.insert(0, str(MODEL_DIR))
        from heartlib import HeartMuLaInfer
        model = HeartMuLaInfer(model_path=str(MODEL_DIR), version="3B")
    return model

def generate(lyrics, tags, length, temp, cfg, progress=gr.Progress()):
    progress(0.1, "모델 로딩...")
    m = load_model()
    
    progress(0.2, "음악 생성 중...")
    output_path = OUTPUT_DIR / f"music_{datetime.now():%Y%m%d_%H%M%S}.mp3"
    
    m.generate(
        lyrics=lyrics,
        tags=tags,
        max_audio_length_ms=int(length * 1000),
        temperature=temp,
        cfg_scale=cfg,
        save_path=str(output_path)
    )
    
    progress(1.0, "완료!")
    return str(output_path), f"저장: {output_path}"

SAMPLE = """[Verse]
The morning light comes through the window
A brand new day is here

[Chorus]
We rise again, we start again
Every day is a new begin"""

with gr.Blocks(title="MuLa Studio") as app:
    gr.Markdown(f"# MuLa Studio\n**실행 환경**: {DEVICE_NAME}")
    
    with gr.Row():
        with gr.Column(scale=2):
            lyrics = gr.Textbox(label="가사", lines=12, value=SAMPLE)
            tags = gr.Textbox(label="스타일 태그", value="piano, happy, pop")
        with gr.Column(scale=1):
            length = gr.Slider(30, 240, 120, step=10, label="길이(초)")
            temp = gr.Slider(0.5, 1.5, 1.0, step=0.1, label="Temperature")
            cfg = gr.Slider(1.0, 3.0, 1.5, step=0.1, label="CFG Scale")
            btn = gr.Button("♪ 음악 생성", variant="primary", size="lg")
    
    status = gr.Textbox(label="상태")
    audio = gr.Audio(label="생성된 음악", type="filepath")
    
    btn.click(generate, [lyrics, tags, length, temp, cfg], [audio, status])
    
    gr.Markdown("---\n*Powered by HeartMuLa (CC BY-NC 4.0)*")

if __name__ == "__main__":
    app.launch(server_name="127.0.0.1", server_port=7860, inbrowser=True)
PYEOF
    
    log "앱 파일 생성 완료"
}

#─────────────────────────────────────────
# 실행 스크립트 및 바로가기
#─────────────────────────────────────────
create_launcher() {
    step "실행 환경 구성"
    
    mkdir -p "$BIN_DIR"
    
    # 실행 스크립트
    cat > "$BIN_DIR/mulastudio" << EOF
#!/bin/bash
source "$INSTALL_DIR/venv/bin/activate"
xdg-open "http://127.0.0.1:7860" 2>/dev/null &
python "$INSTALL_DIR/app/main.py"
EOF
    chmod +x "$BIN_DIR/mulastudio"
    
    # .desktop 파일
    DESKTOP_DIR="$HOME/.local/share/applications"
    mkdir -p "$DESKTOP_DIR"
    
    cat > "$DESKTOP_DIR/mulastudio.desktop" << EOF
[Desktop Entry]
Name=MuLa Studio
Comment=AI Music Generator
Exec=$BIN_DIR/mulastudio
Icon=audio-x-generic
Terminal=false
Type=Application
Categories=Audio;Music;
EOF
    
    # 바탕화면 복사
    for dir in "$HOME/Desktop" "$HOME/바탕화면"; do
        if [[ -d "$dir" ]]; then
            cp "$DESKTOP_DIR/mulastudio.desktop" "$dir/"
            chmod +x "$dir/mulastudio.desktop"
        fi
    done
    
    log "실행 환경 구성 완료"
    
    # PATH 확인
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        warn "PATH에 ~/.local/bin이 없습니다."
        echo "  다음을 ~/.bashrc 또는 ~/.zshrc에 추가하세요:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

#─────────────────────────────────────────
# 제거 스크립트 생성
#─────────────────────────────────────────
create_uninstaller() {
    cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash
echo "MuLa Studio 제거 중..."
rm -rf "$HOME/.mulastudio"
rm -f "$HOME/.local/bin/mulastudio"
rm -f "$HOME/.local/share/applications/mulastudio.desktop"
rm -f "$HOME/Desktop/mulastudio.desktop" 2>/dev/null
rm -f "$HOME/바탕화면/mulastudio.desktop" 2>/dev/null
echo "제거 완료! (출력 폴더 ~/MuLaStudio_Outputs는 유지됩니다)"
EOF
    chmod +x "$INSTALL_DIR/uninstall.sh"
}

#─────────────────────────────────────────
# 메인
#─────────────────────────────────────────
main() {
    echo ""
    read -p "설치를 시작하시겠습니까? (약 15-30분 소요) [Y/n] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Nn]$ ]] && exit 0
    
    check_system
    install_python_env
    install_dependencies
    download_models
    create_app
    create_launcher
    create_uninstaller
    
    echo ""
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  설치 완료!${NC}"
    echo ""
    echo "  실행 방법:"
    echo "    1. 터미널: mulastudio"
    echo "    2. 바탕화면 아이콘 더블클릭"
    echo ""
    echo "  제거: ~/.mulastudio/uninstall.sh"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════${NC}"
    
    read -p "지금 바로 실행하시겠습니까? [Y/n] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Nn]$ ]] && "$BIN_DIR/mulastudio"
}

main "$@"
```

---

## 4. 개발 환경 및 빌드

### 4.1 개발 환경

| 항목 | 도구 |
|------|------|
| Windows 빌드 | NSIS 3.x, Windows 10/11 |
| Mac 빌드 | macOS 12+, create-dmg |
| Linux 테스트 | Ubuntu 20.04/22.04, Fedora, Arch |
| 버전 관리 | Git, GitHub |

### 4.2 빌드 프로세스

#### Windows
```batch
:: build_windows.bat
makensis /DVERSION=1.0.0 MuLaInstaller.nsi
:: 출력: MuLa_Setup_x64.exe, MuLa_Setup_x86.exe
```

#### macOS
```bash
# build_mac.sh
# 앱 번들 생성 후
create-dmg \
  --volname "MuLa Studio" \
  --window-size 600 400 \
  --icon "MuLa Installer.app" 150 150 \
  --app-drop-link 450 150 \
  "MuLa_Installer.dmg" \
  "MuLa Installer.app"
```

#### Linux
```bash
# 스크립트 자체가 설치 프로그램
# GitHub Releases에 mula_install.sh 업로드
```

---

## 5. 개발 일정 (4주)

| 주차 | 작업 | 산출물 |
|------|------|--------|
| W1 | Windows NSIS 설치 프로그램 | MuLa_Setup_x64.exe, x86.exe |
| W2 | macOS DMG 설치 프로그램 | MuLa_Installer.dmg |
| W3 | Linux 설치 스크립트 | mula_install.sh |
| W4 | 테스트 및 버그 수정 | 최종 릴리즈 |

### 상세 일정

```
Week 1: Windows
├── Day 1-2: NSIS 스크립트 작성
├── Day 3: GPU 감지 로직
├── Day 4: 모델 다운로드 통합
└── Day 5: x64/x86 빌드 및 테스트

Week 2: macOS
├── Day 1-2: 설치 스크립트 작성
├── Day 3: 앱 번들 구성
├── Day 4: DMG 생성
└── Day 5: Intel/Apple Silicon 테스트

Week 3: Linux
├── Day 1-2: install.sh 작성
├── Day 3: 배포판별 테스트 (Ubuntu, Fedora)
├── Day 4: 바탕화면 통합
└── Day 5: 문서 작성

Week 4: 마무리
├── Day 1-2: 전체 플랫폼 크로스 테스트
├── Day 3: 버그 수정
├── Day 4: GitHub Releases 등록
└── Day 5: README 작성
```

---

## 6. 테스트 체크리스트

### 6.1 설치 테스트

| 테스트 항목 | Win x64 | Win x86 | Mac ARM | Mac Intel | Linux |
|------------|---------|---------|---------|-----------|-------|
| 클린 설치 | □ | □ | □ | □ | □ |
| 디스크 공간 부족 시 경고 | □ | □ | □ | □ | □ |
| GPU 자동 감지 | □ | □ | □ | □ | □ |
| PyTorch 설치 | □ | □ | □ | □ | □ |
| 모델 다운로드 | □ | □ | □ | □ | □ |
| 바로가기 생성 | □ | □ | □ | □ | □ |
| 실행 확인 | □ | □ | □ | □ | □ |
| 제거 | □ | □ | □ | □ | □ |

### 6.2 실행 테스트

| 테스트 항목 | 예상 결과 |
|------------|----------|
| 브라우저 자동 열림 | http://127.0.0.1:7860 |
| Gradio UI 로드 | 정상 표시 |
| 음악 생성 (GPU) | 2-5분 내 완료 |
| 음악 생성 (CPU) | 30분+ (정상) |
| 출력 파일 저장 | ~/MuLaStudio_Outputs/ |

---

## 7. 파일 배포

### 7.1 GitHub Releases

```
MuLa-Studio-v1.0.0/
├── MuLa_Setup_x64.exe       (Windows 64비트)
├── MuLa_Setup_x86.exe       (Windows 32비트)
├── MuLa_Installer.dmg       (macOS Universal)
├── mula_install.sh          (Linux)
├── README.md
├── LICENSE                  (CC BY-NC 4.0)
└── checksums.txt            (SHA256)
```

### 7.2 다운로드 안내 (README)

```markdown
## 다운로드

| OS | 다운로드 | 비고 |
|----|----------|------|
| Windows 64비트 | [MuLa_Setup_x64.exe](링크) | 권장 |
| Windows 32비트 | [MuLa_Setup_x86.exe](링크) | CPU 전용 |
| macOS | [MuLa_Installer.dmg](링크) | Intel & Apple Silicon |
| Linux | [mula_install.sh](링크) | Ubuntu, Fedora 등 |

### 설치 방법

**Windows**: 다운로드 → 더블클릭 → "다음" 클릭
**macOS**: 다운로드 → 더블클릭 → 앱 드래그
**Linux**: `chmod +x mula_install.sh && ./mula_install.sh`

### 시스템 요구사항

- RAM: 최소 8GB, 권장 16GB+
- 저장공간: 15GB 이상
- GPU (권장): NVIDIA RTX 2060+ 또는 Apple M1+
```

---

## 8. 향후 계획 (서비스)

> **현재 범위 외** - 설치 프로그램 완성 후 검토

```
Phase 2 (향후)
├── 홈페이지 개발
├── 다운로드 페이지
├── 사용자 가이드
└── 샘플 갤러리

Phase 3 (향후)
├── 자동 업데이트 기능
├── UI 개선
└── 다국어 지원
```

---

## 부록: 참고 자료

| 항목 | 링크 |
|------|------|
| NSIS 문서 | https://nsis.sourceforge.io/Docs |
| Python Embedded | https://www.python.org/downloads/windows/ |
| HeartMuLa | https://github.com/HeartMuLa/heartlib |
| create-dmg | https://github.com/create-dmg/create-dmg |

---

**문서 버전**: v1.0
**작성일**: 2026-01-18
**목적**: HeartMuLa 원클릭 설치 프로그램 개발