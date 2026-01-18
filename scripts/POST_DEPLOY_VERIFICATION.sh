#!/bin/bash
# =============================================================================
# POST_DEPLOY_VERIFICATION.sh
# ABADA Music Studio - 배포 후 검증 스크립트
#
# 이 스크립트는 배포 후 웹사이트, API, DNS, 캐시 상태를 종합적으로 검증합니다.
#
# 사용법:
#   ./POST_DEPLOY_VERIFICATION.sh [--domain <domain>] [--verbose] [--json]
#
# 옵션:
#   --domain <domain>   검증할 도메인 (기본값: music.abada.kr)
#   --verbose           상세 출력 모드
#   --json              JSON 형식으로 결과 출력
#   --skip-dns          DNS 검증 건너뛰기
#   --skip-performance  성능 테스트 건너뛰기
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
REPORT_FILE="$LOG_DIR/verification_report_$(date +%Y%m%d_%H%M%S).md"

# 옵션 플래그
DOMAIN="music.abada.kr"
VERBOSE=false
JSON_OUTPUT=false
SKIP_DNS=false
SKIP_PERFORMANCE=false

# 검증 결과
declare -A RESULTS
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# 웹사이트 페이지 목록
PAGES=(
    "/"
    "/download"
    "/gallery"
    "/tutorial"
    "/faq"
    "/about"
)

# API 엔드포인트 목록
API_ENDPOINTS=(
    "/api"
    "/api/health"
    "/api/stats"
    "/api/gallery"
)

# =============================================================================
# 유틸리티 함수
# =============================================================================

mkdir -p "$LOG_DIR"

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_CHECKS++))
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_CHECKS++))
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNING_CHECKS++))
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[CHECK]${NC} $1"
    ((TOTAL_CHECKS++))
}

print_header() {
    echo ""
    echo -e "${MAGENTA}${BOLD}============================================${NC}"
    echo -e "${MAGENTA}${BOLD}  $1${NC}"
    echo -e "${MAGENTA}${BOLD}============================================${NC}"
    echo ""
}

verbose_log() {
    if $VERBOSE; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# HTTP 요청 및 응답 시간 측정
http_check() {
    local url=$1
    local expected_status=${2:-200}
    local timeout=${3:-30}

    local start_time=$(date +%s%N)
    local response=$(curl -s -o /dev/null -w "%{http_code}|%{time_total}|%{size_download}" \
        "$url" \
        --connect-timeout 10 \
        --max-time $timeout \
        -H "User-Agent: ABADA-Verification/1.0" \
        2>/dev/null || echo "000|0|0")

    local http_code=$(echo "$response" | cut -d'|' -f1)
    local time_total=$(echo "$response" | cut -d'|' -f2)
    local size=$(echo "$response" | cut -d'|' -f3)

    echo "$http_code|$time_total|$size"
}

# =============================================================================
# 웹사이트 접근성 검증
# =============================================================================

check_website_accessibility() {
    print_header "웹사이트 접근성 검증"

    local base_url="https://$DOMAIN"

    for page in "${PAGES[@]}"; do
        local url="${base_url}${page}"
        print_step "페이지 확인: $page"

        local result=$(http_check "$url" 200)
        local http_code=$(echo "$result" | cut -d'|' -f1)
        local response_time=$(echo "$result" | cut -d'|' -f2)
        local size=$(echo "$result" | cut -d'|' -f3)

        if [ "$http_code" = "200" ]; then
            print_success "$page (HTTP $http_code, ${response_time}s, ${size} bytes)"
            RESULTS["page_${page//\//_}"]="PASS"
        elif [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
            print_warning "$page 리다이렉트됨 (HTTP $http_code)"
            RESULTS["page_${page//\//_}"]="REDIRECT"
        else
            print_error "$page 접근 실패 (HTTP $http_code)"
            RESULTS["page_${page//\//_}"]="FAIL"
        fi

        verbose_log "  응답 시간: ${response_time}s"
        verbose_log "  응답 크기: ${size} bytes"
    done
}

# =============================================================================
# API 엔드포인트 검증
# =============================================================================

check_api_endpoints() {
    print_header "API 엔드포인트 검증"

    local base_url="https://$DOMAIN"

    for endpoint in "${API_ENDPOINTS[@]}"; do
        local url="${base_url}${endpoint}"
        print_step "API 확인: $endpoint"

        local result=$(http_check "$url" 200)
        local http_code=$(echo "$result" | cut -d'|' -f1)
        local response_time=$(echo "$result" | cut -d'|' -f2)

        # API 응답 내용 확인
        local response_body=$(curl -s "$url" --connect-timeout 10 --max-time 30 2>/dev/null || echo "")

        if [ "$http_code" = "200" ]; then
            # JSON 응답 검증
            if echo "$response_body" | grep -q '"'; then
                print_success "$endpoint (HTTP $http_code, ${response_time}s)"
                RESULTS["api_${endpoint//\//_}"]="PASS"

                # 특정 엔드포인트 상세 검증
                case $endpoint in
                    "/api/health")
                        if echo "$response_body" | grep -q '"status":"ok"'; then
                            verbose_log "  헬스 체크 응답 정상"
                        else
                            print_warning "  헬스 응답 형식 이상"
                        fi
                        ;;
                    "/api")
                        if echo "$response_body" | grep -q '"name":"ABADA Music Studio API"'; then
                            verbose_log "  API 정보 응답 정상"
                        fi
                        ;;
                esac
            else
                print_warning "$endpoint 응답이 JSON이 아님"
                RESULTS["api_${endpoint//\//_}"]="WARNING"
            fi
        else
            print_error "$endpoint 접근 실패 (HTTP $http_code)"
            RESULTS["api_${endpoint//\//_}"]="FAIL"
        fi
    done

    # CORS 검증
    print_step "CORS 설정 확인"
    local cors_response=$(curl -s -I "https://$DOMAIN/api/health" \
        -H "Origin: https://example.com" \
        --connect-timeout 10 --max-time 30 2>/dev/null || echo "")

    if echo "$cors_response" | grep -qi "access-control-allow-origin"; then
        print_success "CORS 헤더 설정됨"
        RESULTS["cors"]="PASS"
    else
        print_warning "CORS 헤더 미설정"
        RESULTS["cors"]="WARNING"
    fi
}

