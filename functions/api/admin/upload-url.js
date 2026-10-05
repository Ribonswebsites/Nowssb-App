/* ══════════════════════════════════════════════════════════════════════
   POST /api/admin/upload-url — a one-time upload address for Cloudflare R2.

   The NowssB admin mode (Flutter app, lib/admin) uploads template pictures
   and clips, word recordings and word pictures STRAIGHT to R2. The R2 keys
   never leave Cloudflare: this function signs a short-lived S3 "PUT" URL
   for exactly one object and hands that back.

   Who may ask
   -----------
   1. A valid Firebase ID token (RS256, checked against Google's published
      securetoken keys, audience = the Firebase project, not expired).
   2. That uid is an admin: a document at Firestore admins/{uid}. Checked
      with the CALLER'S OWN token through the Firestore REST API — the rules
      let a signed-in user read only their own admins/{uid} — so no service
      account is needed. A custom claim `admin: true` also counts. (One
      admin list for the whole site — /api/admin and /api/push use it too.)

   Request   { area: 'ui'|'audio'|'image'|'video', target: '<slot or word key>',
               ext: 'webp', contentType: 'image/webp' }
   Response  { uploadUrl, publicUrl, key, expiresIn }

   The object key is built HERE from area + target + time, so an admin
   phone cannot write anywhere else in the bucket.

   Cloudflare Pages → Settings → Environment variables (Production):
     R2_ACCOUNT_ID         Cloudflare account id (R2 overview page)
     R2_BUCKET             bucket name
     R2_ACCESS_KEY_ID      R2 API token → Access Key ID  (Object Read & Write,
     R2_SECRET_ACCESS_KEY  R2 API token → Secret Access Key  this bucket only)
     R2_PUBLIC_BASE_URL    the bucket's public address, e.g. https://media.nowssb.com
     FIREBASE_PROJECT_ID   nowssb-34f1b   (already set for /api/push)
   ══════════════════════════════════════════════════════════════════════ */

const enc = new TextEncoder();

const json = (obj, status = 200) => new Response(JSON.stringify(obj), {
  status,
  headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
});

const b64urlToBytes = (s) => {
  const b64 = (s + '='.repeat((4 - (s.length % 4)) % 4)).replace(/-/g, '+').replace(/_/g, '/');
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
};

/* ── Firebase ID token ─────────────────────────────────────────────── */
let _jwks = { at: 0, keys: null };
async function googleJwks() {
  if (_jwks.keys && Date.now() - _jwks.at < 3600e3) return _jwks.keys;
  const r = await fetch('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com');
  if (!r.ok) throw new Error('jwks ' + r.status);
  const d = await r.json();
  _jwks = { at: Date.now(), keys: d.keys || [] };
  return _jwks.keys;
}

async function verifyIdToken(token, projectId) {
  const parts = String(token || '').split('.');
  if (parts.length !== 3) return null;
  let header, claims;
  try {
    header = JSON.parse(new TextDecoder().decode(b64urlToBytes(parts[0])));
    claims = JSON.parse(new TextDecoder().decode(b64urlToBytes(parts[1])));
  } catch (e) { return null; }
  const now = Math.floor(Date.now() / 1000);
  if (header.alg !== 'RS256') return null;
  if (claims.aud !== projectId) return null;
  if (claims.iss !== 'https://securetoken.google.com/' + projectId) return null;
  if (!claims.sub || claims.exp <= now || (claims.iat && claims.iat > now + 300)) return null;
  const jwk = (await googleJwks()).find((k) => k.kid === header.kid);
  if (!jwk) return null;
  const key = await crypto.subtle.importKey('jwk', jwk,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key,
    b64urlToBytes(parts[2]), enc.encode(parts[0] + '.' + parts[1]));
  return ok ? claims : null;
}

async function isAdmin(claims, idToken, env) {
  if (claims.admin === true) return true;
  const url = 'https://firestore.googleapis.com/v1/projects/' + env.FIREBASE_PROJECT_ID +
    '/databases/(default)/documents/admins/' + encodeURIComponent(claims.sub);
  const r = await fetch(url, { headers: { Authorization: 'Bearer ' + idToken } });
  return r.status === 200;
}

