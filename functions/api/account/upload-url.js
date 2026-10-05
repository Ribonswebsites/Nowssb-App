/* ══════════════════════════════════════════════════════════════════════
   POST /api/account/upload-url — signed-in user avatar upload to R2.

   Any signed-in (non-anonymous) Firebase user may request a one-time PUT
   URL for THEIR OWN avatar only. The object key is built here as
   users/{uid}/avatar/{uuid}.{ext} — the client never chooses an arbitrary
   key. Only jpeg/png/webp, max 5 MiB.

   Request   { contentType: 'image/jpeg'|'image/png'|'image/webp',
               ext?: 'jpg'|'jpeg'|'png'|'webp',
               contentLength?: number }   // bytes; rejected if > maxBytes
   Response  { uploadUrl, publicUrl, key, expiresIn, maxBytes }

   Cloudflare Pages env (same as admin upload-url — do not invent new secrets):
     R2_ACCOUNT_ID, R2_BUCKET, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY,
     R2_PUBLIC_BASE_URL, FIREBASE_PROJECT_ID
   ══════════════════════════════════════════════════════════════════════ */

import { cors, json, requireUser } from '../../_lib/server.js';
import { R2_VARS, presignPut, publicObjectUrl } from '../../_lib/r2_presign.js';

export const MAX_BYTES = 5 * 1024 * 1024;
export const EXPIRES_IN = 900;

/** contentType → preferred file extension. */
export const ALLOWED_IMAGE_TYPES = Object.freeze({
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
});

const EXT_ALIASES = Object.freeze({
  jpg: 'jpg',
  jpeg: 'jpg',
  png: 'png',
  webp: 'webp',
});

/** Pure: pick a safe extension from contentType + optional client hint. */
export function resolveImageExt(contentType, extHint) {
  const fromType = ALLOWED_IMAGE_TYPES[String(contentType || '').toLowerCase()];
  if (!fromType) return null;
  const hint = String(extHint || '').toLowerCase().replace(/[^a-z0-9]/g, '').slice(0, 5);
  if (!hint) return fromType;
  const mapped = EXT_ALIASES[hint];
  // Hint must agree with the content type family (jpeg↔jpg, etc.).
  if (!mapped || mapped !== fromType) return null;
  return mapped;
}

/**
 * Pure: build a user-owned avatar object key.
 * Always under users/{uid}/avatar/ — never accept a client-chosen path.
 */
export function buildAvatarKey(uid, ext, { uuid = crypto.randomUUID() } = {}) {
  const safeUid = String(uid || '').replace(/[^A-Za-z0-9_-]/g, '').slice(0, 128);
  const safeExt = String(ext || '').toLowerCase().replace(/[^a-z0-9]/g, '').slice(0, 5);
  if (!safeUid) throw new Error('uid required');
  if (!safeExt || !Object.values(EXT_ALIASES).includes(safeExt)) throw new Error('ext not allowed');
  const safeUuid = String(uuid).replace(/[^a-fA-F0-9-]/g, '').slice(0, 36) || crypto.randomUUID();
  return 'users/' + safeUid + '/avatar/' + safeUuid + '.' + safeExt;
}

/** True when the key is confined to this user's avatar prefix. */
export function isUserAvatarKey(key, uid) {
  const safeUid = String(uid || '').replace(/[^A-Za-z0-9_-]/g, '').slice(0, 128);
  if (!safeUid) return false;
  const prefix = 'users/' + safeUid + '/avatar/';
  return typeof key === 'string' && key.startsWith(prefix) && !key.includes('..') && key.indexOf('/', prefix.length) === -1;
}

function isAnonymous(claims) {
  const provider = claims && claims.firebase && claims.firebase.sign_in_provider;
  return provider === 'anonymous';
}

export async function onRequestOptions({ request }) {
  return new Response(null, { status: 204, headers: cors(request) });
}

export async function onRequestPost(context) {
  const { request, env } = context;
  const h = cors(request);

  const claims = await requireUser(request, env, h);
  if (claims instanceof Response) return claims;
  if (isAnonymous(claims)) {
    return json({ error: 'Sign in with a full account to upload a photo.' }, 403, h);
  }
  const uid = claims.sub;

  const missing = [...R2_VARS, 'FIREBASE_PROJECT_ID'].filter((k) => !env[k]);
  if (missing.length) {
    return json({
      error: 'Uploads are not switched on yet. Missing in Cloudflare Pages settings: ' + missing.join(', '),
    }, 501, h);
  }

  let body;
  try { body = await request.json(); } catch (e) {
    return json({ error: 'Send JSON.' }, 400, h);
  }

  const contentType = String(body.contentType || '').toLowerCase().trim();
  const ext = resolveImageExt(contentType, body.ext);
  if (!ext) {
    return json({ error: 'Only JPEG, PNG or WebP photos are allowed.', maxBytes: MAX_BYTES }, 400, h);
  }

  let contentLength = null;
  if (body.contentLength != null && body.contentLength !== '') {
    const n = Number(body.contentLength);
    if (!Number.isFinite(n) || n < 1 || Math.floor(n) !== n) {
      return json({ error: 'contentLength must be a positive whole number of bytes.', maxBytes: MAX_BYTES }, 400, h);
    }
    if (n > MAX_BYTES) {
      return json({ error: 'Photo is too large. Max size is 5 MB.', maxBytes: MAX_BYTES }, 400, h);
    }
    contentLength = n;
  }

  const key = buildAvatarKey(uid, ext);
  if (!isUserAvatarKey(key, uid)) {
    return json({ error: 'Could not build a safe upload path.' }, 500, h);
  }

  const signedHeaders = { 'content-type': contentType };
  if (contentLength != null) signedHeaders['content-length'] = String(contentLength);

  const uploadUrl = await presignPut({
    accountId: env.R2_ACCOUNT_ID,
    bucket: env.R2_BUCKET,
    accessKeyId: env.R2_ACCESS_KEY_ID,
    secret: env.R2_SECRET_ACCESS_KEY,
    key,
    expires: EXPIRES_IN,
    signedHeaders,
  });

  return json({
    uploadUrl,
    publicUrl: publicObjectUrl(env.R2_PUBLIC_BASE_URL, key),
    key,
    expiresIn: EXPIRES_IN,
    maxBytes: MAX_BYTES,
    uid,
  }, 200, h);
}

export async function onRequest(context) {
  if (context.request.method === 'OPTIONS') return onRequestOptions(context);
  if (context.request.method === 'POST') return onRequestPost(context);
  return json({ error: 'POST only.' }, 405, cors(context.request));
}
