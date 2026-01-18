#!/bin/bash
# =============================================================================
# MONITORING_SETUP.sh
# ABADA Music Studio - Cloudflare 모니터링 설정 스크립트
#
# 이 스크립트는 Cloudflare Analytics Engine, RUM, 알림 설정을 자동화합니다.
#
# 사용법:
#   ./MONITORING_SETUP.sh [--dry-run]
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
LOG_FILE="$PROJECT_ROOT/logs/monitoring_setup_$(date +%Y%m%d_%H%M%S).log"

# 옵션 플래그
DRY_RUN=false

# Cloudflare 설정
CF_ACCOUNT_ID=""
CF_API_TOKEN=""
ZONE_ID=""
DOMAIN="music.abada.kr"

# 알림 설정
ALERT_EMAIL=""
SLACK_WEBHOOK_URL=""

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

# =============================================================================
# 환경 로드
# =============================================================================

load_environment() {
    print_header "환경 설정 로드"

    # .env.cloudflare 파일 로드
    if [ -f "$PROJECT_ROOT/.env.cloudflare" ]; then
        source "$PROJECT_ROOT/.env.cloudflare"
        print_info ".env.cloudflare 파일 로드됨"
    fi

    # 환경 변수 확인
    CF_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-$CF_ACCOUNT_ID}"
    CF_API_TOKEN="${CLOUDFLARE_API_TOKEN:-$CF_API_TOKEN}"

    if [ -z "$CF_API_TOKEN" ]; then
        print_warning "CLOUDFLARE_API_TOKEN이 설정되지 않았습니다."
        read -sp "API Token 입력: " CF_API_TOKEN
        echo ""
    fi

    if [ -z "$CF_ACCOUNT_ID" ]; then
        print_warning "CLOUDFLARE_ACCOUNT_ID가 설정되지 않았습니다."
        read -p "Account ID 입력: " CF_ACCOUNT_ID
    fi

    print_success "환경 설정 로드 완료"
    print_info "Account ID: $CF_ACCOUNT_ID"
    print_info "API Token: $(mask_token "$CF_API_TOKEN")"
}

# =============================================================================
# Zone ID 조회
# =============================================================================

get_zone_id() {
    print_header "Zone ID 조회"

    if [ -n "$ZONE_ID" ]; then
        print_info "기존 Zone ID 사용: $ZONE_ID"
        return 0
    fi

    print_step "도메인에서 Zone ID 조회 중: $DOMAIN"

    # 도메인에서 루트 도메인 추출 (music.abada.kr -> abada.kr)
    local root_domain=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"."$NF}')

    if $DRY_RUN; then
        print_info "[DRY-RUN] Zone ID 조회 건너뜀"
        ZONE_ID="dry-run-zone-id"
        return 0
    fi

    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$root_domain" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")

    if command -v jq &> /dev/null; then
        ZONE_ID=$(echo "$response" | jq -r '.result[0].id // empty')
    else
        ZONE_ID=$(echo "$response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    fi

    if [ -n "$ZONE_ID" ] && [ "$ZONE_ID" != "null" ]; then
        print_success "Zone ID 조회 완료: $ZONE_ID"
    else
        print_warning "Zone ID를 찾을 수 없습니다. 수동으로 입력해주세요."
        read -p "Zone ID: " ZONE_ID
    fi
}

# =============================================================================
# Analytics Engine 설정
# =============================================================================

setup_analytics_engine() {
    print_header "Analytics Engine 설정"

    print_info "Cloudflare Analytics Engine은 Workers 분석 데이터를 저장합니다."
    print_info "이 기능은 wrangler.toml에서 활성화됩니다."

    if $DRY_RUN; then
        print_info "[DRY-RUN] Analytics Engine 설정 건너뜀"
        return 0
    fi

    # wrangler.toml에 Analytics Engine 설정 추가 확인
    if grep -q "analytics_engine_datasets" "$PROJECT_ROOT/wrangler.toml"; then
        print_info "wrangler.toml에 Analytics Engine 설정이 이미 있습니다."
    else
        print_info "Analytics Engine을 활성화하려면 wrangler.toml에 다음을 추가하세요:"
        echo ""
        echo "[[analytics_engine_datasets]]"
        echo 'binding = "MUSIC_ANALYTICS"'
        echo ""
    fi

    print_success "Analytics Engine 설정 안내 완료"
}

