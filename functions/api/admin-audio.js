const PROJECT_ID = 'nowssb-34f1b';

function readJwtPayload(token) {
  try {
    const part = token.split('.')[1];
    const normalized = part.replace(/-/g, '+').replace(/_/g, '/');
    const json = decodeURIComponent(Array.from(atob(normalized), (c) => `%${c.charCodeAt(0).toString(16).padStart(2, '0')}`).join(''));
    return JSON.parse(json);
  } catch (_) {
    return null;
  }
}

async function isAdmin(request, env) {
  const auth = request.headers.get('Authorization') || '';
  if (!auth.startsWith('Bearer ')) return false;
  const token = auth.slice(7).trim();
  const claims = readJwtPayload(token);
  if (!claims?.sub || claims.aud !== PROJECT_ID) return false;
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/admins/${encodeURIComponent(claims.sub)}`;
  const response = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
  return response.ok;
}

export async function onRequestPost(context) {
  const { request, env } = context;
  if (!await isAdmin(request, env)) return Response.json({ error: 'Admin access required' }, { status: 403 });
  if (!env.NOWSSB_BUCKET) return Response.json({ error: 'Audio storage is not configured' }, { status: 503 });

  const form = await request.formData();
  const word = String(form.get('word') || '').trim().toLowerCase();
  const level = Number(form.get('level'));
  const audio = form.get('audio');
  if (!/^[a-z0-9_-]+$/.test(word) || !Number.isInteger(level) || level < 1 || level > 10 || !(audio instanceof File)) {
    return Response.json({ error: 'word, level 1-10, and audio are required' }, { status: 400 });
  }
  await env.NOWSSB_BUCKET.put(`reference/${word}/level-${level}.mp3`, audio.stream(), {
    httpMetadata: { contentType: audio.type || 'audio/mpeg', cacheControl: 'public, max-age=31536000, immutable' },
  });
  return Response.json({ ok: true, key: `reference/${word}/level-${level}.mp3` });
}
