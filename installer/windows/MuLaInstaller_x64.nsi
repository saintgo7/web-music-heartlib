;------------------------------------------------------------------------------
; MuLa Studio Installer for Windows x64
; HeartMuLa AI Music Generator - One-Click Installer
;
; Requirements:
;   - NSIS 3.x (with MUI2, nsDialogs, LogicLib plugins)
;   - Python 3.10 embedded (download during build)
;
; Build command:
;   makensis /DVERSION=1.0.0 MuLaInstaller_x64.nsi
;------------------------------------------------------------------------------

!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "LogicLib.nsh"
!include "WinVer.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"

;------------------------------------------------------------------------------
; Installer Attributes
;------------------------------------------------------------------------------
!ifndef VERSION
    !define VERSION "1.0.0"
!endif

Name "MuLa Studio ${VERSION}"
OutFile "MuLa_Setup_x64.exe"
Unicode True
InstallDir "$LOCALAPPDATA\MuLaStudio"
InstallDirRegKey HKCU "Software\MuLaStudio" "InstallDir"
RequestExecutionLevel user

; Version information
VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "MuLa Studio"
VIAddVersionKey "CompanyName" "ABADA Inc."
VIAddVersionKey "LegalCopyright" "CC BY-NC 4.0"
VIAddVersionKey "FileDescription" "MuLa Studio Installer"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"

;------------------------------------------------------------------------------
; Variables
;------------------------------------------------------------------------------
Var GPU_TYPE          ; "cuda" or "cpu"
Var GPU_NAME          ; GPU device name
Var TOTAL_RAM_GB      ; RAM in GB
Var FREE_DISK_GB      ; Free disk space in GB
Var PYTHON_PATH       ; Path to embedded Python
Var DIALOG
Var LABEL_GPU
Var LABEL_RAM
Var LABEL_DISK
Var LABEL_STATUS

;------------------------------------------------------------------------------
; MUI Settings
;------------------------------------------------------------------------------
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\win.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\nsis.bmp"

; Welcome page text
!define MUI_WELCOMEPAGE_TITLE "MuLa Studio ${VERSION} Setup"
!define MUI_WELCOMEPAGE_TEXT "This wizard will install MuLa Studio on your computer.$\r$\n$\r$\nMuLa Studio uses HeartMuLa AI to generate music from lyrics.$\r$\n$\r$\nRequirements:$\r$\n  - 8GB+ RAM (16GB recommended)$\r$\n  - 15GB+ free disk space$\r$\n  - NVIDIA GPU (optional, for acceleration)$\r$\n$\r$\nClick Next to continue."

; Finish page options
!define MUI_FINISHPAGE_RUN "$INSTDIR\run.bat"
!define MUI_FINISHPAGE_RUN_TEXT "Launch MuLa Studio"
!define MUI_FINISHPAGE_SHOWREADME ""
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Create Desktop Shortcut"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION CreateDesktopShortcut
!define MUI_FINISHPAGE_LINK "Visit music.abada.kr"
!define MUI_FINISHPAGE_LINK_LOCATION "https://music.abada.kr"

;------------------------------------------------------------------------------
; Pages
;------------------------------------------------------------------------------
!insertmacro MUI_PAGE_WELCOME
Page custom SystemCheckPage SystemCheckPageLeave
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

;------------------------------------------------------------------------------
; Languages
;------------------------------------------------------------------------------
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Korean"

;------------------------------------------------------------------------------
; Installer Sections
;------------------------------------------------------------------------------
Section "MuLa Studio" SecMain
    SetOutPath "$INSTDIR"

    ; Create directories
    CreateDirectory "$INSTDIR\python"
    CreateDirectory "$INSTDIR\app"
    CreateDirectory "$INSTDIR\models"
    CreateDirectory "$INSTDIR\logs"

    ;------------------------------------------
    ; Step 1: Extract Python Embedded
    ;------------------------------------------
    DetailPrint "Setting up Python environment..."
    SetDetailsPrint textonly

    ; Check if Python embed zip exists, if not download it
    IfFileExists "$EXEDIR\python-3.10.11-embed-amd64.zip" 0 download_python
    CopyFiles /SILENT "$EXEDIR\python-3.10.11-embed-amd64.zip" "$INSTDIR\python\python-embed.zip"
    Goto extract_python

