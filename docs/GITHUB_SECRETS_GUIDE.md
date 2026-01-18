# ABADA Music Studio - GitHub Actions Secrets 설정 가이드

이 문서는 GitHub Actions 워크플로우를 위한 Secrets 설정 방법을 단계별로 설명합니다.

---

## 목차

1. [필수 Secrets 목록](#1-필수-secrets-목록)
2. [Cloudflare API Token 발급](#2-cloudflare-api-token-발급)
3. [Cloudflare Account ID 확인](#3-cloudflare-account-id-확인)
4. [GitHub Secrets 추가](#4-github-secrets-추가)
5. [설정 검증](#5-설정-검증)
6. [보안 모범 사례](#6-보안-모범-사례)
7. [트러블슈팅](#7-트러블슈팅)

---

## 1. 필수 Secrets 목록

| Secret 이름 | 설명 | 필수 여부 | 사용처 |
|------------|------|----------|--------|
| `CLOUDFLARE_API_TOKEN` | Cloudflare API 토큰 | **필수** | Pages/Workers 배포 |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare 계정 ID | **필수** | 계정 식별 |

### 선택적 Secrets (향후 확장용)

| Secret 이름 | 설명 | 사용처 |
|------------|------|--------|
| `DISCORD_WEBHOOK_URL` | 디스코드 알림 | 배포 알림 |
| `SLACK_WEBHOOK_URL` | 슬랙 알림 | 배포 알림 |
| `SENTRY_DSN` | Sentry 에러 추적 | 에러 모니터링 |

---

## 2. Cloudflare API Token 발급

### Step 1: Cloudflare 대시보드 접속

1. [Cloudflare Dashboard](https://dash.cloudflare.com) 접속
2. 로그인 (계정이 없으면 가입)

### Step 2: API Tokens 페이지 이동

1. 우측 상단 프로필 아이콘 클릭
2. **My Profile** 선택
3. 좌측 메뉴에서 **API Tokens** 클릭

또는 직접 접속: https://dash.cloudflare.com/profile/api-tokens

### Step 3: 새 토큰 생성

1. **Create Token** 버튼 클릭
2. **Edit Cloudflare Workers** 템플릿 옆 **Use template** 클릭

### Step 4: 권한 설정

기본 템플릿 권한을 확인하고 필요시 추가:

```yaml
# Account 권한
Account - Cloudflare Workers Scripts - Edit
Account - Workers KV Storage - Edit
Account - Cloudflare Pages - Edit
Account - Account Settings - Read

# Zone 권한 (커스텀 도메인 사용 시)
Zone - DNS - Edit (선택)
Zone - Zone - Read (선택)
```

**상세 설정 화면:**

```
Permissions:
┌─────────────────────────────────────────────────────────┐
│ Account                                                  │
│   Cloudflare Workers Scripts    [Edit]                  │
│   Workers KV Storage            [Edit]                  │
│   Cloudflare Pages              [Edit]                  │
├─────────────────────────────────────────────────────────┤
│ Zone (optional - for custom domain)                      │
│   DNS                           [Edit]                  │
│   Zone                          [Read]                  │
└─────────────────────────────────────────────────────────┘

Account Resources:
  Include: [Your Account Name]

Zone Resources:
  Include: Specific zone - abada.kr (커스텀 도메인 사용 시)

Client IP Address Filtering:
  (보안 강화를 위해 GitHub Actions IP 범위 설정 가능 - 선택사항)

TTL:
  Start date: (현재)
  End date: (선택사항 - 보안을 위해 설정 권장)
```

### Step 5: 토큰 생성 완료

1. **Continue to summary** 클릭
2. 설정 요약 확인
3. **Create Token** 클릭
4. **토큰 즉시 복사** (이 화면을 벗어나면 다시 볼 수 없음)

**토큰 형식:**
```
abCDeFgHiJkLmNoPqRsTuVwXyZ1234567890_AbCdEf
```

### 토큰 테스트

```bash
# 토큰 유효성 테스트
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json"

# 성공 응답
# {"result":{"id":"...","status":"active"},"success":true,...}
```

---

## 3. Cloudflare Account ID 확인

### 방법 A: Dashboard에서 확인

1. [Cloudflare Dashboard](https://dash.cloudflare.com) 접속
2. 좌측 메뉴에서 **Workers & Pages** 선택
3. 우측 사이드바 하단에서 **Account ID** 확인
4. 복사 버튼 클릭

**위치:**
```
┌────────────────────────────────────────┐
│ Workers & Pages                        │
│                                        │
│  [Overview]  [Workers]  [Pages]        │
│                                        │
│  ...                                   │
│                                        │
│  ┌─────────────────────────────────┐  │
│  │ Account details                  │  │
│  │                                  │  │
│  │ Account ID                       │  │
│  │ xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx │  │
│  │ [Copy]                          │  │
│  └─────────────────────────────────┘  │
└────────────────────────────────────────┘
```

### 방법 B: Wrangler CLI로 확인

```bash
# Wrangler 로그인
wrangler login

# 계정 정보 확인
wrangler whoami

# 출력 예시:
# | Account Name    | Account ID                        |
# | --------------- | --------------------------------- |
# | My Account      | 1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p |
```

### 방법 C: API로 확인

```bash
curl -X GET "https://api.cloudflare.com/client/v4/accounts" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json"
```

**Account ID 형식:**
```
1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p
```

---

## 4. GitHub Secrets 추가

### Step 1: Repository Settings 접속

1. GitHub에서 저장소 페이지 이동: `https://github.com/saintgo7/web-music-heartlib`
2. **Settings** 탭 클릭 (저장소 설정 권한 필요)

### Step 2: Secrets 메뉴 이동

1. 좌측 메뉴에서 **Secrets and variables** 확장
2. **Actions** 클릭

**경로:**
```
Settings > Secrets and variables > Actions
```

### Step 3: CLOUDFLARE_API_TOKEN 추가

1. **New repository secret** 버튼 클릭
2. 다음 정보 입력:

```
Name: CLOUDFLARE_API_TOKEN
Secret: [2단계에서 복사한 API 토큰]
```

3. **Add secret** 클릭

### Step 4: CLOUDFLARE_ACCOUNT_ID 추가

1. **New repository secret** 버튼 클릭
2. 다음 정보 입력:

```
Name: CLOUDFLARE_ACCOUNT_ID
Secret: [3단계에서 확인한 Account ID]
```

3. **Add secret** 클릭

### 완료 확인

설정 완료 후 Secrets 목록에서 확인:

```
Repository secrets (2)
┌──────────────────────────────────────────────────────────┐
│ Name                      Updated                        │
├──────────────────────────────────────────────────────────┤
│ CLOUDFLARE_API_TOKEN      [Updated a few seconds ago]    │
│ CLOUDFLARE_ACCOUNT_ID     [Updated a few seconds ago]    │
└──────────────────────────────────────────────────────────┘
```

---

## 5. 설정 검증

### 방법 A: 테스트 워크플로우 실행

테스트용 워크플로우를 생성하여 Secrets가 올바르게 설정되었는지 확인:

1. `.github/workflows/test-secrets.yml` 파일 생성:

```yaml
name: Test Secrets

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Check CLOUDFLARE_API_TOKEN
        run: |
          if [ -n "${{ secrets.CLOUDFLARE_API_TOKEN }}" ]; then
            echo "CLOUDFLARE_API_TOKEN is set (length: ${#CLOUDFLARE_API_TOKEN})"
            # 토큰 앞 4자리만 출력 (보안)
            echo "Token prefix: ${CLOUDFLARE_API_TOKEN:0:4}..."
          else
            echo "ERROR: CLOUDFLARE_API_TOKEN is NOT set"
            exit 1
          fi
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}

      - name: Check CLOUDFLARE_ACCOUNT_ID
        run: |
          if [ -n "${{ secrets.CLOUDFLARE_ACCOUNT_ID }}" ]; then
            echo "CLOUDFLARE_ACCOUNT_ID is set (length: ${#CLOUDFLARE_ACCOUNT_ID})"
            # Account ID 앞 4자리만 출력 (보안)
            echo "Account ID prefix: ${CLOUDFLARE_ACCOUNT_ID:0:4}..."
          else
            echo "ERROR: CLOUDFLARE_ACCOUNT_ID is NOT set"
            exit 1
          fi
        env:
          CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}

      - name: Verify Cloudflare API Token
        run: |
          response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
            -H "Authorization: Bearer ${{ secrets.CLOUDFLARE_API_TOKEN }}" \
            -H "Content-Type: application/json")

          if echo "$response" | grep -q '"success":true'; then
            echo "API Token is valid!"
          else
            echo "ERROR: API Token verification failed"
            echo "$response"
            exit 1
          fi
```

2. GitHub > Actions 탭 이동
3. **Test Secrets** 워크플로우 선택
4. **Run workflow** 클릭
5. 결과 확인

### 방법 B: 실제 배포 워크플로우 테스트

1. `web/` 디렉토리에 작은 변경 적용
2. main 브랜치에 push
3. Actions 탭에서 **Deploy Website** 워크플로우 확인
4. 배포 성공 여부 확인

### 방법 C: GitHub CLI로 확인

```bash
# GitHub CLI 설치 필요
gh secret list --repo saintgo7/web-music-heartlib

# 예상 출력:
# NAME                     UPDATED
# CLOUDFLARE_API_TOKEN     2024-01-19
# CLOUDFLARE_ACCOUNT_ID    2024-01-19
```

---

## 6. 보안 모범 사례

### 6.1 API Token 관리

**권장 사항:**

```yaml
# 최소 권한 원칙
- 필요한 권한만 부여
- 특정 계정/Zone으로 범위 제한
- 만료일 설정 (90일 권장)

# 정기적 갱신
- 90일마다 토큰 갱신
- 갱신 시 이전 토큰 즉시 폐기

# 접근 로그 모니터링
- Cloudflare > Audit Logs 정기 확인
- 비정상 접근 패턴 모니터링
```

### 6.2 GitHub Secrets 보안

**주의 사항:**

```yaml
# 절대 하지 말아야 할 것:
- Secrets를 코드에 하드코딩하지 않음
- Secrets를 로그에 출력하지 않음
- Secrets를 PR 리뷰에 노출하지 않음

# 권장 사항:
- 정기적인 Secrets 로테이션
- 사용하지 않는 Secrets 삭제
- Repository 접근 권한 최소화
```

### 6.3 토큰 만료 시 대응

```bash
# 1. 새 토큰 발급 (Cloudflare Dashboard)

# 2. GitHub Secret 업데이트
# Settings > Secrets > CLOUDFLARE_API_TOKEN > Update

# 3. 이전 토큰 폐기 (Cloudflare Dashboard)
# API Tokens > Roll/Revoke

# 4. 배포 테스트
# Actions 탭에서 워크플로우 수동 실행
```

---

## 7. 트러블슈팅

### 문제: "Authentication error"

**증상:**
```
Error: Authentication error
```

**해결:**
```bash
# 1. API Token 유효성 확인
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 2. Token 만료 확인 (Cloudflare Dashboard)

# 3. 필요 시 새 Token 발급

# 4. GitHub Secret 업데이트
```

### 문제: "Account not found"

**증상:**
```
Error: Could not find account with ID "xxx"
```

**해결:**
```bash
# 1. Account ID 확인
wrangler whoami

# 2. GitHub Secret 값 확인 (복사/붙여넣기 오류 체크)

# 3. Secret 업데이트
```

### 문제: "Permission denied"

**증상:**
```
Error: You do not have permission to perform this action
```

**해결:**
```bash
# 1. API Token 권한 확인
# Cloudflare Dashboard > API Tokens > 해당 토큰 > Edit

# 2. 필요한 권한 추가:
# - Workers Scripts: Edit
# - Workers KV Storage: Edit
# - Pages: Edit

# 3. 토큰 재발급 필요 시 새로 발급 후 Secret 업데이트
```

### 문제: Secret이 설정되지 않음

**증상:**
```
Warning: CLOUDFLARE_API_TOKEN is empty
```

**해결:**
```bash
# 1. GitHub Secrets 목록 확인
# Settings > Secrets and variables > Actions

# 2. Secret 이름 정확히 확인 (대소문자 구분)
# CLOUDFLARE_API_TOKEN (O)
# cloudflare_api_token (X)
# Cloudflare_API_Token (X)

# 3. 값이 비어있지 않은지 확인

# 4. 필요 시 Secret 삭제 후 재생성
```

### 문제: 워크플로우가 Secrets에 접근하지 못함

**증상:**
Fork된 저장소에서 Secrets 접근 불가

**해결:**
```yaml
# Fork된 저장소는 기본적으로 Secrets에 접근 불가
# 해결 방법:

# 1. Fork 저장소에서 별도 Secrets 설정

# 2. 또는 원본 저장소에 PR 생성 후 메인테이너가 병합
```

---

## 빠른 참조: 설정 요약

```bash
# === Cloudflare API Token 발급 ===
# 1. https://dash.cloudflare.com/profile/api-tokens
# 2. Create Token > Edit Cloudflare Workers 템플릿
# 3. 권한: Workers Scripts Edit, KV Storage Edit, Pages Edit
# 4. Create Token > 토큰 복사

# === Account ID 확인 ===
# 1. Cloudflare Dashboard > Workers & Pages
# 2. 우측 하단 Account ID 복사

# === GitHub Secrets 추가 ===
# 1. GitHub > Settings > Secrets > Actions
# 2. New repository secret
# 3. CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID 추가

# === 검증 ===
# 1. Actions 탭 > Deploy Website > Run workflow
# 2. 또는 web/ 변경 후 push > 자동 배포 확인
```

---

**문서 버전**: v1.0.0
**최종 수정**: 2026-01-19
**작성자**: ABADA Inc.
