# ABADA Music Studio - Backup Strategy

**Version**: 1.0.0
**Updated**: 2026-01-19
**Status**: Active

---

## Overview

This document defines the backup and disaster recovery strategy for ABADA Music Studio.

### Backup Scope

| Data Type | Storage | Backup Required |
|-----------|---------|-----------------|
| Website Static Files | Cloudflare Pages | GitHub (source) |
| Worker Code | Cloudflare Workers | GitHub (source) |
| Download Statistics | KV Store (STATS) | Yes |
| Gallery Data | KV Store (GALLERY) | Yes |
| Analytics Events | KV Store (ANALYTICS) | Optional |

---

## Backup Procedures

### KV Store Backup

#### Automated Backup Script

```bash
#!/bin/bash
# KV Store backup script

BACKUP_DIR="./backups/$(date +%Y-%m-%d)"
mkdir -p "$BACKUP_DIR"

# Get namespace IDs from wrangler.toml or environment
STATS_ID="${STATS_KV_ID:-}"
GALLERY_ID="${GALLERY_KV_ID:-}"
ANALYTICS_ID="${ANALYTICS_KV_ID:-}"

# Backup STATS
echo "Backing up STATS namespace..."
wrangler kv:key list --namespace-id="$STATS_ID" > "$BACKUP_DIR/stats_keys.json"
for key in $(jq -r '.[].name' "$BACKUP_DIR/stats_keys.json"); do
    value=$(wrangler kv:key get --namespace-id="$STATS_ID" "$key")
    echo "{\"key\": \"$key\", \"value\": $value}" >> "$BACKUP_DIR/stats_data.jsonl"
done

# Backup GALLERY
echo "Backing up GALLERY namespace..."
wrangler kv:key list --namespace-id="$GALLERY_ID" > "$BACKUP_DIR/gallery_keys.json"
for key in $(jq -r '.[].name' "$BACKUP_DIR/gallery_keys.json"); do
    value=$(wrangler kv:key get --namespace-id="$GALLERY_ID" "$key")
    echo "{\"key\": \"$key\", \"value\": $value}" >> "$BACKUP_DIR/gallery_data.jsonl"
done

# Create backup archive
tar -czvf "backup_$(date +%Y-%m-%d).tar.gz" "$BACKUP_DIR"

echo "Backup completed: backup_$(date +%Y-%m-%d).tar.gz"
```

### Backup Frequency

| Data Type | Frequency | Retention |
|-----------|-----------|-----------|
| STATS | Daily | 90 days |
| GALLERY | Daily | 365 days |
| ANALYTICS | Weekly | 30 days |
| Source Code | On every push | Indefinite |

---

## Disaster Recovery

### Recovery Time Objectives (RTO)

| Scenario | RTO | Priority |
|----------|-----|----------|
| Complete site failure | < 1 hour | P1 |
| KV Store corruption | < 4 hours | P2 |
| Partial data loss | < 24 hours | P3 |

### Recovery Point Objectives (RPO)

| Data Type | RPO | Notes |
|-----------|-----|-------|
| STATS | 24 hours | Daily backup acceptable |
| GALLERY | 24 hours | User submissions |
| ANALYTICS | 7 days | Non-critical data |

### Recovery Procedures

#### Full Site Recovery

1. Verify GitHub repository integrity
2. Redeploy Cloudflare Pages: `wrangler pages deploy web/dist`
3. Redeploy Workers: `wrangler deploy`
4. Restore KV data from backup
5. Verify all endpoints

#### KV Store Recovery

```bash
# Restore KV data
#!/bin/bash

BACKUP_FILE="$1"
NAMESPACE_ID="$2"

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

while IFS= read -r line; do
    key=$(echo "$line" | jq -r '.key')
    value=$(echo "$line" | jq -r '.value')
    wrangler kv:key put --namespace-id="$NAMESPACE_ID" "$key" "$value"
    echo "Restored: $key"
done < "$BACKUP_FILE"

echo "Restore completed"
```

---

## Data Retention Policy

| Data Type | Active Retention | Archive Retention | Deletion |
|-----------|------------------|-------------------|----------|
| Download Stats | 1 year | 5 years | After archive |
| Gallery Items | Indefinite | N/A | On request |
| Analytics | 30 days | 90 days | Automatic |
| Backups | 90 days | 1 year | Automatic |

---

## Verification

### Backup Verification

- Weekly: Verify backup file integrity
- Monthly: Test restore to staging
- Quarterly: Full disaster recovery drill

### Verification Script

```bash
#!/bin/bash
# Verify backup integrity

BACKUP_FILE="$1"

if tar -tzf "$BACKUP_FILE" > /dev/null 2>&1; then
    echo "Backup integrity: OK"

    # Count records
    STATS_COUNT=$(tar -xzf "$BACKUP_FILE" -O | grep -c "stats_data" || echo 0)
    GALLERY_COUNT=$(tar -xzf "$BACKUP_FILE" -O | grep -c "gallery_data" || echo 0)

    echo "STATS records: $STATS_COUNT"
    echo "GALLERY records: $GALLERY_COUNT"
else
    echo "Backup integrity: FAILED"
    exit 1
fi
```

---

## Emergency Contacts

| Role | Contact |
|------|---------|
| Backup Owner | devops@abada.kr |
| Recovery Lead | oncall@abada.kr |

---

**Document Owner**: DevOps Team
**Last Review**: 2026-01-19
