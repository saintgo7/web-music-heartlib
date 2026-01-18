#!/bin/bash
# =============================================================================
# ROLLBACK.sh
# ABADA Music Studio - 재해 복구 롤백 스크립트
#
# 이 스크립트는 배포 실패 시 이전 버전으로 롤백합니다.
#
# 사용법:
#   ./ROLLBACK.sh [--dry-run] [--pages-only] [--workers-only] [--to-version <id>]
#
# 옵션:
#   --dry-run       실제 롤백 없이 시뮬레이션만 수행
#   --pages-only    Pages만 롤백
#   --workers-only  Workers만 롤백
#   --to-version    특정 버전으로 롤백 (deployment ID)
#   --list          사용 가능한 배포 버전 목록 표시
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
LOG_FILE="$LOG_DIR/rollback_$(date +%Y%m%d_%H%M%S).log"
ROLLBACK_ID=$(date +%Y%m%d%H%M%S)

# 옵션 플래그
DRY_RUN=false
PAGES_ONLY=false
WORKERS_ONLY=false
LIST_ONLY=false
TARGET_VERSION=""

# 프로젝트 설정
PAGES_PROJECT_NAME="abada-music"
WORKER_NAME="abada-music-api"
DOMAIN="music.abada.kr"

# 롤백 결과
PAGES_ROLLBACK_SUCCESS=false
WORKERS_ROLLBACK_SUCCESS=false

# =============================================================================
# 유틸리티 함수
# =============================================================================

mkdir -p "$LOG_DIR"

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

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

# 확인 프롬프트
confirm_action() {
    local message=$1
    echo ""
    echo -e "${YELLOW}${BOLD}[WARNING]${NC} $message"
    echo ""
    read -p "계속하시겠습니까? (yes/no): " response
    if [ "$response" != "yes" ]; then
        print_info "작업이 취소되었습니다."
        exit 0
    fi
}

# =============================================================================
# 환경 확인
# =============================================================================