# =============================================================================
# DNS 설정 검증
# =============================================================================

check_dns_configuration() {
    print_header "DNS 설정 검증"

    if $SKIP_DNS; then
        print_info "DNS 검증 건너뜀 (--skip-dns)"
        return 0
    fi

    # A 레코드 확인
    print_step "A 레코드 확인"
    local a_record=$(dig +short A "$DOMAIN" 2>/dev/null || echo "")
    if [ -n "$a_record" ]; then
        print_success "A 레코드: $a_record"
        RESULTS["dns_a"]="PASS"
    else
        print_warning "A 레코드 없음 (CNAME 사용 중일 수 있음)"
        RESULTS["dns_a"]="WARNING"
    fi

    # CNAME 레코드 확인
    print_step "CNAME 레코드 확인"
    local cname_record=$(dig +short CNAME "$DOMAIN" 2>/dev/null || echo "")
    if [ -n "$cname_record" ]; then
        print_success "CNAME 레코드: $cname_record"
        RESULTS["dns_cname"]="PASS"
    else
        print_info "CNAME 레코드 없음"
        RESULTS["dns_cname"]="N/A"
    fi

    # AAAA 레코드 확인 (IPv6)
    print_step "AAAA 레코드 확인 (IPv6)"
    local aaaa_record=$(dig +short AAAA "$DOMAIN" 2>/dev/null || echo "")
    if [ -n "$aaaa_record" ]; then
        print_success "AAAA 레코드: $aaaa_record"
        RESULTS["dns_aaaa"]="PASS"
    else
        print_info "AAAA 레코드 없음"
        RESULTS["dns_aaaa"]="N/A"
    fi

    # NS 레코드 확인
    print_step "NS 레코드 확인"
    local ns_records=$(dig +short NS "${DOMAIN#*.}" 2>/dev/null | head -3 || echo "")
    if [ -n "$ns_records" ]; then
        print_success "NS 레코드 존재"
        verbose_log "  NS: $(echo $ns_records | tr '\n' ' ')"
        RESULTS["dns_ns"]="PASS"
    else
        print_warning "NS 레코드 조회 실패"
        RESULTS["dns_ns"]="WARNING"
    fi
}

# =============================================================================
# SSL/TLS 검증
# =============================================================================