download_python:
    DetailPrint "Downloading Python 3.10 embedded..."
    NSISdl::download "https://www.python.org/ftp/python/3.10.11/python-3.10.11-embed-amd64.zip" "$INSTDIR\python\python-embed.zip"
    Pop $0
    StrCmp $0 "success" extract_python
    MessageBox MB_OK|MB_ICONEXCLAMATION "Failed to download Python. Please check your internet connection."
    Abort

extract_python:
    DetailPrint "Extracting Python..."
    nsisunz::Unzip "$INSTDIR\python\python-embed.zip" "$INSTDIR\python"
    Delete "$INSTDIR\python\python-embed.zip"

    StrCpy $PYTHON_PATH "$INSTDIR\python\python.exe"

    ;------------------------------------------
    ; Step 2: Configure Python for pip
    ;------------------------------------------
    DetailPrint "Configuring Python..."

    ; Modify python310._pth to enable site-packages
    FileOpen $0 "$INSTDIR\python\python310._pth" w
    FileWrite $0 "python310.zip$\r$\n"
    FileWrite $0 ".$\r$\n"
    FileWrite $0 "Lib$\r$\n"
    FileWrite $0 "Lib\site-packages$\r$\n"
    FileWrite $0 "$\r$\n"
    FileWrite $0 "import site$\r$\n"
    FileClose $0

    ; Create Lib and site-packages directories
    CreateDirectory "$INSTDIR\python\Lib"
    CreateDirectory "$INSTDIR\python\Lib\site-packages"

    ;------------------------------------------
    ; Step 3: Install pip
    ;------------------------------------------
    DetailPrint "Installing pip..."
    SetDetailsPrint both

    ; Download get-pip.py
    NSISdl::download "https://bootstrap.pypa.io/get-pip.py" "$INSTDIR\python\get-pip.py"
    Pop $0
    StrCmp $0 "success" install_pip
    MessageBox MB_OK|MB_ICONEXCLAMATION "Failed to download pip installer."
    Abort

install_pip:
    nsExec::ExecToLog '"$PYTHON_PATH" "$INSTDIR\python\get-pip.py" --no-warn-script-location'
    Pop $0
    Delete "$INSTDIR\python\get-pip.py"

    ; Create pip configuration for longer timeout
    CreateDirectory "$INSTDIR\python\pip"
    FileOpen $0 "$INSTDIR\python\pip\pip.ini" w
    FileWrite $0 "[global]$\r$\n"
    FileWrite $0 "timeout = 120$\r$\n"
    FileWrite $0 "retries = 5$\r$\n"
    FileWrite $0 "disable-pip-version-check = true$\r$\n"
    FileClose $0

    ;------------------------------------------
    ; Step 4: Install PyTorch
    ;------------------------------------------
    DetailPrint "Installing PyTorch (this may take several minutes)..."

    ${If} $GPU_TYPE == "cuda"
        DetailPrint "Installing PyTorch with CUDA support..."
        nsExec::ExecToLog '"$PYTHON_PATH" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 --no-cache-dir'
    ${Else}
        DetailPrint "Installing PyTorch (CPU version)..."
        nsExec::ExecToLog '"$PYTHON_PATH" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu --no-cache-dir'
    ${EndIf}
    Pop $0

    ;------------------------------------------
    ; Step 5: Install Dependencies
    ;------------------------------------------
    DetailPrint "Installing additional dependencies..."
    nsExec::ExecToLog '"$PYTHON_PATH" -m pip install gradio huggingface_hub tqdm requests --no-cache-dir'
    Pop $0

    DetailPrint "Installing HeartMuLa (heartlib)..."
    nsExec::ExecToLog '"$PYTHON_PATH" -m pip install git+https://github.com/saintgo7/web-music-heartlib.git --no-cache-dir'
    Pop $0

    ;------------------------------------------
    ; Step 6: Copy Application Files
    ;------------------------------------------
    DetailPrint "Copying application files..."
    SetOutPath "$INSTDIR\app"

    ; Copy main.py from installer package or create it
    IfFileExists "$EXEDIR\..\app\main.py" 0 create_main_py
    CopyFiles /SILENT "$EXEDIR\..\app\main.py" "$INSTDIR\app\main.py"
    Goto copy_download_script

