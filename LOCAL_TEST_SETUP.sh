#!/bin/bash

################################################################################
# ABADA Music Studio - 로컬 테스트 환경 설정 스크립트
# 버전: v0.3.0
# 작성일: 2026-01-19
# 용도: Phase 2 테스트 환경 자동 구성
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_DIR="$PROJECT_ROOT/web"
FUNCTIONS_DIR="$PROJECT_ROOT/functions"
INSTALLER_DIR="$PROJECT_ROOT/installer"
REPORTS_DIR="$PROJECT_ROOT/reports"

# Configuration
NODE_VERSION="18"
PYTHON_VERSION="3.10"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
    echo "$OS"
}

################################################################################
# Step 1: 시스템 요구사항 검증
################################################################################

check_system_requirements() {
    print_header "Step 1: 시스템 요구사항 검증"

    OS=$(check_os)
    print_info "운영체제: $OS"

    # Node.js 확인
    if command_exists node; then
        NODE_CURRENT=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_CURRENT" -ge "$NODE_VERSION" ]; then
            print_success "Node.js $(node --version) 설치됨"
        else
            print_error "Node.js 버전이 낮습니다. v${NODE_VERSION}+ 필요 (현재: v${NODE_CURRENT})"
            exit 1
        fi
    else
        print_error "Node.js가 설치되지 않았습니다."
        print_info "설치: https://nodejs.org/"
        exit 1
    fi

    # npm 확인
    if command_exists npm; then
        print_success "npm $(npm --version) 설치됨"
    else
        print_error "npm이 설치되지 않았습니다."
        exit 1
    fi

    # Git 확인
    if command_exists git; then
        print_success "Git $(git --version | awk '{print $3}') 설치됨"
    else
        print_error "Git이 설치되지 않았습니다."
        exit 1
    fi

    # Python 확인 (선택 사항)
    if command_exists python3; then
        PYTHON_CURRENT=$(python3 --version | awk '{print $2}')
        print_success "Python $PYTHON_CURRENT 설치됨"
    else
        print_warning "Python3가 설치되지 않았습니다 (설치 프로그램 테스트에 필요)"
    fi

    # Docker 확인 (선택 사항)
    if command_exists docker; then
        print_success "Docker $(docker --version | awk '{print $3}' | tr -d ',') 설치됨"
    else
        print_warning "Docker가 설치되지 않았습니다 (Linux 멀티 배포판 테스트에 필요)"
    fi

    # Cloudflare Wrangler 확인 (선택 사항)
    if command_exists wrangler; then
        print_success "Wrangler $(wrangler --version | awk '{print $2}') 설치됨"
    else
        print_warning "Wrangler가 설치되지 않았습니다 (API 로컬 테스트에 필요)"
        print_info "설치: npm install -g wrangler"
    fi

    print_success "시스템 요구사항 검증 완료"
}

################################################################################
# Step 2: 프로젝트 의존성 설치
################################################################################

install_dependencies() {
    print_header "Step 2: 프로젝트 의존성 설치"

    # 웹사이트 의존성
    print_info "웹사이트 의존성 설치 중..."
    cd "$WEB_DIR"
    npm ci
    print_success "웹사이트 의존성 설치 완료"

    # 테스트 도구 설치
    print_info "테스트 도구 설치 중..."
    npm install --save-dev \
        @playwright/test \
        lighthouse \
        webpack-bundle-analyzer \
        vite-bundle-visualizer

    if command_exists wrangler; then
        print_success "Wrangler 이미 설치됨"
    else
        print_info "Wrangler 설치 중..."
        npm install -g wrangler
        print_success "Wrangler 설치 완료"
    fi

    cd "$PROJECT_ROOT"
    print_success "프로젝트 의존성 설치 완료"
}

################################################################################
# Step 3: 테스트 디렉토리 생성
################################################################################

create_test_directories() {
    print_header "Step 3: 테스트 디렉토리 생성"

    # 리포트 디렉토리
    mkdir -p "$REPORTS_DIR"/{lighthouse,bundle,performance,e2e}
    print_success "리포트 디렉토리 생성: $REPORTS_DIR"

    # 테스트 디렉토리
    mkdir -p "$PROJECT_ROOT/tests"/{e2e,performance,unit,integration}
    print_success "테스트 디렉토리 생성: $PROJECT_ROOT/tests"

    # 임시 파일 디렉토리
    mkdir -p "$PROJECT_ROOT/tmp"
    print_success "임시 디렉토리 생성: $PROJECT_ROOT/tmp"
}

