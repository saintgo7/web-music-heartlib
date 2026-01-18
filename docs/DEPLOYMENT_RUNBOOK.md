# ABADA Music Studio - Deployment Runbook

**Version**: 1.0.0
**Updated**: 2026-01-19
**Status**: Active

---

## Quick Reference

### Deployment Commands

```bash
# Full deployment (automated via GitHub Actions)
git push origin main

# Manual website deployment
wrangler pages deploy web/dist --project-name=abada-music

# Manual API deployment
wrangler deploy

# Rollback
wrangler rollback
```

---

## Step-by-Step Deployment Guide

### Step 1: Pre-Deployment Verification

```bash
# 1.1 Verify you're on main branch
git branch --show-current
# Expected: main

# 1.2 Pull latest changes
git pull origin main

# 1.3 Check for uncommitted changes
git status
# Expected: nothing to commit, working tree clean

# 1.4 Verify build locally
cd web && npm ci && npm run build
# Expected: Build successful, no errors

# 1.5 Run tests
npm test
# Expected: All tests passing
```

### Step 2: Deploy Website

#### Option A: Automated (Recommended)

```bash
# Push to main triggers GitHub Actions
git push origin main

# Monitor deployment
# Go to: https://github.com/saintgo7/web-music-heartlib/actions
```

#### Option B: Manual

```bash
# 2.1 Build website
cd web
npm ci
npm run build

# 2.2 Deploy to Cloudflare Pages
wrangler pages deploy dist --project-name=abada-music --branch=main

# Expected output:
# Uploading...
# Deployment complete!
# https://xxxxx.abada-music.pages.dev
```

### Step 3: Deploy API (Workers)

```bash
# 3.1 Return to project root
cd ..

# 3.2 Deploy Workers
wrangler deploy

# Expected output:
# Uploaded abada-music-api (x.xx sec)
# Published abada-music-api (x.xx sec)
#   https://abada-music-api.xxxxx.workers.dev
```

### Step 4: Post-Deployment Verification

```bash
# 4.1 Check website accessibility
curl -I https://music.abada.kr
# Expected: HTTP/2 200

# 4.2 Check API health
curl https://music.abada.kr/api/health
# Expected: {"status":"ok","timestamp":"..."}

# 4.3 Check all pages
for page in "" download gallery tutorial faq about; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://music.abada.kr/${page}")
  echo "/${page:-home}: HTTP ${STATUS}"
done
# Expected: All return HTTP 200

# 4.4 Check API endpoints
curl https://music.abada.kr/api/stats
curl https://music.abada.kr/api/gallery
# Expected: JSON responses with data
```

### Step 5: Monitor

```bash
# 5.1 View real-time logs
wrangler tail

# 5.2 Check Cloudflare Analytics
# Go to: https://dash.cloudflare.com > Analytics

# 5.3 Monitor error rates
# Check for any 5xx errors in the first 15 minutes
```

---

## Troubleshooting

### Issue: Build Fails

```bash
# Check for TypeScript errors
cd web && npx tsc --noEmit

# Check for missing dependencies
rm -rf node_modules package-lock.json
npm install

# Clear cache and rebuild
npm run clean && npm run build
```

### Issue: Pages Deployment Fails

```bash
# Check Cloudflare status
# https://www.cloudflarestatus.com/

# Verify API token permissions
wrangler whoami

# Check project exists
wrangler pages project list

# Try with verbose output
wrangler pages deploy dist --project-name=abada-music --verbose
```

### Issue: Workers Deployment Fails

```bash
# Validate wrangler.toml
cat wrangler.toml

# Check for KV namespace issues
wrangler kv:namespace list

# Check secrets
wrangler secret list

# Deploy with dry-run first
wrangler deploy --dry-run
```

### Issue: 5xx Errors After Deployment

```bash
# Check logs immediately
wrangler tail --format=json

# If critical, rollback
wrangler rollback

# Then investigate in staging
wrangler deploy --env staging
```