# =============================================================================
# 알림 정책 설정
# =============================================================================

setup_alert_policies() {
    print_header "알림 정책 설정"

    # 이메일 알림 설정
    print_step "알림 수신 이메일 설정"
    if [ -z "$ALERT_EMAIL" ]; then
        read -p "알림 수신 이메일 (건너뛰려면 Enter): " ALERT_EMAIL
    fi

    # Slack 웹훅 설정
    print_step "Slack 웹훅 설정 (선택사항)"
    if [ -z "$SLACK_WEBHOOK_URL" ]; then
        read -p "Slack Webhook URL (건너뛰려면 Enter): " SLACK_WEBHOOK_URL
    fi

    if $DRY_RUN; then
        print_info "[DRY-RUN] 알림 정책 설정 건너뜀"
        return 0
    fi

    # 알림 정책 생성 (Cloudflare Notifications API)
    if [ -n "$ALERT_EMAIL" ]; then
        print_step "오류율 알림 정책 생성 중..."

        # 1. 높은 오류율 알림 (> 1%)
        local error_policy=$(cat << EOF
{
    "name": "ABADA Music - High Error Rate",
    "description": "Alert when error rate exceeds 1%",
    "enabled": true,
    "alert_type": "workers_error_rate",
    "mechanisms": {
        "email": [{"id": "$ALERT_EMAIL"}]
    },
    "filters": {
        "script_name": ["abada-music-api"]
    }
}
EOF
)
        local response=$(curl -s -X POST \
            "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/alerting/v3/policies" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "$error_policy")

        if echo "$response" | grep -q '"success":true'; then
            print_success "오류율 알림 정책 생성됨"
        else
            print_warning "오류율 알림 정책 생성 실패 (수동 설정 필요)"
        fi
    fi

    print_success "알림 정책 설정 완료"
}

# =============================================================================
# RUM (Real User Monitoring) 설정
# =============================================================================

