# ABADA Music Studio - Analytics Setup Guide

**Version**: 1.0.0
**Updated**: 2026-01-19
**Status**: Active

---

## Overview

This document describes the analytics configuration for ABADA Music Studio, including Cloudflare Analytics, custom metrics, Real User Monitoring (RUM), and Core Web Vitals tracking.

---

## Cloudflare Analytics

### Web Analytics Setup

1. Navigate to Cloudflare Dashboard
2. Select your zone (abada.kr)
3. Go to Analytics > Web Analytics
4. Enable Web Analytics for music.abada.kr

### Analytics Features

| Feature | Status | Purpose |
|---------|--------|---------|
| Page Views | Enabled | Track page visits |
| Unique Visitors | Enabled | Count unique users |
| Top Pages | Enabled | Popular content |
| Top Countries | Enabled | Geographic distribution |
| Referrers | Enabled | Traffic sources |
| Device Types | Enabled | Mobile vs Desktop |

---

## Custom Analytics Events

### Event Structure

```javascript
// Analytics event payload
const analyticsEvent = {
  event: 'page_view',           // Event type
  page: '/download',            // Page path
  timestamp: Date.now(),        // Unix timestamp
  sessionId: 'uuid-xxx',        // Session identifier
  userId: null,                 // Optional user ID
  metadata: {                   // Custom metadata
    os: 'windows',
    referrer: 'google.com',
    campaign: 'launch2026'
  }
};
```

### Tracked Events

| Event | Trigger | Metadata |
|-------|---------|----------|
| page_view | Page load | path, referrer |
| download_click | Download button | os, version |
| download_complete | Redirect | os, success |
| gallery_view | Gallery page | filter, sort |
| gallery_play | Audio play | sample_id |
| search | FAQ search | query |
| error | JS error | message, stack |

### Client-Side Implementation

```javascript
// Analytics utility
const analytics = {
  track: async (event, metadata = {}) => {
    try {
      await fetch('/api/analytics', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          event,
          page: window.location.pathname,
          timestamp: Date.now(),
          sessionId: getSessionId(),
          metadata: {
            ...metadata,
            userAgent: navigator.userAgent,
            language: navigator.language,
            screenSize: `${window.innerWidth}x${window.innerHeight}`,
          },
        }),
      });
    } catch (e) {
      console.warn('Analytics error:', e);
    }
  },

  pageView: () => {
    analytics.track('page_view', {
      referrer: document.referrer,
      title: document.title,
    });
  },

  downloadClick: (os) => {
    analytics.track('download_click', { os });
  },
};

// Track page views on navigation
window.addEventListener('load', () => analytics.pageView());
```

---

## Real User Monitoring (RUM)

### Performance Metrics

```javascript
// Collect performance metrics
function collectPerformanceMetrics() {
  const navigation = performance.getEntriesByType('navigation')[0];
  const paint = performance.getEntriesByType('paint');

  return {
    // Navigation timing
    dns: navigation.domainLookupEnd - navigation.domainLookupStart,
    tcp: navigation.connectEnd - navigation.connectStart,
    ssl: navigation.secureConnectionStart > 0
      ? navigation.connectEnd - navigation.secureConnectionStart
      : 0,
    ttfb: navigation.responseStart - navigation.requestStart,
    download: navigation.responseEnd - navigation.responseStart,
    domInteractive: navigation.domInteractive,
    domComplete: navigation.domComplete,
    loadComplete: navigation.loadEventEnd,

    // Paint timing
    fp: paint.find(p => p.name === 'first-paint')?.startTime,
    fcp: paint.find(p => p.name === 'first-contentful-paint')?.startTime,
  };
}

// Send RUM data
function sendRUMData() {
  const metrics = collectPerformanceMetrics();

  navigator.sendBeacon('/api/analytics', JSON.stringify({
    event: 'rum_metrics',
    timestamp: Date.now(),
    metrics,
  }));
}

// Collect after page load
window.addEventListener('load', () => {
  setTimeout(sendRUMData, 0);
});
```

---

## Core Web Vitals

### Metrics Definition

| Metric | Good | Needs Work | Poor |
|--------|------|------------|------|
| LCP | < 2.5s | 2.5s - 4s | > 4s |
| FID | < 100ms | 100ms - 300ms | > 300ms |
| CLS | < 0.1 | 0.1 - 0.25 | > 0.25 |
| INP | < 200ms | 200ms - 500ms | > 500ms |
| TTFB | < 800ms | 800ms - 1800ms | > 1800ms |

### Implementation

