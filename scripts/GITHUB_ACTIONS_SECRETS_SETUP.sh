#!/bin/bash
# =============================================================================
# GITHUB_ACTIONS_SECRETS_SETUP.sh
# ABADA Music Studio - GitHub Actions Secrets 자동 설정 스크립트
#
# 이 스크립트는 GitHub Actions에서 사용할 Secrets를 자동으로 설정합니다.
#
# 사용법:
#   ./GITHUB_ACTIONS_SECRETS_SETUP.sh [--dry-run] [--verify-only]
#
# 옵션:
#   --dry-run       실제 실행 없이 시뮬레이션만 수행
#   --verify-only   기존 Secrets 검증만 수행
#
# 요구사항:
#   - GitHub CLI (gh) 설치 및 인증
#   - 저장소에 대한 admin 권한
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
LOG_FILE="$PROJECT_ROOT/logs/github_secrets_setup_$(date +%Y%m%d_%H%M%S).log"
DRY_RUN=false
VERIFY_ONLY=false

# GitHub 저장소 정보 (자동 감지)
GITHUB_REPO=""

# 필수 Secrets 목록
REQUIRED_SECRETS=(
    "CLOUDFLARE_API_TOKEN"
    "CLOUDFLARE_ACCOUNT_ID"
)

# 선택적 Secrets 목록
OPTIONAL_SECRETS=(
    "CLOUDFLARE_PAGES_PROJECT_NAME"
    "DOMAIN_NAME"
    "ADMIN_API_KEY"
)

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

# 값 유효성 검사
validate_not_empty() {
    local value=$1
    local name=$2
    if [ -z "$value" ]; then
        print_error "$name 값이 비어있습니다."
        return 1
    fi
    return 0
}

