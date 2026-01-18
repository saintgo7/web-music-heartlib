@echo off
REM ==============================================================================
REM MuLa Studio Windows Installer Build Script
REM
REM This script builds the Windows NSIS installer for MuLa Studio.
REM
REM Prerequisites:
REM   - NSIS 3.x installed and in PATH (or set NSIS_PATH below)
REM   - Internet connection (for downloading Python embed if not cached)
REM
REM Usage:
REM   build_windows.bat              - Build with default version (1.0.0)
REM   build_windows.bat 1.2.3        - Build with specific version
REM   build_windows.bat 1.2.3 x86    - Build 32-bit version
REM ==============================================================================

setlocal enabledelayedexpansion

REM Configuration
set "SCRIPT_DIR=%~dp0"
set "VERSION=%~1"
set "ARCH=%~2"

if "%VERSION%"=="" set "VERSION=1.0.0"
if "%ARCH%"=="" set "ARCH=x64"

set "PYTHON_VERSION=3.10.11"
set "BUILD_DIR=%SCRIPT_DIR%build"
set "OUTPUT_DIR=%SCRIPT_DIR%dist"

REM NSIS path (auto-detect or set manually)
where makensis >nul 2>&1
if %ERRORLEVEL% neq 0 (
    if exist "C:\Program Files (x86)\NSIS\makensis.exe" (
        set "NSIS_PATH=C:\Program Files (x86)\NSIS"
    ) else if exist "C:\Program Files\NSIS\makensis.exe" (
        set "NSIS_PATH=C:\Program Files\NSIS"
    ) else (
        echo [ERROR] NSIS not found. Please install NSIS 3.x
        echo         Download: https://nsis.sourceforge.io/Download
        exit /b 1
    )
) else (
    for /f "tokens=*" %%i in ('where makensis') do set "NSIS_PATH=%%~dpi"
)

echo ================================================================
echo   MuLa Studio Windows Installer Builder
echo ================================================================
echo.
echo   Version:      %VERSION%
echo   Architecture: %ARCH%
echo   NSIS Path:    %NSIS_PATH%
echo   Output Dir:   %OUTPUT_DIR%
echo.
echo ================================================================

REM Create directories
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM ----------------------------------------
REM Step 1: Download Python Embedded
REM ----------------------------------------
echo.
echo [1/4] Checking Python embedded package...

if "%ARCH%"=="x64" (
    set "PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip"
    set "PYTHON_ZIP=python-%PYTHON_VERSION%-embed-amd64.zip"
) else (
    set "PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-win32.zip"
    set "PYTHON_ZIP=python-%PYTHON_VERSION%-embed-win32.zip"
)

if not exist "%BUILD_DIR%\%PYTHON_ZIP%" (
    echo       Downloading Python %PYTHON_VERSION% ^(%ARCH%^)...
    echo       URL: %PYTHON_URL%

    REM Try PowerShell download
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%BUILD_DIR%\%PYTHON_ZIP%' -UseBasicParsing }" 2>nul
    if !ERRORLEVEL! neq 0 (
        REM Try curl
        curl -L -o "%BUILD_DIR%\%PYTHON_ZIP%" "%PYTHON_URL%" 2>nul
        if !ERRORLEVEL! neq 0 (
            echo [ERROR] Failed to download Python. Please download manually:
            echo         %PYTHON_URL%
            echo         Save to: %BUILD_DIR%\%PYTHON_ZIP%
            exit /b 1
        )
    )
    echo       Downloaded: %PYTHON_ZIP%
) else (
    echo       Using cached: %PYTHON_ZIP%
)

REM ----------------------------------------
REM Step 2: Copy Application Files
REM ----------------------------------------
echo.
echo [2/4] Copying application files...

if not exist "%BUILD_DIR%\app" mkdir "%BUILD_DIR%\app"

REM Copy main.py
if exist "%SCRIPT_DIR%..\app\main.py" (
    copy /Y "%SCRIPT_DIR%..\app\main.py" "%BUILD_DIR%\app\" >nul
    echo       Copied: main.py
)

REM Copy download_models.py
if exist "%SCRIPT_DIR%..\app\download_models.py" (
    copy /Y "%SCRIPT_DIR%..\app\download_models.py" "%BUILD_DIR%\app\" >nul
    echo       Copied: download_models.py
)

REM ----------------------------------------
REM Step 3: Check NSIS Plugins
REM ----------------------------------------
echo.
echo [3/4] Checking NSIS plugins...

REM Check for nsisunz plugin (for ZIP extraction)
if not exist "%NSIS_PATH%\Plugins\x86-unicode\nsisunz.dll" (
    echo       [WARN] nsisunz plugin not found.
    echo              Download from: https://nsis.sourceforge.io/Nsisunz_plug-in
    echo              The installer may not work correctly.
)

REM Check for NSISdl plugin (for downloads - usually included)
if not exist "%NSIS_PATH%\Plugins\x86-unicode\NSISdl.dll" (
    echo       [WARN] NSISdl plugin not found.
)

echo       NSIS plugins verified.

REM ----------------------------------------
REM Step 4: Build NSIS Installer
REM ----------------------------------------
echo.
echo [4/4] Building NSIS installer...

set "NSI_FILE=MuLaInstaller_%ARCH%.nsi"
set "OUTPUT_FILE=MuLa_Setup_%ARCH%.exe"

if not exist "%SCRIPT_DIR%%NSI_FILE%" (
    echo [ERROR] NSIS script not found: %NSI_FILE%
    exit /b 1
)

REM Run NSIS compiler
cd /d "%SCRIPT_DIR%"
"%NSIS_PATH%\makensis.exe" /DVERSION=%VERSION% /DBUILD_DIR=%BUILD_DIR% "%NSI_FILE%"

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] NSIS compilation failed!
    exit /b 1
)

REM Move output to dist folder
if exist "%SCRIPT_DIR%%OUTPUT_FILE%" (
    move /Y "%SCRIPT_DIR%%OUTPUT_FILE%" "%OUTPUT_DIR%\" >nul
)

REM ----------------------------------------
REM Complete
REM ----------------------------------------
echo.
echo ================================================================
echo   Build Complete!
echo ================================================================
echo.
echo   Output: %OUTPUT_DIR%\%OUTPUT_FILE%
echo.

REM Calculate file size
for %%F in ("%OUTPUT_DIR%\%OUTPUT_FILE%") do (
    set "FILE_SIZE=%%~zF"
    set /a "FILE_SIZE_MB=!FILE_SIZE!/1048576"
    echo   Size: !FILE_SIZE_MB! MB
)

echo.
echo   To test the installer:
echo     1. Copy %OUTPUT_FILE% to a Windows machine
echo     2. Double-click to run
echo     3. Follow the installation wizard
echo.
echo ================================================================

endlocal
exit /b 0
