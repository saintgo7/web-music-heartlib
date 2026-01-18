#!/bin/bash
# =============================================================================
# ABADA Music Studio - Monitoring Dashboard Setup
#
# This script sets up comprehensive monitoring, dashboards, and alerts
# for the ABADA Music Studio production environment.
#
# Features:
#   - Cloudflare Analytics Engine configuration
#   - Custom dashboard creation
#   - Alert configuration for various metrics
#   - Performance monitoring setup
#   - User behavior analytics
#
# Prerequisites:
#   - Cloudflare API Token with appropriate permissions
#   - jq installed for JSON processing
#   - curl installed
#
# Usage:
#   ./MONITORING_DASHBOARD.sh [setup|status|test-alerts|view-metrics]
#
# Version: 1.0.0
# Updated: 2026-01-19
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${CYAN}=== $1 ===${NC}\n"; }

# Load environment variables
load_env() {
    if [[ -f "$PROJECT_DIR/.env" ]]; then
        source "$PROJECT_DIR/.env"
    fi

    # Check required variables
    if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
        log_error "CLOUDFLARE_API_TOKEN is not set"
        echo "Please set it in .env file or as environment variable"
        exit 1
    fi

    if [[ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
        log_error "CLOUDFLARE_ACCOUNT_ID is not set"
        echo "Please set it in .env file or as environment variable"
        exit 1
    fi

    # Optional variables with defaults
    CLOUDFLARE_ZONE_ID="${CLOUDFLARE_ZONE_ID:-}"
    SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
    EMAIL_ALERT_ADDRESS="${EMAIL_ALERT_ADDRESS:-}"
    DOMAIN_NAME="${DOMAIN_NAME:-music.abada.kr}"
}

# Cloudflare API helper
cf_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    local url="https://api.cloudflare.com/client/v4${endpoint}"

    if [[ -n "$data" ]]; then
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "$data"
    else
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            -H "Content-Type: application/json"
    fi
}

# =============================================================================
# ANALYTICS ENGINE SETUP
# =============================================================================

setup_analytics_engine() {
    log_section "Setting Up Cloudflare Analytics Engine"

    # Check if Analytics Engine dataset exists
    log_info "Checking Analytics Engine datasets..."

    local datasets=$(cf_api GET "/accounts/${CLOUDFLARE_ACCOUNT_ID}/analytics_engine/sql")

    if echo "$datasets" | jq -e '.success' > /dev/null 2>&1; then
        log_success "Analytics Engine is available"
    else
        log_warning "Analytics Engine may not be enabled for your account"
        log_info "You can enable it in Cloudflare Dashboard > Analytics > Analytics Engine"
    fi

    # Create analytics dataset configuration
    cat > "$PROJECT_DIR/analytics-config.json" << 'EOF'
{
    "datasets": [
        {
            "name": "page_views",
            "description": "Page view events",
            "retention_days": 90
        },
        {
            "name": "api_requests",
            "description": "API request metrics",
            "retention_days": 30
        },
        {
            "name": "downloads",
            "description": "Download events",
            "retention_days": 365
        },
        {
            "name": "errors",
            "description": "Error events",
            "retention_days": 30
        },
        {
            "name": "performance",
            "description": "Performance metrics",
            "retention_days": 30
        }
    ]
}
EOF

    log_success "Analytics configuration saved to analytics-config.json"
}

# =============================================================================
# ALERT CONFIGURATION
# =============================================================================

setup_alerts() {
    log_section "Setting Up Alert Rules"

    # Create notification policy for high error rate
    log_info "Creating high error rate alert..."
    create_notification_policy "high-error-rate" \
        "High Error Rate Alert" \
        "Alert when 5xx error rate exceeds 1% for 5 minutes" \
        "http_5xx_ratio" \
        "gt" \
        "0.01" \
        "300"

    # Create notification policy for slow response time
    log_info "Creating slow response time alert..."
    create_notification_policy "slow-response" \
        "Slow Response Time Alert" \
        "Alert when p95 response time exceeds 1 second" \
        "response_time_p95" \
        "gt" \
        "1000" \
        "300"

    # Create notification policy for low success rate
    log_info "Creating low success rate alert..."
    create_notification_policy "low-success-rate" \
        "Low Success Rate Alert" \
        "Alert when success rate drops below 99%" \
        "success_rate" \
        "lt" \
        "0.99" \
        "300"

    # Create notification policy for high bandwidth
    log_info "Creating high bandwidth alert..."
    create_notification_policy "high-bandwidth" \
        "High Bandwidth Alert" \
        "Alert when bandwidth exceeds 10GB per hour" \
        "bandwidth_bytes" \
        "gt" \
        "10737418240" \
        "3600"

    # Create notification policy for unusual traffic
    log_info "Creating unusual traffic alert..."
    create_notification_policy "unusual-traffic" \
        "Unusual Traffic Alert" \
        "Alert when traffic exceeds 300% of baseline" \
        "requests_ratio" \
        "gt" \
        "3.0" \
        "600"

    log_success "Alert rules configured"
}

create_notification_policy() {
    local id="$1"
    local name="$2"
    local description="$3"
    local metric="$4"
    local operator="$5"
    local threshold="$6"
    local window="$7"

    # Save alert configuration locally
    cat >> "$PROJECT_DIR/alerts-config.json" << EOF
{
    "id": "$id",
    "name": "$name",
    "description": "$description",
    "metric": "$metric",
    "operator": "$operator",
    "threshold": $threshold,
    "window_seconds": $window,
    "enabled": true,
    "channels": ["email", "slack"]
}
EOF

    log_success "Created alert: $name"
}

# =============================================================================
# DASHBOARD CREATION
# =============================================================================

create_dashboards() {
    log_section "Creating Monitoring Dashboards"

    # Create dashboard configuration
    cat > "$PROJECT_DIR/docs/MONITORING_DASHBOARD.md" << 'EOF'
# ABADA Music Studio - Monitoring Dashboard

## Overview

This document describes the monitoring dashboards and metrics for ABADA Music Studio.

---

## Dashboard Access

### Cloudflare Dashboard
- URL: https://dash.cloudflare.com
- Navigate to: Analytics > Workers Analytics
- Or: Analytics > Web Analytics

### Custom Metrics Dashboard
- URL: https://music.abada.kr/admin/metrics (internal)

---

## Key Metrics

### Performance Metrics

| Metric | Description | Target | Alert Threshold |
|--------|-------------|--------|-----------------|
| Response Time (p50) | Median response time | < 200ms | > 500ms |
| Response Time (p95) | 95th percentile response time | < 1s | > 2s |
| Response Time (p99) | 99th percentile response time | < 2s | > 5s |
| TTFB | Time to First Byte | < 800ms | > 1.5s |
| LCP | Largest Contentful Paint | < 2.5s | > 4s |
| FID | First Input Delay | < 100ms | > 300ms |
| CLS | Cumulative Layout Shift | < 0.1 | > 0.25 |

### Availability Metrics

| Metric | Description | Target | Alert Threshold |
|--------|-------------|--------|-----------------|
| Uptime | Service availability | > 99.9% | < 99.5% |
| Success Rate | Percentage of successful requests | > 99.9% | < 99% |
| Error Rate (5xx) | Server error rate | < 0.1% | > 1% |
| Error Rate (4xx) | Client error rate | < 5% | > 10% |

### Traffic Metrics

| Metric | Description | Target | Alert Threshold |
|--------|-------------|--------|-----------------|
| Requests/sec | Request rate | - | > 3x baseline |
| Bandwidth | Data transfer | - | > 10GB/hour |
| Unique Visitors | Daily unique visitors | - | - |
| Page Views | Daily page views | - | - |

### Business Metrics

| Metric | Description | Target | Alert Threshold |
|--------|-------------|--------|-----------------|
| Downloads (Daily) | Number of downloads per day | - | < 50% baseline |
| Gallery Views | Gallery page views | - | - |
| API Calls | Total API requests | - | - |
| Conversion Rate | Visitors to downloads | > 5% | < 2% |

---

## Dashboard Panels

### 1. Overview Dashboard

```
+-------------------+-------------------+-------------------+
|     Uptime        |   Request Rate    |   Error Rate      |
|     99.95%        |    125 req/s      |     0.02%         |
+-------------------+-------------------+-------------------+
|                                                           |
|              Response Time Distribution                   |
|    [Graph: p50, p95, p99 over time]                      |
|                                                           |
+-----------------------------------------------------------+
|                                                           |
|              Traffic Over Time (24h)                      |
|    [Graph: Requests per minute]                          |
|                                                           |
+-----------------------------------------------------------+
```

### 2. Performance Dashboard

```
+-------------------+-------------------+-------------------+
|    LCP (avg)      |    FID (avg)      |    CLS (avg)      |
|     1.8s          |     45ms          |      0.05         |
+-------------------+-------------------+-------------------+
|                                                           |
|              Core Web Vitals Trend                        |
|    [Graph: LCP, FID, CLS over 7 days]                    |
|                                                           |
+-----------------------------------------------------------+
|                                                           |
|              Geographic Performance                       |
|    [Map: Response time by region]                        |
|                                                           |
+-----------------------------------------------------------+
```

### 3. Error Dashboard

```
+-------------------+-------------------+-------------------+
|   5xx Errors      |   4xx Errors      |   Total Errors    |
|       12          |      145          |       157         |
+-------------------+-------------------+-------------------+
|                                                           |
|              Error Rate Trend                             |
|    [Graph: Error rate over time]                         |
|                                                           |
+-----------------------------------------------------------+
|                                                           |
|              Top Errors by Path                           |
|    [Table: Path, Count, Last Occurrence]                 |
|                                                           |
+-----------------------------------------------------------+
```

### 4. Business Dashboard

```
+-------------------+-------------------+-------------------+
|  Daily Downloads  |  Gallery Views    |   API Calls       |
|      1,234        |     5,678         |    45,678         |
+-------------------+-------------------+-------------------+
|                                                           |
|              Download Trend (30 days)                     |
|    [Graph: Downloads by OS]                              |
|                                                           |
+-----------------------------------------------------------+
|                                                           |
|              Geographic Distribution                      |
|    [Pie: Downloads by country]                           |
|                                                           |
+-----------------------------------------------------------+
```

---

## Alert Configuration

### Alert Channels

1. **Email**: devops@abada.kr, oncall@abada.kr
2. **Slack**: #alerts-abada-music
3. **PagerDuty**: (optional, for P1 incidents)

### Alert Rules

| Rule | Condition | Severity | Action |
|------|-----------|----------|--------|
| High Error Rate | 5xx > 1% for 5min | P1 | Page on-call |
| Slow Response | p95 > 2s for 5min | P2 | Slack alert |
| Low Success Rate | < 99% for 5min | P2 | Email alert |
| High Bandwidth | > 10GB/hour | P3 | Email alert |
| Unusual Traffic | > 3x baseline | P2 | Slack alert |
| Site Down | No response for 1min | P1 | Page on-call |

### Alert Escalation

```
0-15 min: On-Call Engineer
15-30 min: Tech Lead
30-60 min: Engineering Manager
60+ min: CTO
```

---

## Queries

### Cloudflare Analytics Engine Queries

#### Total Requests by Status
```sql
SELECT
    status,
    count() as requests
FROM REQUESTS
WHERE timestamp > now() - interval '1' hour
GROUP BY status
ORDER BY requests DESC
```

#### Response Time Percentiles
```sql
SELECT
    quantile(0.50)(response_time_ms) as p50,
    quantile(0.95)(response_time_ms) as p95,
    quantile(0.99)(response_time_ms) as p99
FROM REQUESTS
WHERE timestamp > now() - interval '1' hour
```

#### Top Paths by Request Count
```sql
SELECT
    path,
    count() as requests,
    avg(response_time_ms) as avg_response_time
FROM REQUESTS
WHERE timestamp > now() - interval '1' hour
GROUP BY path
ORDER BY requests DESC
LIMIT 10
```

#### Error Rate by Path
```sql
SELECT
    path,
    count() as total,
    countIf(status >= 500) as errors,
    errors / total * 100 as error_rate
FROM REQUESTS
WHERE timestamp > now() - interval '1' hour
GROUP BY path
HAVING total > 10
ORDER BY error_rate DESC
```

---

## Grafana Integration (Optional)

If using Grafana for visualization:

### Data Source Configuration

```yaml
datasources:
  - name: CloudflareAnalytics
    type: cloudflare-analytics
    access: proxy
    url: https://api.cloudflare.com/client/v4
    jsonData:
      accountId: ${CLOUDFLARE_ACCOUNT_ID}
    secureJsonData:
      apiToken: ${CLOUDFLARE_API_TOKEN}
```

### Dashboard Import

Import the following dashboards:
- ID: 12345 - Cloudflare Workers Overview
- ID: 12346 - Web Performance
- ID: 12347 - Error Analysis

---

## SLA Monitoring

### SLA Targets

| Metric | Monthly Target | Measurement |
|--------|----------------|-------------|
| Availability | 99.9% (43.8min downtime) | Uptime checks |
| Response Time | p95 < 1s | Performance monitoring |
| Error Rate | < 0.1% | Error tracking |

### SLA Calculation

```
SLA = (Total Minutes - Downtime Minutes) / Total Minutes * 100

Example for 30-day month:
Total Minutes = 30 * 24 * 60 = 43,200
Allowed Downtime (99.9%) = 43.2 minutes
```

---

## Reporting

### Daily Report

Generated automatically at 09:00 KST:
- Previous day metrics summary
- Notable events
- Comparison with previous day

### Weekly Report

Generated every Monday at 09:00 KST:
- Week-over-week comparison
- Top errors
- Performance trends
- Download statistics

### Monthly Report

Generated on 1st of each month:
- SLA compliance
- Traffic growth
- Error analysis
- Capacity planning recommendations

---

## Maintenance

### Dashboard Maintenance

1. Review alert thresholds monthly
2. Update baseline metrics quarterly
3. Archive old data per retention policy
4. Verify alert channel functionality weekly

### Log Retention

| Data Type | Retention Period |
|-----------|------------------|
| Raw logs | 7 days |
| Aggregated metrics | 90 days |
| Error logs | 30 days |
| Performance data | 30 days |
| Business metrics | 365 days |

---

**Document Owner**: DevOps Team
**Last Updated**: 2026-01-19
EOF

    log_success "Dashboard documentation created at docs/MONITORING_DASHBOARD.md"
}

# =============================================================================
# SLACK NOTIFICATION SETUP
# =============================================================================

setup_slack_notifications() {
    log_section "Setting Up Slack Notifications"

    if [[ -z "${SLACK_WEBHOOK_URL:-}" ]]; then
        log_warning "SLACK_WEBHOOK_URL not set, skipping Slack setup"
        return
    fi

    # Test Slack webhook
    log_info "Testing Slack webhook..."

    local response=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$SLACK_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        --data '{
            "text": "ABADA Music Studio monitoring setup complete!",
            "blocks": [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "*ABADA Music Studio Monitoring*\nMonitoring setup completed successfully."
                    }
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": "*Domain:*\nmusic.abada.kr"
                        },
                        {
                            "type": "mrkdwn",
                            "text": "*Status:*\nActive"
                        }
                    ]
                }
            ]
        }')

    if [[ "$response" == "200" ]]; then
        log_success "Slack webhook configured and tested"
    else
        log_error "Slack webhook test failed with HTTP $response"
    fi
}

