/**
 * Analytics API
 *
 * Records and retrieves analytics events for the ABADA Music Studio website.
 *
 * Endpoints:
 *   POST /api/analytics - Record an analytics event
 *   GET  /api/analytics - Get analytics data (admin)
 *
 * KV Schema:
 *   analytics:event:{date}:{type} -> count
 *   analytics:pageview:{date}:{page} -> count
 *   analytics:referrer:{date}:{source} -> count
 *
 * @author ABADA Inc.
 * @license CC BY-NC 4.0
 */

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Content-Type': 'application/json',
};

/**
 * Valid event types
 */
const VALID_EVENT_TYPES = [
  'page_view',
  'download_click',
  'download_complete',
  'gallery_view',
  'gallery_play',
  'tutorial_view',
  'faq_view',
  'external_link',
  'share',
  'error',
];

/**
 * Record an analytics event
 *
 * Request body:
 *   {
 *     "event": "page_view",
 *     "page": "/download",
 *     "referrer": "https://google.com",
 *     "metadata": { ... }
 *   }
 *
 * @param {Request} request - The incoming request
 * @param {Object} env - Environment bindings
 * @returns {Response} - JSON response
 */
export async function recordAnalytics(request, env) {
  try {
    const body = await request.json().catch(() => ({}));

    // Validate event type
    const eventType = body.event || 'page_view';
    if (!VALID_EVENT_TYPES.includes(eventType)) {
      return new Response(
        JSON.stringify({
          error: 'Invalid event type',
          valid_types: VALID_EVENT_TYPES,
          success: false,
        }),
        {
          status: 400,
          headers: corsHeaders,
        }
      );
    }

    const today = new Date().toISOString().split('T')[0];
    const hour = new Date().getUTCHours();

    // Extract request metadata
    const userAgent = request.headers.get('User-Agent') || 'unknown';
    const country = request.cf?.country || 'unknown';
    const referer = request.headers.get('Referer') || body.referrer || 'direct';

    // Prepare analytics data
    const analyticsData = {
      event: eventType,
      page: body.page || '/',
      referrer: referer,
      metadata: body.metadata || {},
      timestamp: new Date().toISOString(),
      user_agent: userAgent,
      country: country,
    };

    // Store analytics in KV
    if (env.STATS) {
      // Increment event count
      const eventKey = `analytics:event:${today}:${eventType}`;
      const eventCount = parseInt((await env.STATS.get(eventKey)) || '0');
      await env.STATS.put(eventKey, (eventCount + 1).toString(), {
        expirationTtl: 60 * 60 * 24 * 90, // Keep for 90 days
      });

      // Increment page view count
      if (body.page) {
        const pageKey = `analytics:pageview:${today}:${sanitizePath(body.page)}`;
        const pageCount = parseInt((await env.STATS.get(pageKey)) || '0');
        await env.STATS.put(pageKey, (pageCount + 1).toString(), {
          expirationTtl: 60 * 60 * 24 * 90,
        });
      }

      // Track referrer sources
      if (referer && referer !== 'direct') {
        const referrerSource = extractReferrerSource(referer);
        const referrerKey = `analytics:referrer:${today}:${referrerSource}`;
        const referrerCount = parseInt((await env.STATS.get(referrerKey)) || '0');
        await env.STATS.put(referrerKey, (referrerCount + 1).toString(), {
          expirationTtl: 60 * 60 * 24 * 90,
        });
      }

      // Track hourly activity
      const hourlyKey = `analytics:hourly:${today}:${hour}`;
      const hourlyCount = parseInt((await env.STATS.get(hourlyKey)) || '0');
      await env.STATS.put(hourlyKey, (hourlyCount + 1).toString(), {
        expirationTtl: 60 * 60 * 24 * 7, // Keep for 7 days
      });

      // Track country
      if (country !== 'unknown') {
        const countryKey = `analytics:country:${today}:${country}`;
        const countryCount = parseInt((await env.STATS.get(countryKey)) || '0');
        await env.STATS.put(countryKey, (countryCount + 1).toString(), {
          expirationTtl: 60 * 60 * 24 * 90,
        });
      }

      console.log(`Analytics recorded: ${eventType} on ${body.page} from ${country}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Analytics event recorded',
      }),
      {
        status: 200,
        headers: corsHeaders,
      }
    );
  } catch (error) {
    console.error('Analytics record error:', error);
    return new Response(
      JSON.stringify({
        error: 'Failed to record analytics',
        message: error.message,
        success: false,
      }),
      {
        status: 500,
        headers: corsHeaders,
      }
    );
  }
}

/**
 * Get analytics data
 *
 * Query parameters:
 *   - period: 'today', 'week', 'month' (default: 'today')
 *   - type: event type filter or 'all'
 *
 * @param {Request} request - The incoming request
 * @param {Object} env - Environment bindings
 * @returns {Response} - JSON response with analytics data
 */
export async function getAnalytics(request, env) {
  try {
    const url = new URL(request.url);
    const period = url.searchParams.get('period') || 'today';
    const typeFilter = url.searchParams.get('type') || 'all';

    const dates = getDateRange(period);

    const analytics = {
      period: period,
      date_range: {
        start: dates[dates.length - 1],
        end: dates[0],
      },
      events: {},
      pages: {},
      referrers: {},
      countries: {},
      hourly: {},
      totals: {
        events: 0,
        page_views: 0,
      },
      generated_at: new Date().toISOString(),
    };

    if (!env.STATS) {
      return new Response(
        JSON.stringify({
          error: 'Statistics storage not configured',
          success: false,
        }),
        {
          status: 503,
          headers: corsHeaders,
        }
      );
    }

    // Aggregate data from KV
    for (const date of dates) {
      // Get event counts
      const eventTypes = typeFilter === 'all' ? VALID_EVENT_TYPES : [typeFilter];
      for (const eventType of eventTypes) {
        const eventKey = `analytics:event:${date}:${eventType}`;
        const count = parseInt((await env.STATS.get(eventKey)) || '0');
        if (count > 0) {
          analytics.events[eventType] = (analytics.events[eventType] || 0) + count;
          analytics.totals.events += count;
        }
      }

      // Get page view counts (scan for keys - limited in KV, use list with prefix)
      // Note: KV list is expensive, so we track known pages
      const knownPages = ['/', '/download', '/gallery', '/tutorial', '/faq', '/about'];
      for (const page of knownPages) {
        const pageKey = `analytics:pageview:${date}:${sanitizePath(page)}`;
        const count = parseInt((await env.STATS.get(pageKey)) || '0');
        if (count > 0) {
          analytics.pages[page] = (analytics.pages[page] || 0) + count;
          analytics.totals.page_views += count;
        }
      }

      // Get referrer counts
      const knownReferrers = ['google', 'twitter', 'facebook', 'linkedin', 'github', 'reddit', 'direct', 'other'];
      for (const source of knownReferrers) {
        const referrerKey = `analytics:referrer:${date}:${source}`;
        const count = parseInt((await env.STATS.get(referrerKey)) || '0');
        if (count > 0) {
          analytics.referrers[source] = (analytics.referrers[source] || 0) + count;
        }
      }

      // Get hourly data for today only
      if (date === dates[0]) {
        for (let hour = 0; hour < 24; hour++) {
          const hourlyKey = `analytics:hourly:${date}:${hour}`;
          const count = parseInt((await env.STATS.get(hourlyKey)) || '0');
          analytics.hourly[hour] = count;
        }
      }
    }

    // Sort events by count
    analytics.events = Object.fromEntries(
      Object.entries(analytics.events).sort(([, a], [, b]) => b - a)
    );

    // Sort pages by count
    analytics.pages = Object.fromEntries(
      Object.entries(analytics.pages).sort(([, a], [, b]) => b - a)
    );

    return new Response(JSON.stringify(analytics), {
      status: 200,
      headers: corsHeaders,
    });
  } catch (error) {
    console.error('Analytics get error:', error);
    return new Response(
      JSON.stringify({
        error: 'Failed to retrieve analytics',
        message: error.message,
        success: false,
      }),
      {
        status: 500,
        headers: corsHeaders,
      }
    );
  }
}

/**
 * Get array of date strings for a given period
 */
function getDateRange(period) {
  const dates = [];
  const today = new Date();

  let days;
  switch (period) {
    case 'today':
      days = 1;
      break;
    case 'week':
      days = 7;
      break;
    case 'month':
      days = 30;
      break;
    default:
      days = 1;
  }

  for (let i = 0; i < days; i++) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    dates.push(date.toISOString().split('T')[0]);
  }

  return dates;
}

/**
 * Sanitize path for use as KV key
 */
function sanitizePath(path) {
  return (path || '/')
    .replace(/[^a-zA-Z0-9/\-_]/g, '')
    .replace(/\//g, '_')
    .toLowerCase();
}

/**
 * Extract referrer source from URL
 */
function extractReferrerSource(referrer) {
  try {
    const url = new URL(referrer);
    const hostname = url.hostname.toLowerCase();

    if (hostname.includes('google')) return 'google';
    if (hostname.includes('twitter') || hostname.includes('x.com')) return 'twitter';
    if (hostname.includes('facebook')) return 'facebook';
    if (hostname.includes('linkedin')) return 'linkedin';
    if (hostname.includes('github')) return 'github';
    if (hostname.includes('reddit')) return 'reddit';
    if (hostname.includes('youtube')) return 'youtube';
    if (hostname.includes('abada.kr')) return 'abada';

    return 'other';
  } catch {
    return 'direct';
  }
}