check_ssl_certificate() {
    print_header "SSL/TLS 인증서 검증"

    print_step "SSL 인증서 확인"

    local ssl_info=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "")

    if [ -n "$ssl_info" ]; then
        local not_after=$(echo "$ssl_info" | grep "notAfter" | cut -d= -f2)

        if [ -n "$not_after" ]; then
            local expiry_date=$(date -d "$not_after" +%s 2>/dev/null || date -j -f "%b %d %H:%M:%S %Y %Z" "$not_after" +%s 2>/dev/null || echo "0")
            local current_date=$(date +%s)
            local days_until_expiry=$(( (expiry_date - current_date) / 86400 ))

            if [ $days_until_expiry -gt 30 ]; then
                print_success "SSL 인증서 유효 (만료까지 ${days_until_expiry}일)"
                RESULTS["ssl_cert"]="PASS"
            elif [ $days_until_expiry -gt 0 ]; then
                print_warning "SSL 인증서 곧 만료 (${days_until_expiry}일 남음)"
                RESULTS["ssl_cert"]="WARNING"
            else
                print_error "SSL 인증서 만료됨"
                RESULTS["ssl_cert"]="FAIL"
            fi

            verbose_log "  만료일: $not_after"
        else
            print_warning "SSL 만료일 확인 실패"
            RESULTS["ssl_cert"]="WARNING"
        fi
    else
        print_error "SSL 인증서 조회 실패"
        RESULTS["ssl_cert"]="FAIL"
    fi

    # HTTPS 리다이렉트 확인
    print_step "HTTP -> HTTPS 리다이렉트 확인"
    local http_response=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN" --connect-timeout 10 --max-time 30 -L 2>/dev/null || echo "000")

    if [ "$http_response" = "200" ]; then
        print_success "HTTP -> HTTPS 리다이렉트 정상"
        RESULTS["https_redirect"]="PASS"
    else
        print_warning "HTTP 리다이렉트 확인 필요 (HTTP $http_response)"
        RESULTS["https_redirect"]="WARNING"
    fi
}

# =============================================================================
# Cloudflare 캐시 상태 검증
# =============================================================================

check_cloudflare_cache() {
    print_header "Cloudflare 캐시 상태 검증"

    print_step "CF-Cache-Status 헤더 확인"

    local headers=$(curl -s -I "https://$DOMAIN" --connect-timeout 10 --max-time 30 2>/dev/null || echo "")

    # CF-Cache-Status 확인
    local cache_status=$(echo "$headers" | grep -i "cf-cache-status" | cut -d: -f2 | tr -d ' \r\n')

    if [ -n "$cache_status" ]; then
        case "$cache_status" in
            "HIT")
                print_success "캐시 히트 (HIT)"
                RESULTS["cache_status"]="PASS"
                ;;
            "MISS")
                print_info "캐시 미스 (MISS) - 첫 요청이거나 캐시 만료"
                RESULTS["cache_status"]="PASS"
                ;;
            "BYPASS")
                print_warning "캐시 바이패스 (BYPASS)"
                RESULTS["cache_status"]="WARNING"
                ;;
            "DYNAMIC")
                print_info "동적 컨텐츠 (DYNAMIC)"
                RESULTS["cache_status"]="PASS"
                ;;
            *)
                print_info "캐시 상태: $cache_status"
                RESULTS["cache_status"]="PASS"
                ;;
        esac
    else
        print_warning "CF-Cache-Status 헤더 없음 (Cloudflare 프록시 미사용?)"
        RESULTS["cache_status"]="WARNING"
    fi

    # CF-Ray 확인 (Cloudflare 통과 확인)
    print_step "Cloudflare 프록시 확인"
    local cf_ray=$(echo "$headers" | grep -i "cf-ray" | cut -d: -f2 | tr -d ' \r\n')

    if [ -n "$cf_ray" ]; then
        print_success "Cloudflare 프록시 활성화 (CF-Ray: $cf_ray)"
        RESULTS["cf_proxy"]="PASS"
    else
        print_warning "Cloudflare 프록시 미활성화"
        RESULTS["cf_proxy"]="WARNING"
    fi

    # 서버 헤더 확인
    print_step "서버 헤더 확인"
    local server=$(echo "$headers" | grep -i "^server:" | cut -d: -f2 | tr -d ' \r\n')

    if [ -n "$server" ]; then
        if echo "$server" | grep -qi "cloudflare"; then
            print_success "서버: Cloudflare"
            RESULTS["server"]="PASS"
        else
            print_info "서버: $server"
            RESULTS["server"]="PASS"
        fi
    fi
}

# =============================================================================
# 성능 기준선 측정
# =============================================================================