setup_rum() {
    print_header "Real User Monitoring (RUM) 설정"

    print_info "Cloudflare Web Analytics를 사용하여 실제 사용자 모니터링을 설정합니다."

    if $DRY_RUN; then
        print_info "[DRY-RUN] RUM 설정 건너뜀"
        return 0
    fi

    print_step "Web Analytics 사이트 확인/생성 중..."

    # Web Analytics API 호출
    local sites_response=$(curl -s -X GET \
        "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/rum/site_info" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")

    # 기존 사이트 확인
    local existing_site=""
    if command -v jq &> /dev/null; then
        existing_site=$(echo "$sites_response" | jq -r ".result[] | select(.host==\"$DOMAIN\") | .site_tag // empty" 2>/dev/null || echo "")
    fi

    if [ -n "$existing_site" ]; then
        print_info "기존 Web Analytics 사이트 발견: $existing_site"
        SITE_TAG="$existing_site"
    else
        # 새 사이트 생성
        print_step "새 Web Analytics 사이트 생성 중..."

        local create_response=$(curl -s -X POST \
            "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/rum/site_info" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{\"host\": \"$DOMAIN\", \"auto_install\": true}")

        if command -v jq &> /dev/null; then
            SITE_TAG=$(echo "$create_response" | jq -r '.result.site_tag // empty')
        else
            SITE_TAG=$(echo "$create_response" | grep -o '"site_tag":"[^"]*"' | cut -d'"' -f4)
        fi

        if [ -n "$SITE_TAG" ]; then
            print_success "Web Analytics 사이트 생성됨: $SITE_TAG"
        else
            print_warning "Web Analytics 사이트 생성 실패"
        fi
    fi

    # RUM 스크립트 안내
    if [ -n "$SITE_TAG" ]; then
        print_info ""
        print_info "웹사이트에 다음 스크립트를 추가하세요:"
        echo ""
        echo "<script defer src='https://static.cloudflareinsights.com/beacon.min.js' data-cf-beacon='{\"token\": \"$SITE_TAG\"}'></script>"
        echo ""
        print_info "Cloudflare Pages를 사용하면 자동으로 주입됩니다."
    fi

    print_success "RUM 설정 완료"
}

# =============================================================================
# 모니터링 대시보드 구성
# =============================================================================

create_dashboard_config() {
    print_header "모니터링 대시보드 구성"

    local dashboard_file="$PROJECT_ROOT/docs/monitoring/dashboard_config.json"
    mkdir -p "$(dirname "$dashboard_file")"

    cat > "$dashboard_file" << 'EOF'
{
    "dashboard": {
        "name": "ABADA Music Studio Monitoring",
        "version": "1.0.0",
        "panels": [
            {
                "id": "requests_overview",
                "title": "Request Overview",
                "type": "timeseries",
                "metrics": ["requests", "errors", "bandwidth"]
            },
            {
                "id": "error_rate",
                "title": "Error Rate",
                "type": "gauge",
                "thresholds": {
                    "warning": 0.5,
                    "critical": 1.0
                }
            },
            {
                "id": "response_time",
                "title": "Response Time (p95)",
                "type": "timeseries",
                "thresholds": {
                    "warning": 500,
                    "critical": 1000
                }
            },
            {
                "id": "worker_invocations",
                "title": "Worker Invocations",
                "type": "counter"
            },
            {
                "id": "kv_operations",
                "title": "KV Operations",
                "type": "timeseries",
                "metrics": ["reads", "writes", "deletes"]
            },
            {
                "id": "top_pages",
                "title": "Top Pages",
                "type": "table",
                "limit": 10
            },
            {
                "id": "geographic_distribution",
                "title": "Geographic Distribution",
                "type": "map"
            },
            {
                "id": "browser_breakdown",
                "title": "Browser Breakdown",
                "type": "pie"
            }
        ],
        "alerts": [
            {
                "name": "High Error Rate",
                "condition": "error_rate > 1%",
                "severity": "critical",
                "duration": "5m"
            },
            {
                "name": "Slow Response",
                "condition": "p95_response_time > 1000ms",
                "severity": "warning",
                "duration": "10m"
            },
            {
                "name": "High Memory Usage",
                "condition": "worker_memory > 128MB",
                "severity": "warning",
                "duration": "5m"
            },
            {
                "name": "Traffic Spike",
                "condition": "requests_per_minute > 10000",
                "severity": "info",
                "duration": "1m"
            }
        ],
        "cloudflare_urls": {
            "analytics": "https://dash.cloudflare.com/{account_id}/analytics",
            "workers": "https://dash.cloudflare.com/{account_id}/workers/overview",
            "pages": "https://dash.cloudflare.com/{account_id}/pages"
        }
    }
}
EOF

    print_success "대시보드 구성 파일 생성됨: $dashboard_file"

    # Grafana 대시보드 템플릿 (선택사항)
    local grafana_file="$PROJECT_ROOT/docs/monitoring/grafana_dashboard.json"

    cat > "$grafana_file" << 'EOF'
{
    "annotations": {
        "list": []
    },
    "editable": true,
    "gnetId": null,
    "graphTooltip": 0,
    "id": null,
    "links": [],
    "panels": [
        {
            "aliasColors": {},
            "bars": false,
            "dashLength": 10,
            "dashes": false,
            "datasource": "Cloudflare",
            "fill": 1,
            "fillGradient": 0,
            "gridPos": {
                "h": 8,
                "w": 12,
                "x": 0,
                "y": 0
            },
            "id": 1,
            "legend": {
                "avg": false,
                "current": false,
                "max": false,
                "min": false,
                "show": true,
                "total": false,
                "values": false
            },
            "lines": true,
            "linewidth": 1,
            "nullPointMode": "null",
            "options": {
                "dataLinks": []
            },
            "percentage": false,
            "pointradius": 2,
            "points": false,
            "renderer": "flot",
            "seriesOverrides": [],
            "spaceLength": 10,
            "stack": false,
            "steppedLine": false,
            "targets": [
                {
                    "refId": "A",
                    "target": "cloudflare.requests"
                }
            ],
            "thresholds": [],
            "timeRegions": [],
            "title": "Requests",
            "tooltip": {
                "shared": true,
                "sort": 0,
                "value_type": "individual"
            },
            "type": "graph",
            "xaxis": {
                "buckets": null,
                "mode": "time",
                "name": null,
                "show": true,
                "values": []
            },
            "yaxes": [
                {
                    "format": "short",
                    "label": null,
                    "logBase": 1,
                    "max": null,
                    "min": null,
                    "show": true
                },
                {
                    "format": "short",
                    "label": null,
                    "logBase": 1,
                    "max": null,
                    "min": null,
                    "show": true
                }
            ],
            "yaxis": {
                "align": false,
                "alignLevel": null
            }
        }
    ],
    "refresh": "30s",
    "schemaVersion": 22,
    "style": "dark",
    "tags": ["cloudflare", "abada-music"],
    "templating": {
        "list": []
    },
    "time": {
        "from": "now-6h",
        "to": "now"
    },
    "timepicker": {},
    "timezone": "browser",
    "title": "ABADA Music Studio",
    "uid": "abada-music",
    "version": 1
}
EOF

    print_success "Grafana 대시보드 템플릿 생성됨: $grafana_file"
}

# =============================================================================
# 모니터링 명령어 가이드
# =============================================================================

print_monitoring_guide() {
    print_header "모니터링 명령어 가이드"

    echo -e "${BOLD}Wrangler 로그 모니터링:${NC}"
    echo "  # 실시간 로그 보기"
    echo "  wrangler tail"
    echo ""
    echo "  # JSON 형식으로 로그 보기"
    echo "  wrangler tail --format=json"
    echo ""
    echo "  # 프로덕션 환경 로그"
    echo "  wrangler tail --env production"
    echo ""

    echo -e "${BOLD}Workers 배포 이력:${NC}"
    echo "  # 배포 목록"
    echo "  wrangler deployments list"
    echo ""
    echo "  # 특정 배포 상세"
    echo "  wrangler deployments view <deployment-id>"
    echo ""

    echo -e "${BOLD}KV 데이터 확인:${NC}"
    echo "  # 키 목록"
    echo "  wrangler kv:key list --namespace-id=YOUR_KV_ID"
    echo ""
    echo "  # 키 값 조회"
    echo "  wrangler kv:key get --namespace-id=YOUR_KV_ID \"key\""
    echo ""

    echo -e "${BOLD}Cloudflare Dashboard:${NC}"
    echo "  Analytics: https://dash.cloudflare.com/$CF_ACCOUNT_ID/analytics"
    echo "  Workers:   https://dash.cloudflare.com/$CF_ACCOUNT_ID/workers/overview"
    echo "  Pages:     https://dash.cloudflare.com/$CF_ACCOUNT_ID/pages"
    echo ""
}

# =============================================================================
# 결과 요약
# =============================================================================

print_summary() {
    print_header "모니터링 설정 완료 요약"

    echo -e "${BOLD}설정된 항목:${NC}"
    echo "========================================"
    echo "  Analytics Engine: 설정 안내 완료"
    echo "  Web Analytics (RUM): ${SITE_TAG:-설정 필요}"
    echo "  알림 정책: ${ALERT_EMAIL:-미설정}"
    echo "  대시보드 구성: $PROJECT_ROOT/docs/monitoring/"
    echo "========================================"
    echo ""

    echo -e "${BOLD}다음 단계:${NC}"
    echo "  1. Cloudflare Dashboard에서 알림 확인"
    echo "  2. Web Analytics 스크립트 확인"
    echo "  3. 대시보드 구성 검토"
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
                print_warning "DRY-RUN 모드: 실제 변경 없이 시뮬레이션만 수행합니다."
                shift
                ;;
            --domain)
                DOMAIN="$2"
                shift 2
                ;;
            --email)
                ALERT_EMAIL="$2"
                shift 2
                ;;
            -h|--help)
                echo "사용법: $0 [옵션]"
                echo ""
                echo "옵션:"
                echo "  --dry-run       실제 실행 없이 시뮬레이션만 수행"
                echo "  --domain <d>    대상 도메인 (기본값: music.abada.kr)"
                echo "  --email <e>     알림 수신 이메일"
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
    echo "  Monitoring Setup v1.0.0"
    echo -e "${NC}"

    log "INFO" "스크립트 시작"

    # 실행 단계
    load_environment
    get_zone_id
    setup_analytics_engine
    setup_rum
    setup_alert_policies
    create_dashboard_config
    print_monitoring_guide
    print_summary

    log "INFO" "스크립트 완료"

    print_success "모니터링 설정 완료!"
}

# 스크립트 실행
main "$@"
