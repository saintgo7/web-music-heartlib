<!-- 프로젝트 스윕 상태 보고서: 빌드/테스트 검증 결과와 남은 작업, 문서/논문 골격 정리 -->
# STATUS — music-heartlib (ABADA Music Studio / HeartMuLa)

## English summary

This repository is a **mono-repo** that wraps the upstream open-source music
foundation model **HeartMuLa** with a product layer. It contains four distinct
parts:

1. **`web/`** — the primary, actively-finished deliverable: a React 19 +
   TypeScript + Vite + Tailwind v4 marketing/download website ("ABADA Music
   Studio"). **Verified green**: `npm ci` (210 pkgs, ~9s), `npm run typecheck`
   (`tsc --noEmit`, clean), `npm run build` (`tsc -b && vite build`, 62 modules,
   built in ~5s), and `npm run lint` (eslint, clean) all pass on
   2026-06-14.
2. **`src/heartlib/`** — a vendored copy of the upstream HeartMuLa Python
   inference library (heartcodec, heartmula, pipelines). Requires ~6GB model
   checkpoints + heavy GPU deps (torch 2.4.1, etc.). **Not built/run here** —
   out of time-box and needs GPU + downloads.
3. **`installer/`** — Windows NSIS / macOS / Linux installer scripts (this dir
   is `.gitignore`d at repo root). **Not verified.**
4. **`functions/api/`** — Cloudflare Workers API stubs (download-stats, gallery,
   analytics, index). **Not verified.**

The repo's root `README.md` is the **upstream HeartMuLa model README**, not the
website README — this is expected (the website README lives at `web/README.md`).

**What works (verified):** the `web/` app type-checks, lints, and builds for
production. **What is unverified:** Playwright e2e (50 tests across 8 specs),
Python inference, installers, Cloudflare deploy.

**Sweep action:** No code fixes were needed (all web checks already pass). This
sweep installed web deps, ran the full web check suite to confirm health, wrote
this STATUS.md, and checkpointed pre-existing WIP (a generated commit-analysis
HTML dashboard under `docs/html/` + Python generator scripts under `scripts/`).

---

## 한국어 본문

### 1. 목적

이 저장소는 오픈소스 음악 파운데이션 모델 **HeartMuLa** 를 제품화한 모노레포다.
사용자 대상 산출물은 "ABADA Music Studio" 웹사이트(`web/`)이며, 그 외에 업스트림
파이썬 추론 라이브러리(`src/heartlib/`), 설치 프로그램(`installer/`),
Cloudflare Workers API(`functions/api/`)가 함께 들어 있다.

### 2. 현재 상태 (검증 기준 2026-06-14)

**`web/` (주 산출물) — 정상.**
아래 4개 명령이 모두 성공했다.

| 명령 | 결과 | 비고 |
|------|------|------|
| `npm ci` | 통과 | 210개 패키지, 약 9초 |
| `npm run typecheck` (`tsc --noEmit`) | 통과 | 에러 0 |
| `npm run build` (`tsc -b && vite build`) | 통과 | 62 모듈, 약 5초, `build/` 생성 |
| `npm run lint` (eslint) | 통과 | 경고/에러 0 |

빌드 시 vite가 메인 청크(212KB) 분할을 권고하는 경고만 출력한다(에러 아님).

**검증하지 못한 영역.**

- **Playwright e2e** — 8개 스펙에 총 50개 테스트(`web/tests/e2e/`)가 있으나,
  브라우저 바이너리(`npm run test:install`)와 dev 서버(localhost:5173) 기동이
  필요해 시간 제한상 실행하지 않았다. 미검증.
- **`src/heartlib/` 파이썬 추론** — torch 2.4.1 등 무거운 GPU 의존성과 약 6GB
  체크포인트 다운로드가 필요해 실행하지 않았다. 미검증.
- **`installer/`** — 루트 `.gitignore`에 의해 추적 제외된 디렉터리이며 OS별
  실제 설치 검증은 하지 않았다. 미검증.
- **`functions/api/`** — Cloudflare Workers 배포/런타임 검증은 하지 않았다. 미검증.

### 3. 동작하는 것 vs 안 되는 것

- **동작(검증됨).** `web/` 앱의 타입체크 · 린트 · 프로덕션 빌드.
- **미확인.** e2e 테스트, 파이썬 추론, 설치 프로그램, Cloudflare 배포. 위 표/목록
  근거.
- **주의.** 루트 `README.md`는 업스트림 HeartMuLa 모델 설명서이고, 웹사이트
  설명서는 `web/README.md`에 별도로 존재한다. 두 문서의 대상이 다르다는 점은
  의도된 구성으로 보인다(혼동 방지용 메모).

### 4. 이번 스윕에서 한 일

1. 사전 WIP(미커밋 변경 24건)를 유지한 채 `claude/sweep-2026-06-13` 브랜치로 이동.
2. `web/` 의존성 설치 후 typecheck/build/lint 전부 실행 → 모두 통과 확인.
   별도 코드 수정은 필요하지 않았다(이미 그린 상태).
3. 본 `STATUS.md` 작성.
4. 사전 WIP를 체크포인트 커밋. WIP 내용은 `docs/html/`의 커밋 분석 HTML
   대시보드(PamOut 진행 대시보드 형태)와 `scripts/`의 파이썬 생성 스크립트들이다.
   민감 파일 패턴(.env/.pem/secret/.key 등)은 발견되지 않았다.

### 5. 끝내기 위해 남은 구체적 단계

1. **e2e 안정화.** `cd web && npm run test:install && npm run test:e2e` 를 로컬에서
   돌려 50개 테스트의 실제 통과 여부를 확정한다(현재 미검증).
2. **CI 확인.** `.github/workflows/`의 build-installers / deploy-website /
   lint-and-test 워크플로가 실제로 통과하는지 점검한다.
3. **파이썬 추론 스모크 테스트.** GPU 또는 충분한 자원이 있는 환경에서
   `examples/run_music_generation.py` 가 체크포인트로 동작하는지 1회 확인.
4. **설치 프로그램 검증.** Windows/macOS/Linux 각 OS에서 installer 스크립트 실측.
5. **문서 정합성.** `PROJECT_STATUS.md`(v0.4→v1.0 단계 기술)와 README/RELEASE
   문서들 사이 버전·상태 표기를 한 번 정리.
6. **WIP 대시보드 결정.** `docs/html/`의 PamOut 대시보드가 이 프로젝트용인지,
   다른 프로젝트(워크스테이션 관리)에서 흘러든 산출물인지 사용자 확인 필요. 명칭이
   "PamOut"으로 ABADA와 달라 출처가 모호하다(미해결, 코드 변경 대신 기록만 함).

### 6. 책/문서 골격 (선택)

이 저장소는 연구 논문보다는 **제품 엔지니어링 사례**에 가깝다. 굳이 기술
문서/사례 연구를 쓴다면 아래 골격이 가능하며, 대부분의 재료가 이미 저장소에 있다.

- **1. 개요 — HeartMuLa를 제품으로 감싸기.** 재료: 루트 `README.md`,
  `PROJECT_STATUS.md`, `ROADMAP.md`.
- **2. 아키텍처.** 모노레포 4계층(web/파이썬 추론/installer/Workers). 재료:
  `docs/MASTER_PLAN.md`, `docs/DEV.md`, 디렉터리 구조.
- **3. 웹 프런트엔드.** React 19 + Vite + Tailwind v4, 코드 스플리팅, 성능. 재료:
  `web/README.md`, `web/PERFORMANCE_REPORT.md`, `docs/PERFORMANCE_OPTIMIZATION.md`.
- **4. 크로스 플랫폼 설치 자동화.** NSIS + shell, GPU 감지. 재료:
  `INSTALLER_DEV.md`, `installer/`, `Makefile`.
- **5. 배포·운영.** Cloudflare Pages/Workers/KV, CI/CD. 재료:
  `docs/CLOUDFLARE_SETUP.md`, `docs/DEPLOYMENT_*`, `.github/workflows/`,
  `wrangler.toml`.
- **6. 테스트 전략.** Playwright e2e(50개), 성능 부하(k6, `tests/performance/`).
  재료: `docs/TESTING_*`, `web/tests/`, `tests/`.
- **7. 회고.** 배포 이슈와 해결. 재료: `docs/DEPLOYMENT_ISSUES_REPORT.md`,
  `docs/TROUBLESHOOTING.md`, `docs/INCIDENT_RESPONSE.md`.

논문 작성 잠재력: **낮음**(연구 신규성보다 엔지니어링 사례 성격). 정직성 표기상
위 1~7 중 실측으로 뒷받침되는 것은 §3 웹 빌드 그린뿐이며, 나머지는 문서 기반
서술임을 본문에서 분명히 해야 한다.

---

*검증 일자: 2026-06-14. 위 표/목록의 "통과/미검증" 표기는 본 스윕에서 실제 실행한
결과(web)와 실행하지 않은 항목(e2e/파이썬/installer/Workers)을 구분한 것이다.*