################################################################################
# Step 4: 테스트 데이터 준비
################################################################################

prepare_test_data() {
    print_header "Step 4: 테스트 데이터 준비"

    # 샘플 lyrics 파일
    cat > "$PROJECT_ROOT/tmp/test_lyrics.txt" <<'EOF'
[Verse]
The sun creeps in across the floor
I hear the traffic outside the door
The coffee pot begins to hiss
It is another morning just like this

[Chorus]
Every day the light returns
Every day the fire burns
We keep on walking down this street
Moving to the same steady beat
EOF
    print_success "샘플 lyrics 파일 생성"

    # 샘플 tags 파일
    cat > "$PROJECT_ROOT/tmp/test_tags.txt" <<'EOF'
piano,happy,wedding,synthesizer,romantic
EOF
    print_success "샘플 tags 파일 생성"

    # 테스트 환경 변수
    cat > "$PROJECT_ROOT/.env.test" <<'EOF'
# Cloudflare Workers Test Environment
NODE_ENV=test
BASE_URL=http://localhost:8787

# KV Namespace IDs (Preview)
DOWNLOAD_STATS_PREVIEW_ID=
GALLERY_DATA_PREVIEW_ID=
ANALYTICS_EVENTS_PREVIEW_ID=

# API Keys
CLOUDFLARE_API_TOKEN=
CLOUDFLARE_ACCOUNT_ID=
EOF
    print_success ".env.test 파일 생성"

    print_info "테스트 환경 변수를 .env.test에 설정하세요"
}

################################################################################
# Step 5: Playwright 설정
################################################################################

setup_playwright() {
    print_header "Step 5: Playwright 설정"

    cd "$WEB_DIR"

    # Playwright 설치
    if [ ! -d "node_modules/@playwright/test" ]; then
        print_info "Playwright 설치 중..."
        npm install --save-dev @playwright/test
    fi

    # Playwright 브라우저 설치
    print_info "Playwright 브라우저 설치 중 (Chromium, Firefox, WebKit)..."
    npx playwright install --with-deps

    # Playwright 설정 파일 생성
    if [ ! -f "playwright.config.js" ]; then
        cat > playwright.config.js <<'EOF'
const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
  testDir: '../tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { outputFolder: '../reports/e2e/html' }],
    ['json', { outputFile: '../reports/e2e/results.json' }],
    ['junit', { outputFile: '../reports/e2e/results.xml' }],
  ],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:5173',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'mobile-safari',
      use: { ...devices['iPhone 12'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    port: 5173,
    reuseExistingServer: !process.env.CI,
  },
});
EOF
        print_success "Playwright 설정 파일 생성"
    fi

    cd "$PROJECT_ROOT"
    print_success "Playwright 설정 완료"
}

################################################################################
# Step 6: 샘플 테스트 작성
################################################################################

create_sample_tests() {
    print_header "Step 6: 샘플 테스트 작성"

    # E2E 테스트
    cat > "$PROJECT_ROOT/tests/e2e/homepage.spec.js" <<'EOF'
const { test, expect } = require('@playwright/test');

test.describe('홈페이지 테스트', () => {
  test('페이지 로드 및 타이틀 확인', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/ABADA Music Studio/);
  });

  test('Hero 섹션 표시', async ({ page }) => {
    await page.goto('/');
    const hero = page.locator('.hero-section');
    await expect(hero).toBeVisible();
  });

  test('다운로드 버튼 클릭', async ({ page }) => {
    await page.goto('/');
    await page.click('a[href="/download"]');
    await expect(page).toHaveURL(/.*download/);
  });
});
EOF
    print_success "E2E 테스트 샘플 생성: tests/e2e/homepage.spec.js"

    # 성능 테스트 (k6)
    mkdir -p "$PROJECT_ROOT/tests/performance"
    cat > "$PROJECT_ROOT/tests/performance/load-test.js" <<'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 10 },
    { duration: '1m', target: 10 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    'http_req_duration': ['p(95)<200'],
  },
};