create_main_py:
    ; Create main.py inline if not found
    FileOpen $0 "$INSTDIR\app\main.py" w
    FileWrite $0 '#!/usr/bin/env python3$\r$\n'
    FileWrite $0 '"""MuLa Studio - HeartMuLa AI Music Generator UI"""$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'import gradio as gr$\r$\n'
    FileWrite $0 'import torch$\r$\n'
    FileWrite $0 'import os$\r$\n'
    FileWrite $0 'from pathlib import Path$\r$\n'
    FileWrite $0 'from datetime import datetime$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'MODEL_DIR = Path.home() / ".mulastudio" / "models"$\r$\n'
    FileWrite $0 'OUTPUT_DIR = Path.home() / "Documents" / "MuLaStudio_Outputs"$\r$\n'
    FileWrite $0 'OUTPUT_DIR.mkdir(parents=True, exist_ok=True)$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'if torch.cuda.is_available():$\r$\n'
    FileWrite $0 '    DEVICE = "cuda"$\r$\n'
    FileWrite $0 '    DEVICE_NAME = torch.cuda.get_device_name(0)$\r$\n'
    FileWrite $0 'else:$\r$\n'
    FileWrite $0 '    DEVICE = "cpu"$\r$\n'
    FileWrite $0 '    DEVICE_NAME = "CPU"$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'model = None$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'def load_model():$\r$\n'
    FileWrite $0 '    global model$\r$\n'
    FileWrite $0 '    if model is None:$\r$\n'
    FileWrite $0 '        try:$\r$\n'
    FileWrite $0 '            from heartlib import HeartMuLaInfer$\r$\n'
    FileWrite $0 '            model = HeartMuLaInfer(model_path=str(MODEL_DIR), version="3B")$\r$\n'
    FileWrite $0 '        except Exception as e:$\r$\n'
    FileWrite $0 '            return None, f"Error loading model: {str(e)}"$\r$\n'
    FileWrite $0 '    return model, None$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'def generate(lyrics, tags, length, temp, cfg, progress=gr.Progress()):$\r$\n'
    FileWrite $0 '    try:$\r$\n'
    FileWrite $0 '        progress(0.1, "Loading model...")$\r$\n'
    FileWrite $0 '        m, error = load_model()$\r$\n'
    FileWrite $0 '        if error:$\r$\n'
    FileWrite $0 '            return None, error$\r$\n'
    FileWrite $0 '        progress(0.2, "Generating music...")$\r$\n'
    FileWrite $0 '        output_path = OUTPUT_DIR / f"music_{datetime.now():%Y%m%d_%H%M%S}.mp3"$\r$\n'
    FileWrite $0 '        m.generate($\r$\n'
    FileWrite $0 '            lyrics=lyrics,$\r$\n'
    FileWrite $0 '            tags=tags,$\r$\n'
    FileWrite $0 '            max_audio_length_ms=int(length * 1000),$\r$\n'
    FileWrite $0 '            temperature=temp,$\r$\n'
    FileWrite $0 '            cfg_scale=cfg,$\r$\n'
    FileWrite $0 '            save_path=str(output_path)$\r$\n'
    FileWrite $0 '        )$\r$\n'
    FileWrite $0 '        progress(1.0, "Complete!")$\r$\n'
    FileWrite $0 '        return str(output_path), f"Saved: {output_path.name}"$\r$\n'
    FileWrite $0 '    except Exception as e:$\r$\n'
    FileWrite $0 '        return None, f"Error: {str(e)}"$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'SAMPLE = """[Verse]$\r$\n'
    FileWrite $0 'The morning light comes through the window$\r$\n'
    FileWrite $0 'A brand new day is here$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 '[Chorus]$\r$\n'
    FileWrite $0 'We rise again, we start again$\r$\n'
    FileWrite $0 'Every day is a new begin"""$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'with gr.Blocks(title="MuLa Studio", theme=gr.themes.Soft()) as app:$\r$\n'
    FileWrite $0 '    gr.Markdown(f"# MuLa Studio$\\n**Device**: {DEVICE_NAME}")$\r$\n'
    FileWrite $0 '    with gr.Row():$\r$\n'
    FileWrite $0 '        with gr.Column(scale=2):$\r$\n'
    FileWrite $0 '            lyrics = gr.Textbox(label="Lyrics", lines=12, value=SAMPLE)$\r$\n'
    FileWrite $0 '            tags = gr.Textbox(label="Style Tags", value="piano,happy,pop")$\r$\n'
    FileWrite $0 '        with gr.Column(scale=1):$\r$\n'
    FileWrite $0 '            length = gr.Slider(30, 240, 120, step=10, label="Length(sec)")$\r$\n'
    FileWrite $0 '            temp = gr.Slider(0.5, 1.5, 1.0, step=0.1, label="Temperature")$\r$\n'
    FileWrite $0 '            cfg = gr.Slider(1.0, 3.0, 1.5, step=0.1, label="CFG Scale")$\r$\n'
    FileWrite $0 '            btn = gr.Button("Generate Music", variant="primary", size="lg")$\r$\n'
    FileWrite $0 '    status = gr.Textbox(label="Status", interactive=False)$\r$\n'
    FileWrite $0 '    audio = gr.Audio(label="Generated Music", type="filepath")$\r$\n'
    FileWrite $0 '    btn.click(generate, [lyrics, tags, length, temp, cfg], [audio, status])$\r$\n'
    FileWrite $0 '    gr.Markdown("---$\\n*Powered by HeartMuLa (CC BY-NC 4.0)*")$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'if __name__ == "__main__":$\r$\n'
    FileWrite $0 '    app.launch(server_name="127.0.0.1", server_port=7860, inbrowser=True)$\r$\n'
    FileClose $0