check_performance_baseline() {
    print_header "성능 기준선 측정"

    if $SKIP_PERFORMANCE; then
        print_info "성능 테스트 건너뜀 (--skip-performance)"
        return 0
    fi

    local base_url="https://$DOMAIN"
    local total_time=0
    local measurements=5

    print_step "응답 시간 측정 ($measurements회 측정)"

    for i in $(seq 1 $measurements); do
        local result=$(http_check "$base_url" 200)
        local response_time=$(echo "$result" | cut -d'|' -f2)
        total_time=$(echo "$total_time + $response_time" | bc 2>/dev/null || echo "$total_time")
        verbose_log "  측정 $i: ${response_time}s"
        sleep 0.5
    done

    local avg_time=$(echo "scale=3; $total_time / $measurements" | bc 2>/dev/null || echo "0")

    if (( $(echo "$avg_time < 1.0" | bc -l 2>/dev/null || echo "0") )); then
        print_success "평균 응답 시간: ${avg_time}s (양호)"
        RESULTS["performance"]="PASS"
    elif (( $(echo "$avg_time < 2.0" | bc -l 2>/dev/null || echo "0") )); then
        print_warning "평균 응답 시간: ${avg_time}s (보통)"
        RESULTS["performance"]="WARNING"
    else
        print_error "평균 응답 시간: ${avg_time}s (느림)"
        RESULTS["performance"]="FAIL"
    fi

    # TTFB (Time To First Byte) 측정
    print_step "TTFB 측정"
    local ttfb=$(curl -s -o /dev/null -w "%{time_starttransfer}" "$base_url" --connect-timeout 10 --max-time 30 2>/dev/null || echo "0")

    if (( $(echo "$ttfb < 0.5" | bc -l 2>/dev/null || echo "0") )); then
        print_success "TTFB: ${ttfb}s (양호)"
        RESULTS["ttfb"]="PASS"
    elif (( $(echo "$ttfb < 1.0" | bc -l 2>/dev/null || echo "0") )); then
        print_warning "TTFB: ${ttfb}s (보통)"
        RESULTS["ttfb"]="WARNING"
    else
        print_error "TTFB: ${ttfb}s (느림)"
        RESULTS["ttfb"]="FAIL"
    fi
}

# =============================================================================
# 검증 리포트 생성
# =============================================================================

generate_report() {
    print_header "검증 리포트 생성"

    cat > "$REPORT_FILE" << EOF
# ABADA Music Studio - 배포 검증 리포트

## 검증 정보
- **검증 일시**: $(date '+%Y-%m-%d %H:%M:%S')
- **대상 도메인**: $DOMAIN
- **검증 스크립트 버전**: 1.0.0

## 검증 결과 요약

| 항목 | 결과 |
|------|------|
| 총 검증 항목 | $TOTAL_CHECKS |
| 성공 | $PASSED_CHECKS |
| 실패 | $FAILED_CHECKS |
| 경고 | $WARNING_CHECKS |

## 상세 결과

### 웹사이트 접근성
EOF

    for page in "${PAGES[@]}"; do
        local key="page_${page//\//_}"
        local result="${RESULTS[$key]:-N/A}"
        echo "- \`$page\`: $result" >> "$REPORT_FILE"
    done

    cat >> "$REPORT_FILE" << EOF

### API 엔드포인트
EOF

    for endpoint in "${API_ENDPOINTS[@]}"; do
        local key="api_${endpoint//\//_}"
        local result="${RESULTS[$key]:-N/A}"
        echo "- \`$endpoint\`: $result" >> "$REPORT_FILE"
    done

    cat >> "$REPORT_FILE" << EOF

### 인프라 검증
- DNS A 레코드: ${RESULTS[dns_a]:-N/A}
- DNS CNAME 레코드: ${RESULTS[dns_cname]:-N/A}
- SSL 인증서: ${RESULTS[ssl_cert]:-N/A}
- HTTPS 리다이렉트: ${RESULTS[https_redirect]:-N/A}
- Cloudflare 캐시: ${RESULTS[cache_status]:-N/A}
- Cloudflare 프록시: ${RESULTS[cf_proxy]:-N/A}

### 성능
- 평균 응답 시간: ${RESULTS[performance]:-N/A}
- TTFB: ${RESULTS[ttfb]:-N/A}

## 권장 조치

EOF

    # 권장 조치 추가
    if [ "${RESULTS[ssl_cert]}" = "WARNING" ]; then
        echo "- SSL 인증서 갱신 필요" >> "$REPORT_FILE"
    fi

    if [ "${RESULTS[performance]}" = "FAIL" ] || [ "${RESULTS[performance]}" = "WARNING" ]; then
        echo "- 성능 최적화 검토 필요" >> "$REPORT_FILE"
    fi

    if [ "${RESULTS[cf_proxy]}" = "WARNING" ]; then
        echo "- Cloudflare DNS 프록시 활성화 권장" >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

---
*이 리포트는 POST_DEPLOY_VERIFICATION.sh에 의해 자동 생성되었습니다.*
EOF

    print_success "리포트 생성됨: $REPORT_FILE"
}