export default function () {
  const res = http.get('http://localhost:5173/');
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
  sleep(1);
}
EOF
    print_success "성능 테스트 샘플 생성: tests/performance/load-test.js"
}

################################################################################
# Step 7: 빌드 및 검증
################################################################################

build_and_validate() {
    print_header "Step 7: 빌드 및 검증"

    cd "$WEB_DIR"

    # 개발 빌드
    print_info "개발 서버 테스트 빌드 중..."
    npm run build
    print_success "빌드 완료"

    # 빌드 결과 확인
    if [ -d "dist" ]; then
        BUNDLE_SIZE=$(du -sh dist | awk '{print $1}')
        print_success "빌드 결과: dist/ ($BUNDLE_SIZE)"
    else
        print_error "빌드 디렉토리(dist/)가 생성되지 않았습니다"
        exit 1
    fi

    cd "$PROJECT_ROOT"
}

################################################################################
# Step 8: 초기 검증 테스트 실행
################################################################################

run_initial_tests() {
    print_header "Step 8: 초기 검증 테스트 실행"

    cd "$WEB_DIR"

    # ESLint 검사
    print_info "ESLint 검사 실행 중..."
    if npm run lint 2>/dev/null; then
        print_success "ESLint 검사 통과"
    else
        print_warning "ESLint 경고 발견 (무시하고 계속)"
    fi

    # TypeScript 타입 체크
    print_info "TypeScript 타입 체크 중..."
    if npx tsc --noEmit 2>/dev/null; then
        print_success "TypeScript 타입 체크 통과"
    else
        print_warning "TypeScript 타입 오류 발견 (무시하고 계속)"
    fi

    cd "$PROJECT_ROOT"
}

################################################################################
# Step 9: 테스트 실행 가이드 출력
################################################################################

print_usage_guide() {
    print_header "Step 9: 테스트 실행 가이드"

    cat <<EOF

${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${GREEN}  테스트 환경 설정 완료${NC}
${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

${BLUE}다음 명령어로 테스트를 실행할 수 있습니다:${NC}

${YELLOW}1. 웹사이트 개발 서버 실행:${NC}
   cd web && npm run dev
   → http://localhost:5173

${YELLOW}2. E2E 테스트 실행:${NC}
   cd web && npx playwright test
   → 리포트: reports/e2e/html/index.html

${YELLOW}3. Lighthouse 성능 테스트:${NC}
   lighthouse http://localhost:5173 --output html --output-path reports/lighthouse/report.html

${YELLOW}4. 번들 사이즈 분석:${NC}
   cd web && npm run build && npx vite-bundle-visualizer
   → 리포트: web/dist/stats.html

${YELLOW}5. API 로컬 테스트 (Wrangler):${NC}
   wrangler dev
   → http://localhost:8787

${YELLOW}6. k6 로드 테스트:${NC}
   k6 run tests/performance/load-test.js

${BLUE}테스트 디렉토리:${NC}
   - E2E 테스트: tests/e2e/
   - 성능 테스트: tests/performance/
   - 리포트: reports/

${BLUE}문서:${NC}
   - 테스트 계획: docs/TESTING_PLAN.md
   - E2E 시나리오: docs/E2E_TEST_SCENARIOS.md
   - 성능 가이드: docs/PERFORMANCE_TEST_GUIDE.md
   - 문제 해결: docs/TROUBLESHOOTING.md

${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

EOF
}

################################################################################
# Main Execution
################################################################################

main() {
    clear
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                                   ║${NC}"
    echo -e "${BLUE}║         ABADA Music Studio - 로컬 테스트 환경 설정 도구           ║${NC}"
    echo -e "${BLUE}║                     버전: v0.3.0 (Phase 2)                        ║${NC}"
    echo -e "${BLUE}║                                                                   ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # 실행 확인
    read -p "로컬 테스트 환경을 설정하시겠습니까? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "설정이 취소되었습니다"
        exit 0
    fi

    # 단계별 실행
    check_system_requirements
    install_dependencies
    create_test_directories
    prepare_test_data
    setup_playwright
    create_sample_tests
    build_and_validate
    run_initial_tests
    print_usage_guide

    print_success "로컬 테스트 환경 설정이 완료되었습니다"
    exit 0
}

# 스크립트 실행
main "$@"