# Cloudflare API Token 유효성 검사
validate_cloudflare_token() {
    local token=$1

    print_step "Cloudflare API Token 검증 중..."

    if [ ${#token} -lt 20 ]; then
        print_error "토큰이 너무 짧습니다. 올바른 토큰인지 확인하세요."
        return 1
    fi

    # API 호출로 토큰 검증
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        --connect-timeout 10 \
        --max-time 30 2>/dev/null)

    if echo "$response" | grep -q '"success":true'; then
        print_success "Cloudflare API Token 검증 완료"
        return 0
    else
        print_error "Cloudflare API Token 검증 실패"
        print_info "응답: $response"
        return 1
    fi
}

# Cloudflare Account ID 유효성 검사
validate_cloudflare_account_id() {
    local account_id=$1
    local token=$2

    print_step "Cloudflare Account ID 검증 중..."

    # Account ID 형식 검사 (32자 hex 문자열)
    if ! [[ "$account_id" =~ ^[a-f0-9]{32}$ ]]; then
        print_warning "Account ID 형식이 일반적이지 않습니다: $account_id"
        read -p "계속 진행하시겠습니까? (y/n): " continue_check
        if [[ ! "$continue_check" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi

    # API 호출로 Account 접근 검증
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$account_id" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        --connect-timeout 10 \
        --max-time 30 2>/dev/null)

    if echo "$response" | grep -q '"success":true'; then
        print_success "Cloudflare Account ID 검증 완료"
        return 0
    else
        print_error "Cloudflare Account ID 검증 실패"
        print_info "응답: $response"
        return 1
    fi
}

# =============================================================================
# GitHub CLI 확인
# =============================================================================

check_github_cli() {
    print_header "GitHub CLI 환경 확인"

    # gh 설치 확인
    print_step "GitHub CLI (gh) 확인 중..."
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh)가 설치되어 있지 않습니다."
        print_info ""
        print_info "설치 방법:"
        print_info "  macOS:   brew install gh"
        print_info "  Ubuntu:  sudo apt install gh"
        print_info "  Windows: winget install GitHub.cli"
        print_info ""
        print_info "설치 후 'gh auth login'으로 인증하세요."
        exit 1
    fi

    local gh_version=$(gh --version | head -1)
    print_success "GitHub CLI 설치됨: $gh_version"

    # gh 인증 확인
    print_step "GitHub CLI 인증 상태 확인 중..."
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI가 인증되지 않았습니다."
        print_info ""
        print_info "다음 명령어로 인증하세요:"
        print_info "  gh auth login"
        exit 1
    fi

    local auth_user=$(gh api user -q '.login' 2>/dev/null || echo "unknown")
    print_success "GitHub 인증됨: $auth_user"
}

# =============================================================================
# 저장소 정보 감지
# =============================================================================

detect_github_repo() {
    print_header "GitHub 저장소 감지"

    print_step "현재 저장소 정보 조회 중..."

    # .git 디렉토리 확인
    if [ ! -d "$PROJECT_ROOT/.git" ]; then
        print_error "Git 저장소가 아닙니다."
        exit 1
    fi

    # 원격 저장소 URL에서 owner/repo 추출
    local remote_url=$(git -C "$PROJECT_ROOT" remote get-url origin 2>/dev/null || echo "")

    if [ -z "$remote_url" ]; then
        print_error "원격 저장소 정보를 찾을 수 없습니다."
        read -p "저장소를 직접 입력하세요 (owner/repo): " GITHUB_REPO
    else
        # URL 형식에 따라 파싱
        # https://github.com/owner/repo.git
        # git@github.com:owner/repo.git
        if [[ "$remote_url" == *"github.com"* ]]; then
            GITHUB_REPO=$(echo "$remote_url" | sed -E 's/.*github\.com[:/]([^/]+\/[^/]+)(\.git)?$/\1/')
            # .git 제거
            GITHUB_REPO="${GITHUB_REPO%.git}"
        fi
    fi

    if [ -z "$GITHUB_REPO" ]; then
        print_error "GitHub 저장소를 감지할 수 없습니다."
        read -p "저장소를 직접 입력하세요 (owner/repo): " GITHUB_REPO
    fi

    print_success "저장소 감지됨: $GITHUB_REPO"

    # 저장소 접근 권한 확인
    print_step "저장소 접근 권한 확인 중..."
    local repo_info=$(gh repo view "$GITHUB_REPO" --json name,owner 2>/dev/null || echo "")

    if [ -z "$repo_info" ]; then
        print_error "저장소에 접근할 수 없습니다: $GITHUB_REPO"
        print_info "저장소 권한을 확인하세요."
        exit 1
    fi

    print_success "저장소 접근 확인됨"
}

# =============================================================================
# 기존 Secrets 확인
# =============================================================================

check_existing_secrets() {
    print_header "기존 Secrets 확인"

    print_step "저장소의 Secrets 목록 조회 중..."

    local secrets_list=$(gh secret list -R "$GITHUB_REPO" 2>/dev/null || echo "")

    if [ -z "$secrets_list" ]; then
        print_info "현재 설정된 Secrets가 없습니다."
        return 0
    fi

    echo ""
    echo -e "${BOLD}현재 설정된 Secrets:${NC}"
    echo "----------------------------------------"
    echo "$secrets_list" | while read -r line; do
        local secret_name=$(echo "$line" | awk '{print $1}')
        local updated_at=$(echo "$line" | awk '{print $2, $3}')
        echo "  [SET] $secret_name (업데이트: $updated_at)"
    done
    echo "----------------------------------------"
    echo ""

    # 필수 Secrets 확인
    local missing_required=()
    for secret in "${REQUIRED_SECRETS[@]}"; do
        if echo "$secrets_list" | grep -q "^$secret"; then
            print_success "필수 Secret 설정됨: $secret"
        else
            print_warning "필수 Secret 누락: $secret"
            missing_required+=("$secret")
        fi
    done

    # 선택적 Secrets 확인
    for secret in "${OPTIONAL_SECRETS[@]}"; do
        if echo "$secrets_list" | grep -q "^$secret"; then
            print_info "선택적 Secret 설정됨: $secret"
        else
            print_info "선택적 Secret 미설정: $secret"
        fi
    done

    if [ ${#missing_required[@]} -eq 0 ]; then
        print_success "모든 필수 Secrets가 설정되어 있습니다."
        if $VERIFY_ONLY; then
            return 0
        fi

        echo ""
        read -p "기존 Secrets를 업데이트하시겠습니까? (y/n): " update_existing
        if [[ ! "$update_existing" =~ ^[Yy]$ ]]; then
            print_info "Secrets 업데이트를 건너뜁니다."
            exit 0
        fi
    fi

    return 0
}

# =============================================================================
# Secrets 입력 및 설정
# =============================================================================

collect_and_set_secrets() {
    print_header "Secrets 수집 및 설정"

    # 환경 변수 파일 로드 (있는 경우)
    local env_file="$PROJECT_ROOT/.env.cloudflare"
    if [ -f "$env_file" ]; then
        print_info "환경 변수 파일 발견: $env_file"
        source "$env_file" 2>/dev/null || true
    fi

    echo ""
    echo -e "${BOLD}Secrets 설정을 시작합니다.${NC}"
    echo ""
    echo "각 값을 입력하세요. 환경 변수가 이미 설정된 경우"
    echo "Enter를 눌러 기존 값을 사용할 수 있습니다."
    echo ""

    # 1. CLOUDFLARE_API_TOKEN
    print_step "1/5 CLOUDFLARE_API_TOKEN 설정"
    echo ""
    print_info "Cloudflare API Token을 입력하세요."
    print_info "토큰 생성: https://dash.cloudflare.com/profile/api-tokens"
    print_info ""
    print_info "필요한 권한:"
    print_info "  - Account:Cloudflare Pages:Edit"
    print_info "  - Account:Workers KV Storage:Edit"
    print_info "  - Account:Workers Scripts:Edit"

    local cf_token=""
    if [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
        print_info "현재 값: $(mask_token "$CLOUDFLARE_API_TOKEN")"
        read -sp "새 값 (Enter로 유지): " new_token
        echo ""
        cf_token="${new_token:-$CLOUDFLARE_API_TOKEN}"
    else
        read -sp "API Token: " cf_token
        echo ""
    fi

    if [ -z "$cf_token" ]; then
        print_error "CLOUDFLARE_API_TOKEN은 필수입니다."
        exit 1
    fi

    # 토큰 검증
    if ! $DRY_RUN; then
        if ! validate_cloudflare_token "$cf_token"; then
            print_error "유효하지 않은 API Token입니다."
            read -p "계속 진행하시겠습니까? (y/n): " continue_setup
            if [[ ! "$continue_setup" =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi

    # 2. CLOUDFLARE_ACCOUNT_ID
    echo ""
    print_step "2/5 CLOUDFLARE_ACCOUNT_ID 설정"
    print_info "Cloudflare Account ID를 입력하세요."
    print_info "위치: Cloudflare Dashboard > 계정 선택 > URL에서 확인"

    local cf_account_id=""
    if [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
        print_info "현재 값: $CLOUDFLARE_ACCOUNT_ID"
        read -p "새 값 (Enter로 유지): " new_account_id
        cf_account_id="${new_account_id:-$CLOUDFLARE_ACCOUNT_ID}"
    else
        read -p "Account ID: " cf_account_id
    fi

    if [ -z "$cf_account_id" ]; then
        print_error "CLOUDFLARE_ACCOUNT_ID는 필수입니다."
        exit 1
    fi

    # Account ID 검증
    if ! $DRY_RUN && [ -n "$cf_token" ]; then
        if ! validate_cloudflare_account_id "$cf_account_id" "$cf_token"; then
            print_error "유효하지 않은 Account ID입니다."
            read -p "계속 진행하시겠습니까? (y/n): " continue_setup
            if [[ ! "$continue_setup" =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi

    # 3. CLOUDFLARE_PAGES_PROJECT_NAME (선택)
    echo ""
    print_step "3/5 CLOUDFLARE_PAGES_PROJECT_NAME 설정 (선택사항)"
    print_info "Cloudflare Pages 프로젝트 이름"

    local pages_project="${CLOUDFLARE_PAGES_PROJECT_NAME:-abada-music}"
    print_info "기본값: $pages_project"
    read -p "프로젝트 이름 (Enter로 유지): " new_pages_project
    pages_project="${new_pages_project:-$pages_project}"

    # 4. DOMAIN_NAME (선택)
    echo ""
    print_step "4/5 DOMAIN_NAME 설정 (선택사항)"
    print_info "커스텀 도메인 이름"

    local domain_name="${DOMAIN_NAME:-music.abada.kr}"
    print_info "기본값: $domain_name"
    read -p "도메인 이름 (Enter로 유지): " new_domain_name
    domain_name="${new_domain_name:-$domain_name}"

    # 5. ADMIN_API_KEY (선택)
    echo ""
    print_step "5/5 ADMIN_API_KEY 설정 (선택사항)"
    print_info "관리자 API 키 (갤러리 관리 등에 사용)"

    local admin_key=""
    if [ -n "${ADMIN_API_KEY:-}" ]; then
        print_info "현재 값: $(mask_token "$ADMIN_API_KEY")"
        read -sp "새 값 (Enter로 유지, 'skip'으로 건너뛰기): " new_admin_key
        echo ""
        if [ "$new_admin_key" == "skip" ]; then
            admin_key=""
        else
            admin_key="${new_admin_key:-$ADMIN_API_KEY}"
        fi
    else
        read -sp "Admin API Key (Enter로 건너뛰기): " admin_key
        echo ""
    fi

    # Secrets 설정 확인
    echo ""
    print_header "Secrets 설정 확인"

    echo -e "${BOLD}설정할 Secrets:${NC}"
    echo "----------------------------------------"
    echo "  CLOUDFLARE_API_TOKEN: $(mask_token "$cf_token")"
    echo "  CLOUDFLARE_ACCOUNT_ID: $cf_account_id"
    echo "  CLOUDFLARE_PAGES_PROJECT_NAME: $pages_project"
    echo "  DOMAIN_NAME: $domain_name"
    if [ -n "$admin_key" ]; then
        echo "  ADMIN_API_KEY: $(mask_token "$admin_key")"
    fi
    echo "----------------------------------------"

    echo ""
    read -p "위 내용으로 Secrets를 설정하시겠습니까? (y/n): " confirm_setup
    if [[ ! "$confirm_setup" =~ ^[Yy]$ ]]; then
        print_info "설정이 취소되었습니다."
        exit 0
    fi

    # Secrets 설정
    print_header "GitHub Secrets 설정 중"

    if $DRY_RUN; then
        print_info "[DRY-RUN] Secrets 설정 건너뜀"
        return 0
    fi

    local set_count=0
    local error_count=0

    # CLOUDFLARE_API_TOKEN
    print_step "CLOUDFLARE_API_TOKEN 설정 중..."
    if echo "$cf_token" | gh secret set CLOUDFLARE_API_TOKEN -R "$GITHUB_REPO" 2>/dev/null; then
        print_success "CLOUDFLARE_API_TOKEN 설정 완료"
        ((set_count++))
    else
        print_error "CLOUDFLARE_API_TOKEN 설정 실패"
        ((error_count++))
    fi

    # CLOUDFLARE_ACCOUNT_ID
    print_step "CLOUDFLARE_ACCOUNT_ID 설정 중..."
    if echo "$cf_account_id" | gh secret set CLOUDFLARE_ACCOUNT_ID -R "$GITHUB_REPO" 2>/dev/null; then
        print_success "CLOUDFLARE_ACCOUNT_ID 설정 완료"
        ((set_count++))
    else
        print_error "CLOUDFLARE_ACCOUNT_ID 설정 실패"
        ((error_count++))
    fi

    # CLOUDFLARE_PAGES_PROJECT_NAME
    print_step "CLOUDFLARE_PAGES_PROJECT_NAME 설정 중..."
    if echo "$pages_project" | gh secret set CLOUDFLARE_PAGES_PROJECT_NAME -R "$GITHUB_REPO" 2>/dev/null; then
        print_success "CLOUDFLARE_PAGES_PROJECT_NAME 설정 완료"
        ((set_count++))
    else
        print_error "CLOUDFLARE_PAGES_PROJECT_NAME 설정 실패"
        ((error_count++))
    fi

    # DOMAIN_NAME
    print_step "DOMAIN_NAME 설정 중..."
    if echo "$domain_name" | gh secret set DOMAIN_NAME -R "$GITHUB_REPO" 2>/dev/null; then
        print_success "DOMAIN_NAME 설정 완료"
        ((set_count++))
    else
        print_error "DOMAIN_NAME 설정 실패"
        ((error_count++))
    fi

    # ADMIN_API_KEY (선택)
    if [ -n "$admin_key" ]; then
        print_step "ADMIN_API_KEY 설정 중..."
        if echo "$admin_key" | gh secret set ADMIN_API_KEY -R "$GITHUB_REPO" 2>/dev/null; then
            print_success "ADMIN_API_KEY 설정 완료"
            ((set_count++))
        else
            print_error "ADMIN_API_KEY 설정 실패"
            ((error_count++))
        fi
    fi

    echo ""
    print_header "설정 결과"
    echo -e "${BOLD}결과 요약:${NC}"
    echo "  성공: $set_count"
    echo "  실패: $error_count"
    echo ""

    if [ $error_count -gt 0 ]; then
        print_warning "일부 Secrets 설정에 실패했습니다."
        return 1
    fi

    print_success "모든 Secrets 설정 완료!"
}

# =============================================================================
# 설정 검증
# =============================================================================

verify_secrets_setup() {
    print_header "Secrets 설정 검증"

    print_step "설정된 Secrets 목록 확인 중..."

    local secrets_list=$(gh secret list -R "$GITHUB_REPO" 2>/dev/null || echo "")

    local all_required_set=true

    for secret in "${REQUIRED_SECRETS[@]}"; do
        if echo "$secrets_list" | grep -q "^$secret"; then
            print_success "[확인됨] $secret"
        else
            print_error "[누락됨] $secret"
            all_required_set=false
        fi
    done

    for secret in "${OPTIONAL_SECRETS[@]}"; do
        if echo "$secrets_list" | grep -q "^$secret"; then
            print_success "[확인됨] $secret (선택)"
        else
            print_info "[미설정] $secret (선택)"
        fi
    done

    echo ""

    if $all_required_set; then
        print_success "모든 필수 Secrets가 설정되어 있습니다."
        return 0
    else
        print_error "일부 필수 Secrets가 누락되어 있습니다."
        return 1
    fi
}

# =============================================================================
# 요약 출력
# =============================================================================

print_summary() {
    print_header "설정 완료 요약"

    echo -e "${BOLD}GitHub Secrets 설정 정보:${NC}"
    echo "========================================"
    echo "  저장소: $GITHUB_REPO"
    echo ""
    echo -e "${BOLD}설정된 Secrets:${NC}"

    local secrets_list=$(gh secret list -R "$GITHUB_REPO" 2>/dev/null || echo "")
    echo "$secrets_list" | while read -r line; do
        if [ -n "$line" ]; then
            local secret_name=$(echo "$line" | awk '{print $1}')
            echo "  - $secret_name"
        fi
    done

    echo "========================================"
    echo ""

    echo -e "${BOLD}다음 단계:${NC}"
    echo "  1. GitHub Actions 워크플로우가 올바르게 구성되어 있는지 확인:"
    echo "     .github/workflows/deploy-website.yml"
    echo ""
    echo "  2. 배포 실행:"
    echo "     ./scripts/DEPLOY.sh"
    echo ""
    echo "  3. 또는 GitHub에서 직접 실행:"
    echo "     gh workflow run deploy-website.yml -R $GITHUB_REPO"
    echo ""

    if [ -f "$LOG_FILE" ]; then
        print_info "상세 로그: $LOG_FILE"
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
            --verify-only)
                VERIFY_ONLY=true
                print_info "검증 전용 모드: 기존 Secrets 확인만 수행합니다."
                shift
                ;;
            -h|--help)
                echo "사용법: $0 [--dry-run] [--verify-only]"
                echo ""
                echo "옵션:"
                echo "  --dry-run       실제 실행 없이 시뮬레이션만 수행"
                echo "  --verify-only   기존 Secrets 검증만 수행"
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
    echo "  GitHub Actions Secrets Setup v1.0.0"
    echo -e "${NC}"

    log "INFO" "스크립트 시작"
    log "INFO" "DRY_RUN 모드: $DRY_RUN"
    log "INFO" "VERIFY_ONLY 모드: $VERIFY_ONLY"

    # 실행 단계
    check_github_cli
    detect_github_repo
    check_existing_secrets

    if ! $VERIFY_ONLY; then
        collect_and_set_secrets
    fi

    verify_secrets_setup
    print_summary

    log "INFO" "스크립트 완료"

    print_success "GitHub Actions Secrets 설정 완료!"
}

# 스크립트 실행
main "$@"
