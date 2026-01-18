#!/bin/bash
# =============================================================================
# CLOUDFLARE_SETUP_AUTOMATION.sh
# ABADA Music Studio - Cloudflare 자동 설정 스크립트
#
# 이 스크립트는 Cloudflare Pages 프로젝트 생성, KV 네임스페이스 생성,
# wrangler.toml 구성을 자동화합니다.
#
# 사용법:
#   ./CLOUDFLARE_SETUP_AUTOMATION.sh [--dry-run]
#
# 옵션:
#   --dry-run    실제 실행 없이 시뮬레이션만 수행
#
# 요구사항:
#   - Node.js 18+
#   - Wrangler CLI (npm install -g wrangler)
#   - Cloudflare 계정 및 API 토큰
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
WRANGLER_TOML="$PROJECT_ROOT/wrangler.toml"
LOG_FILE="$PROJECT_ROOT/logs/cloudflare_setup_$(date +%Y%m%d_%H%M%S).log"
DRY_RUN=false

# 프로젝트 설정
PROJECT_NAME="abada-music"
PAGES_PROJECT_NAME="abada-music"
WORKER_NAME="abada-music-api"
DOMAIN_NAME="music.abada.kr"

# KV 네임스페이스 이름
KV_NAMESPACES=("STATS" "GALLERY" "ANALYTICS")

# =============================================================================
# 유틸리티 함수
# =============================================================================

# 로그 디렉토리 생성
mkdir -p "$PROJECT_ROOT/logs"

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

# 프로그레스 바
show_progress() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))

    printf "\r["
    printf "%${completed}s" | tr ' ' '#'
    printf "%${remaining}s" | tr ' ' '-'
    printf "] %3d%%" "$percentage"
}