/* ── AWS Signature V4, query-string presign (R2's S3 API) ──────────── */
const hex = (buf) => [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
async function sha256Hex(s) { return hex(await crypto.subtle.digest('SHA-256', enc.encode(s))); }
async function hmac(key, s) {
  const k = await crypto.subtle.importKey('raw', typeof key === 'string' ? enc.encode(key) : key,
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return crypto.subtle.sign('HMAC', k, enc.encode(s));
}
// RFC 3986 encoding, as SigV4 wants it.
const rfc3986 = (s) => encodeURIComponent(s).replace(/[!'()*]/g, (c) => '%' + c.charCodeAt(0).toString(16).toUpperCase());

async function presignPut({ accountId, bucket, accessKeyId, secret, key, expires = 900, now = new Date(), extraQuery = {} }) {
  const host = accountId + '.r2.cloudflarestorage.com';
  const region = 'auto';
  const service = 's3';
  const amzDate = now.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
  const day = amzDate.slice(0, 8);
  const scope = day + '/' + region + '/' + service + '/aws4_request';
  const path = '/' + bucket + '/' + key.split('/').map(rfc3986).join('/');
  const q = {
    'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
    'X-Amz-Content-Sha256': 'UNSIGNED-PAYLOAD',
    'X-Amz-Credential': accessKeyId + '/' + scope,
    'X-Amz-Date': amzDate,
    'X-Amz-Expires': String(expires),
    'X-Amz-SignedHeaders': 'host',
    ...extraQuery,
  };
  const query = Object.keys(q).sort().map((k) => rfc3986(k) + '=' + rfc3986(q[k])).join('&');
  const canonical = ['PUT', path, query, 'host:' + host + '\n', 'host', 'UNSIGNED-PAYLOAD'].join('\n');
  const toSign = ['AWS4-HMAC-SHA256', amzDate, scope, await sha256Hex(canonical)].join('\n');
  let k = await hmac('AWS4' + secret, day);
  k = await hmac(k, region);
  k = await hmac(k, service);
  k = await hmac(k, 'aws4_request');
  const sig = hex(await hmac(k, toSign));
  return 'https://' + host + path + '?' + query + '&X-Amz-Signature=' + sig;
}

/* ── What may be uploaded where ────────────────────────────────────── */
const AREAS = {
  ui: { prefix: 'ui', types: /^(image|video)\// },
  audio: { prefix: 'audio', types: /^audio\// },
  image: { prefix: 'images/words', types: /^image\// },
  // Word / request clips (admin word editor) and request voice notes.
  video: { prefix: 'video/words', types: /^video\// },
};
const cleanTarget = (s) => String(s || '').replace(/[^A-Za-z0-9._~-]/g, '-').replace(/-+/g, '-').slice(0, 180);

export async function onRequestPost(context) {
  const { request, env } = context;
  const missing = ['R2_ACCOUNT_ID', 'R2_BUCKET', 'R2_ACCESS_KEY_ID', 'R2_SECRET_ACCESS_KEY', 'R2_PUBLIC_BASE_URL', 'FIREBASE_PROJECT_ID']
    .filter((k) => !env[k]);
  if (missing.length) {
    return json({ error: 'Uploads are not switched on yet. Missing in Cloudflare Pages settings: ' + missing.join(', ') }, 501);
  }

  const auth = request.headers.get('Authorization') || '';
  if (!auth.startsWith('Bearer ')) return json({ error: 'Sign in first.' }, 401);
  const idToken = auth.slice(7);
  let claims;
  try { claims = await verifyIdToken(idToken, env.FIREBASE_PROJECT_ID); } catch (e) {
    return json({ error: 'Could not check the sign-in.' }, 503);
  }
  if (!claims) return json({ error: 'That sign-in is not valid.' }, 401);
  let admin = false;
  try { admin = await isAdmin(claims, idToken, env); } catch (e) { admin = false; }
  if (!admin) return json({ error: 'Not an admin.' }, 403);

  let body;
  try { body = await request.json(); } catch (e) { return json({ error: 'Send JSON.' }, 400); }
  const area = Object.hasOwn(AREAS, String(body.area || '')) ? AREAS[String(body.area)] : null;
  const target = cleanTarget(body.target);
  const ext = String(body.ext || '').toLowerCase().replace(/[^a-z0-9]/g, '').slice(0, 5);
  const type = String(body.contentType || '');
  if (!area) return json({ error: 'area must be ui, audio, image or video.' }, 400);
  if (!target || target === '.' || target === '..') return json({ error: 'target is required.' }, 400);
  if (!ext) return json({ error: 'ext is required.' }, 400);
  if (!area.types.test(type)) return json({ error: 'That file type is not allowed here.' }, 400);

  const key = area.prefix + '/' + target + '/' + Date.now() + '-' + crypto.randomUUID().slice(0, 8) + '.' + ext;
  const uploadUrl = await presignPut({
    accountId: env.R2_ACCOUNT_ID,
    bucket: env.R2_BUCKET,
    accessKeyId: env.R2_ACCESS_KEY_ID,
    secret: env.R2_SECRET_ACCESS_KEY,
    key,
  });
  const base = String(env.R2_PUBLIC_BASE_URL).replace(/\/+$/, '');
  return json({
    uploadUrl,
    publicUrl: base + '/' + key.split('/').map(encodeURIComponent).join('/'),
    key,
    expiresIn: 900,
    uid: claims.sub,
  });
}

export async function onRequest(context) {
  if (context.request.method === 'POST') return onRequestPost(context);
  return json({ error: 'POST only.' }, 405);
}