# =============================================================================
# 결과 요약 출력
# =============================================================================

print_summary() {
    print_header "검증 결과 요약"

    local pass_rate=0
    if [ $TOTAL_CHECKS -gt 0 ]; then
        pass_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    fi

    echo -e "${BOLD}검증 통계:${NC}"
    echo "========================================"
    echo "  총 검증 항목: $TOTAL_CHECKS"
    echo -e "  ${GREEN}성공${NC}: $PASSED_CHECKS"
    echo -e "  ${RED}실패${NC}: $FAILED_CHECKS"
    echo -e "  ${YELLOW}경고${NC}: $WARNING_CHECKS"
    echo "  통과율: ${pass_rate}%"
    echo "========================================"
    echo ""

    if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
        echo -e "${GREEN}${BOLD}모든 검증 통과!${NC}"
    elif [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${YELLOW}${BOLD}검증 완료 (일부 경고 있음)${NC}"
    else
        echo -e "${RED}${BOLD}검증 실패 (문제 해결 필요)${NC}"
    fi

    echo ""
    print_info "상세 리포트: $REPORT_FILE"
}

# =============================================================================
# JSON 출력
# =============================================================================

output_json() {
    if ! $JSON_OUTPUT; then
        return 0
    fi

    local json="{"
    json+="\"timestamp\":\"$(date -Iseconds)\","
    json+="\"domain\":\"$DOMAIN\","
    json+="\"total_checks\":$TOTAL_CHECKS,"
    json+="\"passed\":$PASSED_CHECKS,"
    json+="\"failed\":$FAILED_CHECKS,"
    json+="\"warnings\":$WARNING_CHECKS,"
    json+="\"results\":{"

    local first=true
    for key in "${!RESULTS[@]}"; do
        if $first; then
            first=false
        else
            json+=","
        fi
        json+="\"$key\":\"${RESULTS[$key]}\""
    done

    json+="}}"

    echo "$json"
}

# =============================================================================
# 메인 실행
# =============================================================================

main() {
    # 인자 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            --domain)
                DOMAIN="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --skip-dns)
                SKIP_DNS=true
                shift
                ;;
            --skip-performance)
                SKIP_PERFORMANCE=true
                shift
                ;;
            -h|--help)
                echo "사용법: $0 [옵션]"
                echo ""
                echo "옵션:"
                echo "  --domain <domain>   검증할 도메인 (기본값: music.abada.kr)"
                echo "  --verbose           상세 출력 모드"
                echo "  --json              JSON 형식으로 결과 출력"
                echo "  --skip-dns          DNS 검증 건너뛰기"
                echo "  --skip-performance  성능 테스트 건너뛰기"
                echo "  -h, --help          이 도움말 표시"
                exit 0
                ;;
            *)
                print_error "알 수 없는 옵션: $1"
                exit 1
                ;;
        esac
    done

    if ! $JSON_OUTPUT; then
        echo ""
        echo -e "${CYAN}${BOLD}"
        echo "  ___  ______  ___  ____   ___    __  __           _      "
        echo " / _ \ | ___ \/ _ \|  _ \ / _ \  |  \/  |_   _ ___(_) ___ "
        echo "| |_| || |_/ / /_\ \ | | | |_| | | |\/| | | | / __| |/ __|"
        echo "|  _  || ___ \  _  | |_| |  _  | | |  | | |_| \__ \ | (__ "
        echo "|_| |_||_| \_\_| |_|____/|_| |_| |_|  |_|\__,_|___/_|\___|"
        echo ""
        echo "  Post-Deployment Verification v1.0.0"
        echo "  Domain: $DOMAIN"
        echo -e "${NC}"
    fi

    # 검증 실행
    check_website_accessibility
    check_api_endpoints
    check_dns_configuration
    check_ssl_certificate
    check_cloudflare_cache
    check_performance_baseline

    # 리포트 생성
    generate_report

    # 결과 출력
    if $JSON_OUTPUT; then
        output_json
    else
        print_summary
    fi

    # 종료 코드 결정
    if [ $FAILED_CHECKS -gt 0 ]; then
        exit 1
    elif [ $WARNING_CHECKS -gt 0 ]; then
        exit 0
    else
        exit 0
    fi
}

# 스크립트 실행
main "$@"
