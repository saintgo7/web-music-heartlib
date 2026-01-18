# ABADA Music Studio - 배포 체크리스트

이 문서는 ABADA Music Studio의 배포 과정에서 필요한 모든 체크리스트를 제공합니다.

---

## 목차

1. [사전 배포 체크리스트](#1-사전-배포-체크리스트)
2. [배포 중 체크리스트](#2-배포-중-체크리스트)
3. [배포 후 검증](#3-배포-후-검증)
4. [모니터링 및 로깅](#4-모니터링-및-로깅)
5. [롤백 절차](#5-롤백-절차)
6. [긴급 대응](#6-긴급-대응)

---

## 1. 사전 배포 체크리스트

### 1.1 코드 검토

```
[ ] 모든 코드 변경사항 PR 리뷰 완료
[ ] 린팅 오류 없음 (npm run lint)
[ ] 타입 에러 없음 (npm run type-check)
[ ] 모든 테스트 통과 (npm run test)
[ ] 빌드 성공 (npm run build)
```

### 1.2 Cloudflare 설정 확인

```
Cloudflare 계정:
[ ] Cloudflare 계정 로그인 가능
[ ] Account ID 확인됨
[ ] API Token 유효성 확인

KV Namespaces:
[ ] STATS KV namespace 생성됨
[ ] GALLERY KV namespace 생성됨
[ ] wrangler.toml에 KV ID 업데이트됨

Pages 설정:
[ ] Pages 프로젝트 생성됨 (abada-music)
[ ] 빌드 설정 구성됨
[ ] 환경 변수 설정됨
```

### 1.3 GitHub 설정 확인

```
Secrets:
[ ] CLOUDFLARE_API_TOKEN 설정됨
[ ] CLOUDFLARE_ACCOUNT_ID 설정됨
[ ] Secrets 값 유효성 확인됨

Workflows:
[ ] deploy-website.yml 파일 존재
[ ] build-installers.yml 파일 존재
[ ] lint-and-test.yml 파일 존재
[ ] 워크플로우 권한 설정됨
```

### 1.4 DNS 설정 확인

```
[ ] music.abada.kr CNAME 레코드 설정됨
[ ] DNS 전파 확인됨 (dig music.abada.kr)
[ ] SSL 인증서 발급 확인됨
```

### 1.5 보안 체크

```
[ ] API 키/토큰이 코드에 하드코딩되지 않음
[ ] .env 파일이 .gitignore에 포함됨
[ ] Secrets만 wrangler secret으로 설정됨
[ ] CORS 설정 검토됨
[ ] Admin API Key 설정됨 (wrangler secret put)
```

---

## 2. 배포 중 체크리스트

### 2.1 웹사이트 배포 (Cloudflare Pages)

```bash
# 수동 배포 시
cd web-music-heartlib/web
npm install
npm run build
wrangler pages deploy build --project-name=abada-music

# 확인 사항
[ ] 빌드 오류 없음
[ ] 배포 명령 성공
[ ] Pages URL 접속 가능
```

### 2.2 Workers API 배포

```bash
# 수동 배포 시
cd web-music-heartlib
wrangler deploy

# 환경별 배포
wrangler deploy --env production

# 확인 사항
[ ] 배포 명령 성공
[ ] Worker URL 접속 가능
```

### 2.3 GitHub Actions 자동 배포

```
[ ] main 브랜치에 push됨
[ ] Actions 탭에서 워크플로우 실행 확인
[ ] 모든 job 성공
[ ] 배포 완료 알림 확인
```

---

## 3. 배포 후 검증

### 3.1 웹사이트 검증

```bash
# 웹사이트 응답 확인
curl -I https://music.abada.kr

# 기대 응답
# HTTP/2 200
# content-type: text/html
```

**페이지별 확인:**

| 페이지 | URL | 확인 항목 |
|-------|-----|----------|
| 홈페이지 | `/` | Hero 섹션, Features, Footer |
| 다운로드 | `/download` | 다운로드 버튼, OS 감지 |
| 튜토리얼 | `/tutorial` | 설치 가이드 표시 |
| 갤러리 | `/gallery` | 샘플 목록, 재생 기능 |
| FAQ | `/faq` | 검색 기능, 질문 목록 |
| 소개 | `/about` | ABADA 정보 |

```
[ ] 홈페이지 로딩 정상
[ ] 모든 페이지 라우팅 정상
[ ] 모바일 반응형 확인
[ ] 이미지 로딩 정상
[ ] JavaScript 에러 없음 (Console 확인)
```

### 3.2 API 검증

```bash
# Health Check
curl https://music.abada.kr/api/health

# 기대 응답
# {"status":"ok","timestamp":"...","environment":"production"}

# API Documentation
curl https://music.abada.kr/api

# Download Stats
curl https://music.abada.kr/api/stats

# Gallery
curl https://music.abada.kr/api/gallery
```

**API 엔드포인트 검증:**

| 엔드포인트 | 메서드 | 상태코드 | 확인 |
|-----------|--------|---------|------|
| `/api/health` | GET | 200 | [ ] |
| `/api` | GET | 200 | [ ] |
| `/api/stats` | GET | 200 | [ ] |
| `/api/gallery` | GET | 200 | [ ] |
| `/api/download` | POST | 200/302 | [ ] |
| `/api/analytics` | POST | 200 | [ ] |

### 3.3 다운로드 기능 검증

```bash
# Windows x64 다운로드 리다이렉트
curl -I "https://music.abada.kr/api/download?os=windows-x64"

# 기대 응답
# HTTP/2 302
# location: https://github.com/.../MuLa_Setup_x64.exe
```

**OS별 다운로드 확인:**

```
[ ] Windows x64 다운로드 동작
[ ] Windows x86 다운로드 동작
[ ] macOS 다운로드 동작
[ ] Linux 다운로드 동작
```

### 3.4 성능 검증

```bash
# 응답 시간 측정
curl -w "@curl-format.txt" -o /dev/null -s https://music.abada.kr

# PageSpeed Insights 테스트
# https://pagespeed.web.dev/?url=https://music.abada.kr
```

**성능 기준:**

| 지표 | 목표 | 확인 |
|------|------|------|
| First Contentful Paint | < 1.8s | [ ] |
| Largest Contentful Paint | < 2.5s | [ ] |
| Time to Interactive | < 3.8s | [ ] |
| Cumulative Layout Shift | < 0.1 | [ ] |
| Total Blocking Time | < 200ms | [ ] |

### 3.5 보안 검증

```bash
# HTTPS 확인
curl -I https://music.abada.kr

# Headers 확인
curl -I https://music.abada.kr | grep -i "strict-transport-security"
```

**보안 체크:**

```
[ ] HTTPS 리다이렉트 동작
[ ] HSTS 헤더 존재
[ ] 민감한 정보 노출 없음
[ ] CORS 정책 적절함
```

---

## 4. 모니터링 및 로깅

### 4.1 Cloudflare Analytics

**확인 위치:** Cloudflare Dashboard > Workers & Pages > Analytics

```
확인 항목:
[ ] 요청 수 (Requests)
[ ] 대역폭 사용량 (Bandwidth)
[ ] 에러율 (Error rate)
[ ] 지역별 트래픽 (Geographic distribution)
```

### 4.2 Workers 로그

```bash
# 실시간 로그 스트리밍
wrangler tail

# 환경별 로그
wrangler tail --env production

# 필터링
wrangler tail --status error
```

**로그 확인 항목:**

```
[ ] 에러 로그 없음
[ ] 비정상 요청 패턴 없음
[ ] KV 접근 오류 없음
```

### 4.3 GitHub Actions 모니터링

**확인 위치:** GitHub > Actions 탭

```
[ ] 최근 워크플로우 실행 성공
[ ] 빌드 시간 정상 범위 (< 5분)
[ ] 경고 메시지 확인
```

### 4.4 알림 설정 (권장)

```yaml
# 슬랙/디스코드 알림 설정 (선택사항)
# GitHub Actions에서 배포 상태 알림

# 예시: Discord Webhook
- name: Notify Discord
  run: |
    curl -X POST ${{ secrets.DISCORD_WEBHOOK }} \
      -H "Content-Type: application/json" \
      -d '{"content": "Deployment successful!"}'
```

---

## 5. 롤백 절차

### 5.1 웹사이트 롤백 (Cloudflare Pages)

**방법 A: 대시보드에서 롤백**

1. Cloudflare Dashboard > Workers & Pages 이동
2. `abada-music` 프로젝트 선택
3. Deployments 탭 이동
4. 이전 배포 선택 > "Rollback to this deployment" 클릭

**방법 B: Git 롤백 후 재배포**

```bash
# 이전 커밋으로 롤백
git revert HEAD
git push origin main

# 또는 특정 커밋으로 롤백
git reset --hard <previous-commit-hash>
git push origin main --force  # 주의: force push
```

### 5.2 Workers API 롤백

**방법 A: Wrangler로 롤백**

```bash
# 이전 버전 목록 확인
wrangler deployments list

# 특정 버전으로 롤백
wrangler rollback <deployment-id>
```

**방법 B: Git 롤백 후 재배포**

```bash
# Git 롤백
git revert HEAD
git push origin main

# 수동 재배포
wrangler deploy
```

### 5.3 KV 데이터 롤백

```bash
# 백업에서 복원 (백업이 있는 경우)
wrangler kv:bulk put --namespace-id=YOUR_KV_ID backup.json

# 특정 키 삭제
wrangler kv:key delete --namespace-id=YOUR_KV_ID "corrupted-key"
```

### 5.4 롤백 체크리스트

```
[ ] 롤백 대상 버전 확인
[ ] 롤백 전 현재 상태 백업 (필요시)
[ ] 롤백 실행
[ ] 롤백 후 기능 검증
[ ] 팀에 롤백 알림
```

---

## 6. 긴급 대응

### 6.1 서비스 장애 시

**즉시 확인:**

```bash
# 웹사이트 상태
curl -I https://music.abada.kr

# API 상태
curl https://music.abada.kr/api/health

# Cloudflare 상태
# https://www.cloudflarestatus.com/
```

**대응 순서:**

1. 장애 범위 파악 (웹사이트/API/전체)
2. Cloudflare 상태 페이지 확인
3. 로그 분석
4. 롤백 필요 여부 결정
5. 롤백 실행 또는 핫픽스 배포
6. 서비스 복구 확인
7. 사후 분석 (Post-mortem)

### 6.2 보안 침해 시

**즉시 실행:**

```bash
# API Token 즉시 갱신
# Cloudflare Dashboard > Profile > API Tokens > Revoke > Create new

# GitHub Secrets 갱신
# Settings > Secrets > Update

# Admin API Key 갱신
wrangler secret put ADMIN_API_KEY
```

**보안 체크리스트:**

```
[ ] 침해 범위 파악
[ ] 영향받은 토큰/키 모두 갱신
[ ] 로그 검토 (비정상 접근 확인)
[ ] GitHub Secrets 갱신
[ ] Cloudflare API Token 갱신
[ ] 서비스 정상화 확인
```

### 6.3 비용 이상 시

**Cloudflare Free Tier 한도:**

| 항목 | 한도 | 알림 기준 |
|------|------|----------|
| Workers 요청 | 100,000/일 | 80,000/일 |
| KV 읽기 | 100,000/일 | 80,000/일 |
| KV 쓰기 | 1,000/일 | 800/일 |
| Pages 빌드 | 500/월 | 400/월 |

**비용 급증 시:**

1. Cloudflare Analytics에서 트래픽 패턴 확인
2. 비정상 요청 소스 식별
3. Rate limiting 설정 검토
4. 필요시 차단 규칙 추가

### 6.4 연락처

```
Cloudflare 지원:
- 대시보드 내 Support 티켓
- https://developers.cloudflare.com/support

GitHub 지원:
- https://support.github.com

프로젝트 관리자:
- GitHub Issues: https://github.com/saintgo7/web-music-heartlib/issues
```

---

## 빠른 참조: 배포 명령어

```bash
# === 웹사이트 배포 ===
cd web && npm install && npm run build
wrangler pages deploy build --project-name=abada-music

# === Workers API 배포 ===
wrangler deploy

# === 환경별 배포 ===
wrangler deploy --env production

# === 로그 확인 ===
wrangler tail

# === 롤백 ===
wrangler rollback <deployment-id>

# === KV 관리 ===
wrangler kv:namespace list
wrangler kv:key list --namespace-id=YOUR_KV_ID
```

---

## 버전 기록

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2026-01-19 | 초기 문서 작성 |

---

**문서 버전**: v1.0.0
**최종 수정**: 2026-01-19
**작성자**: ABADA Inc.