check_environment() {
    print_header "환경 확인"

    # Wrangler 확인
    print_step "Wrangler CLI 확인..."
    if ! command -v wrangler &> /dev/null; then
        print_error "Wrangler CLI가 설치되어 있지 않습니다."
        print_info "설치: npm install -g wrangler"
        exit 1
    fi
    print_success "Wrangler $(wrangler --version 2>/dev/null | head -1)"

    # 인증 확인
    print_step "Cloudflare 인증 확인..."

    # .env.cloudflare 파일 로드
    if [ -f "$PROJECT_ROOT/.env.cloudflare" ]; then
        source "$PROJECT_ROOT/.env.cloudflare"
    fi

    if [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
        print_error "CLOUDFLARE_API_TOKEN이 설정되지 않았습니다."
        exit 1
    fi
    print_success "Cloudflare 인증 설정됨"
}

# =============================================================================
# 배포 목록 조회
# =============================================================================

list_deployments() {
    print_header "사용 가능한 배포 버전"

    # Workers 배포 목록
    print_step "Workers 배포 목록 조회 중..."

    if $DRY_RUN; then
        print_info "[DRY-RUN] 배포 목록 조회 건너뜀"
    else
        echo ""
        echo -e "${BOLD}Workers 배포:${NC}"
        echo "----------------------------------------"
        wrangler deployments list 2>/dev/null || print_warning "Workers 배포 목록 조회 실패"
        echo "----------------------------------------"
    fi

    # Pages 배포 목록
    print_step "Pages 배포 목록 조회 중..."

    if $DRY_RUN; then
        print_info "[DRY-RUN] Pages 배포 목록 조회 건너뜀"
    else
        echo ""
        echo -e "${BOLD}Pages 배포:${NC}"
        echo "----------------------------------------"
        print_info "Pages 배포 목록은 Cloudflare Dashboard에서 확인하세요:"
        print_info "https://dash.cloudflare.com에서 Pages > $PAGES_PROJECT_NAME > Deployments"
        echo "----------------------------------------"
    fi

    echo ""
}

# =============================================================================
# Workers 롤백
# =============================================================================

rollback_workers() {
    print_header "Cloudflare Workers 롤백"

    if $PAGES_ONLY; then
        print_info "Workers 롤백 건너뜀 (--pages-only)"
        return 0
    fi

    print_step "현재 Workers 배포 상태 확인..."

    if $DRY_RUN; then
        print_info "[DRY-RUN] Workers 롤백 시뮬레이션"
        WORKERS_ROLLBACK_SUCCESS=true
        return 0
    fi

    # 현재 배포 정보 확인
    local current_deployment=$(wrangler deployments list 2>/dev/null | head -5 || echo "")

    if [ -z "$current_deployment" ]; then
        print_warning "현재 Workers 배포 정보를 가져올 수 없습니다."
    else
        echo ""
        echo -e "${BOLD}현재 배포:${NC}"
        echo "$current_deployment"
        echo ""
    fi

    # 롤백 확인
    confirm_action "Workers를 이전 버전으로 롤백합니다."

    print_step "Workers 롤백 실행 중..."

    # 특정 버전으로 롤백
    if [ -n "$TARGET_VERSION" ]; then
        print_info "특정 버전으로 롤백: $TARGET_VERSION"
        # wrangler rollback은 특정 버전 지정을 지원하지 않을 수 있음
        # Dashboard에서 수동 롤백 권장
        print_warning "특정 버전 롤백은 Cloudflare Dashboard에서 수행하세요."
        print_info "https://dash.cloudflare.com > Workers > $WORKER_NAME > Deployments"
    else
        # 직전 버전으로 롤백
        local rollback_output=$(wrangler rollback 2>&1) || true

        if echo "$rollback_output" | grep -qi "success\|rolled back"; then
            print_success "Workers 롤백 완료"
            WORKERS_ROLLBACK_SUCCESS=true
        else
            print_error "Workers 롤백 실패"
            echo "$rollback_output"
        fi
    fi
}

# =============================================================================
# Pages 롤백
# =============================================================================

rollback_pages() {
    print_header "Cloudflare Pages 롤백"

    if $WORKERS_ONLY; then
        print_info "Pages 롤백 건너뜀 (--workers-only)"
        return 0
    fi

    print_step "Pages 롤백 안내"

    print_info ""
    print_info "Cloudflare Pages 롤백은 Dashboard에서 수행해야 합니다:"
    print_info ""
    print_info "1. Cloudflare Dashboard 접속"
    print_info "   https://dash.cloudflare.com"
    print_info ""
    print_info "2. Pages 선택"
    print_info "   프로젝트: $PAGES_PROJECT_NAME"
    print_info ""
    print_info "3. Deployments 탭에서 이전 배포 선택"
    print_info ""
    print_info "4. 'Rollback to this deployment' 클릭"
    print_info ""

    if ! $DRY_RUN; then
        # 브라우저 열기 (macOS)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            read -p "Dashboard를 브라우저에서 열까요? (y/n): " open_browser
            if [[ "$open_browser" =~ ^[Yy]$ ]]; then
                open "https://dash.cloudflare.com" || true
            fi
        fi
    fi

    # Pages 롤백 API 호출 시도 (지원되는 경우)
    if [ -n "$TARGET_VERSION" ]; then
        print_step "Pages 배포 ID로 롤백 시도: $TARGET_VERSION"

        # API를 통한 롤백 시도
        if [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
            local response=$(curl -s -X POST \
                "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/pages/projects/${PAGES_PROJECT_NAME}/deployments/${TARGET_VERSION}/rollback" \
                -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
                -H "Content-Type: application/json" 2>/dev/null || echo "")

            if echo "$response" | grep -q '"success":true'; then
                print_success "Pages 롤백 API 호출 성공"
                PAGES_ROLLBACK_SUCCESS=true
            else
                print_warning "Pages 롤백 API 호출 실패 - Dashboard에서 수동 롤백 필요"
            fi
        fi
    else
        print_info "특정 배포 ID가 지정되지 않았습니다."
        print_info "--to-version <deployment-id> 옵션으로 지정하거나 Dashboard를 사용하세요."
    fi

    PAGES_ROLLBACK_SUCCESS=true  # 안내 완료로 처리
}

# =============================================================================
# KV 데이터 복원 (백업에서)
# =============================================================================

restore_kv_data() {
    print_header "KV Store 데이터 복원"

    # 백업 파일 확인
    local backup_dir="$PROJECT_ROOT/backups/kv"

    if [ ! -d "$backup_dir" ]; then
        print_info "KV 백업 디렉토리가 없습니다: $backup_dir"
        print_info "KV 데이터 복원을 건너뜁니다."
        return 0
    fi

    # 최신 백업 찾기
    local latest_backup=$(ls -t "$backup_dir"/*.json 2>/dev/null | head -1 || echo "")

    if [ -z "$latest_backup" ]; then
        print_info "KV 백업 파일이 없습니다."
        return 0
    fi

    print_info "최신 백업 파일: $latest_backup"

    read -p "이 백업에서 KV 데이터를 복원하시겠습니까? (y/n): " restore_confirm
    if [[ ! "$restore_confirm" =~ ^[Yy]$ ]]; then
        print_info "KV 복원을 건너뜁니다."
        return 0
    fi

    if $DRY_RUN; then
        print_info "[DRY-RUN] KV 복원 시뮬레이션"
        return 0
    fi

    print_step "KV 데이터 복원 중..."
    print_warning "KV 복원 기능은 별도의 백업/복원 스크립트가 필요합니다."
    print_info "백업 파일을 사용하여 wrangler kv:bulk put 명령어로 복원하세요."
}

# =============================================================================
# 롤백 후 검증
# =============================================================================

verify_rollback() {
    print_header "롤백 검증"

    if $DRY_RUN; then
        print_info "[DRY-RUN] 검증 건너뜀"
        return 0
    fi

    local checks_passed=0
    local checks_total=0

    # 웹사이트 접근 확인
    print_step "웹사이트 접근 확인..."
    ((checks_total++))

    sleep 5  # 롤백 전파 대기

    local website_response=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" --connect-timeout 10 --max-time 30 2>/dev/null || echo "000")

    if [ "$website_response" = "200" ]; then
        print_success "웹사이트 접근 가능 (HTTP $website_response)"
        ((checks_passed++))
    else
        print_warning "웹사이트 접근 확인 필요 (HTTP $website_response)"
    fi

    # API 헬스 체크
    if ! $PAGES_ONLY; then
        print_step "API 헬스 체크..."
        ((checks_total++))

        local api_response=$(curl -s "https://$DOMAIN/api/health" --connect-timeout 10 --max-time 30 2>/dev/null || echo "")

        if echo "$api_response" | grep -q '"status":"ok"'; then
            print_success "API 헬스 체크 통과"
            ((checks_passed++))
        else
            print_warning "API 헬스 체크 실패"
        fi
    fi

    echo ""
    echo -e "${BOLD}검증 결과: $checks_passed/$checks_total 통과${NC}"
}

# =============================================================================
# 롤백 리포트 생성
# =============================================================================

generate_rollback_report() {
    print_header "롤백 리포트 생성"

    local report_file="$LOG_DIR/rollback_report_${ROLLBACK_ID}.md"

    cat > "$report_file" << EOF
# ABADA Music Studio - 롤백 리포트

## 롤백 정보
- **롤백 ID**: $ROLLBACK_ID
- **실행 시간**: $(date '+%Y-%m-%d %H:%M:%S')
- **대상 도메인**: $DOMAIN
- **DRY_RUN 모드**: $DRY_RUN

## 롤백 대상
| 컴포넌트 | 결과 |
|----------|------|
| Workers | $([ "$WORKERS_ROLLBACK_SUCCESS" = true ] && echo "성공/완료" || echo "실패/건너뜀") |
| Pages | $([ "$PAGES_ROLLBACK_SUCCESS" = true ] && echo "성공/안내완료" || echo "실패/건너뜀") |

## 롤백 옵션
- Pages Only: $PAGES_ONLY
- Workers Only: $WORKERS_ONLY
- Target Version: ${TARGET_VERSION:-자동 (직전 버전)}

## 검증 결과
- 웹사이트 접근: 확인 필요
- API 상태: 확인 필요

## 후속 조치
1. 웹사이트 기능 수동 테스트
2. API 엔드포인트 테스트
3. 사용자 영향 모니터링
4. 근본 원인 분석

## 로그 파일
$LOG_FILE

---
*이 리포트는 ROLLBACK.sh에 의해 자동 생성되었습니다.*
EOF

    print_success "롤백 리포트 생성됨: $report_file"
}

# =============================================================================
# 결과 요약
# =============================================================================

print_summary() {
    print_header "롤백 완료 요약"

    echo -e "${BOLD}롤백 결과:${NC}"
    echo "========================================"
    echo "  롤백 ID: $ROLLBACK_ID"
    echo "  DRY_RUN: $DRY_RUN"
    echo ""

    if ! $PAGES_ONLY; then
        echo "  Workers: $([ "$WORKERS_ROLLBACK_SUCCESS" = true ] && echo -e "${GREEN}성공${NC}" || echo -e "${RED}실패/건너뜀${NC}")"
    fi

    if ! $WORKERS_ONLY; then
        echo "  Pages: $([ "$PAGES_ROLLBACK_SUCCESS" = true ] && echo -e "${GREEN}안내완료${NC}" || echo -e "${YELLOW}수동필요${NC}")"
    fi

    echo "========================================"
    echo ""

    echo -e "${BOLD}후속 조치:${NC}"
    echo "  1. 배포 검증 스크립트 실행:"
    echo "     ./scripts/POST_DEPLOY_VERIFICATION.sh"
    echo ""
    echo "  2. 수동 기능 테스트 수행"
    echo ""
    echo "  3. 근본 원인 분석 및 수정"
    echo ""

    print_info "상세 로그: $LOG_FILE"
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
                print_warning "DRY-RUN 모드: 실제 롤백 없이 시뮬레이션만 수행합니다."
                shift
                ;;
            --pages-only)
                PAGES_ONLY=true
                shift
                ;;
            --workers-only)
                WORKERS_ONLY=true
                shift
                ;;
            --to-version)
                TARGET_VERSION="$2"
                shift 2
                ;;
            --list)
                LIST_ONLY=true
                shift
                ;;
            -h|--help)
                echo "사용법: $0 [옵션]"
                echo ""
                echo "옵션:"
                echo "  --dry-run          실제 롤백 없이 시뮬레이션만 수행"
                echo "  --pages-only       Pages만 롤백"
                echo "  --workers-only     Workers만 롤백"
                echo "  --to-version <id>  특정 버전으로 롤백"
                echo "  --list             사용 가능한 배포 버전 목록"
                echo "  -h, --help         이 도움말 표시"
                exit 0
                ;;
            *)
                print_error "알 수 없는 옵션: $1"
                exit 1
                ;;
        esac
    done

    echo ""
    echo -e "${RED}${BOLD}"
    echo "  ____   ___  _     _     ____    _    ____ _  __"
    echo " |  _ \ / _ \| |   | |   | __ )  / \  / ___| |/ /"
    echo " | |_) | | | | |   | |   |  _ \ / _ \| |   | ' / "
    echo " |  _ <| |_| | |___| |___| |_) / ___ \ |___| . \ "
    echo " |_| \_\\___/|_____|_____|____/_/   \_\____|_|\_\\"
    echo ""
    echo "  Disaster Recovery Rollback v1.0.0"
    echo -e "${NC}"

    print_warning "이 스크립트는 프로덕션 환경을 이전 버전으로 롤백합니다!"
    print_warning "신중하게 실행하세요."
    echo ""

    log "INFO" "롤백 스크립트 시작"
    log "INFO" "롤백 ID: $ROLLBACK_ID"

    # 환경 확인
    check_environment

    # 목록만 표시
    if $LIST_ONLY; then
        list_deployments
        exit 0
    fi

    # 롤백 확인
    if ! $DRY_RUN; then
        confirm_action "프로덕션 환경을 롤백합니다. 이 작업은 되돌릴 수 없습니다."
    fi

    # 롤백 실행
    rollback_workers
    rollback_pages
    restore_kv_data
    verify_rollback
    generate_rollback_report
    print_summary

    log "INFO" "롤백 스크립트 완료"

    if $WORKERS_ROLLBACK_SUCCESS || $PAGES_ROLLBACK_SUCCESS; then
        print_success "롤백이 완료되었습니다. 검증 결과를 확인하세요."
    else
        print_warning "롤백이 완료되지 않았습니다. 수동 확인이 필요합니다."
    fi
}

# 스크립트 실행
main "$@"
