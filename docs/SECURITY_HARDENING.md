# ABADA Music Studio - Security Hardening Guide

**Version**: 1.0.0
**Updated**: 2026-01-19
**Status**: Active

---

## Table of Contents

1. [Overview](#overview)
2. [Security Headers](#security-headers)
3. [CORS Configuration](#cors-configuration)
4. [Content Security Policy](#content-security-policy)
5. [Rate Limiting](#rate-limiting)
6. [Bot Detection](#bot-detection)
7. [DDoS Mitigation](#ddos-mitigation)
8. [Input Validation](#input-validation)
9. [Output Encoding](#output-encoding)
10. [KV Store Security](#kv-store-security)
11. [Secrets Management](#secrets-management)
12. [Security Monitoring](#security-monitoring)

---

## Overview

This document outlines security configurations and best practices for ABADA Music Studio production environment.

### Security Objectives

1. **Confidentiality**: Protect user data and system secrets
2. **Integrity**: Prevent unauthorized modifications
3. **Availability**: Ensure service resilience against attacks
4. **Compliance**: Meet industry security standards

### Threat Model

| Threat | Likelihood | Impact | Mitigation |
|--------|------------|--------|------------|
| DDoS Attack | High | High | Cloudflare DDoS protection |
| XSS Attack | Medium | High | CSP, output encoding |
| CSRF Attack | Low | Medium | SameSite cookies, CORS |
| Injection Attack | Medium | High | Input validation |
| Data Breach | Low | Critical | Encryption, access control |
| Bot Abuse | High | Medium | Rate limiting, bot detection |

---

## Security Headers

### Required Headers

Configure these headers via Cloudflare Transform Rules or Workers:

```javascript
// Security headers configuration
const securityHeaders = {
  // Prevent MIME type sniffing
  'X-Content-Type-Options': 'nosniff',

  // Clickjacking protection
  'X-Frame-Options': 'DENY',

  // XSS protection (legacy browsers)
  'X-XSS-Protection': '1; mode=block',

  // Referrer policy
  'Referrer-Policy': 'strict-origin-when-cross-origin',

  // HSTS (handled by Cloudflare SSL settings)
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',

  // Permissions policy
  'Permissions-Policy': 'geolocation=(), microphone=(), camera=(), payment=()',

  // Cross-origin isolation
  'Cross-Origin-Embedder-Policy': 'require-corp',
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Cross-Origin-Resource-Policy': 'same-origin',
};
```

### Cloudflare Transform Rule

Create a Transform Rule in Cloudflare Dashboard:

**Rule Name**: Security Headers
**When**: (http.host eq "music.abada.kr")
**Then**: Set static response headers

```
Set:
  X-Content-Type-Options = nosniff
  X-Frame-Options = DENY
  X-XSS-Protection = 1; mode=block
  Referrer-Policy = strict-origin-when-cross-origin
  Permissions-Policy = geolocation=(), microphone=(), camera=()
```

### Header Verification

```bash
# Check security headers
curl -I https://music.abada.kr

# Detailed analysis
curl -s -D - https://music.abada.kr -o /dev/null | grep -E "^(X-|Strict|Referrer|Permissions|Content-Security)"

# Use securityheaders.com for full analysis
# https://securityheaders.com/?q=music.abada.kr
```

---

## CORS Configuration

### Production CORS Policy

```javascript
// Allowed origins
const ALLOWED_ORIGINS = [
  'https://music.abada.kr',
  'https://abada-music.pages.dev',
];

// CORS headers
function getCorsHeaders(request) {
  const origin = request.headers.get('Origin');

  if (ALLOWED_ORIGINS.includes(origin)) {
    return {
      'Access-Control-Allow-Origin': origin,
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400',
      'Access-Control-Allow-Credentials': 'false',
    };
  }

  return {
    'Access-Control-Allow-Origin': 'https://music.abada.kr',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Max-Age': '86400',
  };
}

// Preflight handler
function handlePreflight(request) {
  return new Response(null, {
    status: 204,
    headers: getCorsHeaders(request),
  });
}
```

### CORS by Endpoint

| Endpoint | Methods | Origins | Credentials |
|----------|---------|---------|-------------|
| /api/health | GET | * | No |
| /api/stats | GET | music.abada.kr | No |
| /api/gallery | GET, POST | music.abada.kr | No |
| /api/analytics | POST | music.abada.kr | No |
| /api/download | GET, POST | music.abada.kr | No |

### Testing CORS

```bash
# Test preflight request
curl -X OPTIONS https://music.abada.kr/api/stats \
  -H "Origin: https://music.abada.kr" \
  -H "Access-Control-Request-Method: GET" \
  -I

# Test actual request with origin
curl https://music.abada.kr/api/stats \
  -H "Origin: https://music.abada.kr" \
  -I
```

---

## Content Security Policy

### CSP Configuration

```javascript
// Content Security Policy
const CSP_POLICY = [
  // Default: only allow same origin
  "default-src 'self'",

  // Scripts: self and inline for React
  "script-src 'self' 'unsafe-inline'",

  // Styles: self and inline for Tailwind
  "style-src 'self' 'unsafe-inline'",

  // Images: self, data URIs, and HTTPS
  "img-src 'self' data: https:",

  // Fonts: self and data URIs
  "font-src 'self' data:",

  // Connections: self and API
  "connect-src 'self' https://music.abada.kr https://api.github.com",

  // Media: self for audio samples
  "media-src 'self' blob:",

  // Objects: none
  "object-src 'none'",

  // Frames: none
  "frame-ancestors 'none'",

  // Form actions: self only
  "form-action 'self'",

  // Base URI: self only
  "base-uri 'self'",

  // Upgrade insecure requests
  "upgrade-insecure-requests",
].join('; ');
```

### CSP Header

Add to security headers:

```javascript
'Content-Security-Policy': CSP_POLICY
```

### CSP Report-Only (Testing)

For testing before enforcement:

```javascript
'Content-Security-Policy-Report-Only': CSP_POLICY + "; report-uri /api/csp-report"
```

### CSP Violation Handler

```javascript
// CSP violation report endpoint
app.post('/api/csp-report', async (request, env) => {
  const report = await request.json();

  // Log violation
  console.warn('CSP Violation:', JSON.stringify(report));

  // Store for analysis
  const key = `csp-violation:${Date.now()}`;
  await env.ANALYTICS.put(key, JSON.stringify(report), {
    expirationTtl: 60 * 60 * 24 * 7, // 7 days
  });

  return new Response(null, { status: 204 });
});
```

---

## Rate Limiting

### Rate Limit Configuration

```javascript
// Rate limiting configuration
const RATE_LIMITS = {
  // General API calls
  api: {
    requests: 100,
    window: 60, // 100 requests per minute
  },
  // Download endpoint
  download: {
    requests: 10,
    window: 60, // 10 downloads per minute
  },
  // Gallery submission
  gallery: {
    requests: 5,
    window: 300, // 5 submissions per 5 minutes
  },
  // Analytics events
  analytics: {
    requests: 60,
    window: 60, // 60 events per minute
  },
  // Health check (higher limit)
  health: {
    requests: 300,
    window: 60, // 300 checks per minute
  },
};
```

### Rate Limiter Implementation

```javascript
// Simple rate limiter using KV Store
async function checkRateLimit(env, key, limit, window) {
  const now = Math.floor(Date.now() / 1000);
  const windowKey = `ratelimit:${key}:${Math.floor(now / window)}`;

  const current = parseInt(await env.STATS.get(windowKey) || '0');

  if (current >= limit) {
    return {
      allowed: false,
      remaining: 0,
      reset: (Math.floor(now / window) + 1) * window,
    };
  }

  await env.STATS.put(windowKey, (current + 1).toString(), {
    expirationTtl: window * 2,
  });

  return {
    allowed: true,
    remaining: limit - current - 1,
    reset: (Math.floor(now / window) + 1) * window,
  };
}

// Rate limit middleware
async function rateLimitMiddleware(request, env, endpoint) {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const config = RATE_LIMITS[endpoint] || RATE_LIMITS.api;

  const result = await checkRateLimit(env, `${endpoint}:${ip}`, config.requests, config.window);

  if (!result.allowed) {
    return new Response(JSON.stringify({
      error: 'Too Many Requests',
      retryAfter: result.reset - Math.floor(Date.now() / 1000),
    }), {
      status: 429,
      headers: {
        'Content-Type': 'application/json',
        'Retry-After': (result.reset - Math.floor(Date.now() / 1000)).toString(),
        'X-RateLimit-Limit': config.requests.toString(),
        'X-RateLimit-Remaining': '0',
        'X-RateLimit-Reset': result.reset.toString(),
      },
    });
  }

  return null; // Continue processing
}
```

### Cloudflare Rate Limiting Rule

Create in Cloudflare Dashboard > Security > WAF > Rate limiting rules:

**Rule 1: API Rate Limit**
- Expression: `(http.request.uri.path matches "^/api/")`
- Rate: 100 requests per minute
- Action: Block for 1 minute
- Response: Custom JSON

**Rule 2: Download Rate Limit**
- Expression: `(http.request.uri.path eq "/api/download")`
- Rate: 10 requests per minute
- Action: Block for 5 minutes

---

## Bot Detection

### Bot Management Configuration

```javascript
// Bot detection
function detectBot(request) {
  const userAgent = request.headers.get('User-Agent') || '';
  const cfBot = request.headers.get('CF-Bot-Score');

  // Known good bots (allow)
  const goodBots = [
    'Googlebot',
    'Bingbot',
    'DuckDuckBot',
    'Slackbot',
    'Twitterbot',
  ];

  // Known bad bots (block)
  const badBots = [
    'SemrushBot',
    'AhrefsBot',
    'MJ12bot',
    'DotBot',
    'BLEXBot',
  ];

  // Check Cloudflare bot score
  if (cfBot && parseInt(cfBot) < 30) {
    return { isBot: true, type: 'suspicious', score: cfBot };
  }

  // Check known good bots
  for (const bot of goodBots) {
    if (userAgent.includes(bot)) {
      return { isBot: true, type: 'good', name: bot };
    }
  }

  // Check known bad bots
  for (const bot of badBots) {
    if (userAgent.includes(bot)) {
      return { isBot: true, type: 'bad', name: bot };
    }
  }

  return { isBot: false };
}
```

### Cloudflare Bot Fight Mode

Enable in Cloudflare Dashboard:
1. Navigate to Security > Bots
2. Enable "Bot Fight Mode"
3. Configure "Super Bot Fight Mode" if available

### Bot Blocking Rules

**Firewall Rule 1: Block Bad Bots**
```
(cf.bot_management.score lt 30) and
(not cf.bot_management.verified_bot)
```
Action: Block

**Firewall Rule 2: Challenge Suspicious**
```
(cf.bot_management.score ge 30 and cf.bot_management.score lt 50)
```
Action: Managed Challenge

---

## DDoS Mitigation

### Cloudflare DDoS Settings

1. **L7 DDoS Protection**: Automatic (always on)
2. **L3/L4 DDoS Protection**: Automatic (always on)
3. **Advanced DDoS**: Enable if available

### Under Attack Mode

When to enable:
- Traffic spike > 10x normal
- High error rates from attacks
- Confirmed DDoS attack

```bash
# Enable Under Attack Mode via API
curl -X PATCH "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/settings/security_level" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"value":"under_attack"}'
```

### Emergency Response

```bash
# 1. Enable Under Attack Mode
# 2. Increase security level
# 3. Block suspicious countries (if applicable)
# 4. Enable additional rate limiting
# 5. Contact Cloudflare support if persistent
```

---

## Input Validation

### Validation Rules

```javascript
// Input validation helpers
const validators = {
  // OS parameter
  os: (value) => {
    const valid = ['windows-x64', 'windows-x86', 'macos', 'linux'];
    return valid.includes(value);
  },

  // Event name
  eventName: (value) => {
    return typeof value === 'string' &&
           value.length <= 50 &&
           /^[a-z_]+$/.test(value);
  },

  // Gallery title
  galleryTitle: (value) => {
    return typeof value === 'string' &&
           value.length >= 1 &&
           value.length <= 100;
  },

  // URL
  url: (value) => {
    try {
      new URL(value);
      return true;
    } catch {
      return false;
    }
  },

  // Integer ID
  id: (value) => {
    return Number.isInteger(Number(value)) && Number(value) > 0;
  },
};

// Validate request body
function validateBody(body, schema) {
  const errors = [];

  for (const [field, rules] of Object.entries(schema)) {
    const value = body[field];

    if (rules.required && (value === undefined || value === null)) {
      errors.push(`${field} is required`);
      continue;
    }

    if (value !== undefined && rules.validator && !rules.validator(value)) {
      errors.push(`${field} is invalid`);
    }
  }

  return errors;
}
```

### Sanitization

```javascript
// HTML sanitization
function sanitizeHtml(input) {
  return input
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;');
}

// SQL-safe string (for logging)
function sanitizeForLog(input) {
  return input
    .replace(/[\x00-\x1F\x7F]/g, '')
    .substring(0, 1000);
}

// JSON sanitization
function sanitizeJson(obj) {
  return JSON.parse(JSON.stringify(obj));
}
```

---

## Output Encoding

### Response Encoding

```javascript
// JSON response with proper encoding
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'X-Content-Type-Options': 'nosniff',
    },
  });
}

// HTML response with encoding
function htmlResponse(html, status = 200) {
  return new Response(html, {
    status,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'X-Content-Type-Options': 'nosniff',
    },
  });
}
```

---

## KV Store Security

### Access Control

```javascript
// KV access patterns
const KV_ACCESS = {
  STATS: {
    read: ['public'],
    write: ['api'],
  },
  GALLERY: {
    read: ['public'],
    write: ['admin'],
  },
  ANALYTICS: {
    read: ['admin'],
    write: ['api'],
  },
};

// Admin authentication
function requireAdmin(request, env) {
  const authHeader = request.headers.get('Authorization');

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('Unauthorized');
  }

  const token = authHeader.substring(7);

  if (token !== env.ADMIN_API_KEY) {
    throw new Error('Forbidden');
  }
}
```

### Data Encryption

For sensitive data (if needed):

```javascript
// Encrypt data before storing
async function encryptData(data, key) {
  const encoder = new TextEncoder();
  const iv = crypto.getRandomValues(new Uint8Array(12));

  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    encoder.encode(key),
    { name: 'AES-GCM' },
    false,
    ['encrypt']
  );

  const encrypted = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    cryptoKey,
    encoder.encode(JSON.stringify(data))
  );

  return btoa(String.fromCharCode(...iv, ...new Uint8Array(encrypted)));
}
```

---

## Secrets Management

### Secret Storage

**DO NOT** store secrets in:
- Source code
- wrangler.toml
- Environment variables in CI logs

**DO** store secrets in:
- Wrangler secrets (`wrangler secret put`)
- GitHub Secrets (for CI/CD)
- Environment-specific secret stores

### Setting Secrets

```bash
# Set admin API key
wrangler secret put ADMIN_API_KEY
# Enter secret when prompted

# Set for specific environment
wrangler secret put ADMIN_API_KEY --env production

# List secrets (names only)
wrangler secret list
```

### Secret Rotation

1. Generate new secret
2. Update in Wrangler secrets
3. Update in GitHub Secrets
4. Verify functionality
5. Delete old secret references
6. Document rotation date

**Rotation Schedule**:
- API Keys: Every 90 days
- Admin Keys: Every 30 days
- After any potential exposure: Immediately

---

## Security Monitoring

### Security Events to Monitor

| Event | Severity | Action |
|-------|----------|--------|
| Failed auth attempts > 10/min | High | Alert + block IP |
| Rate limit triggers > 100/min | Medium | Alert |
| CSP violations | Low | Log + review |
| Bot score < 10 | High | Auto-block |
| New admin access | Medium | Alert |
| Config changes | Low | Log |

### Security Logging

```javascript
// Security event logging
async function logSecurityEvent(env, event) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    type: event.type,
    severity: event.severity,
    ip: event.ip,
    userAgent: event.userAgent,
    path: event.path,
    details: event.details,
  };

  const key = `security:${Date.now()}:${event.type}`;
  await env.ANALYTICS.put(key, JSON.stringify(logEntry), {
    expirationTtl: 60 * 60 * 24 * 30, // 30 days
  });

  // Alert on high severity
  if (event.severity === 'high') {
    // Send to alerting system
    console.error('SECURITY ALERT:', JSON.stringify(logEntry));
  }
}
```

### Security Audit Checklist

**Weekly**:
- [ ] Review blocked IPs
- [ ] Check rate limit triggers
- [ ] Review CSP violations
- [ ] Check bot activity

**Monthly**:
- [ ] Review access patterns
- [ ] Rotate secrets if needed
- [ ] Update WAF rules
- [ ] Security scan

**Quarterly**:
- [ ] Full security audit
- [ ] Penetration testing
- [ ] Dependency audit
- [ ] Update security policies

---

## Security Contacts

| Role | Contact | Responsibility |
|------|---------|----------------|
| Security Lead | security@abada.kr | Overall security |
| DevOps | devops@abada.kr | Infrastructure security |
| On-Call | oncall@abada.kr | Incident response |

### Reporting Security Issues

Email: security@abada.kr
Include:
- Description of vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

---

**Document Owner**: Security Team
**Last Review**: 2026-01-19
**Next Review**: 2026-04-19
