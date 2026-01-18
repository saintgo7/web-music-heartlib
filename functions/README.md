# ABADA Music Studio - Cloudflare Workers API

This directory contains the Cloudflare Workers that power the ABADA Music Studio API.

## Overview

The API provides the following functionality:
- **Download Statistics**: Track and report installer downloads
- **Gallery**: Manage and serve sample music gallery
- **Analytics**: Record and retrieve website analytics

## API Endpoints

### Download Statistics

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/download` | POST | Record a download and redirect to file |
| `/api/download?os=<os>` | GET | Redirect to download file |
| `/api/stats` | GET | Get download statistics |

**OS Options**: `windows-x64`, `windows-x86`, `macos`, `linux`

**Example - Record Download**:
```bash
curl -X POST "https://music.abada.kr/api/download" \
  -H "Content-Type: application/json" \
  -d '{"os": "windows-x64"}'
```

**Example - Get Statistics**:
```bash
curl "https://music.abada.kr/api/stats?period=week"
```

### Gallery

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/gallery` | GET | Get gallery samples |
| `/api/gallery` | POST | Add gallery item (admin) |

**Query Parameters**:
- `limit`: Number of items (default: 20, max: 100)
- `offset`: Pagination offset (default: 0)
- `tag`: Filter by tag
- `featured`: Filter featured items (`true`/`false`)
- `sort`: Sort order (`newest`, `oldest`, `popular`)

**Example - Get Gallery**:
```bash
curl "https://music.abada.kr/api/gallery?limit=10&tag=pop"
```

### Analytics

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/analytics` | POST | Record analytics event |
| `/api/analytics` | GET | Get analytics data |

**Event Types**:
- `page_view`
- `download_click`
- `download_complete`
- `gallery_view`
- `gallery_play`
- `tutorial_view`
- `faq_view`
- `external_link`
- `share`
- `error`

**Example - Record Event**:
```bash
curl -X POST "https://music.abada.kr/api/analytics" \
  -H "Content-Type: application/json" \
  -d '{"event": "page_view", "page": "/download"}'
```

### Health Check

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/health` | GET | Health check |
| `/api` | GET | API documentation |

## Setup

### Prerequisites

1. Cloudflare account
2. Wrangler CLI installed (`npm install -g wrangler`)
3. KV namespaces created

### Environment Setup

1. **Create KV Namespaces**:
   ```bash
   wrangler kv:namespace create "STATS"
   wrangler kv:namespace create "GALLERY"
   ```

2. **Update wrangler.toml** with the KV namespace IDs from step 1.

3. **Set Secrets** (optional):
   ```bash
   wrangler secret put ADMIN_API_KEY
   ```

### Local Development

```bash
# Install dependencies
npm install

# Run development server
wrangler dev

# The API will be available at http://localhost:8787
```

### Deployment

```bash
# Deploy to production
wrangler deploy

# Deploy to staging
wrangler deploy --env staging
```

## KV Schema

### STATS Namespace

| Key Pattern | Value | Description |
|-------------|-------|-------------|
| `download:{os}:{date}` | count | Daily download count |
| `download:total:{os}` | count | Total download count |
| `analytics:event:{date}:{type}` | count | Event count |
| `analytics:pageview:{date}:{page}` | count | Page view count |
| `analytics:referrer:{date}:{source}` | count | Referrer count |
| `analytics:hourly:{date}:{hour}` | count | Hourly activity |
| `analytics:country:{date}:{country}` | count | Country stats |

### GALLERY Namespace

| Key Pattern | Value | Description |
|-------------|-------|-------------|
| `gallery:items` | JSON array | All gallery items |
| `gallery:item:{id}` | JSON object | Individual item |
| `gallery:count` | number | Total item count |

## Security

- CORS is enabled for all origins (`*`)
- Admin endpoints require Bearer token authentication
- Rate limiting is handled by Cloudflare

## Monitoring

View logs and analytics in the Cloudflare dashboard:
1. Go to Workers & Pages
2. Select `abada-music-api`
3. View Logs / Analytics

## Files

```
functions/
├── api/
│   ├── index.js          # Main entry point and router
│   ├── download-stats.js # Download statistics API
│   ├── gallery.js        # Gallery management API
│   └── analytics.js      # Analytics recording API
└── README.md             # This file
```

## License

CC BY-NC 4.0 - ABADA Inc.
