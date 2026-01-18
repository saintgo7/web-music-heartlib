/**
 * Gallery API
 *
 * Manages the gallery of user-generated music samples.
 *
 * Endpoints:
 *   GET  /api/gallery - Get gallery samples
 *   POST /api/gallery - Add a new gallery item (requires API key)
 *
 * KV Schema:
 *   gallery:items -> JSON array of gallery items
 *   gallery:item:{id} -> individual item data
 *   gallery:count -> total item count
 *
 * @author ABADA Inc.
 * @license CC BY-NC 4.0
 */

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Content-Type': 'application/json',
};

/**
 * Default gallery samples for initial display
 */
const DEFAULT_SAMPLES = [
  {
    id: 'sample-001',
    title: 'Morning Light',
    description: 'A cheerful pop song about new beginnings',
    lyrics: '[Verse]\nThe morning light comes through the window\nA brand new day is here\n\n[Chorus]\nWe rise again, we start again\nEvery day is a new begin',
    tags: ['pop', 'happy', 'morning', 'piano'],
    audio_url: 'https://music.abada.kr/samples/morning-light.mp3',
    thumbnail_url: 'https://music.abada.kr/samples/morning-light-thumb.jpg',
    duration_seconds: 120,
    created_at: '2026-01-15T10:00:00Z',
    created_by: 'ABADA Team',
    featured: true,
  },
  {
    id: 'sample-002',
    title: 'Midnight Dream',
    description: 'Ambient relaxing music for late night vibes',
    lyrics: '[Verse]\nWhen the night falls silent\nStars begin to shine\n\n[Bridge]\nDreams are calling me\nInto the peaceful night',
    tags: ['ambient', 'relaxing', 'night', 'dreamy'],
    audio_url: 'https://music.abada.kr/samples/midnight-dream.mp3',
    thumbnail_url: 'https://music.abada.kr/samples/midnight-dream-thumb.jpg',
    duration_seconds: 180,
    created_at: '2026-01-16T22:00:00Z',
    created_by: 'ABADA Team',
    featured: true,
  },
  {
    id: 'sample-003',
    title: 'City Lights',
    description: 'Electronic dance track with urban vibes',
    lyrics: '[Verse]\nNeon signs light up the street\nBass drops, feel the beat\n\n[Chorus]\nCity lights, city nights\nWe dance until the morning light',
    tags: ['electronic', 'dance', 'edm', 'urban'],
    audio_url: 'https://music.abada.kr/samples/city-lights.mp3',
    thumbnail_url: 'https://music.abada.kr/samples/city-lights-thumb.jpg',
    duration_seconds: 150,
    created_at: '2026-01-17T18:00:00Z',
    created_by: 'Community',
    featured: false,
  },
  {
    id: 'sample-004',
    title: 'Acoustic Serenade',
    description: 'Gentle acoustic guitar piece',
    lyrics: '[Verse]\nSoft strings whisper tales\nOf love beneath the moon\n\n[Chorus]\nPlay for me tonight\nLet the melody take flight',
    tags: ['acoustic', 'guitar', 'romantic', 'soft'],
    audio_url: 'https://music.abada.kr/samples/acoustic-serenade.mp3',
    thumbnail_url: 'https://music.abada.kr/samples/acoustic-serenade-thumb.jpg',
    duration_seconds: 200,
    created_at: '2026-01-18T14:00:00Z',
    created_by: 'Community',
    featured: false,
  },
  {
    id: 'sample-005',
    title: 'Jazz Cafe',
    description: 'Smooth jazz for coffee time',
    lyrics: '[Instrumental]\nSmooth saxophone melody\nPiano accompaniment\nDouble bass groove',
    tags: ['jazz', 'instrumental', 'cafe', 'smooth'],
    audio_url: 'https://music.abada.kr/samples/jazz-cafe.mp3',
    thumbnail_url: 'https://music.abada.kr/samples/jazz-cafe-thumb.jpg',
    duration_seconds: 240,
    created_at: '2026-01-18T20:00:00Z',
    created_by: 'ABADA Team',
    featured: true,
  },
];

/**
 * Get gallery items
 *
 * Query parameters:
 *   - limit: number of items to return (default: 20, max: 100)
 *   - offset: pagination offset (default: 0)
 *   - tag: filter by tag
 *   - featured: filter featured items only ('true' or 'false')
 *   - sort: sort order ('newest', 'oldest', 'popular')
 *
 * @param {Request} request - The incoming request
 * @param {Object} env - Environment bindings
 * @returns {Response} - JSON response with gallery items
 */