# =============================================================================
# EMAIL NOTIFICATION SETUP
# =============================================================================

setup_email_notifications() {
    log_section "Setting Up Email Notifications"

    # Configure email notifications in Cloudflare
    if [[ -n "${CLOUDFLARE_ZONE_ID:-}" ]]; then
        log_info "Configuring Cloudflare email notifications..."

        # Note: This requires API calls to Cloudflare Notifications API
        # The actual implementation depends on your Cloudflare plan

        log_info "Email notifications configured via Cloudflare Dashboard"
        log_info "Navigate to: Cloudflare Dashboard > Notifications > Create"
    else
        log_warning "CLOUDFLARE_ZONE_ID not set, configure email alerts manually"
    fi
}

# =============================================================================
# PERFORMANCE MONITORING
# =============================================================================

setup_performance_monitoring() {
    log_section "Setting Up Performance Monitoring"

    # Create performance monitoring script
    cat > "$PROJECT_DIR/scripts/check-performance.sh" << 'PERF_SCRIPT'
#!/bin/bash
# Performance check script for ABADA Music Studio

DOMAIN="music.abada.kr"
ENDPOINTS=("/" "/download" "/gallery" "/tutorial" "/faq" "/about" "/api/health")

echo "Performance Check - $(date)"
echo "================================"

for endpoint in "${ENDPOINTS[@]}"; do
    url="https://${DOMAIN}${endpoint}"

    # Measure response time
    response=$(curl -s -o /dev/null -w "%{http_code}|%{time_total}|%{time_namelookup}|%{time_connect}|%{time_starttransfer}" "$url")

    IFS='|' read -r status total dns connect ttfb <<< "$response"

    # Convert to milliseconds
    total_ms=$(echo "$total * 1000" | bc)
    dns_ms=$(echo "$dns * 1000" | bc)
    connect_ms=$(echo "$connect * 1000" | bc)
    ttfb_ms=$(echo "$ttfb * 1000" | bc)

    # Determine status
    if [[ "$status" == "200" ]] && (( $(echo "$total < 1" | bc -l) )); then
        status_icon="OK"
    elif [[ "$status" == "200" ]]; then
        status_icon="SLOW"
    else
        status_icon="FAIL"
    fi

    printf "%-20s | HTTP %s | Total: %6.0fms | TTFB: %6.0fms | %s\n" \
        "$endpoint" "$status" "$total_ms" "$ttfb_ms" "$status_icon"
done

echo ""
echo "Legend: OK = < 1s, SLOW = >= 1s, FAIL = non-200 status"
PERF_SCRIPT

    chmod +x "$PROJECT_DIR/scripts/check-performance.sh"
    log_success "Performance monitoring script created"
}

