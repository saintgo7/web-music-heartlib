/**
 * ABADA Music Studio API - Main Entry Point
 *
 * This Cloudflare Worker handles all API requests for the ABADA Music Studio website.
 *
 * Endpoints:
 *   POST /api/download        - Record a download event
 *   GET  /api/stats           - Get download statistics
 *   GET  /api/gallery         - Get gallery samples
 *   POST /api/analytics       - Record analytics event
 *
 * @author ABADA Inc.
 * @license CC BY-NC 4.0
 */

import { handleDownload, getDownloadStats } from './download-stats.js';
import { getGallery, addGalleryItem } from './gallery.js';
import { recordAnalytics, getAnalytics } from './analytics.js';

/**
 * CORS headers for cross-origin requests
 */
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Max-Age': '86400',
};

/**
 * JSON response helper
 */
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders,
    },
  });
}

/**
 * Error response helper
 */
function errorResponse(message, status = 400) {
  return jsonResponse({ error: message, success: false }, status);
}

/**
 * Main request handler
 */
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // Handle CORS preflight
    if (method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: corsHeaders,
      });
    }

    try {
      // Route requests
      switch (true) {
        // Download Statistics
        case path === '/api/download' && method === 'POST':
          return await handleDownload(request, env);

        case path === '/api/download' && method === 'GET':
          const os = url.searchParams.get('os');
          if (os) {
            return await handleDownloadRedirect(os, env);
          }
          return errorResponse('Missing "os" parameter');

        case path === '/api/stats' && method === 'GET':
          return await getDownloadStats(request, env);

        // Gallery
        case path === '/api/gallery' && method === 'GET':
          return await getGallery(request, env);

        case path === '/api/gallery' && method === 'POST':
          return await addGalleryItem(request, env);

        // Analytics
        case path === '/api/analytics' && method === 'POST':
          return await recordAnalytics(request, env);

        case path === '/api/analytics' && method === 'GET':
          return await getAnalytics(request, env);

        // Health check
        case path === '/api/health':
          return jsonResponse({
            status: 'ok',
            timestamp: new Date().toISOString(),
            environment: env.ENVIRONMENT || 'unknown',
          });

        // API documentation
        case path === '/api' || path === '/api/':
          return jsonResponse({
            name: 'ABADA Music Studio API',
            version: '1.0.0',
            endpoints: {
              'POST /api/download': 'Record download and redirect to file',
              'GET /api/download?os=<os>': 'Redirect to download file',
              'GET /api/stats': 'Get download statistics',
              'GET /api/gallery': 'Get gallery samples',
              'POST /api/gallery': 'Add gallery item (admin)',
              'POST /api/analytics': 'Record analytics event',
              'GET /api/analytics': 'Get analytics data',
              'GET /api/health': 'Health check',
            },
            documentation: 'https://music.abada.kr/docs/api',
          });

        default:
          return errorResponse('Not found', 404);
      }
    } catch (error) {
      console.error('API Error:', error);
      return errorResponse(`Internal server error: ${error.message}`, 500);
    }
  },
};

/**
 * Handle download redirect with statistics tracking
 */
async function handleDownloadRedirect(os, env) {
  // Record the download
  const today = new Date().toISOString().split('T')[0];
  const key = `download:${os}:${today}`;

  try {
    const current = parseInt((await env.STATS.get(key)) || '0');
    await env.STATS.put(key, (current + 1).toString(), {
      expirationTtl: 60 * 60 * 24 * 365, // 1 year
    });
  } catch (e) {
    console.error('Failed to record download:', e);
  }

  // Get latest release URL
  const downloadUrls = {
    'windows-x64': `${env.GITHUB_RELEASES_URL}/latest/download/MuLa_Setup_x64.exe`,
    'windows-x86': `${env.GITHUB_RELEASES_URL}/latest/download/MuLa_Setup_x86.exe`,
    'macos': `${env.GITHUB_RELEASES_URL}/latest/download/MuLa_Installer.dmg`,
    'linux': `${env.GITHUB_RELEASES_URL}/latest/download/mula_install.sh`,
  };

  const downloadUrl = downloadUrls[os] || downloadUrls['windows-x64'];

  return new Response(null, {
    status: 302,
    headers: {
      Location: downloadUrl,
      ...corsHeaders,
    },
  });
}