export async function getGallery(request, env) {
  try {
    const url = new URL(request.url);

    // Parse query parameters
    const limit = Math.min(parseInt(url.searchParams.get('limit')) || 20, 100);
    const offset = parseInt(url.searchParams.get('offset')) || 0;
    const tagFilter = url.searchParams.get('tag');
    const featuredFilter = url.searchParams.get('featured');
    const sort = url.searchParams.get('sort') || 'newest';

    // Get items from KV or use defaults
    let items = [];

    if (env.GALLERY) {
      const storedItems = await env.GALLERY.get('gallery:items', { type: 'json' });
      items = storedItems || DEFAULT_SAMPLES;
    } else {
      items = DEFAULT_SAMPLES;
    }

    // Apply filters
    let filteredItems = [...items];

    if (tagFilter) {
      filteredItems = filteredItems.filter((item) =>
        item.tags.some((tag) => tag.toLowerCase() === tagFilter.toLowerCase())
      );
    }

    if (featuredFilter === 'true') {
      filteredItems = filteredItems.filter((item) => item.featured === true);
    } else if (featuredFilter === 'false') {
      filteredItems = filteredItems.filter((item) => item.featured !== true);
    }

    // Apply sorting
    switch (sort) {
      case 'oldest':
        filteredItems.sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
        break;
      case 'popular':
        filteredItems.sort((a, b) => (b.plays || 0) - (a.plays || 0));
        break;
      case 'newest':
      default:
        filteredItems.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    }

    // Apply pagination
    const total = filteredItems.length;
    const paginatedItems = filteredItems.slice(offset, offset + limit);

    // Get unique tags for filtering UI
    const allTags = [...new Set(items.flatMap((item) => item.tags))].sort();

    return new Response(
      JSON.stringify({
        success: true,
        items: paginatedItems,
        pagination: {
          total: total,
          limit: limit,
          offset: offset,
          has_more: offset + limit < total,
        },
        available_tags: allTags,
        generated_at: new Date().toISOString(),
      }),
      {
        status: 200,
        headers: corsHeaders,
      }
    );
  } catch (error) {
    console.error('Gallery handler error:', error);
    return new Response(
      JSON.stringify({
        error: 'Failed to retrieve gallery',
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
 * Add a new gallery item
 *
 * Requires API key in Authorization header for admin operations.
 *
 * Request body:
 *   {
 *     "title": "Song Title",
 *     "description": "Description",
 *     "lyrics": "Song lyrics",
 *     "tags": ["tag1", "tag2"],
 *     "audio_url": "https://...",
 *     "thumbnail_url": "https://...",
 *     "duration_seconds": 120,
 *     "created_by": "Username",
 *     "featured": false
 *   }
 *
 * @param {Request} request - The incoming request
 * @param {Object} env - Environment bindings
 * @returns {Response} - JSON response
 */
export async function addGalleryItem(request, env) {
  try {
    // Check for API key (simple auth)
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({
          error: 'Authorization required',
          success: false,
        }),
        {
          status: 401,
          headers: corsHeaders,
        }
      );
    }

    const apiKey = authHeader.substring(7);
    if (env.ADMIN_API_KEY && apiKey !== env.ADMIN_API_KEY) {
      return new Response(
        JSON.stringify({
          error: 'Invalid API key',
          success: false,
        }),
        {
          status: 403,
          headers: corsHeaders,
        }
      );
    }

    // Parse request body
    const body = await request.json();

    // Validate required fields
    const requiredFields = ['title', 'audio_url'];
    for (const field of requiredFields) {
      if (!body[field]) {
        return new Response(
          JSON.stringify({
            error: `Missing required field: ${field}`,
            success: false,
          }),
          {
            status: 400,
            headers: corsHeaders,
          }
        );
      }
    }

    // Create new item
    const newItem = {
      id: `item-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      title: body.title,
      description: body.description || '',
      lyrics: body.lyrics || '',
      tags: body.tags || [],
      audio_url: body.audio_url,
      thumbnail_url: body.thumbnail_url || '',
      duration_seconds: body.duration_seconds || 0,
      created_at: new Date().toISOString(),
      created_by: body.created_by || 'Anonymous',
      featured: body.featured || false,
      plays: 0,
    };

    // Get existing items
    let items = [];
    if (env.GALLERY) {
      const storedItems = await env.GALLERY.get('gallery:items', { type: 'json' });
      items = storedItems || DEFAULT_SAMPLES;

      // Add new item
      items.unshift(newItem);

      // Save updated items
      await env.GALLERY.put('gallery:items', JSON.stringify(items));

      // Update count
      await env.GALLERY.put('gallery:count', items.length.toString());
    }

    return new Response(
      JSON.stringify({
        success: true,
        item: newItem,
        message: 'Gallery item added successfully',
      }),
      {
        status: 201,
        headers: corsHeaders,
      }
    );
  } catch (error) {
    console.error('Add gallery item error:', error);
    return new Response(
      JSON.stringify({
        error: 'Failed to add gallery item',
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
