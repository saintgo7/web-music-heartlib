#!/bin/bash
# =============================================================================
# CLOUDFLARE_KV_SEED.sh
# ABADA Music Studio - KV Store 초기 데이터 시드 스크립트
#
# 이 스크립트는 Cloudflare KV Store에 샘플 데이터를 초기화합니다.
#
# 사용법:
#   ./CLOUDFLARE_KV_SEED.sh [--dry-run] [--env <environment>] [--clear-first]
#
# 옵션:
#   --dry-run      실제 실행 없이 시뮬레이션만 수행
#   --env <env>    대상 환경 (development, staging, production)
#   --clear-first  기존 데이터 삭제 후 시드
#   --stats-only   통계 데이터만 시드
#   --gallery-only 갤러리 데이터만 시드
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
LOG_FILE="$PROJECT_ROOT/logs/kv_seed_$(date +%Y%m%d_%H%M%S).log"

# 옵션 플래그
DRY_RUN=false
ENVIRONMENT="production"
CLEAR_FIRST=false
STATS_ONLY=false
GALLERY_ONLY=false

# KV 네임스페이스 ID (wrangler.toml 또는 환경 변수에서 가져옴)
KV_STATS_ID=""
KV_GALLERY_ID=""
KV_ANALYTICS_ID=""

# =============================================================================
# 유틸리티 함수
# =============================================================================

mkdir -p "$PROJECT_ROOT/logs"

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