copy_download_script:
    ; Create download_models.py
    FileOpen $0 "$INSTDIR\app\download_models.py" w
    FileWrite $0 '#!/usr/bin/env python3$\r$\n'
    FileWrite $0 '"""Download HeartMuLa AI models from HuggingFace"""$\r$\n'
    FileWrite $0 'import sys$\r$\n'
    FileWrite $0 'import os$\r$\n'
    FileWrite $0 'from pathlib import Path$\r$\n'
    FileWrite $0 'from huggingface_hub import snapshot_download$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'def download_models(model_dir):$\r$\n'
    FileWrite $0 '    model_dir = Path(model_dir)$\r$\n'
    FileWrite $0 '    model_dir.mkdir(parents=True, exist_ok=True)$\r$\n'
    FileWrite $0 '    $\r$\n'
    FileWrite $0 '    print("[1/3] Downloading HeartMuLaGen...")$\r$\n'
    FileWrite $0 '    snapshot_download("HeartMuLa/HeartMuLaGen", local_dir=str(model_dir))$\r$\n'
    FileWrite $0 '    $\r$\n'
    FileWrite $0 '    print("[2/3] Downloading HeartMuLa-oss-3B...")$\r$\n'
    FileWrite $0 '    snapshot_download("HeartMuLa/HeartMuLa-oss-3B", $\r$\n'
    FileWrite $0 '                      local_dir=str(model_dir / "HeartMuLa-oss-3B"))$\r$\n'
    FileWrite $0 '    $\r$\n'
    FileWrite $0 '    print("[3/3] Downloading HeartCodec-oss...")$\r$\n'
    FileWrite $0 '    snapshot_download("HeartMuLa/HeartCodec-oss", $\r$\n'
    FileWrite $0 '                      local_dir=str(model_dir / "HeartCodec-oss"))$\r$\n'
    FileWrite $0 '    $\r$\n'
    FileWrite $0 '    print("Download complete!")$\r$\n'
    FileWrite $0 '    return True$\r$\n'
    FileWrite $0 '$\r$\n'
    FileWrite $0 'if __name__ == "__main__":$\r$\n'
    FileWrite $0 '    model_dir = sys.argv[1] if len(sys.argv) > 1 else str(Path.home() / ".mulastudio" / "models")$\r$\n'
    FileWrite $0 '    download_models(model_dir)$\r$\n'
    FileClose $0

    ;------------------------------------------
    ; Step 7: Download AI Models
    ;------------------------------------------
    DetailPrint "Downloading AI models (approximately 6GB, this may take 10-30 minutes)..."

    ; Create user models directory
    CreateDirectory "$PROFILE\.mulastudio\models"

    nsExec::ExecToLog '"$PYTHON_PATH" "$INSTDIR\app\download_models.py" "$PROFILE\.mulastudio\models"'
    Pop $0

    ;------------------------------------------
    ; Step 8: Create Run Script
    ;------------------------------------------
    SetOutPath "$INSTDIR"
    DetailPrint "Creating launch scripts..."

    FileOpen $0 "$INSTDIR\run.bat" w
    FileWrite $0 '@echo off$\r$\n'
    FileWrite $0 'cd /d "$INSTDIR"$\r$\n'
    FileWrite $0 'echo Starting MuLa Studio...$\r$\n'
    FileWrite $0 'echo Browser will open automatically at http://127.0.0.1:7860$\r$\n'
    FileWrite $0 'start "" http://127.0.0.1:7860$\r$\n'
    FileWrite $0 '"$INSTDIR\python\python.exe" "$INSTDIR\app\main.py"$\r$\n'
    FileWrite $0 'pause$\r$\n'
    FileClose $0

    ; Create hidden launcher (no console window)
    FileOpen $0 "$INSTDIR\MuLaStudio.vbs" w
    FileWrite $0 'Set WshShell = CreateObject("WScript.Shell")$\r$\n'
    FileWrite $0 'WshShell.Run chr(34) & "$INSTDIR\run.bat" & chr(34), 0$\r$\n'
    FileWrite $0 'Set WshShell = Nothing$\r$\n'
    FileClose $0

    ;------------------------------------------
    ; Step 9: Create Start Menu Shortcuts
    ;------------------------------------------
    DetailPrint "Creating shortcuts..."

    CreateDirectory "$SMPROGRAMS\MuLa Studio"
    CreateShortCut "$SMPROGRAMS\MuLa Studio\MuLa Studio.lnk" "$INSTDIR\run.bat" "" "$INSTDIR\python\python.exe" 0
    CreateShortCut "$SMPROGRAMS\MuLa Studio\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

    ;------------------------------------------
    ; Step 10: Create Uninstaller
    ;------------------------------------------
    WriteUninstaller "$INSTDIR\Uninstall.exe"

    ; Registry entries for Add/Remove Programs
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio" \
                     "DisplayName" "MuLa Studio"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio" \
                     "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio" \
                     "DisplayIcon" "$INSTDIR\python\python.exe"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio" \
                     "Publisher" "ABADA Inc."
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio" \
                     "DisplayVersion" "${VERSION}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio" \
                     "URLInfoAbout" "https://music.abada.kr"
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio" \
                     "EstimatedSize" 7340032  ; ~7GB in KB
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio" \
                     "NoModify" 1
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio" \
                     "NoRepair" 1

    ; Save install directory
    WriteRegStr HKCU "Software\MuLaStudio" "InstallDir" "$INSTDIR"
    WriteRegStr HKCU "Software\MuLaStudio" "Version" "${VERSION}"

    DetailPrint "Installation complete!"
