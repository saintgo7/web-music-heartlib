# ABADA Music Studio - 문제 해결 가이드 (Troubleshooting)

**버전**: v0.3.0
**작성일**: 2026-01-19
**대상**: 개발자, QA 엔지니어, 사용자 지원팀

---

## 목차

1. [설치 프로그램 문제](#설치-프로그램-문제)
   - [Windows](#windows-설치-문제)
   - [macOS](#macos-설치-문제)
   - [Linux](#linux-설치-문제)
2. [웹사이트 문제](#웹사이트-문제)
3. [API 문제](#api-문제)
4. [성능 문제](#성능-문제)
5. [디버그 로깅](#디버그-로깅)
6. [자주 묻는 질문 (FAQ)](#자주-묻는-질문)

---

## 설치 프로그램 문제

### Windows 설치 문제

#### 문제 1: "nvidia-smi가 인식되지 않음" 오류

**증상**:
```
'nvidia-smi'은(는) 내부 또는 외부 명령, 실행할 수 있는 프로그램, 또는 배치 파일이 아닙니다.
```

**원인**:
- NVIDIA 드라이버가 설치되지 않음
- PATH 환경 변수에 CUDA 경로가 없음
- GPU가 없는 시스템

**해결 방법**:

1. **NVIDIA 드라이버 확인**:
   ```powershell
   # 디바이스 관리자에서 GPU 확인
   devmgmt.msc
   ```

2. **PATH 환경 변수 추가**:
   ```powershell
   # System Properties → Environment Variables
   C:\Program Files\NVIDIA Corporation\NVSMI
   ```

3. **CPU 모드로 설치**:
   - 설치 프로그램이 자동으로 CPU 버전으로 전환됩니다.
   - 성능은 GPU 대비 5-10배 느립니다.

**디버그**:
```powershell
# NVIDIA 드라이버 버전 확인
nvidia-smi

# 설치 로그 확인
type "C:\Program Files\ABADA\MuLa\install.log"
```

---

#### 문제 2: "관리자 권한 필요" 오류

**증상**:
```
이 앱을 실행하려면 관리자 권한이 필요합니다.
```

**원인**:
- UAC(User Account Control)가 활성화됨
- 설치 경로(`C:\Program Files\`)에 쓰기 권한 없음

**해결 방법**:

1. **관리자 권한으로 실행**:
   - 설치 파일 우클릭 → "관리자 권한으로 실행"

2. **UAC 일시 비활성화** (권장하지 않음):
   ```powershell
   # Control Panel → User Accounts → Change User Account Control settings
   ```

3. **사용자 디렉토리에 설치** (대안):
   - 설치 경로를 `C:\Users\{USER}\AppData\Local\MuLa`로 변경
   - NSIS 스크립트 수정 필요

---

#### 문제 3: "Python 설치 실패"

**증상**:
```
Python 3.10 임베딩 설치 중 오류 발생
Error code: 1603
```

**원인**:
- 디스크 공간 부족 (약 200MB 필요)
- 안티바이러스가 설치 차단
- 기존 Python 버전 충돌

**해결 방법**:

1. **디스크 공간 확인**:
   ```powershell
   Get-PSDrive C | Select-Object Used,Free
   ```

2. **안티바이러스 예외 추가**:
   - Windows Defender → Virus & threat protection → Exclusions
   - 경로 추가: `C:\Program Files\ABADA\MuLa`

3. **수동 설치**:
   ```powershell
   # Python 3.10 Embedded 다운로드
   Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.10.11/python-3.10.11-embed-amd64.zip" -OutFile python.zip

   # 압축 해제
   Expand-Archive -Path python.zip -DestinationPath "C:\Program Files\ABADA\MuLa\python"
   ```

---

#### 문제 4: "모델 다운로드 실패" (HuggingFace)

**증상**:
```
HTTPSConnectionPool(host='huggingface.co', port=443): Max retries exceeded
```

**원인**:
- 네트워크 연결 불안정
- 방화벽/프록시 차단
- HuggingFace 서버 다운

**해결 방법**:

1. **네트워크 연결 확인**:
   ```powershell
   Test-NetConnection huggingface.co -Port 443
   ```

2. **프록시 설정** (기업 환경):
   ```bash
   export HTTP_PROXY=http://proxy.company.com:8080
   export HTTPS_PROXY=http://proxy.company.com:8080
   ```

3. **ModelScope 미러 사용** (중국):
   ```python
   # download_models.py 수정
   from modelscope import snapshot_download

   snapshot_download('HeartMuLa/HeartMuLa-oss-3B', cache_dir='./ckpt')
   ```

4. **수동 다운로드**:
   - https://huggingface.co/HeartMuLa/HeartMuLa-oss-3B/tree/main
   - 파일을 `C:\Users\{USER}\.cache\huggingface\hub\` 에 배치

**재시도 로직**:
```python
# download_models.py에 재시도 추가
import time
from requests.exceptions import ConnectionError

def download_with_retry(model_id, max_retries=3):
    for attempt in range(max_retries):
        try:
            return snapshot_download(model_id)
        except ConnectionError:
            if attempt < max_retries - 1:
                time.sleep(5 * (attempt + 1))  # Exponential backoff
            else:
                raise
```

---

#### 문제 5: "PyTorch CUDA 설치 실패"

**증상**:
```
ERROR: Could not find a version that satisfies the requirement torch==2.x.x+cu118
```

**원인**:
- CUDA 버전 불일치
- pip 인덱스 URL 오류
- 인터넷 연결 문제

**해결 방법**:

1. **CUDA 버전 확인**:
   ```powershell
   nvidia-smi  # CUDA Version 확인
   ```

2. **적절한 인덱스 URL 사용**:
   ```bash
   # CUDA 11.8
   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

   # CUDA 12.1
   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

   # CPU only
   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
   ```

3. **pip 업그레이드**:
   ```bash
   python -m pip install --upgrade pip
   ```

---

### macOS 설치 문제

#### 문제 6: "앱을 열 수 없습니다. 개발자를 확인할 수 없습니다."

**증상**:
```
"MuLa.app"을(를) 열 수 없습니다. Apple에서 악성 소프트웨어가 있는지 확인할 수 없습니다.
```

**원인**:
- Gatekeeper가 미서명 앱 차단
- 공증(Notarization) 미완료 (Phase 3 예정)

**해결 방법**:

1. **보안 예외 추가**:
   ```bash
   # 터미널에서 실행
   xattr -cr /Applications/MuLa.app
   ```

2. **시스템 환경설정에서 허용**:
   - System Preferences → Security & Privacy → General
   - "Open Anyway" 버튼 클릭

3. **우클릭 + 열기**:
   - Finder에서 MuLa.app 우클릭 → 열기

**영구 해결** (Phase 3):
```bash
# 개발자 서명
codesign --force --deep --sign "Developer ID Application: ABADA (TEAM_ID)" MuLa.app

# 공증
xcrun altool --notarize-app --primary-bundle-id "kr.abada.mula" --file MuLa.dmg
```

---

#### 문제 7: "Homebrew를 찾을 수 없습니다."

**증상**:
```
brew: command not found
```

**원인**:
- Homebrew 미설치
- PATH 환경 변수 미설정 (Apple Silicon)

**해결 방법**:

1. **Homebrew 설치**:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **PATH 추가** (Apple Silicon):
   ```bash
   echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
   source ~/.zprofile
   ```

3. **설치 확인**:
   ```bash
   brew --version
   ```

---

#### 문제 8: "Python 3.10을 찾을 수 없습니다."

**증상**:
```
python3.10: command not found
```

**원인**:
- Homebrew로 설치한 Python이 PATH에 없음
- 다른 Python 버전만 설치됨

**해결 방법**:

1. **Python 3.10 설치**:
   ```bash
   brew install python@3.10
   ```

2. **PATH 추가**:
   ```bash
   echo 'export PATH="/opt/homebrew/opt/python@3.10/bin:$PATH"' >> ~/.zprofile
   source ~/.zprofile
   ```

3. **심볼릭 링크 생성**:
   ```bash
   ln -s /opt/homebrew/bin/python3.10 /usr/local/bin/python3.10
   ```

---

#### 문제 9: "MPS 디바이스를 찾을 수 없습니다." (Apple Silicon)

**증상**:
```python
>>> import torch
>>> torch.backends.mps.is_available()
False
```

**원인**:
- PyTorch 버전이 MPS 미지원 (< 2.0)
- macOS 버전이 낮음 (Monterey 12.3+ 필요)

**해결 방법**:

1. **macOS 버전 확인**:
   ```bash
   sw_vers -productVersion  # 12.3 이상 필요
   ```

2. **PyTorch 업그레이드**:
   ```bash
   pip install --upgrade torch torchvision torchaudio
   ```

3. **MPS 확인**:
   ```python
   import torch
   print(f"MPS available: {torch.backends.mps.is_available()}")
   print(f"MPS built: {torch.backends.mps.is_built()}")
   ```

4. **CPU 폴백** (MPS 실패 시):
   ```python
   device = "mps" if torch.backends.mps.is_available() else "cpu"
   ```

---

### Linux 설치 문제

#### 문제 10: "패키지 관리자를 찾을 수 없습니다."

**증상**:
```
apt: command not found
dnf: command not found
```

**원인**:
- 지원되지 않는 배포판
- 설치 스크립트의 OS 감지 실패

**해결 방법**:

1. **배포판 확인**:
   ```bash
   cat /etc/os-release
   ```

2. **수동 패키지 매니저 지정**:
   ```bash
   # Ubuntu/Debian
   sudo apt update && sudo apt install python3.10 python3.10-venv

   # Fedora
   sudo dnf install python3.10

   # Arch Linux
   sudo pacman -S python
   ```

3. **설치 스크립트 수정**:
   ```bash
   # mula_install.sh 수정
   if command -v apt >/dev/null 2>&1; then
       PKG_MANAGER="apt"
   elif command -v dnf >/dev/null 2>&1; then
       PKG_MANAGER="dnf"
   elif command -v pacman >/dev/null 2>&1; then
       PKG_MANAGER="pacman"
   else
       echo "지원되지 않는 배포판입니다."
       exit 1
   fi
   ```

---

#### 문제 11: "Desktop Entry가 표시되지 않습니다."

**증상**:
- 애플리케이션 메뉴에 MuLa 아이콘이 없음
- .desktop 파일이 생성되었지만 동작 안 함

**원인**:
- Desktop Entry 경로 오류
- 데스크톱 환경 미지원 (headless 서버)
- 권한 문제

**해결 방법**:

1. **.desktop 파일 확인**:
   ```bash
   cat ~/.local/share/applications/mula.desktop
   ```

2. **데스크톱 데이터베이스 업데이트**:
   ```bash
   update-desktop-database ~/.local/share/applications/
   ```

3. **권한 확인**:
   ```bash
   chmod 644 ~/.local/share/applications/mula.desktop
   ```

4. **수동 실행 테스트**:
   ```bash
   gtk-launch mula.desktop
   # 또는
   ~/.local/share/mula/venv/bin/python ~/.local/share/mula/main.py
   ```

---

#### 문제 12: "CUDA 라이브러리를 로드할 수 없습니다."

**증상**:
```
OSError: libcudart.so.11.0: cannot open shared object file: No such file or directory
```

**원인**:
- CUDA Toolkit 미설치
- LD_LIBRARY_PATH 미설정

**해결 방법**:

1. **CUDA Toolkit 설치**:
   ```bash
   # Ubuntu
   sudo apt install nvidia-cuda-toolkit

   # Arch Linux
   sudo pacman -S cuda
   ```

2. **LD_LIBRARY_PATH 설정**:
   ```bash
   echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
   source ~/.bashrc
   ```

3. **CPU 버전 사용** (대안):
   ```bash
   pip uninstall torch
   pip install torch --index-url https://download.pytorch.org/whl/cpu
   ```

---

## 웹사이트 문제

### 문제 13: "페이지가 로드되지 않습니다." (무한 로딩)

**증상**:
- 브라우저가 무한 로딩 스피너 표시
- 콘솔에 오류 없음

**원인**:
- JavaScript 번들 로드 실패
- React lazy loading 오류
- 네트워크 타임아웃

**해결 방법**:

1. **브라우저 콘솔 확인** (F12):
   ```javascript
   // 네트워크 탭에서 실패한 요청 확인
   ```

2. **캐시 삭제**:
   ```
   Ctrl+Shift+Delete (Chrome)
   → Cached images and files
   ```

3. **Service Worker 제거**:
   ```javascript
   // 콘솔에서 실행
   navigator.serviceWorker.getRegistrations().then(function(registrations) {
     for(let registration of registrations) {
       registration.unregister();
     }
   });
   ```

4. **Hard Reload**:
   ```
   Ctrl+Shift+R (Windows/Linux)
   Cmd+Shift+R (macOS)
   ```

---

### 문제 14: "다운로드 통계가 기록되지 않습니다."

**증상**:
- 다운로드 버튼 클릭해도 통계 증가 없음
- API 호출 실패

**원인**:
- Cloudflare Workers API 오류
- CORS 차단
- KV Store 권한 문제

**해결 방법**:

1. **네트워크 탭 확인**:
   ```
   F12 → Network → Filter: XHR
   → POST /api/download-stats 확인
   ```

2. **CORS 헤더 확인**:
   ```javascript
   // 응답 헤더
   Access-Control-Allow-Origin: *
   Access-Control-Allow-Methods: GET, POST, OPTIONS
   ```

3. **KV Namespace 권한 확인**:
   ```bash
   wrangler kv:namespace list
   # DOWNLOAD_STATS 네임스페이스 존재 확인
   ```

4. **수동 API 테스트**:
   ```bash
   curl -X POST https://music.abada.kr/api/download-stats \
     -H "Content-Type: application/json" \
     -d '{"os":"windows","version":"v1.0.0","timestamp":"2026-01-19T12:00:00Z"}'
   ```

---

### 문제 15: "갤러리 음악이 재생되지 않습니다."

**증상**:
- 재생 버튼 클릭해도 소리 없음
- 진행률 바가 업데이트되지 않음

**원인**:
- 오디오 파일 CORS 오류
- 브라우저 자동 재생 정책
- 파일 형식 미지원

**해결 방법**:

1. **CORS 헤더 확인** (CDN):
   ```
   Access-Control-Allow-Origin: *
   ```

2. **브라우저 자동 재생 정책**:
   - 사용자 인터랙션(클릭) 후에만 재생 가능
   - `autoplay` 속성 제거

3. **오디오 형식 확인**:
   ```html
   <audio>
     <source src="audio.mp3" type="audio/mpeg">
     <source src="audio.ogg" type="audio/ogg">
     Your browser does not support the audio element.
   </audio>
   ```

4. **콘솔 오류 확인**:
   ```javascript
   document.querySelector('audio').addEventListener('error', (e) => {
     console.error('Audio error:', e);
   });
   ```

---

## API 문제

### 문제 16: "API 응답 시간이 느립니다." (> 1초)

**증상**:
- API 요청이 1초 이상 소요
- 사용자 경험 저하

**원인**:
- KV Store 읽기 지연
- 캐싱 미적용
- Cloudflare Workers Cold Start

**해결 방법**:

1. **KV Store 캐싱**:
   ```javascript
   // functions/api/gallery.js
   const cache = caches.default;
   const cacheKey = new Request(url.toString(), request);

   let response = await cache.match(cacheKey);
   if (response) return response; // Cache hit

   // Query KV Store
   const data = await env.GALLERY_DATA.get('items', { type: 'json' });

   response = new Response(JSON.stringify(data), {
     headers: {
       'Content-Type': 'application/json',
       'Cache-Control': 'public, max-age=3600',
     },
   });

   ctx.waitUntil(cache.put(cacheKey, response.clone()));
   return response;
   ```

2. **Cloudflare Edge Caching**:
   ```yaml
   # wrangler.toml
   [env.production]
   routes = [
     { pattern = "music.abada.kr/api/gallery", zone_name = "abada.kr" }
   ]
   ```

3. **데이터 사전 로드**:
   ```javascript
   // 자주 사용하는 데이터를 Workers 메모리에 캐싱
   let cachedData = null;
   let lastFetch = 0;
   const CACHE_TTL = 60000; // 1 minute

   export default {
     async fetch(request, env, ctx) {
       const now = Date.now();
       if (!cachedData || now - lastFetch > CACHE_TTL) {
         cachedData = await env.GALLERY_DATA.get('items', { type: 'json' });
         lastFetch = now;
       }
       return new Response(JSON.stringify(cachedData));
     },
   };
   ```

---

### 문제 17: "429 Too Many Requests" 오류

**증상**:
```json
{
  "error": "Too Many Requests",
  "retry_after": 60
}
```

**원인**:
- Rate Limiting 초과 (100 req/min)
- 봇 공격 또는 스크립트 오남용

**해결 방법**:

1. **요청 빈도 줄이기**:
   ```javascript
   // Debounce API calls
   const debounce = (func, delay) => {
     let timeoutId;
     return (...args) => {
       clearTimeout(timeoutId);
       timeoutId = setTimeout(() => func(...args), delay);
     };
   };

   const fetchGallery = debounce(() => {
     fetch('/api/gallery').then(/* ... */);
   }, 300); // 300ms delay
   ```

2. **Retry-After 헤더 준수**:
   ```javascript
   async function fetchWithRetry(url, options = {}) {
     const response = await fetch(url, options);

     if (response.status === 429) {
       const retryAfter = response.headers.get('Retry-After') || 60;
       console.log(`Rate limited. Retrying after ${retryAfter}s`);
       await new Promise(resolve => setTimeout(resolve, retryAfter * 1000));
       return fetchWithRetry(url, options);
     }

     return response;
   }
   ```

3. **Rate Limit 증가 요청** (관리자):
   ```javascript
   // functions/api/_middleware.js
   const RATE_LIMIT = 200; // 100 → 200 req/min
   ```

---

## 성능 문제

### 문제 18: "Lighthouse 점수가 낮습니다." (< 70)

**증상**:
- Performance: 65/100
- LCP > 4초

**원인**:
- JavaScript 번들 크기 과다 (> 1MB)
- 이미지 미최화
- 렌더 차단 리소스

**해결 방법**:

1. **번들 사이즈 최적화**:
   ```bash
   cd web
   npm run build
   npx vite-bundle-visualizer

   # 큰 라이브러리 제거 또는 대체
   # 예: moment.js → date-fns (경량)
   ```

2. **Code Splitting**:
   ```javascript
   // web/src/App.tsx
   import { lazy, Suspense } from 'react';

   const GalleryPage = lazy(() => import('./pages/GalleryPage'));

   function App() {
     return (
       <Suspense fallback={<div>Loading...</div>}>
         <Routes>
           <Route path="/gallery" element={<GalleryPage />} />
         </Routes>
       </Suspense>
     );
   }
   ```

3. **이미지 최적화**:
   ```bash
   # WebP 변환
   for img in public/images/*.jpg; do
     cwebp -q 80 "$img" -o "${img%.jpg}.webp"
   done
   ```

4. **Critical CSS 인라인**:
   ```html
   <!-- index.html -->
   <style>
     /* Critical CSS (Above the fold) */
     .hero-section { /* ... */ }
   </style>
   <link rel="stylesheet" href="/assets/index.css">
   ```

---

### 문제 19: "번들 사이즈가 너무 큽니다." (> 1MB)

**증상**:
- `dist/assets/index-*.js` 크기: 1.2MB (gzipped: 400KB)
- 페이지 로드 느림

**해결 방법**:

1. **Tree Shaking 확인**:
   ```javascript
   // Named imports 사용
   import { useState } from 'react'; // ✓ 좋음
   import React from 'react'; // ✗ 나쁨 (전체 import)
   ```

2. **Heavy 라이브러리 제거**:
   ```json
   // package.json에서 불필요한 라이브러리 제거
   {
     "dependencies": {
       "moment": "^2.29.4" // ✗ 제거 (290KB)
     }
   }

   // date-fns로 대체 (13KB)
   npm install date-fns
   ```

3. **Dynamic Import**:
   ```javascript
   // 페이지 진입 시 로드
   async function loadChart() {
     const Chart = await import('chart.js');
     return Chart.default;
   }
   ```

---

## 디버그 로깅

### Windows 디버그

```powershell
# 설치 로그
Get-Content "C:\Program Files\ABADA\MuLa\install.log"

# 애플리케이션 로그
Get-Content "$env:APPDATA\MuLa\logs\app.log"

# 이벤트 뷰어
eventvwr.msc
→ Windows Logs → Application
```

### macOS 디버그

```bash
# 설치 로그
cat /Applications/MuLa.app/Contents/Resources/install.log

# 애플리케이션 로그
cat ~/Library/Logs/MuLa/app.log

# 시스템 로그
log show --predicate 'process == "MuLa"' --last 1h
```

### Linux 디버그

```bash
# 설치 로그
cat ~/.local/share/mula/install.log

# 애플리케이션 로그
cat ~/.local/share/mula/logs/app.log

# systemd 로그 (서비스로 실행 시)
journalctl -u mula.service -f
```

### 웹사이트 디버그

```javascript
// 브라우저 콘솔 (F12)

// 1. React DevTools
// Chrome Extension: React Developer Tools

// 2. Network 분석
// F12 → Network → All
// 느린 요청 확인 (Waterfall)

// 3. Performance Profiling
// F12 → Performance → Record
// 페이지 로드 시 프로파일링

// 4. Memory Leak 검사
// F12 → Memory → Heap snapshot
```

### API 디버그

```bash
# Cloudflare Workers 로그
wrangler tail

# KV Store 확인
wrangler kv:key list --binding=DOWNLOAD_STATS
wrangler kv:key get "stats" --binding=DOWNLOAD_STATS

# 로컬 디버그
wrangler dev --local --persist
```

---

## 자주 묻는 질문

### Q1: 설치에 얼마나 시간이 걸리나요?

**A**:
- Windows (GPU): 5-10분 (모델 다운로드 6GB)
- macOS: 5-8분
- Linux: 5-10분
- 네트워크 속도에 따라 달라집니다.

---

### Q2: GPU 없이 사용할 수 있나요?

**A**:
- 예, CPU 모드로 사용 가능합니다.
- 성능: GPU 대비 5-10배 느립니다.
- 1분 음악 생성: GPU 2분 → CPU 10분

---

### Q3: 생성된 음악의 저작권은 누구에게 있나요?

**A**:
- 사용자에게 있습니다 (비상업적 사용).
- 상업적 사용 시 별도 라이선스 필요.
- 자세한 내용: [LICENSE.md](../LICENSE.md)

---

### Q4: 여러 언어로 가사를 쓸 수 있나요?

**A**:
- 예, 영어, 한국어, 중국어, 일본어, 스페인어 지원.
- 혼합 언어도 가능합니다.

---

### Q5: 오프라인에서 사용할 수 있나요?

**A**:
- 예, 모델 다운로드 후 오프라인 가능.
- 첫 설치 시에만 인터넷 연결 필요.

---

### Q6: 웹사이트가 모바일에서 느려요.

**A**:
```javascript
// 해결 방법:
1. 브라우저 캐시 삭제
2. Wi-Fi 연결 확인 (4G/5G)
3. 크롬 "Data Saver" 모드 비활성화
```

---

### Q7: API 호출이 실패합니다. (403 Forbidden)

**A**:
- CORS 문제입니다.
- Cloudflare Workers에서 CORS 헤더 확인:
  ```javascript
  headers: {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  }
  ```

---

## 추가 지원

**이메일**: support@abada.kr
**GitHub Issues**: https://github.com/saintgo7/web-music-heartlib/issues
**Discord**: https://discord.gg/abada (예정)

---

**문서 버전**: 1.0.0
**마지막 업데이트**: 2026-01-19
**다음 리뷰**: 2026-02-01