# KV에 값 설정
kv_put() {
    local namespace_id=$1
    local key=$2
    local value=$3
    local ttl=${4:-}

    if $DRY_RUN; then
        print_info "[DRY-RUN] PUT $key = ${value:0:50}..."
        return 0
    fi

    local ttl_flag=""
    if [ -n "$ttl" ]; then
        ttl_flag="--expiration-ttl=$ttl"
    fi

    if wrangler kv:key put --namespace-id="$namespace_id" "$key" "$value" $ttl_flag 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# KV에서 값 삭제
kv_delete() {
    local namespace_id=$1
    local key=$2

    if $DRY_RUN; then
        print_info "[DRY-RUN] DELETE $key"
        return 0
    fi

    wrangler kv:key delete --namespace-id="$namespace_id" "$key" 2>/dev/null || true
}

# =============================================================================
# 환경 설정 로드
# =============================================================================

load_kv_ids() {
    print_header "KV 네임스페이스 ID 로드"

    # .env.cloudflare 파일에서 로드
    if [ -f "$PROJECT_ROOT/.env.cloudflare" ]; then
        source "$PROJECT_ROOT/.env.cloudflare"
        print_info ".env.cloudflare 파일 로드됨"
    fi

    # 환경 변수 확인
    KV_STATS_ID="${KV_STATS_ID:-}"
    KV_GALLERY_ID="${KV_GALLERY_ID:-}"
    KV_ANALYTICS_ID="${KV_ANALYTICS_ID:-}"

    # wrangler.toml에서 파싱 시도
    if [ -z "$KV_STATS_ID" ] && [ -f "$PROJECT_ROOT/wrangler.toml" ]; then
        print_info "wrangler.toml에서 KV ID 파싱 시도..."

        # STATS KV ID 추출 (PLACEHOLDER가 아닌 경우)
        local stats_id=$(grep -A1 'binding = "STATS"' "$PROJECT_ROOT/wrangler.toml" | grep "^id = " | head -1 | cut -d'"' -f2 || echo "")
        if [ -n "$stats_id" ] && [[ "$stats_id" != PLACEHOLDER* ]]; then
            KV_STATS_ID="$stats_id"
        fi

        local gallery_id=$(grep -A1 'binding = "GALLERY"' "$PROJECT_ROOT/wrangler.toml" | grep "^id = " | head -1 | cut -d'"' -f2 || echo "")
        if [ -n "$gallery_id" ] && [[ "$gallery_id" != PLACEHOLDER* ]]; then
            KV_GALLERY_ID="$gallery_id"
        fi

        local analytics_id=$(grep -A1 'binding = "ANALYTICS"' "$PROJECT_ROOT/wrangler.toml" | grep "^id = " | head -1 | cut -d'"' -f2 || echo "")
        if [ -n "$analytics_id" ] && [[ "$analytics_id" != PLACEHOLDER* ]]; then
            KV_ANALYTICS_ID="$analytics_id"
        fi
    fi

    # 결과 확인
    if [ -z "$KV_STATS_ID" ]; then
        print_warning "STATS KV 네임스페이스 ID가 설정되지 않았습니다."
        if ! $GALLERY_ONLY; then
            print_info "KV ID를 입력하세요 (건너뛰려면 Enter):"
            read -p "STATS KV ID: " KV_STATS_ID
        fi
    else
        print_success "STATS KV ID: $KV_STATS_ID"
    fi

    if [ -z "$KV_GALLERY_ID" ]; then
        print_warning "GALLERY KV 네임스페이스 ID가 설정되지 않았습니다."
        if ! $STATS_ONLY; then
            read -p "GALLERY KV ID: " KV_GALLERY_ID
        fi
    else
        print_success "GALLERY KV ID: $KV_GALLERY_ID"
    fi

    if [ -z "$KV_ANALYTICS_ID" ]; then
        print_warning "ANALYTICS KV 네임스페이스 ID가 설정되지 않았습니다."
        if ! $STATS_ONLY && ! $GALLERY_ONLY; then
            read -p "ANALYTICS KV ID: " KV_ANALYTICS_ID
        fi
    else
        print_success "ANALYTICS KV ID: $KV_ANALYTICS_ID"
    fi
}

# =============================================================================
# 다운로드 통계 시드 데이터
# =============================================================================

seed_download_stats() {
    print_header "다운로드 통계 시드 데이터"

    if [ -z "$KV_STATS_ID" ]; then
        print_warning "STATS KV ID가 없어 건너뜁니다."
        return 0
    fi

    print_step "다운로드 통계 데이터 생성 중..."

    # 최근 30일 샘플 데이터
    local today=$(date +%Y-%m-%d)
    local count=0
    local total=30

    for i in $(seq 0 29); do
        local date
        if [[ "$OSTYPE" == "darwin"* ]]; then
            date=$(date -v-${i}d +%Y-%m-%d)
        else
            date=$(date -d "-$i days" +%Y-%m-%d)
        fi

        # 랜덤 다운로드 수 생성 (10-100 범위)
        local windows_x64=$((RANDOM % 50 + 20))
        local windows_x86=$((RANDOM % 20 + 5))
        local macos=$((RANDOM % 30 + 10))
        local linux=$((RANDOM % 15 + 3))

        # KV에 저장
        kv_put "$KV_STATS_ID" "download:windows-x64:$date" "$windows_x64" "31536000"
        kv_put "$KV_STATS_ID" "download:windows-x86:$date" "$windows_x86" "31536000"
        kv_put "$KV_STATS_ID" "download:macos:$date" "$macos" "31536000"
        kv_put "$KV_STATS_ID" "download:linux:$date" "$linux" "31536000"

        ((count++))
        printf "\r  진행률: %d/%d" "$count" "$total"
    done
    echo ""

    # 총계 데이터
    print_step "총계 데이터 생성 중..."

    local total_downloads=$((RANDOM % 5000 + 2000))
    kv_put "$KV_STATS_ID" "stats:total_downloads" "$total_downloads" ""
    kv_put "$KV_STATS_ID" "stats:total_users" "$((total_downloads / 3))" ""
    kv_put "$KV_STATS_ID" "stats:last_updated" "$(date -Iseconds)" ""

    print_success "다운로드 통계 시드 데이터 완료"
}

# =============================================================================
# 갤러리 시드 데이터
# =============================================================================

seed_gallery_data() {
    print_header "갤러리 시드 데이터"

    if [ -z "$KV_GALLERY_ID" ]; then
        print_warning "GALLERY KV ID가 없어 건너뜁니다."
        return 0
    fi

    print_step "갤러리 샘플 데이터 생성 중..."

    # 샘플 음악 메타데이터
    local samples=(
        '{"id":"sample-001","title":"Lo-Fi Morning Vibes","artist":"ABADA Studio","genre":"Lo-Fi","duration":180,"bpm":85,"key":"C Major","tags":["chill","study","morning"],"created_at":"2024-12-01T09:00:00Z","downloads":1250}'
        '{"id":"sample-002","title":"Epic Orchestral Rise","artist":"ABADA Studio","genre":"Cinematic","duration":240,"bpm":120,"key":"D Minor","tags":["epic","trailer","dramatic"],"created_at":"2024-12-05T14:30:00Z","downloads":890}'
        '{"id":"sample-003","title":"Synthwave Sunset","artist":"ABADA Studio","genre":"Synthwave","duration":210,"bpm":110,"key":"A Minor","tags":["retro","80s","neon"],"created_at":"2024-12-10T18:00:00Z","downloads":1560}'
        '{"id":"sample-004","title":"Acoustic Coffee Shop","artist":"ABADA Studio","genre":"Acoustic","duration":195,"bpm":95,"key":"G Major","tags":["acoustic","cafe","relax"],"created_at":"2024-12-15T11:00:00Z","downloads":720}'
        '{"id":"sample-005","title":"Electronic Future Bass","artist":"ABADA Studio","genre":"EDM","duration":225,"bpm":150,"key":"F Major","tags":["edm","future bass","energetic"],"created_at":"2024-12-20T20:00:00Z","downloads":2100}'
        '{"id":"sample-006","title":"Jazz Piano Improvisation","artist":"ABADA Studio","genre":"Jazz","duration":300,"bpm":75,"key":"Bb Major","tags":["jazz","piano","improvisation"],"created_at":"2024-12-25T16:00:00Z","downloads":450}'
        '{"id":"sample-007","title":"Hip Hop Boom Bap","artist":"ABADA Studio","genre":"Hip Hop","duration":185,"bpm":90,"key":"E Minor","tags":["hip hop","boom bap","old school"],"created_at":"2024-12-28T13:00:00Z","downloads":980}'
        '{"id":"sample-008","title":"Ambient Space Meditation","artist":"ABADA Studio","genre":"Ambient","duration":360,"bpm":60,"key":"C# Minor","tags":["ambient","meditation","space"],"created_at":"2025-01-01T00:00:00Z","downloads":670}'
    )

    local count=0
    local total=${#samples[@]}

    for sample in "${samples[@]}"; do
        local id=$(echo "$sample" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
        kv_put "$KV_GALLERY_ID" "sample:$id" "$sample" ""

        ((count++))
        printf "\r  진행률: %d/%d" "$count" "$total"
    done
    echo ""

    # 샘플 목록 인덱스
    print_step "갤러리 인덱스 생성 중..."

    local index='["sample-001","sample-002","sample-003","sample-004","sample-005","sample-006","sample-007","sample-008"]'
    kv_put "$KV_GALLERY_ID" "gallery:index" "$index" ""
    kv_put "$KV_GALLERY_ID" "gallery:count" "${#samples[@]}" ""
    kv_put "$KV_GALLERY_ID" "gallery:last_updated" "$(date -Iseconds)" ""

    # 장르별 인덱스
    kv_put "$KV_GALLERY_ID" "genre:Lo-Fi" '["sample-001"]' ""
    kv_put "$KV_GALLERY_ID" "genre:Cinematic" '["sample-002"]' ""
    kv_put "$KV_GALLERY_ID" "genre:Synthwave" '["sample-003"]' ""
    kv_put "$KV_GALLERY_ID" "genre:Acoustic" '["sample-004"]' ""
    kv_put "$KV_GALLERY_ID" "genre:EDM" '["sample-005"]' ""
    kv_put "$KV_GALLERY_ID" "genre:Jazz" '["sample-006"]' ""
    kv_put "$KV_GALLERY_ID" "genre:Hip Hop" '["sample-007"]' ""
    kv_put "$KV_GALLERY_ID" "genre:Ambient" '["sample-008"]' ""

    print_success "갤러리 시드 데이터 완료"
}

# =============================================================================
# 애널리틱스 시드 데이터
# =============================================================================

seed_analytics_data() {
    print_header "애널리틱스 시드 데이터"

    if [ -z "$KV_ANALYTICS_ID" ]; then
        print_warning "ANALYTICS KV ID가 없어 건너뜁니다."
        return 0
    fi

    print_step "애널리틱스 샘플 데이터 생성 중..."

    # 페이지뷰 이벤트
    local page_views='{"total":15000,"pages":{"/":8500,"/download":3200,"/gallery":1800,"/tutorial":900,"/faq":400,"/about":200}}'
    kv_put "$KV_ANALYTICS_ID" "pageviews:total" "$page_views" ""

    # 일별 방문자 수 (최근 7일)
    for i in $(seq 0 6); do
        local date
        if [[ "$OSTYPE" == "darwin"* ]]; then
            date=$(date -v-${i}d +%Y-%m-%d)
        else
            date=$(date -d "-$i days" +%Y-%m-%d)
        fi

        local visitors=$((RANDOM % 500 + 200))
        local page_views=$((visitors * 3))
        local bounce_rate=$((RANDOM % 30 + 20))

        local daily_stats="{\"date\":\"$date\",\"visitors\":$visitors,\"page_views\":$page_views,\"bounce_rate\":$bounce_rate}"
        kv_put "$KV_ANALYTICS_ID" "daily:$date" "$daily_stats" "604800"
    done

    # 이벤트 로그
    local events=(
        '{"event":"download","os":"windows-x64","timestamp":"2025-01-19T10:30:00Z","country":"KR"}'
        '{"event":"download","os":"macos","timestamp":"2025-01-19T11:15:00Z","country":"US"}'
        '{"event":"page_view","page":"/gallery","timestamp":"2025-01-19T11:30:00Z","country":"JP"}'
        '{"event":"download","os":"linux","timestamp":"2025-01-19T12:00:00Z","country":"DE"}'
        '{"event":"sample_play","sample_id":"sample-003","timestamp":"2025-01-19T12:30:00Z","country":"KR"}'
    )

    local idx=1
    for event in "${events[@]}"; do
        kv_put "$KV_ANALYTICS_ID" "event:$(date +%s)$idx" "$event" "86400"
        ((idx++))
    done

    # 집계 데이터
    kv_put "$KV_ANALYTICS_ID" "aggregate:countries" '{"KR":8500,"US":3200,"JP":1500,"DE":800,"GB":500,"other":500}' ""
    kv_put "$KV_ANALYTICS_ID" "aggregate:browsers" '{"Chrome":9000,"Firefox":2500,"Safari":2000,"Edge":1000,"other":500}' ""
    kv_put "$KV_ANALYTICS_ID" "aggregate:os" '{"Windows":8000,"macOS":4000,"Linux":2000,"iOS":500,"Android":500}' ""
    kv_put "$KV_ANALYTICS_ID" "analytics:last_updated" "$(date -Iseconds)" ""

    print_success "애널리틱스 시드 데이터 완료"
}

# =============================================================================
# 기존 데이터 삭제
# =============================================================================

clear_existing_data() {
    print_header "기존 데이터 삭제"

    if ! $CLEAR_FIRST; then
        print_info "기존 데이터 삭제 건너뜀 (--clear-first 옵션 필요)"
        return 0
    fi

    print_warning "기존 KV 데이터를 삭제합니다. 계속하시겠습니까?"
    read -p "확인 (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "데이터 삭제 취소됨"
        return 0
    fi

    if $DRY_RUN; then
        print_info "[DRY-RUN] 데이터 삭제 건너뜀"
        return 0
    fi

    # STATS 데이터 삭제
    if [ -n "$KV_STATS_ID" ]; then
        print_step "STATS 데이터 삭제 중..."
        local keys=$(wrangler kv:key list --namespace-id="$KV_STATS_ID" 2>/dev/null | grep -o '"name":"[^"]*"' | cut -d'"' -f4 || echo "")
        for key in $keys; do
            kv_delete "$KV_STATS_ID" "$key"
        done
        print_success "STATS 데이터 삭제 완료"
    fi

    # GALLERY 데이터 삭제
    if [ -n "$KV_GALLERY_ID" ]; then
        print_step "GALLERY 데이터 삭제 중..."
        local keys=$(wrangler kv:key list --namespace-id="$KV_GALLERY_ID" 2>/dev/null | grep -o '"name":"[^"]*"' | cut -d'"' -f4 || echo "")
        for key in $keys; do
            kv_delete "$KV_GALLERY_ID" "$key"
        done
        print_success "GALLERY 데이터 삭제 완료"
    fi

    # ANALYTICS 데이터 삭제
    if [ -n "$KV_ANALYTICS_ID" ]; then
        print_step "ANALYTICS 데이터 삭제 중..."
        local keys=$(wrangler kv:key list --namespace-id="$KV_ANALYTICS_ID" 2>/dev/null | grep -o '"name":"[^"]*"' | cut -d'"' -f4 || echo "")
        for key in $keys; do
            kv_delete "$KV_ANALYTICS_ID" "$key"
        done
        print_success "ANALYTICS 데이터 삭제 완료"
    fi
}

# =============================================================================
# 결과 요약
# =============================================================================

print_summary() {
    print_header "시드 데이터 완료 요약"

    echo -e "${BOLD}시드 데이터 정보:${NC}"
    echo "========================================"
    echo "  환경: $ENVIRONMENT"
    echo "  DRY_RUN: $DRY_RUN"
    echo ""
    echo -e "${BOLD}KV 네임스페이스:${NC}"
    echo "  STATS: ${KV_STATS_ID:-N/A}"
    echo "  GALLERY: ${KV_GALLERY_ID:-N/A}"
    echo "  ANALYTICS: ${KV_ANALYTICS_ID:-N/A}"
    echo ""
    echo -e "${BOLD}시드된 데이터:${NC}"

    if [ -n "$KV_STATS_ID" ] && ! $GALLERY_ONLY; then
        echo "  - 다운로드 통계: 30일 데이터"
    fi
    if [ -n "$KV_GALLERY_ID" ] && ! $STATS_ONLY; then
        echo "  - 갤러리 샘플: 8개"
    fi
    if [ -n "$KV_ANALYTICS_ID" ] && ! $STATS_ONLY && ! $GALLERY_ONLY; then
        echo "  - 애널리틱스: 7일 데이터"
    fi
    echo "========================================"
    echo ""

    print_info "데이터 확인 방법:"
    if [ -n "$KV_STATS_ID" ]; then
        print_info "  wrangler kv:key list --namespace-id=$KV_STATS_ID"
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
            --env)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --clear-first)
                CLEAR_FIRST=true
                shift
                ;;
            --stats-only)
                STATS_ONLY=true
                shift
                ;;
            --gallery-only)
                GALLERY_ONLY=true
                shift
                ;;
            -h|--help)
                echo "사용법: $0 [옵션]"
                echo ""
                echo "옵션:"
                echo "  --dry-run      실제 실행 없이 시뮬레이션만 수행"
                echo "  --env <env>    대상 환경 (development, staging, production)"
                echo "  --clear-first  기존 데이터 삭제 후 시드"
                echo "  --stats-only   통계 데이터만 시드"
                echo "  --gallery-only 갤러리 데이터만 시드"
                echo "  -h, --help     이 도움말 표시"
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
    echo "  KV Store Seed Script v1.0.0"
    echo -e "${NC}"

    log "INFO" "스크립트 시작"

    # 실행 단계
    load_kv_ids
    clear_existing_data

    if ! $GALLERY_ONLY; then
        seed_download_stats
    fi

    if ! $STATS_ONLY; then
        seed_gallery_data
    fi

    if ! $STATS_ONLY && ! $GALLERY_ONLY; then
        seed_analytics_data
    fi

    print_summary

    log "INFO" "스크립트 완료"

    print_success "KV Store 시드 데이터 초기화 완료!"
}

# 스크립트 실행
main "$@"
