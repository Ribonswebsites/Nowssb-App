/* Shared helpers for Pages Functions (not a route: no onRequest exports).
   Firebase ID-token check, Google OIDC check, a Google access token from a
   service account, Firestore REST, SHA-256/HMAC, JSON + CORS. WebCrypto only —
   no dependencies. */

export const enc = new TextEncoder();

const ALLOWED_ORIGINS = [
  'https://nowssb.com', 'https://www.nowssb.com', 'https://ribonswebsites.github.io',
  'capacitor://localhost', 'https://localhost', 'http://localhost',
];
export function cors(request) {
  const o = request.headers.get('Origin') || '';
  const ok = ALLOWED_ORIGINS.includes(o) || /^http:\/\/localhost(:\d+)?$/.test(o) || /\.pages\.dev$/.test(o);
  return ok ? {
    'Access-Control-Allow-Origin': o,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  } : {};
}
export const json = (obj, status = 200, extra = {}) => new Response(JSON.stringify(obj), {
  status,
  headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', ...extra },
});

export const bytesToB64url = (bytes) => {
  let s = '';
  const b = new Uint8Array(bytes);
  for (let i = 0; i < b.length; i++) s += String.fromCharCode(b[i]);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
};
export const b64urlToBytes = (s) => {
  const b64 = (s + '='.repeat((4 - (s.length % 4)) % 4)).replace(/-/g, '+').replace(/_/g, '/');
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
};
export const hex = (buf) => [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');

export async function hmacHex(secret, message) {
  const k = await crypto.subtle.importKey('raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return hex(await crypto.subtle.sign('HMAC', k, enc.encode(message)));
}
/** Constant-time compare of two hex/ASCII strings. */
export function safeEqual(a, b) {
  a = String(a || ''); b = String(b || '');
  if (a.length !== b.length || !a.length) return false;
  let d = 0;
  for (let i = 0; i < a.length; i++) d |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return d === 0;
}

/* ── Firebase ID token (RS256 against Google's securetoken JWKs) ── */
let _jwks = { at: 0, keys: null };
async function googleJwks() {
  if (_jwks.keys && Date.now() - _jwks.at < 3600e3) return _jwks.keys;
  const r = await fetch('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com');
  if (!r.ok) throw new Error('jwks ' + r.status);
  _jwks = { at: Date.now(), keys: (await r.json()).keys || [] };
  return _jwks.keys;
}
export async function verifyIdToken(token, projectId) {
  const parts = String(token || '').split('.');
  if (parts.length !== 3) return null;
  let header, claims;
  try {
    header = JSON.parse(new TextDecoder().decode(b64urlToBytes(parts[0])));
    claims = JSON.parse(new TextDecoder().decode(b64urlToBytes(parts[1])));
  } catch (e) { return null; }
  const now = Math.floor(Date.now() / 1000);
  if (header.alg !== 'RS256' || claims.aud !== projectId) return null;
  if (claims.iss !== 'https://securetoken.google.com/' + projectId) return null;
  if (!claims.sub || claims.exp <= now || (claims.iat && claims.iat > now + 300)) return null;
  const jwk = (await googleJwks()).find((k) => k.kid === header.kid);
  if (!jwk) return null;
  const key = await crypto.subtle.importKey('jwk', jwk, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, b64urlToBytes(parts[2]), enc.encode(parts[0] + '.' + parts[1]));
  return ok ? claims : null;
}
/* ── Google-signed OIDC token (e.g. a Pub/Sub push) ── */
let _gcerts = { at: 0, keys: null };
async function googleOidcJwks() {
  if (_gcerts.keys && Date.now() - _gcerts.at < 3600e3) return _gcerts.keys;
  const r = await fetch('https://www.googleapis.com/oauth2/v3/certs');
  if (!r.ok) throw new Error('certs ' + r.status);
  _gcerts = { at: Date.now(), keys: (await r.json()).keys || [] };
  return _gcerts.keys;
}
/** Verifies an RS256 Google OIDC token; returns claims when aud matches. */
export async function verifyGoogleOidc(token, audience) {
  const parts = String(token || '').split('.');
  if (parts.length !== 3) return null;
  let header, claims;
  try {
    header = JSON.parse(new TextDecoder().decode(b64urlToBytes(parts[0])));
    claims = JSON.parse(new TextDecoder().decode(b64urlToBytes(parts[1])));
  } catch (e) { return null; }
  const now = Math.floor(Date.now() / 1000);
  if (header.alg !== 'RS256' || claims.aud !== audience) return null;
  if (claims.iss !== 'https://accounts.google.com' && claims.iss !== 'accounts.google.com') return null;
  if (!claims.exp || claims.exp <= now) return null;
  const jwk = (await googleOidcJwks()).find((k) => k.kid === header.kid);
  if (!jwk) return null;
  const key = await crypto.subtle.importKey('jwk', jwk, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, b64urlToBytes(parts[2]), enc.encode(parts[0] + '.' + parts[1]));
  return ok ? claims : null;
}

/** Returns claims, or a Response to send back. */
export async function requireUser(request, env, headers = {}) {
  const auth = request.headers.get('Authorization') || '';
  if (!auth.startsWith('Bearer ')) return json({ error: 'Sign in first.' }, 401, headers);
  let claims;
  try { claims = await verifyIdToken(auth.slice(7), env.FIREBASE_PROJECT_ID); } catch (e) {
    return json({ error: 'Could not check the sign-in.' }, 503, headers);
  }
  if (!claims) return json({ error: 'That sign-in is not valid. Sign in again.' }, 401, headers);
  return claims;
}

/* ── Service account → Google access token ── */
export function parseServiceAccount(raw) {
  if (!raw) return null;
  try {
    const sa = typeof raw === 'string' ? JSON.parse(raw) : raw;
    return sa && sa.private_key && sa.client_email ? sa : null;
  } catch (e) { return null; }
}
/** Firebase Admin service account (Firestore REST). FCM_SERVICE_ACCOUNT is
    accepted when it holds the same kind of JSON. */
export function serviceAccount(env) {
  return parseServiceAccount(env.FIREBASE_SERVICE_ACCOUNT) || parseServiceAccount(env.FCM_SERVICE_ACCOUNT);
}
function pemToPkcs8(pem) {
  const bin = atob(pem.replace(/-----[^-]+-----/g, '').replace(/\s+/g, ''));
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}
export const SCOPE_FIRESTORE = 'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/cloud-platform';
export const SCOPE_ANDROIDPUBLISHER = 'https://www.googleapis.com/auth/androidpublisher';
const _toks = new Map();
/** OAuth access token for a service account (JWT bearer flow), cached per
    account + scope for just under an hour. Never logs key material. */
export async function googleToken(sa, scope = SCOPE_FIRESTORE) {
  const cacheKey = sa.client_email + ' ' + scope;
  const hit = _toks.get(cacheKey);
  if (hit && Date.now() - hit.at < 3540e3) return hit.value;
  const now = Math.floor(Date.now() / 1000);
  const head = bytesToB64url(enc.encode(JSON.stringify({ alg: 'RS256', typ: 'JWT', kid: sa.private_key_id })));
  const body = bytesToB64url(enc.encode(JSON.stringify({
    iss: sa.client_email, sub: sa.client_email, aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 3600, scope,
  })));
  const key = await crypto.subtle.importKey('pkcs8', pemToPkcs8(sa.private_key), { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, enc.encode(head + '.' + body));
  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' + head + '.' + body + '.' + bytesToB64url(sig),
  });
  const d = await r.json().catch(() => ({}));
  if (!r.ok || !d.access_token) throw new Error('google auth failed (' + r.status + ')');
  _toks.set(cacheKey, { at: Date.now(), value: d.access_token });
  return d.access_token;
}

export async function sha256Hex(text) {
  return hex(await crypto.subtle.digest('SHA-256', enc.encode(String(text))));
}

/* ── Firestore REST ── */
export function fsValue(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(fsValue) } };
  if (typeof v === 'object') return { mapValue: { fields: fsFields(v) } };
  return { stringValue: String(v) };
}
export function fsFields(obj) {
  const out = {};
  for (const [k, v] of Object.entries(obj)) out[k] = fsValue(v);
  return out;
}
export function fsPlain(value) {
  if (!value) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('timestampValue' in value) return value.timestampValue;
  if ('nullValue' in value) return null;
  if ('arrayValue' in value) return (value.arrayValue.values || []).map(fsPlain);
  if ('mapValue' in value) {
    const o = {};
    for (const [k, v] of Object.entries(value.mapValue.fields || {})) o[k] = fsPlain(v);
    return o;
  }
  return null;
}
export const fsBase = (project) => `projects/${project}/databases/(default)/documents`;
export async function fsGet(token, project, path) {
  const r = await fetch(`https://firestore.googleapis.com/v1/${fsBase(project)}/${path}`, { headers: { Authorization: 'Bearer ' + token } });
  if (r.status === 404) return null;
  if (!r.ok) throw new Error('firestore get ' + r.status);
  const d = await r.json();
  return fsPlain({ mapValue: { fields: d.fields || {} } });
}
/** Atomic batch. Returns { ok, status, error }. */
export async function fsCommit(token, project, writes) {
  const r = await fetch(`https://firestore.googleapis.com/v1/${fsBase(project)}:commit`, {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' },
    body: JSON.stringify({ writes }),
  });
  const d = await r.json().catch(() => ({}));
  return { ok: r.ok, status: r.status, error: d.error };
}
/** Structured query on one collection; returns [{ name, data }]. */
export async function fsQuery(token, project, collectionId, where, limit = 5) {
  const r = await fetch(`https://firestore.googleapis.com/v1/${fsBase(project)}:runQuery`, {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' },
    body: JSON.stringify({ structuredQuery: { from: [{ collectionId }], where, limit } }),
  });
  if (!r.ok) throw new Error('firestore query ' + r.status);
  const rows = await r.json();
  return (rows || []).filter((x) => x.document).map((x) => ({
    name: x.document.name,
    data: fsPlain({ mapValue: { fields: x.document.fields || {} } }),
  }));
}
