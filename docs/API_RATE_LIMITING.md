# ABADA Music Studio - API Rate Limiting Configuration

**Version**: 1.0.0
**Updated**: 2026-01-19
**Status**: Active

---

## Overview

This document defines the rate limiting configuration for the ABADA Music Studio API.

---

## Rate Limits by Endpoint

| Endpoint | Method | Limit | Window | Burst |
|----------|--------|-------|--------|-------|
| /api/health | GET | 300/min | 60s | 10 |
| /api/stats | GET | 100/min | 60s | 20 |
| /api/gallery | GET | 100/min | 60s | 20 |
| /api/gallery | POST | 5/5min | 300s | 2 |
| /api/download | GET | 10/min | 60s | 5 |
| /api/download | POST | 10/min | 60s | 5 |
| /api/analytics | POST | 60/min | 60s | 10 |
| /api/* (default) | * | 100/min | 60s | 20 |

---

## Rate Limit Headers

All API responses include rate limit headers:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1705680000
Retry-After: 45  (only on 429 responses)
```

---

## Error Response

When rate limited, clients receive:

```json
{
  "error": "Too Many Requests",
  "message": "Rate limit exceeded. Please wait before retrying.",
  "retryAfter": 45,
  "limit": 100,
  "window": "60s"
}
```

HTTP Status: 429 Too Many Requests

---

## Client Best Practices

1. **Implement Exponential Backoff**: On 429, wait `Retry-After` seconds
2. **Cache Responses**: Stats and gallery data are cacheable
3. **Batch Requests**: Combine multiple analytics events
4. **Respect Headers**: Monitor `X-RateLimit-Remaining`

### Example: Exponential Backoff

```javascript
async function fetchWithRetry(url, options = {}, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    const response = await fetch(url, options);

    if (response.status !== 429) {
      return response;
    }

    const retryAfter = parseInt(response.headers.get('Retry-After') || '60');
    const backoff = Math.min(retryAfter * 1000, Math.pow(2, i) * 1000);

    await new Promise(resolve => setTimeout(resolve, backoff));
  }

  throw new Error('Max retries exceeded');
}
```

---

## Per-User Limits

Limits are applied per IP address by default.

### Authenticated Users

For future authenticated endpoints:
- Premium users: 2x limits
- Admin users: No limits

---

## Cloudflare Rules

### Rule 1: General API Rate Limit

```
Expression: (http.request.uri.path matches "^/api/")
Limit: 100 requests per minute
Action: Block for 60 seconds
```

### Rule 2: Download Endpoint

```
Expression: (http.request.uri.path eq "/api/download")
Limit: 10 requests per minute
Action: Block for 300 seconds
```

### Rule 3: Gallery POST

```
Expression: (http.request.uri.path eq "/api/gallery") and (http.request.method eq "POST")
Limit: 5 requests per 5 minutes
Action: Block for 600 seconds
```

---

## Monitoring

Track rate limit metrics:
- Total rate limited requests
- Rate limited requests by endpoint
- Rate limited requests by IP
- Average request rate by endpoint

---

**Document Owner**: Backend Team
**Last Review**: 2026-01-19
