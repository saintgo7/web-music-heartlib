# ABADA Music Studio - Cloudflare Rules Configuration

**Version**: 1.0.0
**Updated**: 2026-01-19
**Status**: Active

---

## Overview

This document defines all Cloudflare rules for ABADA Music Studio including firewall rules, transform rules, cache rules, and page rules.

---

## Firewall Rules

### Rule 1: Block Bad Bots

**Name**: Block Known Bad Bots
**Expression**:
```
(http.user_agent contains "SemrushBot") or
(http.user_agent contains "AhrefsBot") or
(http.user_agent contains "MJ12bot") or
(http.user_agent contains "DotBot") or
(http.user_agent contains "BLEXBot")
```
**Action**: Block
**Priority**: 1

### Rule 2: Block Suspicious Bot Score

**Name**: Block Low Bot Score
**Expression**:
```
(cf.bot_management.score lt 20) and
(not cf.bot_management.verified_bot)
```
**Action**: Block
**Priority**: 2

### Rule 3: Challenge Suspicious Requests

**Name**: Challenge Suspicious Traffic
**Expression**:
```
(cf.bot_management.score ge 20 and cf.bot_management.score lt 50) and
(not cf.bot_management.verified_bot) and
(not http.request.uri.path eq "/api/health")
```
**Action**: Managed Challenge
**Priority**: 3

### Rule 4: Block Direct IP Access

**Name**: Block Direct IP Access
**Expression**:
```
(http.host ne "music.abada.kr") and
(http.host ne "abada-music.pages.dev")
```
**Action**: Block
**Priority**: 4

### Rule 5: Block Countries (Optional)

**Name**: Geo-Block High Risk Countries
**Expression**:
```
(ip.geoip.country in {"XX" "YY"})
```
**Action**: Block
**Priority**: 5
**Note**: Enable only if needed

---

## Transform Rules

### Rule 1: Security Headers

**Name**: Add Security Headers
**When**: All requests
**Expression**: `(true)`
**Action**: Rewrite > Set static response headers

| Header | Value |
|--------|-------|
| X-Content-Type-Options | nosniff |
| X-Frame-Options | DENY |
| X-XSS-Protection | 1; mode=block |
| Referrer-Policy | strict-origin-when-cross-origin |
| Permissions-Policy | geolocation=(), microphone=(), camera=() |

### Rule 2: Remove Sensitive Headers

**Name**: Remove Server Info Headers
**When**: All responses
**Expression**: `(true)`
**Action**: Remove response headers

| Header to Remove |
|-----------------|
| Server |
| X-Powered-By |

---

## Cache Rules

### Rule 1: Cache Static Assets

**Name**: Cache Static Assets
**Expression**:
```
(http.request.uri.path matches "\.(js|css|png|jpg|jpeg|gif|ico|woff|woff2)$")
```
**Action**:
- Cache eligibility: Eligible
- Edge TTL: 1 year
- Browser TTL: 1 week

### Rule 2: Cache API Stats

**Name**: Cache Stats Endpoint
**Expression**:
```
(http.request.uri.path eq "/api/stats")
```
**Action**:
- Cache eligibility: Eligible
- Edge TTL: 5 minutes
- Browser TTL: 1 minute

### Rule 3: Cache Gallery

**Name**: Cache Gallery Endpoint
**Expression**:
```
(http.request.uri.path eq "/api/gallery") and
(http.request.method eq "GET")
```
**Action**:
- Cache eligibility: Eligible
- Edge TTL: 1 hour
- Browser TTL: 5 minutes

### Rule 4: No Cache for Dynamic

**Name**: Bypass Cache for POST/Admin
**Expression**:
```
(http.request.method ne "GET") or
(http.request.uri.path contains "/admin")
```
**Action**:
- Cache eligibility: Bypass

---

## Page Rules

### Rule 1: Force HTTPS

**URL**: `*music.abada.kr/*`
**Settings**:
- Always Use HTTPS: On

### Rule 2: Forwarding Rule

**URL**: `www.music.abada.kr/*`
**Settings**:
- Forwarding URL: 301 to `https://music.abada.kr/$1`

---

## Rate Limiting Rules

### Rule 1: API Rate Limit

**Name**: API General Rate Limit
**Expression**:
```
(http.request.uri.path matches "^/api/")
```
**Characteristics**: IP
**Rate**: 100 requests per minute
**Action**: Block for 60 seconds

### Rule 2: Download Rate Limit

**Name**: Download Rate Limit
**Expression**:
```
(http.request.uri.path eq "/api/download")
```
**Characteristics**: IP
**Rate**: 10 requests per minute
**Action**: Block for 300 seconds

---

## WAF Managed Rules

### Cloudflare Managed Ruleset

- **Status**: Enabled
- **Action**: Default (varies by rule)
- **Exceptions**: None

### OWASP Core Ruleset

- **Status**: Enabled
- **Sensitivity**: Medium
- **Action**: Default

---

## Version Control

Rules are managed via:
1. Cloudflare Dashboard (primary)
2. Terraform configuration (optional)
3. This documentation (reference)

### Change Process

1. Document proposed change
2. Review with security team
3. Implement in staging (if applicable)
4. Deploy to production
5. Monitor for impact
6. Update documentation

---

## Monitoring

Monitor these metrics for rules:
- Firewall events by rule
- Rate limit triggers
- Cache hit ratio
- Challenge solve rate

---

**Document Owner**: Security Team
**Last Review**: 2026-01-19
