# ABADA Music Studio - Production Deployment Guide

**Version**: 1.0.0
**Updated**: 2026-01-19
**Status**: Production Ready

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Pre-Deployment Checklist](#pre-deployment-checklist)
4. [Deployment Steps](#deployment-steps)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Monitoring Setup](#monitoring-setup)
7. [Incident Response](#incident-response)
8. [Rollback Procedures](#rollback-procedures)
9. [Maintenance Windows](#maintenance-windows)

---

## Overview

This document provides comprehensive instructions for deploying ABADA Music Studio to production environment on Cloudflare infrastructure.

### Architecture

```
                    +------------------+
                    |   Cloudflare     |
                    |   DNS + CDN      |
                    +--------+---------+
                             |
              +--------------+--------------+
              |                             |
    +---------v---------+         +---------v---------+
    |  Cloudflare Pages |         | Cloudflare Workers|
    |   (Static Web)    |         |    (API Server)   |
    +-------------------+         +---------+---------+
                                            |
                          +-----------------+-----------------+
                          |                 |                 |
                +---------v----+  +---------v----+  +---------v----+
                |   KV Store   |  |   KV Store   |  |   KV Store   |
                |    (STATS)   |  |   (GALLERY)  |  |  (ANALYTICS) |
                +--------------+  +--------------+  +--------------+
```

### Environments

| Environment | Domain | Purpose |
|-------------|--------|---------|
| Production | music.abada.kr | Live user traffic |
| Staging | staging.music.abada.kr | Pre-release testing |
| Development | localhost:5173 / localhost:8787 | Local development |

---

## Prerequisites

### Required Accounts

- [x] Cloudflare Account (Free or paid plan)
- [x] GitHub Account with repository access
- [x] Domain registration (abada.kr)

### Required Tools

```bash
# Node.js 20+
node --version  # v20.x.x

# npm 10+
npm --version   # 10.x.x

# Wrangler CLI (Cloudflare Workers)
npm install -g wrangler@latest
wrangler --version  # 3.x.x

# GitHub CLI (optional but recommended)
gh --version  # 2.x.x
```

### Required Secrets

| Secret | Location | Purpose |
|--------|----------|---------|
| CLOUDFLARE_API_TOKEN | GitHub Secrets | API authentication |
| CLOUDFLARE_ACCOUNT_ID | GitHub Secrets | Account identifier |
| ADMIN_API_KEY | Wrangler Secrets | Gallery admin access |
| SLACK_WEBHOOK_URL | GitHub Secrets | Alert notifications (optional) |

---

## Pre-Deployment Checklist

### DNS Configuration

- [ ] CNAME record for `music` pointing to `abada-music.pages.dev`
- [ ] CNAME record for `staging.music` pointing to `abada-music-staging.pages.dev` (optional)
- [ ] DNS propagation verified (use `dig music.abada.kr`)
- [ ] TTL set appropriately (300-3600 seconds)

### SSL/TLS Configuration

- [ ] Cloudflare SSL mode set to "Full (strict)"
- [ ] Always Use HTTPS enabled
- [ ] HSTS enabled with appropriate max-age
- [ ] Minimum TLS Version set to 1.2

### Security Headers

- [ ] Content-Security-Policy configured
- [ ] X-Content-Type-Options: nosniff
- [ ] X-Frame-Options: DENY
- [ ] Referrer-Policy: strict-origin-when-cross-origin
- [ ] Permissions-Policy configured

### Rate Limiting

- [ ] Rate limiting rules created in Cloudflare
- [ ] API rate limits configured (100 requests/minute)
- [ ] DDoS protection enabled (automatic)

### Code Quality

- [ ] All tests passing
- [ ] No TypeScript errors
- [ ] ESLint warnings resolved
- [ ] Build succeeds locally
- [ ] Security audit passed (`npm audit`)

### KV Namespaces

- [ ] STATS namespace created and ID configured
- [ ] GALLERY namespace created and ID configured
- [ ] ANALYTICS namespace created and ID configured
- [ ] Preview namespaces created for development

---

## Deployment Steps

### Step 1: Prepare Environment

```bash
# Clone repository
git clone https://github.com/saintgo7/web-music-heartlib.git
cd web-music-heartlib

# Verify branch
git checkout main
git pull origin main

# Install dependencies
cd web && npm ci && cd ..
```

### Step 2: Build Website

```bash
cd web

# Set environment variables
export NODE_ENV=production
export VITE_APP_VERSION=$(cat package.json | grep version | cut -d'"' -f4)
export VITE_API_URL=https://music.abada.kr/api

# Build
npm run build

# Verify build output
ls -la dist/
du -sh dist/
```

### Step 3: Deploy to Cloudflare Pages

```bash
# Login to Cloudflare
wrangler login

# Deploy Pages
wrangler pages deploy dist \
  --project-name=abada-music \
  --branch=main \
  --commit-dirty=true

# Note the deployment URL
```

### Step 4: Deploy Cloudflare Workers

```bash
# Return to project root
cd ..

# Verify wrangler.toml configuration
cat wrangler.toml | head -30

# Deploy Workers
wrangler deploy

# Deploy to specific environment (optional)
wrangler deploy --env production
```

### Step 5: Configure Secrets

```bash
# Set admin API key
wrangler secret put ADMIN_API_KEY

# Verify secrets
wrangler secret list
```

### Step 6: Verify Deployment

```bash
# Check Pages deployment
curl -I https://music.abada.kr

# Check API health
curl https://music.abada.kr/api/health

# Check specific endpoints
curl https://music.abada.kr/api/stats
curl https://music.abada.kr/api/gallery
```

---

## Post-Deployment Verification

### Automated Health Checks

The deployment workflow automatically runs health checks after deployment:

1. **Website Accessibility**: HTTP 200 from main domain
2. **API Health**: `/api/health` returns `{"status":"ok"}`
3. **Critical Pages**: All 6 pages return HTTP 200

### Manual Verification Checklist

```bash
# 1. Homepage loads
curl -s -o /dev/null -w "%{http_code}" https://music.abada.kr

# 2. API health
curl -s https://music.abada.kr/api/health | jq .

# 3. Download stats
curl -s https://music.abada.kr/api/stats | jq .

# 4. Gallery data
curl -s https://music.abada.kr/api/gallery | jq .

# 5. All pages accessible
for page in "" download gallery tutorial faq about; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://music.abada.kr/${page}")
  echo "/${page}: ${STATUS}"
done
```

### Performance Verification

```bash
# Lighthouse audit (requires Chrome)
npx lighthouse https://music.abada.kr \
  --output=json \
  --output-path=./lighthouse-report.json

# Core Web Vitals
# Use Chrome DevTools > Performance tab
# Or use web.dev/measure
```

### Expected Metrics

| Metric | Target | Critical |
|--------|--------|----------|
| Uptime | 99.9%+ | 99.0% |
| Response Time (p95) | < 1s | < 2s |
| Error Rate | < 0.1% | < 1% |
| Lighthouse Score | > 90 | > 70 |
| LCP | < 2.5s | < 4s |
| FID | < 100ms | < 300ms |
| CLS | < 0.1 | < 0.25 |

---

## Monitoring Setup

### Cloudflare Analytics

1. Navigate to Cloudflare Dashboard > Analytics
2. Enable Web Analytics for the zone
3. Configure custom event tracking

### Real User Monitoring (RUM)

The website includes built-in analytics tracking:

```javascript
// Automatically tracked events
- Page views
- Download button clicks
- Gallery interactions
- Error occurrences
```

### Alert Configuration

Configure alerts in Cloudflare Dashboard:

1. **High Error Rate**: > 1% 5xx errors in 5 minutes
2. **Slow Response**: p95 > 2s for 5 minutes
3. **Traffic Anomaly**: > 3x normal traffic
4. **Security Event**: Any WAF blocks

### External Monitoring (Recommended)

- **Uptime**: UptimeRobot or Pingdom
- **Performance**: SpeedCurve or Calibre
- **Error Tracking**: Sentry or Bugsnag

---

## Incident Response

### Severity Levels

| Level | Definition | Response Time | Examples |
|-------|------------|---------------|----------|
| P1 | Critical | < 15 min | Site down, data loss |
| P2 | High | < 1 hour | Major feature broken |
| P3 | Medium | < 4 hours | Minor feature broken |
| P4 | Low | < 24 hours | Cosmetic issues |

### Response Procedure

1. **Detect**: Alert received or user report
2. **Assess**: Determine severity and impact
3. **Communicate**: Notify stakeholders
4. **Investigate**: Identify root cause
5. **Mitigate**: Apply fix or rollback
6. **Resolve**: Verify fix and close incident
7. **Review**: Post-mortem for P1/P2 incidents

### Escalation Path

```
Developer On-Call
       |
       v
  Tech Lead
       |
       v
Engineering Manager
       |
       v
  CTO / VP Engineering
```

---

## Rollback Procedures

### Quick Rollback (< 5 minutes)

```bash
# Rollback Workers to previous version
wrangler rollback

# Verify rollback
wrangler deployments list
```

### Full Rollback

```bash
# 1. Get previous deployment info
wrangler deployments list

# 2. Rollback Workers
wrangler rollback --version <version-id>

# 3. Rollback Pages (via Cloudflare Dashboard)
# Navigate to Pages > Deployments > Select previous deployment > Rollback

# 4. Verify rollback
curl https://music.abada.kr/api/health
```

### Database Rollback (KV Store)

```bash
# Export current data (backup)
./scripts/kv-backup.sh export

# Restore from backup
./scripts/kv-backup.sh restore <backup-date>
```

### Emergency Procedures

If complete outage:

1. **Enable maintenance mode**: Deploy maintenance page
2. **Investigate**: Check Cloudflare Dashboard for errors
3. **Communicate**: Update status page
4. **Fix**: Apply fix or rollback
5. **Verify**: Test thoroughly before going live
6. **Communicate**: Update status page

---

## Maintenance Windows

### Scheduled Maintenance

- **Preferred Window**: Sunday 02:00-06:00 KST
- **Notification**: 48 hours in advance
- **Duration**: Maximum 2 hours

### Maintenance Procedure

1. **Before**:
   - Send notification email
   - Update status page
   - Prepare rollback plan

2. **During**:
   - Enable maintenance mode
   - Perform updates
   - Test changes
   - Disable maintenance mode

3. **After**:
   - Monitor for issues
   - Update status page
   - Send completion notification

### Emergency Maintenance

- No advance notice required
- Update status page immediately
- Follow incident response procedure

---

## Appendix

### Useful Commands

```bash
# View real-time logs
wrangler tail

# Check deployment status
wrangler deployments list

# View KV data
wrangler kv:key list --namespace-id=<id>

# Test API locally
wrangler dev
```

### Contact Information

| Role | Contact |
|------|---------|
| DevOps Lead | devops@abada.kr |
| Engineering Lead | engineering@abada.kr |
| On-Call | oncall@abada.kr |
| Status Page | status.abada.kr |

### Related Documents

- [PRODUCTION_CHECKLIST.md](./PRODUCTION_CHECKLIST.md)
- [INCIDENT_RESPONSE.md](./INCIDENT_RESPONSE.md)
- [SECURITY_HARDENING.md](./SECURITY_HARDENING.md)
- [MONITORING_DASHBOARD.md](./MONITORING_DASHBOARD.md)
- [BACKUP_STRATEGY.md](./BACKUP_STRATEGY.md)

---

**Document Owner**: DevOps Team
**Last Review**: 2026-01-19
**Next Review**: 2026-04-19