```javascript
// Using web-vitals library
import { onCLS, onFID, onLCP, onINP, onTTFB } from 'web-vitals';

function sendToAnalytics(metric) {
  const body = JSON.stringify({
    event: 'web_vital',
    name: metric.name,
    value: metric.value,
    rating: metric.rating,
    delta: metric.delta,
    id: metric.id,
    navigationType: metric.navigationType,
  });

  // Use sendBeacon for reliability
  if (navigator.sendBeacon) {
    navigator.sendBeacon('/api/analytics', body);
  } else {
    fetch('/api/analytics', {
      method: 'POST',
      body,
      keepalive: true,
    });
  }
}

// Register observers
onCLS(sendToAnalytics);
onFID(sendToAnalytics);
onLCP(sendToAnalytics);
onINP(sendToAnalytics);
onTTFB(sendToAnalytics);
```

---

## Conversion Tracking

### Conversion Funnel

```
Landing Page (100%)
      |
      v
Download Page (60%)
      |
      v
Download Click (40%)
      |
      v
Download Complete (35%)
      |
      v
Installation (estimate)
```

### Tracking Implementation

```javascript
// Conversion tracking
const conversions = {
  visitDownloadPage: () => {
    analytics.track('conversion', {
      step: 'download_page',
      funnel: 'main',
    });
  },

  clickDownload: (os) => {
    analytics.track('conversion', {
      step: 'download_click',
      funnel: 'main',
      os,
    });
  },

  downloadComplete: (os) => {
    analytics.track('conversion', {
      step: 'download_complete',
      funnel: 'main',
      os,
    });
  },
};
```

---

## User Behavior Analysis

### Scroll Depth Tracking

```javascript
// Track scroll depth
let maxScroll = 0;
const scrollMilestones = [25, 50, 75, 100];
const trackedMilestones = new Set();

window.addEventListener('scroll', () => {
  const scrollPercent = Math.round(
    (window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100
  );

  maxScroll = Math.max(maxScroll, scrollPercent);

  for (const milestone of scrollMilestones) {
    if (scrollPercent >= milestone && !trackedMilestones.has(milestone)) {
      trackedMilestones.add(milestone);
      analytics.track('scroll_depth', { depth: milestone });
    }
  }
});
```

### Time on Page

```javascript
// Track time on page
const pageLoadTime = Date.now();

window.addEventListener('beforeunload', () => {
  const timeOnPage = Date.now() - pageLoadTime;

  navigator.sendBeacon('/api/analytics', JSON.stringify({
    event: 'time_on_page',
    duration: timeOnPage,
    page: window.location.pathname,
  }));
});
```

---

## Analytics API

### Endpoint: POST /api/analytics

```javascript
// Request
{
  "event": "page_view",
  "page": "/download",
  "timestamp": 1705680000000,
  "sessionId": "uuid-xxx",
  "metadata": {}
}

// Response
{
  "success": true,
  "eventId": "evt_xxx"
}
```

### Endpoint: GET /api/analytics (Admin)

```javascript
// Query parameters
?start=2026-01-01&end=2026-01-31&event=page_view

// Response
{
  "events": [
    { "event": "page_view", "count": 1234, "date": "2026-01-15" }
  ],
  "total": 45678
}
```

---

## Dashboard Metrics

### Key Performance Indicators (KPIs)

| KPI | Target | Measurement |
|-----|--------|-------------|
| Daily Active Users | Growth | Unique visitors/day |
| Downloads | Growth | Download events/day |
| Conversion Rate | > 5% | Downloads / Visitors |
| Bounce Rate | < 40% | Single page sessions |
| Avg Time on Site | > 2min | Session duration |
| Core Web Vitals | All green | LCP, FID, CLS |

### Reporting Schedule

| Report | Frequency | Audience |
|--------|-----------|----------|
| Daily Summary | Daily 9AM | Team |
| Weekly Report | Monday 9AM | Management |
| Monthly Report | 1st of month | Stakeholders |

---

## Privacy Considerations

### Data Collection

- No PII collected by default
- IP addresses anonymized
- Session IDs are temporary
- No third-party tracking

### Cookie Policy

- Essential cookies only
- No tracking cookies
- Session cookies expire on browser close

### Compliance

- GDPR compliant (no PII)
- CCPA compliant
- Privacy-first design

---

## Troubleshooting

### Events Not Recording

1. Check browser console for errors
2. Verify /api/analytics endpoint is accessible
3. Check rate limiting (60 events/min)
4. Verify KV Store connectivity

### Inaccurate Metrics

1. Exclude bot traffic
2. Check for ad blockers
3. Verify sampling rate
4. Review data aggregation logic

---

**Document Owner**: Analytics Team
**Last Review**: 2026-01-19