### Issue: CORS Errors

```bash
# Verify CORS headers
curl -I https://music.abada.kr/api/stats \
  -H "Origin: https://music.abada.kr"

# Check OPTIONS preflight
curl -X OPTIONS https://music.abada.kr/api/stats \
  -H "Origin: https://music.abada.kr" \
  -H "Access-Control-Request-Method: GET" \
  -I
```

---

## Deployment Scripts

### scripts/deploy.sh

```bash
#!/bin/bash
set -e

echo "Starting deployment..."

# Build website
echo "Building website..."
cd web
npm ci
npm run build
cd ..

# Deploy Pages
echo "Deploying to Cloudflare Pages..."
wrangler pages deploy web/dist --project-name=abada-music --branch=main

# Deploy Workers
echo "Deploying Cloudflare Workers..."
wrangler deploy

# Verify deployment
echo "Verifying deployment..."
sleep 10

# Health check
HEALTH=$(curl -s https://music.abada.kr/api/health)
if echo "$HEALTH" | grep -q '"status":"ok"'; then
  echo "Deployment successful!"
  echo "$HEALTH"
else
  echo "ERROR: Health check failed!"
  echo "$HEALTH"
  exit 1
fi
```

### scripts/verify-deployment.sh

```bash
#!/bin/bash

DOMAIN="${1:-music.abada.kr}"

echo "Verifying deployment for: $DOMAIN"
echo "================================"

# Check pages
PAGES=("" "download" "gallery" "tutorial" "faq" "about")
FAILED=0

for page in "${PAGES[@]}"; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN}/${page}")
  TIME=$(curl -s -o /dev/null -w "%{time_total}" "https://${DOMAIN}/${page}")

  if [[ "$STATUS" == "200" ]]; then
    echo "OK: /${page:-home} (${TIME}s)"
  else
    echo "FAIL: /${page:-home} - HTTP ${STATUS}"
    FAILED=$((FAILED + 1))
  fi
done

# Check API
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN}/api/health")
if [[ "$API_STATUS" == "200" ]]; then
  echo "OK: /api/health"
else
  echo "FAIL: /api/health - HTTP ${API_STATUS}"
  FAILED=$((FAILED + 1))
fi

echo ""
if [[ $FAILED -eq 0 ]]; then
  echo "All checks passed!"
  exit 0
else
  echo "FAILED: $FAILED checks failed"
  exit 1
fi
```

---

## Expected Outputs

### Successful Pages Deployment

```
Uploading... (5/5)

Successfully built!
Deploying your site to Cloudflare's global network...

Deployment complete! Take a peek over at:
  https://xxxxx.abada-music.pages.dev
  https://music.abada.kr
```

### Successful Workers Deployment

```
Total Upload: 25.67 KiB / gzip: 8.12 KiB
Uploaded abada-music-api (2.48 sec)
Published abada-music-api (0.21 sec)
  https://abada-music-api.xxxxx.workers.dev
Current Deployment ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### Successful Health Check

```json
{
  "status": "ok",
  "timestamp": "2026-01-19T15:30:00.000Z",
  "environment": "production"
}
```

---

## Automation vs Manual

| Task | Automated | Manual When |
|------|-----------|-------------|
| Website deploy | GitHub Actions on push | Emergency fix, testing |
| Workers deploy | GitHub Actions on push | Configuration change |
| Rollback | Manual | Always manual decision |
| Health checks | Automated post-deploy | Manual verification |
| Monitoring | Always automated | Additional debugging |

---

## Contacts

| Role | Contact | When |
|------|---------|------|
| DevOps | devops@abada.kr | Deployment issues |
| On-Call | oncall@abada.kr | Production incidents |
| Security | security@abada.kr | Security concerns |

---

**Document Owner**: DevOps Team
**Last Review**: 2026-01-19