SectionEnd

;------------------------------------------------------------------------------
; System Check Page Functions
;------------------------------------------------------------------------------
Function SystemCheckPage
    !insertmacro MUI_HEADER_TEXT "System Check" "Checking your system requirements..."

    nsDialogs::Create 1018
    Pop $DIALOG
    ${If} $DIALOG == error
        Abort
    ${EndIf}

    ; Title
    ${NSD_CreateLabel} 0 0 100% 20u "Checking system requirements..."
    Pop $0

    ; GPU Status
    ${NSD_CreateLabel} 0 30u 100% 15u "GPU: Checking..."
    Pop $LABEL_GPU

    ; RAM Status
    ${NSD_CreateLabel} 0 50u 100% 15u "RAM: Checking..."
    Pop $LABEL_RAM

    ; Disk Status
    ${NSD_CreateLabel} 0 70u 100% 15u "Disk Space: Checking..."
    Pop $LABEL_DISK

    ; Status
    ${NSD_CreateLabel} 0 100u 100% 40u ""
    Pop $LABEL_STATUS

    ; Perform checks
    Call CheckGPU
    Call CheckRAM
    Call CheckDiskSpace
    Call UpdateStatusMessage

    nsDialogs::Show
FunctionEnd

Function SystemCheckPageLeave
    ; Verify minimum requirements
    ${If} $FREE_DISK_GB < 15
        MessageBox MB_YESNO|MB_ICONEXCLAMATION "Warning: Less than 15GB of free disk space detected.$\r$\n$\r$\nThe installation may fail. Continue anyway?" IDYES +2
        Abort
    ${EndIf}

    ${If} $TOTAL_RAM_GB < 8
        MessageBox MB_YESNO|MB_ICONEXCLAMATION "Warning: Less than 8GB of RAM detected.$\r$\n$\r$\nMuLa Studio may run slowly. Continue anyway?" IDYES +2
        Abort
    ${EndIf}
