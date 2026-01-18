#!/bin/bash
# =============================================================================
# DEPLOY.sh
# ABADA Music Studio - 완전 자동화 배포 스크립트
#
# 이 스크립트는 웹사이트 빌드, Cloudflare Pages 배포, Workers API 배포,
# 그리고 배포 후 검증을 자동으로 수행합니다.
#
# 사용법:
#   ./DEPLOY.sh [--dry-run] [--skip-build] [--skip-workers] [--env <environment>]
#
# 옵션:
#   --dry-run       실제 배포 없이 시뮬레이션만 수행
#   --skip-build    웹사이트 빌드 단계 건너뛰기
#   --skip-workers  Workers 배포 건너뛰기
#   --skip-pages    Pages 배포 건너뛰기
#   --env <env>     배포 환경 (development, staging, production)
#
# 요구사항:
#   - Node.js 18+
#   - npm
#   - Wrangler CLI
#   - CLOUDFLARE_API_TOKEN 환경 변수
#   - CLOUDFLARE_ACCOUNT_ID 환경 변수
#
# @author ABADA Inc.
# @version 1.0.0
# @date 2025-01-19
# =============================================================================

set -euo pipefail

# =============================================================================
# 색상 정의
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# =============================================================================
# 설정 변수
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/deploy_$(date +%Y%m%d_%H%M%S).log"
DEPLOYMENT_ID=$(date +%Y%m%d%H%M%S)

# 옵션 플래그
DRY_RUN=false
SKIP_BUILD=false
SKIP_WORKERS=false
SKIP_PAGES=false
ENVIRONMENT="production"

# 프로젝트 설정
PAGES_PROJECT_NAME="abada-music"
WORKER_NAME="abada-music-api"
DOMAIN_NAME="music.abada.kr"
WEB_DIR="$PROJECT_ROOT/web"
FUNCTIONS_DIR="$PROJECT_ROOT/functions"
BUILD_DIR="$WEB_DIR/dist"

# 배포 상태 추적
DEPLOY_START_TIME=""
BUILD_SUCCESS=false
PAGES_DEPLOY_SUCCESS=false
WORKERS_DEPLOY_SUCCESS=false
HEALTH_CHECK_SUCCESS=false

# =============================================================================
# 유틸리티 함수
# =============================================================================

# 로그 디렉토리 생성
mkdir -p "$LOG_DIR"

# 로깅 함수
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# 출력 함수
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log "SUCCESS" "$1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "ERROR" "$1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log "WARNING" "$1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO" "$1"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
    log "STEP" "$1"
}

print_header() {
    echo ""
    echo -e "${MAGENTA}${BOLD}============================================${NC}"
    echo -e "${MAGENTA}${BOLD}  $1${NC}"
    echo -e "${MAGENTA}${BOLD}============================================${NC}"
    echo ""
    log "HEADER" "$1"
}

# 프로그레스 스피너
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "      \b\b\b\b\b\b"
}

# 실행 시간 계산
get_elapsed_time() {
    local start=$1
    local end=$(date +%s)
    local elapsed=$((end - start))
    echo "${elapsed}초"
}

# 롤백 함수
rollback() {
    print_header "롤백 시작"

    print_warning "배포 실패로 인해 롤백을 수행합니다."

    # Pages 롤백 (이전 배포로 복원)
    if $PAGES_DEPLOY_SUCCESS; then
        print_step "Cloudflare Pages 롤백 중..."
        # 실제 롤백은 Cloudflare Dashboard에서 수동으로 수행
        print_warning "Pages 롤백은 Cloudflare Dashboard에서 수동으로 수행해주세요."
        print_info "https://dash.cloudflare.com 에서 이전 배포를 선택하여 롤백"
    fi

    # Workers 롤백
    if $WORKERS_DEPLOY_SUCCESS; then
        print_step "Cloudflare Workers 롤백 중..."
        print_warning "Workers 롤백은 다음 명령어로 수행할 수 있습니다:"
        print_info "  wrangler rollback"
    fi

    print_error "롤백 필요: 배포가 실패했습니다."
    print_info "롤백 스크립트: ./scripts/ROLLBACK.sh"
}

# 종료 핸들러
cleanup() {
    local exit_code=$?
    local end_time=$(date +%s)

    if [ $exit_code -ne 0 ]; then
        print_error "배포가 오류로 종료되었습니다. (종료 코드: $exit_code)"
        rollback
    fi

    log "INFO" "배포 프로세스 종료 (종료 코드: $exit_code)"
}

