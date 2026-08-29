export async function onRequestGet(context) {
  const { request, env } = context;
  const url = new URL(request.url);
  const word = (url.searchParams.get('word') || '').trim().toLowerCase();
  const level = Number(url.searchParams.get('level'));

  if (!/^[a-z0-9_-]+$/.test(word) || !Number.isInteger(level) || level < 1 || level > 10) {
    return new Response('word and level are required', { status: 400 });
  }
  if (!env.NOWSSB_BUCKET) {
    return new Response('Audio storage is not configured', { status: 503 });
  }

  const object = await env.NOWSSB_BUCKET.get(`reference/${word}/level-${level}.mp3`);
  if (!object) return new Response('Audio not found for this word/level', { status: 404 });

  const headers = new Headers({
    'Content-Type': 'audio/mpeg',
    'Cache-Control': 'public, max-age=31536000, immutable',
    'Accept-Ranges': 'bytes',
  });
  object.writeHttpMetadata(headers);
  if (object.httpEtag) headers.set('ETag', object.httpEtag);
  return new Response(object.body, { headers });
}

export async function onRequestOptions() {
  return new Response(null, { headers: { Allow: 'GET, OPTIONS' } });
}