FunctionEnd

;------------------------------------------------------------------------------
; GPU Detection
;------------------------------------------------------------------------------
Function CheckGPU
    ; Try to detect NVIDIA GPU using nvidia-smi
    nsExec::ExecToStack 'cmd /c "nvidia-smi --query-gpu=name --format=csv,noheader 2>nul"'
    Pop $0  ; Return code
    Pop $1  ; Output

    ${If} $0 == 0
    ${AndIf} $1 != ""
        ; GPU detected
        StrCpy $GPU_TYPE "cuda"
        StrCpy $GPU_NAME $1
        ${NSD_SetText} $LABEL_GPU "GPU: $GPU_NAME (CUDA acceleration enabled)"
    ${Else}
        ; No NVIDIA GPU
        StrCpy $GPU_TYPE "cpu"
        StrCpy $GPU_NAME "Not detected"
        ${NSD_SetText} $LABEL_GPU "GPU: Not detected (CPU mode - slower generation)"
    ${EndIf}
FunctionEnd

;------------------------------------------------------------------------------
; RAM Check
;------------------------------------------------------------------------------
Function CheckRAM
    ; Get total physical memory
    System::Alloc 64
    Pop $0
    System::Call 'kernel32::GlobalMemoryStatusEx(p r0)i.r1'
    System::Call '*$0(i, i, l .r2, l, l, l, l, l, l)'
    System::Free $0

    ; Convert bytes to GB
    System::Int64Op $2 / 1073741824
    Pop $TOTAL_RAM_GB

    ${If} $TOTAL_RAM_GB >= 16
        ${NSD_SetText} $LABEL_RAM "RAM: $TOTAL_RAM_GB GB (Excellent)"
    ${ElseIf} $TOTAL_RAM_GB >= 8
        ${NSD_SetText} $LABEL_RAM "RAM: $TOTAL_RAM_GB GB (OK)"
    ${Else}
        ${NSD_SetText} $LABEL_RAM "RAM: $TOTAL_RAM_GB GB (Warning: Minimum 8GB recommended)"
    ${EndIf}
FunctionEnd

;------------------------------------------------------------------------------
; Disk Space Check
;------------------------------------------------------------------------------
Function CheckDiskSpace
    ${GetRoot} "$LOCALAPPDATA" $0

    System::Call 'kernel32::GetDiskFreeSpaceEx(t r0, *l .r1, *l, *l)i.r2'

    ; Convert bytes to GB
    System::Int64Op $1 / 1073741824
    Pop $FREE_DISK_GB

    ${If} $FREE_DISK_GB >= 20
        ${NSD_SetText} $LABEL_DISK "Free Disk Space: $FREE_DISK_GB GB (Excellent)"
    ${ElseIf} $FREE_DISK_GB >= 15
        ${NSD_SetText} $LABEL_DISK "Free Disk Space: $FREE_DISK_GB GB (OK)"
    ${Else}
        ${NSD_SetText} $LABEL_DISK "Free Disk Space: $FREE_DISK_GB GB (Warning: Need at least 15GB)"
    ${EndIf}