trap cleanup EXIT

# =============================================================================
# 환경 검증
# =============================================================================

check_environment() {
    print_header "환경 요구사항 검증"

    local missing_deps=()
    local missing_env=()

    # Node.js 확인
    print_step "Node.js 확인 중..."
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        local node_major=$(echo "$node_version" | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$node_major" -ge 18 ]; then
            print_success "Node.js $node_version"
        else
            print_warning "Node.js 18+ 권장 (현재: $node_version)"
        fi
    else
        missing_deps+=("Node.js")
        print_error "Node.js가 설치되어 있지 않습니다"
    fi

    # npm 확인
    print_step "npm 확인 중..."
    if command -v npm &> /dev/null; then
        print_success "npm $(npm --version)"
    else
        missing_deps+=("npm")
        print_error "npm이 설치되어 있지 않습니다"
    fi

    # Wrangler 확인
    print_step "Wrangler CLI 확인 중..."
    if command -v wrangler &> /dev/null; then
        local wrangler_version=$(wrangler --version 2>/dev/null | head -1)
        print_success "Wrangler $wrangler_version"
    else
        print_warning "Wrangler CLI가 설치되어 있지 않습니다. 설치합니다..."
        if ! $DRY_RUN; then
            npm install -g wrangler || {
                missing_deps+=("Wrangler")
            }
        fi
    fi

    # 환경 변수 확인
    print_step "환경 변수 확인 중..."

    # .env.cloudflare 파일 로드
    if [ -f "$PROJECT_ROOT/.env.cloudflare" ]; then
        source "$PROJECT_ROOT/.env.cloudflare"
        print_info ".env.cloudflare 파일 로드됨"
    fi

    if [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
        missing_env+=("CLOUDFLARE_API_TOKEN")
        print_error "CLOUDFLARE_API_TOKEN이 설정되지 않았습니다"
    else
        print_success "CLOUDFLARE_API_TOKEN 설정됨"
    fi

    if [ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
        missing_env+=("CLOUDFLARE_ACCOUNT_ID")
        print_error "CLOUDFLARE_ACCOUNT_ID가 설정되지 않았습니다"
    else
        print_success "CLOUDFLARE_ACCOUNT_ID 설정됨"
    fi

    # 프로젝트 구조 확인
    print_step "프로젝트 구조 확인 중..."

    if [ ! -d "$WEB_DIR" ]; then
        print_error "웹 디렉토리가 없습니다: $WEB_DIR"
        missing_deps+=("web directory")
    else
        print_success "웹 디렉토리 확인됨: $WEB_DIR"
    fi

    if [ ! -f "$WEB_DIR/package.json" ]; then
        print_error "package.json이 없습니다: $WEB_DIR/package.json"
        missing_deps+=("package.json")
    else
        print_success "package.json 확인됨"
    fi

    if [ ! -f "$PROJECT_ROOT/wrangler.toml" ]; then
        print_error "wrangler.toml이 없습니다"
        missing_deps+=("wrangler.toml")
    else
        print_success "wrangler.toml 확인됨"
    fi

    if [ ! -d "$FUNCTIONS_DIR" ]; then
        print_warning "functions 디렉토리가 없습니다. Workers 배포를 건너뜁니다."
        SKIP_WORKERS=true
    else
        print_success "functions 디렉토리 확인됨"
    fi

    # 결과 확인
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "누락된 의존성: ${missing_deps[*]}"
        exit 1
    fi

    if [ ${#missing_env[@]} -gt 0 ]; then
        print_error "누락된 환경 변수: ${missing_env[*]}"
        print_info "환경 변수 설정 방법:"
        print_info "  export CLOUDFLARE_API_TOKEN='your-token'"
        print_info "  export CLOUDFLARE_ACCOUNT_ID='your-account-id'"
        print_info ""
        print_info "또는 ./scripts/GITHUB_ACTIONS_SECRETS_SETUP.sh 실행"
        exit 1
    fi

    print_success "모든 환경 요구사항 충족"
}

# =============================================================================
# 웹사이트 빌드
# =============================================================================

build_website() {
    print_header "웹사이트 빌드"

    if $SKIP_BUILD; then
        print_info "빌드 단계 건너뜀 (--skip-build)"

        if [ ! -d "$BUILD_DIR" ]; then
            print_error "빌드 디렉토리가 없습니다: $BUILD_DIR"
            print_info "먼저 빌드를 수행하거나 --skip-build 옵션을 제거하세요."
            exit 1
        fi

        print_success "기존 빌드 사용: $BUILD_DIR"
        BUILD_SUCCESS=true
        return 0
    fi

    if $DRY_RUN; then
        print_info "[DRY-RUN] 빌드 건너뜀"
        BUILD_SUCCESS=true
        return 0
    fi

    local build_start=$(date +%s)

    # 의존성 설치
    print_step "의존성 설치 중..."
    cd "$WEB_DIR"

    if [ -f "package-lock.json" ]; then
        npm ci --silent 2>&1 | tee -a "$LOG_FILE" || {
            print_warning "npm ci 실패, npm install 시도..."
            npm install --silent 2>&1 | tee -a "$LOG_FILE" || {
                print_error "의존성 설치 실패"
                exit 1
            }
        }
    else
        npm install --silent 2>&1 | tee -a "$LOG_FILE" || {
            print_error "의존성 설치 실패"
            exit 1
        }
    fi

    print_success "의존성 설치 완료"

    # 빌드 실행
    print_step "프로덕션 빌드 중..."

    NODE_ENV=production npm run build 2>&1 | tee -a "$LOG_FILE" || {
        print_error "빌드 실패"
        exit 1
    }

    # 빌드 결과 확인
    if [ ! -d "$BUILD_DIR" ]; then
        # dist 대신 build 디렉토리 확인
        if [ -d "$WEB_DIR/build" ]; then
            BUILD_DIR="$WEB_DIR/build"
        else
            print_error "빌드 출력 디렉토리를 찾을 수 없습니다"
            exit 1
        fi
    fi

    local build_size=$(du -sh "$BUILD_DIR" | cut -f1)
    local file_count=$(find "$BUILD_DIR" -type f | wc -l | tr -d ' ')
    local build_time=$(get_elapsed_time $build_start)

    print_success "빌드 완료"
    print_info "  출력 디렉토리: $BUILD_DIR"
    print_info "  빌드 크기: $build_size"
    print_info "  파일 수: $file_count"
    print_info "  빌드 시간: $build_time"

    BUILD_SUCCESS=true
    cd "$PROJECT_ROOT"
}

# =============================================================================
# Cloudflare Pages 배포
# =============================================================================

deploy_pages() {
    print_header "Cloudflare Pages 배포"

    if $SKIP_PAGES; then
        print_info "Pages 배포 건너뜀 (--skip-pages)"
        return 0
    fi

    if $DRY_RUN; then
        print_info "[DRY-RUN] Pages 배포 건너뜀"
        PAGES_DEPLOY_SUCCESS=true
        return 0
    fi

    local deploy_start=$(date +%s)

    print_step "Cloudflare Pages에 배포 중..."
    print_info "  프로젝트: $PAGES_PROJECT_NAME"
    print_info "  빌드 디렉토리: $BUILD_DIR"

    # wrangler pages deploy 실행
    local deploy_output=$(wrangler pages deploy "$BUILD_DIR" \
        --project-name="$PAGES_PROJECT_NAME" \
        --commit-dirty=true \
        --branch=main \
        2>&1)

    local deploy_exit_code=$?
    echo "$deploy_output" >> "$LOG_FILE"

    if [ $deploy_exit_code -eq 0 ]; then
        # 배포 URL 추출
        local deploy_url=$(echo "$deploy_output" | grep -oE 'https://[^ ]+\.pages\.dev' | head -1 || echo "")

        print_success "Cloudflare Pages 배포 완료"
        if [ -n "$deploy_url" ]; then
            print_info "  미리보기 URL: $deploy_url"
        fi
        print_info "  프로덕션 URL: https://$DOMAIN_NAME"
        print_info "  배포 시간: $(get_elapsed_time $deploy_start)"

        PAGES_DEPLOY_SUCCESS=true
    else
        print_error "Cloudflare Pages 배포 실패"
        print_info "오류 출력:"
        echo "$deploy_output"
        exit 1
    fi
}

# =============================================================================
# Cloudflare Workers 배포
# =============================================================================

deploy_workers() {
    print_header "Cloudflare Workers API 배포"

    if $SKIP_WORKERS; then
        print_info "Workers 배포 건너뜀 (--skip-workers)"
        return 0
    fi

    if [ ! -d "$FUNCTIONS_DIR" ]; then
        print_warning "functions 디렉토리가 없습니다. Workers 배포를 건너뜁니다."
        return 0
    fi

    if $DRY_RUN; then
        print_info "[DRY-RUN] Workers 배포 건너뜀"
        WORKERS_DEPLOY_SUCCESS=true
        return 0
    fi

    local deploy_start=$(date +%s)

    print_step "Cloudflare Workers에 배포 중..."
    print_info "  워커 이름: $WORKER_NAME"

    cd "$PROJECT_ROOT"

    # 환경별 배포
    local env_flag=""
    if [ "$ENVIRONMENT" != "production" ]; then
        env_flag="--env $ENVIRONMENT"
    fi

    # wrangler deploy 실행
    local deploy_output=$(wrangler deploy $env_flag 2>&1)
    local deploy_exit_code=$?

    echo "$deploy_output" >> "$LOG_FILE"

    if [ $deploy_exit_code -eq 0 ]; then
        # Workers URL 추출
        local workers_url=$(echo "$deploy_output" | grep -oE 'https://[^ ]+\.workers\.dev' | head -1 || echo "")

        print_success "Cloudflare Workers 배포 완료"
        if [ -n "$workers_url" ]; then
            print_info "  Workers URL: $workers_url"
        fi
        print_info "  배포 시간: $(get_elapsed_time $deploy_start)"

        WORKERS_DEPLOY_SUCCESS=true
    else
        print_error "Cloudflare Workers 배포 실패"
        print_info "오류 출력:"
        echo "$deploy_output"
        exit 1
    fi
}

# =============================================================================
# 배포 후 검증
# =============================================================================

run_health_checks() {
    print_header "배포 후 헬스 체크"

    if $DRY_RUN; then
        print_info "[DRY-RUN] 헬스 체크 건너뜀"
        HEALTH_CHECK_SUCCESS=true
        return 0
    fi

    local checks_passed=0
    local checks_total=0

    # 웹사이트 접근성 확인
    print_step "웹사이트 접근성 확인 중..."

    local website_url="https://$DOMAIN_NAME"
    local pages_url="https://${PAGES_PROJECT_NAME}.pages.dev"

    # 대기 시간 (배포 전파)
    print_info "배포 전파 대기 중 (10초)..."
    sleep 10

    # Pages URL 확인
    ((checks_total++))
    local pages_response=$(curl -s -o /dev/null -w "%{http_code}" "$pages_url" --connect-timeout 10 --max-time 30 2>/dev/null || echo "000")
    if [ "$pages_response" = "200" ]; then
        print_success "Pages URL 접근 가능: $pages_url (HTTP $pages_response)"
        ((checks_passed++))
    else
        print_warning "Pages URL 접근 실패: $pages_url (HTTP $pages_response)"
    fi

    # 커스텀 도메인 확인 (설정된 경우)
    ((checks_total++))
    local domain_response=$(curl -s -o /dev/null -w "%{http_code}" "$website_url" --connect-timeout 10 --max-time 30 2>/dev/null || echo "000")
    if [ "$domain_response" = "200" ]; then
        print_success "커스텀 도메인 접근 가능: $website_url (HTTP $domain_response)"
        ((checks_passed++))
    else
        print_warning "커스텀 도메인 접근 실패: $website_url (HTTP $domain_response)"
        print_info "DNS 설정을 확인하세요."
    fi

    # Workers API 헬스 체크
    if $WORKERS_DEPLOY_SUCCESS; then
        print_step "Workers API 헬스 체크 중..."

        local api_health_url="https://${WORKER_NAME}.${CLOUDFLARE_ACCOUNT_ID}.workers.dev/api/health"
        # 또는 커스텀 도메인 사용
        local api_health_url_custom="$website_url/api/health"

        ((checks_total++))
        local api_response=$(curl -s "$api_health_url_custom" --connect-timeout 10 --max-time 30 2>/dev/null || echo "")

        if echo "$api_response" | grep -q '"status":"ok"'; then
            print_success "API 헬스 체크 통과"
            ((checks_passed++))
        else
            # Workers.dev URL 시도
            api_response=$(curl -s "$api_health_url" --connect-timeout 10 --max-time 30 2>/dev/null || echo "")
            if echo "$api_response" | grep -q '"status":"ok"'; then
                print_success "API 헬스 체크 통과 (workers.dev)"
                ((checks_passed++))
            else
                print_warning "API 헬스 체크 실패"
                print_info "응답: $api_response"
            fi
        fi

        # API 엔드포인트 테스트
        print_step "API 엔드포인트 테스트 중..."

        # /api 루트 확인
        ((checks_total++))
        local api_root_response=$(curl -s "$website_url/api" --connect-timeout 10 --max-time 30 2>/dev/null || echo "")
        if echo "$api_root_response" | grep -q '"name":"ABADA Music Studio API"'; then
            print_success "API 루트 엔드포인트 응답 정상"
            ((checks_passed++))
        else
            print_warning "API 루트 엔드포인트 응답 이상"
        fi

        # /api/stats 확인
        ((checks_total++))
        local stats_response=$(curl -s "$website_url/api/stats" --connect-timeout 10 --max-time 30 2>/dev/null || echo "")
        if [ -n "$stats_response" ]; then
            print_success "API /api/stats 엔드포인트 응답"
            ((checks_passed++))
        else
            print_warning "API /api/stats 엔드포인트 응답 없음"
        fi
    fi

    # 결과 요약
    echo ""
    echo -e "${BOLD}헬스 체크 결과: $checks_passed/$checks_total 통과${NC}"

    if [ $checks_passed -eq $checks_total ]; then
        print_success "모든 헬스 체크 통과"
        HEALTH_CHECK_SUCCESS=true
    elif [ $checks_passed -gt 0 ]; then
        print_warning "일부 헬스 체크 실패"
        HEALTH_CHECK_SUCCESS=true
    else
        print_error "모든 헬스 체크 실패"
        HEALTH_CHECK_SUCCESS=false
    fi
}

# =============================================================================
# 배포 요약
# =============================================================================

print_deployment_summary() {
    print_header "배포 완료 요약"

    local end_time=$(date +%s)
    local total_time=$((end_time - DEPLOY_START_TIME))

    echo -e "${BOLD}배포 정보:${NC}"
    echo "========================================"
    echo "  배포 ID: $DEPLOYMENT_ID"
    echo "  환경: $ENVIRONMENT"
    echo "  총 소요 시간: ${total_time}초"
    echo ""
    echo -e "${BOLD}상태:${NC}"
    echo "  빌드: $([ "$BUILD_SUCCESS" = true ] && echo -e "${GREEN}성공${NC}" || echo -e "${RED}실패${NC}")"
    if ! $SKIP_PAGES; then
        echo "  Pages 배포: $([ "$PAGES_DEPLOY_SUCCESS" = true ] && echo -e "${GREEN}성공${NC}" || echo -e "${RED}실패${NC}")"
    fi
    if ! $SKIP_WORKERS; then
        echo "  Workers 배포: $([ "$WORKERS_DEPLOY_SUCCESS" = true ] && echo -e "${GREEN}성공${NC}" || echo -e "${RED}실패${NC}")"
    fi
    echo "  헬스 체크: $([ "$HEALTH_CHECK_SUCCESS" = true ] && echo -e "${GREEN}성공${NC}" || echo -e "${YELLOW}경고${NC}")"
    echo ""
    echo -e "${BOLD}URL:${NC}"
    echo "  웹사이트: https://$DOMAIN_NAME"
    echo "  Pages: https://${PAGES_PROJECT_NAME}.pages.dev"
    if ! $SKIP_WORKERS; then
        echo "  API: https://$DOMAIN_NAME/api"
    fi
    echo "========================================"
    echo ""

    echo -e "${BOLD}다음 단계:${NC}"
    echo "  1. 배포 검증 스크립트 실행:"
    echo "     ./scripts/POST_DEPLOY_VERIFICATION.sh"
    echo ""
    echo "  2. 문제 발생 시 롤백:"
    echo "     ./scripts/ROLLBACK.sh"
    echo ""

    if [ -f "$LOG_FILE" ]; then
        print_info "상세 로그: $LOG_FILE"
    fi

    # 배포 로그 생성
    create_deployment_log
}

# =============================================================================
# 배포 로그 생성
# =============================================================================

create_deployment_log() {
    local deploy_log_file="$LOG_DIR/deployment_${DEPLOYMENT_ID}.md"

    cat > "$deploy_log_file" << EOF
# Deployment Log - $DEPLOYMENT_ID

## Deployment Information
- **Deployment ID**: $DEPLOYMENT_ID
- **Timestamp**: $(date '+%Y-%m-%d %H:%M:%S')
- **Environment**: $ENVIRONMENT
- **Git Branch**: $(git -C "$PROJECT_ROOT" branch --show-current 2>/dev/null || echo "N/A")
- **Git Commit**: $(git -C "$PROJECT_ROOT" rev-parse HEAD 2>/dev/null || echo "N/A")

## Status
| Component | Status |
|-----------|--------|
| Build | $([ "$BUILD_SUCCESS" = true ] && echo "SUCCESS" || echo "FAILED") |
| Pages Deploy | $([ "$PAGES_DEPLOY_SUCCESS" = true ] && echo "SUCCESS" || echo "SKIPPED/FAILED") |
| Workers Deploy | $([ "$WORKERS_DEPLOY_SUCCESS" = true ] && echo "SUCCESS" || echo "SKIPPED/FAILED") |
| Health Check | $([ "$HEALTH_CHECK_SUCCESS" = true ] && echo "PASSED" || echo "WARNING/FAILED") |

## URLs
- Website: https://$DOMAIN_NAME
- Pages: https://${PAGES_PROJECT_NAME}.pages.dev
- API: https://$DOMAIN_NAME/api

## Options Used
- DRY_RUN: $DRY_RUN
- SKIP_BUILD: $SKIP_BUILD
- SKIP_PAGES: $SKIP_PAGES
- SKIP_WORKERS: $SKIP_WORKERS

## Log File
$LOG_FILE
EOF

    print_info "배포 로그 생성됨: $deploy_log_file"
}

# =============================================================================
# 메인 실행
# =============================================================================

main() {
    DEPLOY_START_TIME=$(date +%s)

    # 인자 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                print_warning "DRY-RUN 모드: 실제 배포 없이 시뮬레이션만 수행합니다."
                shift
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --skip-workers)
                SKIP_WORKERS=true
                shift
                ;;
            --skip-pages)
                SKIP_PAGES=true
                shift
                ;;
            --env)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -h|--help)
                echo "사용법: $0 [옵션]"
                echo ""
                echo "옵션:"
                echo "  --dry-run       실제 배포 없이 시뮬레이션만 수행"
                echo "  --skip-build    웹사이트 빌드 단계 건너뛰기"
                echo "  --skip-workers  Workers 배포 건너뛰기"
                echo "  --skip-pages    Pages 배포 건너뛰기"
                echo "  --env <env>     배포 환경 (development, staging, production)"
                echo "  -h, --help      이 도움말 표시"
                exit 0
                ;;
            *)
                print_error "알 수 없는 옵션: $1"
                exit 1
                ;;
        esac
    done

    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "  ___  ______  ___  ____   ___    __  __           _      "
    echo " / _ \ | ___ \/ _ \|  _ \ / _ \  |  \/  |_   _ ___(_) ___ "
    echo "| |_| || |_/ / /_\ \ | | | |_| | | |\/| | | | / __| |/ __|"
    echo "|  _  || ___ \  _  | |_| |  _  | | |  | | |_| \__ \ | (__ "
    echo "|_| |_||_| \_\_| |_|____/|_| |_| |_|  |_|\__,_|___/_|\___|"
    echo ""
    echo "  Deployment Script v1.0.0"
    echo "  Environment: $ENVIRONMENT"
    echo -e "${NC}"

    log "INFO" "배포 스크립트 시작"
    log "INFO" "배포 ID: $DEPLOYMENT_ID"
    log "INFO" "환경: $ENVIRONMENT"
    log "INFO" "DRY_RUN: $DRY_RUN"

    # 실행 단계
    check_environment
    build_website
    deploy_pages
    deploy_workers
    run_health_checks
    print_deployment_summary

    log "INFO" "배포 스크립트 완료"

    if $BUILD_SUCCESS && $HEALTH_CHECK_SUCCESS; then
        print_success "배포가 성공적으로 완료되었습니다!"
        exit 0
    else
        print_warning "배포가 완료되었지만 일부 문제가 있습니다."
        exit 1
    fi
}

# 스크립트 실행
main "$@"