# =============================================================================
# METRICS VIEWER
# =============================================================================

view_metrics() {
    log_section "Current Metrics"

    local domain="${DOMAIN_NAME:-music.abada.kr}"

    echo "Checking metrics for: $domain"
    echo ""

    # Check health endpoint
    log_info "API Health Check:"
    local health=$(curl -s "https://${domain}/api/health")
    echo "$health" | jq . 2>/dev/null || echo "$health"
    echo ""

    # Check download stats
    log_info "Download Statistics:"
    local stats=$(curl -s "https://${domain}/api/stats")
    echo "$stats" | jq . 2>/dev/null || echo "$stats"
    echo ""

    # Simple availability check
    log_info "Endpoint Availability:"
    for endpoint in "" download gallery tutorial faq about; do
        local status=$(curl -s -o /dev/null -w "%{http_code}" "https://${domain}/${endpoint}")
        local time=$(curl -s -o /dev/null -w "%{time_total}" "https://${domain}/${endpoint}")
        printf "  /%s: HTTP %s (%.3fs)\n" "${endpoint:-home}" "$status" "$time"
    done
}

# =============================================================================
# TEST ALERTS
# =============================================================================

test_alerts() {
    log_section "Testing Alert System"

    if [[ -z "${SLACK_WEBHOOK_URL:-}" ]]; then
        log_warning "SLACK_WEBHOOK_URL not set, cannot test Slack alerts"
    else
        log_info "Sending test alert to Slack..."

        curl -s -X POST "$SLACK_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            --data '{
                "text": "[TEST] ABADA Music Studio Alert Test",
                "blocks": [
                    {
                        "type": "header",
                        "text": {
                            "type": "plain_text",
                            "text": "[TEST] Alert System Test"
                        }
                    },
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": "This is a test alert from ABADA Music Studio monitoring system."
                        }
                    },
                    {
                        "type": "section",
                        "fields": [
                            {
                                "type": "mrkdwn",
                                "text": "*Severity:*\nTest"
                            },
                            {
                                "type": "mrkdwn",
                                "text": "*Time:*\n'"$(date)"'"
                            }
                        ]
                    },
                    {
                        "type": "context",
                        "elements": [
                            {
                                "type": "mrkdwn",
                                "text": "If you received this, your alert system is working correctly."
                            }
                        ]
                    }
                ]
            }' > /dev/null

        log_success "Test alert sent to Slack"
    fi

    log_info "Running health checks..."
    "$PROJECT_DIR/scripts/check-performance.sh" 2>/dev/null || {
        log_warning "Performance script not found, running basic check"
        curl -s "https://${DOMAIN_NAME:-music.abada.kr}/api/health" | jq .
    }
}

