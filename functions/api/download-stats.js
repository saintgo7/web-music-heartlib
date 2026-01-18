/**
 * Download Statistics API
 *
 * Tracks and reports download statistics for ABADA Music Studio installers.
 *
 * Endpoints:
 *   POST /api/download - Record a download event
 *   GET  /api/stats    - Get download statistics
 *
 * KV Schema:
 *   download:{os}:{date} -> count (integer as string)
 *   download:total:{os}  -> total count
 *
 * @author ABADA Inc.
 * @license CC BY-NC 4.0
 */

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Content-Type': 'application/json',
};

/**
 * Valid OS options for download tracking
 */
const VALID_OS = ['windows-x64', 'windows-x86', 'macos', 'linux'];

/**
 * GitHub release download URLs
 */
const DOWNLOAD_URLS = {
  'windows-x64': 'https://github.com/saintgo7/web-music-heartlib/releases/latest/download/MuLa_Setup_x64.exe',
  'windows-x86': 'https://github.com/saintgo7/web-music-heartlib/releases/latest/download/MuLa_Setup_x86.exe',
  'macos': 'https://github.com/saintgo7/web-music-heartlib/releases/latest/download/MuLa_Installer.dmg',
  'linux': 'https://github.com/saintgo7/web-music-heartlib/releases/latest/download/mula_install.sh',
};

/**
 * Handle download request - record statistics and redirect to download URL
 *
 * @param {Request} request - The incoming request
 * @param {Object} env - Environment bindings (KV namespaces, secrets)
 * @returns {Response} - Redirect response or JSON response
 */
export async function handleDownload(request, env) {
  try {
    // Parse request body or query params
    let os;
    const url = new URL(request.url);

    if (request.method === 'POST') {
      const body = await request.json().catch(() => ({}));
      os = body.os || url.searchParams.get('os');
    } else {
      os = url.searchParams.get('os');
    }

    // Validate OS parameter
    if (!os || !VALID_OS.includes(os)) {
      return new Response(
        JSON.stringify({
          error: 'Invalid or missing "os" parameter',
          valid_options: VALID_OS,
          success: false,
        }),
        {
          status: 400,
          headers: corsHeaders,
        }
      );
    }

    // Get current date for daily tracking
    const today = new Date().toISOString().split('T')[0];
    const dailyKey = `download:${os}:${today}`;
    const totalKey = `download:total:${os}`;

    // Record the download
    if (env.STATS) {
      // Increment daily count
      const dailyCount = parseInt((await env.STATS.get(dailyKey)) || '0');
      await env.STATS.put(dailyKey, (dailyCount + 1).toString(), {
        expirationTtl: 60 * 60 * 24 * 365, // Keep for 1 year
      });

      // Increment total count
      const totalCount = parseInt((await env.STATS.get(totalKey)) || '0');
      await env.STATS.put(totalKey, (totalCount + 1).toString());

      // Log for debugging (visible in Cloudflare dashboard)
      console.log(`Download recorded: ${os}, daily: ${dailyCount + 1}, total: ${totalCount + 1}`);
    }

    // Check if redirect is requested
    const redirect = url.searchParams.get('redirect') !== 'false';

    if (redirect) {
      // Redirect to the actual download URL
      return new Response(null, {
        status: 302,
        headers: {
          Location: DOWNLOAD_URLS[os],
          ...corsHeaders,
        },
      });
    }

    // Return JSON response without redirect
    return new Response(
      JSON.stringify({
        success: true,
        os: os,
        download_url: DOWNLOAD_URLS[os],
        message: 'Download recorded',
      }),
      {
        status: 200,
        headers: corsHeaders,
      }
    );
  } catch (error) {
    console.error('Download handler error:', error);
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
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
 * Get download statistics
 *
 * Query parameters:
 *   - period: 'today', 'week', 'month', 'all' (default: 'all')
 *   - os: specific OS or 'all' (default: 'all')
 *
 * @param {Request} request - The incoming request
 * @param {Object} env - Environment bindings
 * @returns {Response} - JSON response with statistics
 */
export async function getDownloadStats(request, env) {
  try {
    const url = new URL(request.url);
    const period = url.searchParams.get('period') || 'all';
    const requestedOs = url.searchParams.get('os') || 'all';

    const stats = {
      period: period,
      generated_at: new Date().toISOString(),
      downloads: {},
      total: 0,
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

    // Get statistics for each OS
    const osToQuery = requestedOs === 'all' ? VALID_OS : [requestedOs];

    for (const os of osToQuery) {
      if (!VALID_OS.includes(os)) continue;

      let count = 0;

      if (period === 'all') {
        // Get total count
        count = parseInt((await env.STATS.get(`download:total:${os}`)) || '0');
      } else {
        // Get counts for specific period
        const dates = getDateRange(period);
        for (const date of dates) {
          const dailyCount = parseInt((await env.STATS.get(`download:${os}:${date}`)) || '0');
          count += dailyCount;
        }
      }

      stats.downloads[os] = count;
      stats.total += count;
    }

    // Add breakdown by category
    stats.breakdown = {
      windows: (stats.downloads['windows-x64'] || 0) + (stats.downloads['windows-x86'] || 0),
      macos: stats.downloads['macos'] || 0,
      linux: stats.downloads['linux'] || 0,
    };

    return new Response(JSON.stringify(stats), {
      status: 200,
      headers: corsHeaders,
    });
  } catch (error) {
    console.error('Stats handler error:', error);
    return new Response(
      JSON.stringify({
        error: 'Failed to retrieve statistics',
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
 *
 * @param {string} period - 'today', 'week', 'month'
 * @returns {string[]} - Array of date strings (YYYY-MM-DD)
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