FunctionEnd

;------------------------------------------------------------------------------
; Update Status Message
;------------------------------------------------------------------------------
Function UpdateStatusMessage
    ${If} $GPU_TYPE == "cuda"
        ${NSD_SetText} $LABEL_STATUS "Your system will use CUDA GPU acceleration.$\r$\nMusic generation will be fast (2-5 minutes per song)."
    ${Else}
        ${NSD_SetText} $LABEL_STATUS "Your system will use CPU mode.$\r$\nMusic generation will be slower (30+ minutes per song).$\r$\n$\r$\nFor faster generation, consider using a computer with an NVIDIA GPU."
    ${EndIf}
FunctionEnd

;------------------------------------------------------------------------------
; Create Desktop Shortcut
;------------------------------------------------------------------------------
Function CreateDesktopShortcut
    CreateShortCut "$DESKTOP\MuLa Studio.lnk" "$INSTDIR\run.bat" "" "$INSTDIR\python\python.exe" 0
FunctionEnd

;------------------------------------------------------------------------------
; Uninstaller Section
;------------------------------------------------------------------------------
Section "Uninstall"
    ; Remove files and directories
    RMDir /r "$INSTDIR\python"
    RMDir /r "$INSTDIR\app"
    RMDir /r "$INSTDIR\logs"
    Delete "$INSTDIR\run.bat"
    Delete "$INSTDIR\MuLaStudio.vbs"
    Delete "$INSTDIR\Uninstall.exe"
    RMDir "$INSTDIR"

    ; Remove shortcuts
    Delete "$DESKTOP\MuLa Studio.lnk"
    RMDir /r "$SMPROGRAMS\MuLa Studio"

    ; Remove registry entries
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\MuLaStudio"
    DeleteRegKey HKCU "Software\MuLaStudio"

    ; Note: Models directory in user profile is NOT removed
    ; Users can manually delete $PROFILE\.mulastudio if needed

    MessageBox MB_OK "MuLa Studio has been uninstalled.$\r$\n$\r$\nNote: AI models (~6GB) in $PROFILE\.mulastudio are preserved.$\r$\nDelete this folder manually if you want to free up space."
SectionEnd

;------------------------------------------------------------------------------
; Installer Functions
;------------------------------------------------------------------------------
Function .onInit
    ; Check Windows version
    ${IfNot} ${AtLeastWin10}
        MessageBox MB_OK|MB_ICONSTOP "MuLa Studio requires Windows 10 or later."
        Abort
    ${EndIf}

    ; Check if 64-bit
    ${IfNot} ${RunningX64}
        MessageBox MB_OK|MB_ICONSTOP "This installer is for 64-bit Windows only.$\r$\n$\r$\nPlease download MuLa_Setup_x86.exe for 32-bit systems."
        Abort
    ${EndIf}

    ; Check if already installed
    ReadRegStr $0 HKCU "Software\MuLaStudio" "InstallDir"
    ${If} $0 != ""
        MessageBox MB_YESNO|MB_ICONQUESTION "MuLa Studio appears to be already installed at:$\r$\n$0$\r$\n$\r$\nDo you want to reinstall?" IDYES +2
        Abort
    ${EndIf}

    ; Set default language based on system locale
    System::Call 'kernel32::GetUserDefaultUILanguage() i .r0'
    ${If} $0 == 1042  ; Korean
        !insertmacro MUI_LANGDLL_DISPLAY
    ${EndIf}
FunctionEnd

Function un.onInit
    MessageBox MB_YESNO|MB_ICONQUESTION "Are you sure you want to uninstall MuLa Studio?" IDYES +2
    Abort
FunctionEnd