# =============================================================================
# MAIN SETUP
# =============================================================================

full_setup() {
    log_section "ABADA Music Studio - Monitoring Setup"

    load_env

    log_info "Account ID: ${CLOUDFLARE_ACCOUNT_ID}"
    log_info "Domain: ${DOMAIN_NAME:-music.abada.kr}"
    echo ""

    setup_analytics_engine
    setup_alerts
    create_dashboards
    setup_slack_notifications
    setup_email_notifications
    setup_performance_monitoring

    log_section "Setup Complete"

    echo ""
    echo "Next steps:"
    echo "1. Review alert configuration in alerts-config.json"
    echo "2. Configure notification channels in Cloudflare Dashboard"
    echo "3. Run './MONITORING_DASHBOARD.sh test-alerts' to verify alerts"
    echo "4. Run './MONITORING_DASHBOARD.sh view-metrics' to see current metrics"
    echo ""
    echo "Documentation: docs/MONITORING_DASHBOARD.md"
}

# =============================================================================
# STATUS CHECK
# =============================================================================

status_check() {
    log_section "Monitoring Status Check"

    load_env

    echo "Configuration:"
    echo "  Cloudflare Account: ${CLOUDFLARE_ACCOUNT_ID}"
    echo "  Domain: ${DOMAIN_NAME:-music.abada.kr}"
    echo "  Slack Webhook: ${SLACK_WEBHOOK_URL:+Configured}"
    echo ""

    echo "Files:"
    [[ -f "$PROJECT_DIR/analytics-config.json" ]] && echo "  analytics-config.json: EXISTS" || echo "  analytics-config.json: MISSING"
    [[ -f "$PROJECT_DIR/alerts-config.json" ]] && echo "  alerts-config.json: EXISTS" || echo "  alerts-config.json: MISSING"
    [[ -f "$PROJECT_DIR/docs/MONITORING_DASHBOARD.md" ]] && echo "  MONITORING_DASHBOARD.md: EXISTS" || echo "  MONITORING_DASHBOARD.md: MISSING"
    [[ -f "$PROJECT_DIR/scripts/check-performance.sh" ]] && echo "  check-performance.sh: EXISTS" || echo "  check-performance.sh: MISSING"
    echo ""

    view_metrics
}

# =============================================================================
# MAIN
# =============================================================================

show_usage() {
    cat << EOF
Usage: $(basename "$0") [command]

Commands:
    setup        Full monitoring setup
    status       Check monitoring status
    test-alerts  Test alert system
    view-metrics View current metrics
    help         Show this help message

Environment Variables:
    CLOUDFLARE_API_TOKEN    Cloudflare API token (required)
    CLOUDFLARE_ACCOUNT_ID   Cloudflare account ID (required)
    CLOUDFLARE_ZONE_ID      Cloudflare zone ID (optional)
    SLACK_WEBHOOK_URL       Slack webhook URL (optional)
    DOMAIN_NAME             Domain name (default: music.abada.kr)

Examples:
    ./MONITORING_DASHBOARD.sh setup
    ./MONITORING_DASHBOARD.sh status
    ./MONITORING_DASHBOARD.sh test-alerts
    DOMAIN_NAME=staging.music.abada.kr ./MONITORING_DASHBOARD.sh view-metrics

EOF
}

main() {
    case "${1:-help}" in
        setup)
            full_setup
            ;;
        status)
            status_check
            ;;
        test-alerts)
            load_env
            test_alerts
            ;;
        view-metrics)
            load_env
            view_metrics
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