# API 토큰 마스킹
mask_token() {
    local token=$1
    local length=${#token}
    if [ $length -le 8 ]; then
        echo "********"
    else
        echo "${token:0:4}...${token: -4}"
    fi
}

# 타임아웃 명령어 실행
run_with_timeout() {
    local timeout=$1
    shift
    local cmd="$@"

    if $DRY_RUN; then
        print_info "[DRY-RUN] 실행 예정: $cmd"
        return 0
    fi

    timeout $timeout bash -c "$cmd" 2>&1 || {
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            print_error "명령어 타임아웃 (${timeout}초 초과)"
        fi
        return $exit_code
    }
}

# =============================================================================
# 환경 검증 함수
# =============================================================================

check_prerequisites() {
    print_header "환경 요구사항 검증"

    local missing_deps=()

    # Node.js 확인
    print_step "Node.js 확인 중..."
    if command -v node &> /dev/null; then
        local node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$node_version" -ge 18 ]; then
            print_success "Node.js $(node --version) 설치됨"
        else
            print_warning "Node.js 18+ 권장 (현재: $(node --version))"
        fi
    else
        missing_deps+=("Node.js")
        print_error "Node.js가 설치되어 있지 않습니다"
    fi

    # npm 확인
    print_step "npm 확인 중..."
    if command -v npm &> /dev/null; then
        print_success "npm $(npm --version) 설치됨"
    else
        missing_deps+=("npm")
        print_error "npm이 설치되어 있지 않습니다"
    fi

    # Wrangler 확인
    print_step "Wrangler CLI 확인 중..."
    if command -v wrangler &> /dev/null; then
        local wrangler_version=$(wrangler --version 2>/dev/null | head -1)
        print_success "Wrangler $wrangler_version 설치됨"
    else
        print_warning "Wrangler CLI가 설치되어 있지 않습니다. 설치합니다..."
        if ! $DRY_RUN; then
            npm install -g wrangler || {
                print_error "Wrangler 설치 실패"
                missing_deps+=("Wrangler")
            }
        fi
    fi

    # jq 확인 (JSON 처리용)
    print_step "jq 확인 중..."
    if command -v jq &> /dev/null; then
        print_success "jq $(jq --version) 설치됨"
    else
        print_warning "jq가 설치되어 있지 않습니다 (선택사항)"
    fi

    # curl 확인
    print_step "curl 확인 중..."
    if command -v curl &> /dev/null; then
        print_success "curl 설치됨"
    else
        missing_deps+=("curl")
        print_error "curl이 설치되어 있지 않습니다"
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "누락된 의존성: ${missing_deps[*]}"
        print_info "위 프로그램들을 먼저 설치해주세요."
        exit 1
    fi

    print_success "모든 환경 요구사항 충족"
}

# =============================================================================
# Cloudflare 인증 함수
# =============================================================================

setup_cloudflare_auth() {
    print_header "Cloudflare 인증 설정"

    # 환경 변수 확인
    if [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
        print_info "환경 변수에서 CLOUDFLARE_API_TOKEN 감지됨"
        CF_API_TOKEN="$CLOUDFLARE_API_TOKEN"
    else
        print_info "Cloudflare API 토큰을 입력해주세요."
        print_info "토큰 생성 위치: https://dash.cloudflare.com/profile/api-tokens"
        print_info ""
        print_info "필요한 권한:"
        print_info "  - Account:Cloudflare Pages:Edit"
        print_info "  - Account:Workers KV Storage:Edit"
        print_info "  - Account:Workers Scripts:Edit"
        print_info "  - Zone:DNS:Edit (선택사항)"
        echo ""
        read -sp "API 토큰: " CF_API_TOKEN
        echo ""
    fi

    if [ -z "$CF_API_TOKEN" ]; then
        print_error "API 토큰이 필요합니다."
        exit 1
    fi

    # 토큰 검증
    print_step "API 토큰 검증 중..."
    if ! $DRY_RUN; then
        local verify_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json")

        local success=$(echo "$verify_response" | grep -o '"success":true' || echo "")

        if [ -z "$success" ]; then
            print_error "API 토큰 검증 실패"
            print_info "응답: $verify_response"
            exit 1
        fi

        print_success "API 토큰 검증 완료 ($(mask_token "$CF_API_TOKEN"))"
    else
        print_info "[DRY-RUN] API 토큰 검증 건너뜀"
    fi

    # Account ID 확인
    if [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
        print_info "환경 변수에서 CLOUDFLARE_ACCOUNT_ID 감지됨"
        CF_ACCOUNT_ID="$CLOUDFLARE_ACCOUNT_ID"
    else
        print_step "Cloudflare Account ID 조회 중..."
        if ! $DRY_RUN; then
            local accounts_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts" \
                -H "Authorization: Bearer $CF_API_TOKEN" \
                -H "Content-Type: application/json")

            if command -v jq &> /dev/null; then
                local account_id=$(echo "$accounts_response" | jq -r '.result[0].id // empty')
                local account_name=$(echo "$accounts_response" | jq -r '.result[0].name // empty')
            else
                local account_id=$(echo "$accounts_response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
                local account_name=$(echo "$accounts_response" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
            fi

            if [ -n "$account_id" ]; then
                print_info "발견된 계정: $account_name ($account_id)"
                read -p "이 계정을 사용하시겠습니까? (y/n): " use_account
                if [[ "$use_account" =~ ^[Yy]$ ]]; then
                    CF_ACCOUNT_ID="$account_id"
                else
                    read -p "Account ID를 직접 입력하세요: " CF_ACCOUNT_ID
                fi
            else
                print_warning "계정을 자동으로 찾을 수 없습니다."
                read -p "Account ID를 입력하세요: " CF_ACCOUNT_ID
            fi
        else
            read -p "[DRY-RUN] Account ID를 입력하세요: " CF_ACCOUNT_ID
        fi
    fi

    if [ -z "$CF_ACCOUNT_ID" ]; then
        print_error "Account ID가 필요합니다."
        exit 1
    fi

    print_success "Cloudflare 인증 설정 완료"
    print_info "  Account ID: $CF_ACCOUNT_ID"
    print_info "  API Token: $(mask_token "$CF_API_TOKEN")"

    # 환경 변수 내보내기
    export CLOUDFLARE_API_TOKEN="$CF_API_TOKEN"
    export CLOUDFLARE_ACCOUNT_ID="$CF_ACCOUNT_ID"
}

# =============================================================================
# Cloudflare Pages 프로젝트 생성
# =============================================================================

create_pages_project() {
    print_header "Cloudflare Pages 프로젝트 생성"

    print_step "기존 프로젝트 확인 중..."

    if ! $DRY_RUN; then
        local projects_response=$(curl -s -X GET \
            "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/pages/projects" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json")

        # 프로젝트 존재 여부 확인
        local existing_project=""
        if command -v jq &> /dev/null; then
            existing_project=$(echo "$projects_response" | jq -r ".result[] | select(.name==\"$PAGES_PROJECT_NAME\") | .name // empty")
        else
            existing_project=$(echo "$projects_response" | grep -o "\"name\":\"$PAGES_PROJECT_NAME\"" || echo "")
        fi

        if [ -n "$existing_project" ]; then
            print_warning "프로젝트 '$PAGES_PROJECT_NAME'이(가) 이미 존재합니다."
            read -p "계속 진행하시겠습니까? (y/n): " continue_setup
            if [[ ! "$continue_setup" =~ ^[Yy]$ ]]; then
                print_info "프로젝트 생성을 건너뜁니다."
                return 0
            fi
        else
            print_step "새 Pages 프로젝트 생성 중: $PAGES_PROJECT_NAME"

            local create_response=$(curl -s -X POST \
                "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/pages/projects" \
                -H "Authorization: Bearer $CF_API_TOKEN" \
                -H "Content-Type: application/json" \
                --data "{
                    \"name\": \"$PAGES_PROJECT_NAME\",
                    \"production_branch\": \"main\",
                    \"build_config\": {
                        \"build_command\": \"npm run build\",
                        \"destination_dir\": \"dist\",
                        \"root_dir\": \"web\"
                    }
                }")

            local success=$(echo "$create_response" | grep -o '"success":true' || echo "")

            if [ -n "$success" ]; then
                print_success "Pages 프로젝트 생성 완료: $PAGES_PROJECT_NAME"
            else
                print_error "Pages 프로젝트 생성 실패"
                print_info "응답: $create_response"
            fi
        fi
    else
        print_info "[DRY-RUN] Pages 프로젝트 생성 건너뜀: $PAGES_PROJECT_NAME"
    fi
}

# =============================================================================
# KV 네임스페이스 생성
# =============================================================================

create_kv_namespaces() {
    print_header "KV 네임스페이스 생성"

    local total=${#KV_NAMESPACES[@]}
    local current=0

    # 결과 저장을 위한 배열
    declare -A KV_IDS
    declare -A KV_PREVIEW_IDS

    for ns in "${KV_NAMESPACES[@]}"; do
        ((current++))
        show_progress $current $total
        echo ""

        print_step "KV 네임스페이스 생성 중: $ns"

        if ! $DRY_RUN; then
            # 프로덕션 네임스페이스 생성
            local ns_name="${WORKER_NAME}_${ns}"

            # 기존 네임스페이스 확인
            local existing_response=$(curl -s -X GET \
                "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/storage/kv/namespaces" \
                -H "Authorization: Bearer $CF_API_TOKEN" \
                -H "Content-Type: application/json")

            local existing_id=""
            if command -v jq &> /dev/null; then
                existing_id=$(echo "$existing_response" | jq -r ".result[] | select(.title==\"$ns_name\") | .id // empty")
            else
                # 간단한 grep 기반 파싱
                existing_id=$(echo "$existing_response" | grep -o "\"title\":\"$ns_name\"[^}]*\"id\":\"[^\"]*\"" | grep -o '"id":"[^"]*"' | cut -d'"' -f4 || echo "")
            fi

            if [ -n "$existing_id" ]; then
                print_info "기존 네임스페이스 사용: $ns_name ($existing_id)"
                KV_IDS[$ns]=$existing_id
            else
                # 새 네임스페이스 생성
                local create_response=$(curl -s -X POST \
                    "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/storage/kv/namespaces" \
                    -H "Authorization: Bearer $CF_API_TOKEN" \
                    -H "Content-Type: application/json" \
                    --data "{\"title\": \"$ns_name\"}")

                local new_id=""
                if command -v jq &> /dev/null; then
                    new_id=$(echo "$create_response" | jq -r '.result.id // empty')
                else
                    new_id=$(echo "$create_response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
                fi

                if [ -n "$new_id" ]; then
                    print_success "네임스페이스 생성됨: $ns_name ($new_id)"
                    KV_IDS[$ns]=$new_id
                else
                    print_error "네임스페이스 생성 실패: $ns_name"
                    print_info "응답: $create_response"
                fi
            fi

            # 프리뷰 네임스페이스 생성
            local preview_ns_name="${WORKER_NAME}_${ns}_preview"

            local existing_preview_id=""
            if command -v jq &> /dev/null; then
                existing_preview_id=$(echo "$existing_response" | jq -r ".result[] | select(.title==\"$preview_ns_name\") | .id // empty")
            fi

            if [ -n "$existing_preview_id" ]; then
                print_info "기존 프리뷰 네임스페이스 사용: $preview_ns_name ($existing_preview_id)"
                KV_PREVIEW_IDS[$ns]=$existing_preview_id
            else
                local preview_response=$(curl -s -X POST \
                    "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/storage/kv/namespaces" \
                    -H "Authorization: Bearer $CF_API_TOKEN" \
                    -H "Content-Type: application/json" \
                    --data "{\"title\": \"$preview_ns_name\"}")

                local preview_id=""
                if command -v jq &> /dev/null; then
                    preview_id=$(echo "$preview_response" | jq -r '.result.id // empty')
                else
                    preview_id=$(echo "$preview_response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
                fi

                if [ -n "$preview_id" ]; then
                    print_success "프리뷰 네임스페이스 생성됨: $preview_ns_name ($preview_id)"
                    KV_PREVIEW_IDS[$ns]=$preview_id
                else
                    print_warning "프리뷰 네임스페이스 생성 건너뜀"
                fi
            fi
        else
            print_info "[DRY-RUN] KV 네임스페이스 생성 건너뜀: $ns"
            KV_IDS[$ns]="DRY_RUN_${ns}_ID"
            KV_PREVIEW_IDS[$ns]="DRY_RUN_${ns}_PREVIEW_ID"
        fi
    done

    echo ""
    print_success "KV 네임스페이스 설정 완료"

    # 결과 요약 출력
    echo ""
    echo -e "${BOLD}생성된 KV 네임스페이스:${NC}"
    echo "----------------------------------------"
    for ns in "${KV_NAMESPACES[@]}"; do
        echo "  $ns:"
        echo "    Production: ${KV_IDS[$ns]:-N/A}"
        echo "    Preview: ${KV_PREVIEW_IDS[$ns]:-N/A}"
    done
    echo "----------------------------------------"

    # wrangler.toml 업데이트를 위해 전역 변수로 저장
    export KV_STATS_ID="${KV_IDS[STATS]:-PLACEHOLDER_STATS_KV_ID}"
    export KV_STATS_PREVIEW_ID="${KV_PREVIEW_IDS[STATS]:-PLACEHOLDER_STATS_KV_PREVIEW_ID}"
    export KV_GALLERY_ID="${KV_IDS[GALLERY]:-PLACEHOLDER_GALLERY_KV_ID}"
    export KV_GALLERY_PREVIEW_ID="${KV_PREVIEW_IDS[GALLERY]:-PLACEHOLDER_GALLERY_KV_PREVIEW_ID}"
    export KV_ANALYTICS_ID="${KV_IDS[ANALYTICS]:-PLACEHOLDER_ANALYTICS_KV_ID}"
    export KV_ANALYTICS_PREVIEW_ID="${KV_PREVIEW_IDS[ANALYTICS]:-PLACEHOLDER_ANALYTICS_KV_PREVIEW_ID}"
}

# =============================================================================
# wrangler.toml 업데이트
# =============================================================================

update_wrangler_toml() {
    print_header "wrangler.toml 구성 업데이트"

    if [ ! -f "$WRANGLER_TOML" ]; then
        print_error "wrangler.toml 파일을 찾을 수 없습니다: $WRANGLER_TOML"
        exit 1
    fi

    # 백업 생성
    local backup_file="${WRANGLER_TOML}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$WRANGLER_TOML" "$backup_file"
    print_info "백업 생성됨: $backup_file"

    if ! $DRY_RUN; then
        print_step "KV 네임스페이스 ID 업데이트 중..."

        # sed를 사용하여 플레이스홀더 교체
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/PLACEHOLDER_STATS_KV_ID/${KV_STATS_ID}/g" "$WRANGLER_TOML"
            sed -i '' "s/PLACEHOLDER_STATS_KV_PREVIEW_ID/${KV_STATS_PREVIEW_ID}/g" "$WRANGLER_TOML"
            sed -i '' "s/PLACEHOLDER_GALLERY_KV_ID/${KV_GALLERY_ID}/g" "$WRANGLER_TOML"
            sed -i '' "s/PLACEHOLDER_GALLERY_KV_PREVIEW_ID/${KV_GALLERY_PREVIEW_ID}/g" "$WRANGLER_TOML"
        else
            # Linux
            sed -i "s/PLACEHOLDER_STATS_KV_ID/${KV_STATS_ID}/g" "$WRANGLER_TOML"
            sed -i "s/PLACEHOLDER_STATS_KV_PREVIEW_ID/${KV_STATS_PREVIEW_ID}/g" "$WRANGLER_TOML"
            sed -i "s/PLACEHOLDER_GALLERY_KV_ID/${KV_GALLERY_ID}/g" "$WRANGLER_TOML"
            sed -i "s/PLACEHOLDER_GALLERY_KV_PREVIEW_ID/${KV_GALLERY_PREVIEW_ID}/g" "$WRANGLER_TOML"
        fi

        print_success "wrangler.toml 업데이트 완료"
    else
        print_info "[DRY-RUN] wrangler.toml 업데이트 건너뜀"
    fi
}

# =============================================================================
# API 연결 테스트
# =============================================================================

test_cloudflare_api() {
    print_header "Cloudflare API 연결 테스트"

    if $DRY_RUN; then
        print_info "[DRY-RUN] API 연결 테스트 건너뜀"
        return 0
    fi

    local tests_passed=0
    local tests_total=4

    # 1. 계정 정보 조회
    print_step "1/4 계정 정보 조회..."
    local account_response=$(curl -s -X GET \
        "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")

    if echo "$account_response" | grep -q '"success":true'; then
        print_success "계정 정보 조회 성공"
        ((tests_passed++))
    else
        print_error "계정 정보 조회 실패"
    fi

    # 2. Pages 프로젝트 목록 조회
    print_step "2/4 Pages 프로젝트 목록 조회..."
    local pages_response=$(curl -s -X GET \
        "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/pages/projects" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")

    if echo "$pages_response" | grep -q '"success":true'; then
        print_success "Pages 프로젝트 목록 조회 성공"
        ((tests_passed++))
    else
        print_error "Pages 프로젝트 목록 조회 실패"
    fi

    # 3. KV 네임스페이스 목록 조회
    print_step "3/4 KV 네임스페이스 목록 조회..."
    local kv_response=$(curl -s -X GET \
        "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/storage/kv/namespaces" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")

    if echo "$kv_response" | grep -q '"success":true'; then
        print_success "KV 네임스페이스 목록 조회 성공"
        ((tests_passed++))
    else
        print_error "KV 네임스페이스 목록 조회 실패"
    fi

    # 4. Workers 스크립트 목록 조회
    print_step "4/4 Workers 스크립트 목록 조회..."
    local workers_response=$(curl -s -X GET \
        "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/workers/scripts" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")

    if echo "$workers_response" | grep -q '"success":true'; then
        print_success "Workers 스크립트 목록 조회 성공"
        ((tests_passed++))
    else
        print_error "Workers 스크립트 목록 조회 실패"
    fi

    echo ""
    echo -e "${BOLD}API 테스트 결과: $tests_passed/$tests_total 통과${NC}"

    if [ $tests_passed -eq $tests_total ]; then
        print_success "모든 API 테스트 통과"
        return 0
    else
        print_warning "일부 API 테스트 실패"
        return 1
    fi
}

# =============================================================================
# 설정 요약 출력
# =============================================================================

print_summary() {
    print_header "설정 완료 요약"

    echo -e "${BOLD}Cloudflare 설정 정보:${NC}"
    echo "========================================"
    echo "  Account ID: $CF_ACCOUNT_ID"
    echo "  API Token: $(mask_token "${CF_API_TOKEN:-N/A}")"
    echo ""
    echo -e "${BOLD}Pages 프로젝트:${NC}"
    echo "  이름: $PAGES_PROJECT_NAME"
    echo "  도메인: $DOMAIN_NAME"
    echo ""
    echo -e "${BOLD}Workers API:${NC}"
    echo "  이름: $WORKER_NAME"
    echo ""
    echo -e "${BOLD}KV 네임스페이스:${NC}"
    echo "  STATS: ${KV_STATS_ID:-N/A}"
    echo "  GALLERY: ${KV_GALLERY_ID:-N/A}"
    echo "  ANALYTICS: ${KV_ANALYTICS_ID:-N/A}"
    echo "========================================"
    echo ""

    echo -e "${BOLD}다음 단계:${NC}"
    echo "  1. GitHub Actions Secrets 설정:"
    echo "     ./scripts/GITHUB_ACTIONS_SECRETS_SETUP.sh"
    echo ""
    echo "  2. 배포 실행:"
    echo "     ./scripts/DEPLOY.sh"
    echo ""
    echo "  3. 배포 후 검증:"
    echo "     ./scripts/POST_DEPLOY_VERIFICATION.sh"
    echo ""

    if [ -f "$LOG_FILE" ]; then
        print_info "상세 로그: $LOG_FILE"
    fi
}

# =============================================================================
# 환경 변수 저장
# =============================================================================

save_env_file() {
    print_header "환경 변수 파일 생성"

    local env_file="$PROJECT_ROOT/.env.cloudflare"

    if $DRY_RUN; then
        print_info "[DRY-RUN] 환경 변수 파일 생성 건너뜀"
        return 0
    fi

    cat > "$env_file" << EOF
# =============================================================================
# Cloudflare Configuration
# Generated by CLOUDFLARE_SETUP_AUTOMATION.sh
# Date: $(date '+%Y-%m-%d %H:%M:%S')
# =============================================================================

# Account Settings
CLOUDFLARE_ACCOUNT_ID=$CF_ACCOUNT_ID

# Project Settings
CLOUDFLARE_PAGES_PROJECT_NAME=$PAGES_PROJECT_NAME
CLOUDFLARE_WORKER_NAME=$WORKER_NAME
DOMAIN_NAME=$DOMAIN_NAME

# KV Namespace IDs
KV_STATS_ID=${KV_STATS_ID:-}
KV_STATS_PREVIEW_ID=${KV_STATS_PREVIEW_ID:-}
KV_GALLERY_ID=${KV_GALLERY_ID:-}
KV_GALLERY_PREVIEW_ID=${KV_GALLERY_PREVIEW_ID:-}
KV_ANALYTICS_ID=${KV_ANALYTICS_ID:-}
KV_ANALYTICS_PREVIEW_ID=${KV_ANALYTICS_PREVIEW_ID:-}

# WARNING: API Token은 여기에 저장하지 마세요!
# 대신 환경 변수로 설정하거나 GitHub Secrets를 사용하세요.
EOF

    chmod 600 "$env_file"
    print_success "환경 변수 파일 생성됨: $env_file"
    print_warning "이 파일을 .gitignore에 추가하세요!"

    # .gitignore에 추가
    if ! grep -q ".env.cloudflare" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
        echo ".env.cloudflare" >> "$PROJECT_ROOT/.gitignore"
        print_info ".gitignore에 .env.cloudflare 추가됨"
    fi
}

# =============================================================================
# 메인 실행
# =============================================================================

main() {
    # 인자 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                print_warning "DRY-RUN 모드: 실제 변경 없이 시뮬레이션만 수행합니다."
                shift
                ;;
            -h|--help)
                echo "사용법: $0 [--dry-run]"
                echo ""
                echo "옵션:"
                echo "  --dry-run    실제 실행 없이 시뮬레이션만 수행"
                echo "  -h, --help   이 도움말 표시"
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
    echo "  Cloudflare Setup Automation v1.0.0"
    echo -e "${NC}"

    log "INFO" "스크립트 시작"
    log "INFO" "DRY_RUN 모드: $DRY_RUN"

    # 작업 디렉토리 확인
    if [ ! -f "$PROJECT_ROOT/wrangler.toml" ]; then
        print_error "프로젝트 루트 디렉토리에서 실행해주세요."
        print_info "현재 디렉토리: $(pwd)"
        exit 1
    fi

    # 실행 단계
    check_prerequisites
    setup_cloudflare_auth
    test_cloudflare_api
    create_pages_project
    create_kv_namespaces
    update_wrangler_toml
    save_env_file
    print_summary

    log "INFO" "스크립트 완료"

    print_success "Cloudflare 설정 자동화 완료!"
}

# 스크립트 실행
main "$@"
