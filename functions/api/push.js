/* ══════════════════════════════════════════════════════════════════════
   POST /api/push — send a notification to subscribed phones.

   Cloudflare Pages Function, living beside _middleware.js because that is
   where this site's server side already is. Nothing about it is Firebase
   Cloud Functions; the app is hosted on Pages.

   Why this exists
   ---------------
   A phone with the app closed can only be woken by a push, and a push is
   only accepted if it is signed by the key pair the subscription was made
   against. app/js/part068.js holds the public half and subscribes with it.
   This holds the private half and does the signing. It never appears in
   anything the browser downloads.

   What it does, in order
   ----------------------
   1. Checks the caller is one of your admins — a real Firebase ID token,
      signature verified against Google's public certificates, then the uid
      looked up at Firestore admins/{uid} (or the admin claim) — the same
      list /api/admin/* uses. A stolen page cannot fake this.
   1b. Works out who gets it on the server (pushSubs; one uid, or everyone
      except admins). The caller never supplies the subscription list.
   2. Encrypts the message separately for every subscription (RFC 8291:
      ECDH to the phone's key, HKDF, AES-128-GCM).
   3. Signs a VAPID token per push service (RFC 8292) and POSTs.
   4. Reports back per subscription, and says which ones the push service
      has retired so they can be deleted.

   Secrets — set with `wrangler pages secret put NAME`, or in the Cloudflare
   dashboard under Settings → Environment variables (encrypted):

     VAPID_PRIVATE_KEY   the private half, base64url, from the same Firebase
                         console screen the public half came from
     VAPID_PUBLIC_KEY    the public half (also in part068.js — not a secret,
                         it lives here so the two can never drift apart)
     VAPID_SUBJECT       mailto:you@nowssb.com — push services want a way to
                         contact whoever is sending
     FIREBASE_SERVICE_ACCOUNT  reads admins/ and pushSubs (required)
     FIREBASE_PROJECT_ID nowssb-34f1b

   And one more, only needed once the Android app ships (see CAPACITOR.md):

     FCM_SERVICE_ACCOUNT the whole service-account JSON, pasted as one line.
                         Firebase console → Project settings → Service
                         accounts → Generate new private key. Without it the
                         web half below still works exactly as before and
                         Android subscriptions simply report as unsent.

   Android and the web take different routes for the same reason phones and
   browsers are different things: the shipped app has no push service and no
   service worker, so it is reached through FCM with a token instead of
   through a push endpoint with a key. Both live in the same pushSubs
   collection and both are sent from this one call.
   ══════════════════════════════════════════════════════════════════════ */

import { categoryFor, fcmMessage } from '../_lib/notify/push.js';
import { googleToken, serviceAccount } from '../_lib/server.js';
import { restStore } from '../_lib/admin_store.js';

const enc = new TextEncoder();

/* ── small helpers ───────────────────────────────────────────────────── */
const b64urlToBytes = (s) => {
  const b64 = (s + '='.repeat((4 - (s.length % 4)) % 4)).replace(/-/g, '+').replace(/_/g, '/');
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
};
const bytesToB64url = (bytes) => {
  let s = '';
  const b = new Uint8Array(bytes);
  for (let i = 0; i < b.length; i++) s += String.fromCharCode(b[i]);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
};
const concat = (...arrs) => {
  const len = arrs.reduce((n, a) => n + a.length, 0);
  const out = new Uint8Array(len);
  let o = 0;
  for (const a of arrs) { out.set(a, o); o += a.length; }
  return out;
};

async function hmac(keyBytes, data) {
  const k = await crypto.subtle.importKey('raw', keyBytes, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return new Uint8Array(await crypto.subtle.sign('HMAC', k, data));
}
/* HKDF, the two halves written out rather than via deriveBits, because the
   info strings here are exact byte sequences the spec pins down. */
const hkdfExtract = (salt, ikm) => hmac(salt, ikm);
async function hkdfExpand(prk, info, length) {
  const t = await hmac(prk, concat(info, new Uint8Array([1])));
  return t.slice(0, length);
}

/* ── RFC 8291 — encrypting the payload for one subscription ──────────── */
async function encryptPayload(plaintext, p256dhB64, authB64) {
  const uaPublic = b64urlToBytes(p256dhB64);       // the phone's public key, 65 bytes
  const authSecret = b64urlToBytes(authB64);        // 16 bytes

  /* A fresh key pair per message — the sender half of the exchange. */
  const asKeys = await crypto.subtle.generateKey({ name: 'ECDH', namedCurve: 'P-256' }, true, ['deriveBits']);
  const asPublic = new Uint8Array(await crypto.subtle.exportKey('raw', asKeys.publicKey)); // 65 bytes

  const uaKey = await crypto.subtle.importKey('raw', uaPublic, { name: 'ECDH', namedCurve: 'P-256' }, false, []);
  const shared = new Uint8Array(await crypto.subtle.deriveBits({ name: 'ECDH', public: uaKey }, asKeys.privateKey, 256));

  /* The auth secret is the salt for the first stage; the second binds the
     result to both public keys so it cannot be replayed at anyone else. */
  const prkCombine = await hkdfExtract(authSecret, shared);
  const keyInfo = concat(enc.encode('WebPush: info\0'), uaPublic, asPublic);
  const ikm = await hkdfExpand(prkCombine, keyInfo, 32);

  const salt = crypto.getRandomValues(new Uint8Array(16));
  const prk = await hkdfExtract(salt, ikm);
  const cek = await hkdfExpand(prk, enc.encode('Content-Encoding: aes128gcm\0'), 16);
  const nonce = await hkdfExpand(prk, enc.encode('Content-Encoding: nonce\0'), 12);

  /* 0x02 marks the last record. Everything here is a single record. */
  const padded = concat(enc.encode(plaintext), new Uint8Array([2]));
  const aesKey = await crypto.subtle.importKey('raw', cek, { name: 'AES-GCM' }, false, ['encrypt']);
  const ciphertext = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce }, aesKey, padded));

  /* Header, per RFC 8188: salt | record size | key length | key. */
  const rs = new Uint8Array(4);
  new DataView(rs.buffer).setUint32(0, 4096);
  return concat(salt, rs, new Uint8Array([asPublic.length]), asPublic, ciphertext);
}

/* ── RFC 8292 — the VAPID token that says who is sending ─────────────── */
async function vapidAuth(endpoint, publicKeyB64, privateKeyB64, subject) {
  const aud = new URL(endpoint).origin;
  const header = { typ: 'JWT', alg: 'ES256' };
  const payload = { aud, exp: Math.floor(Date.now() / 1000) + 12 * 3600, sub: subject };
  const signingInput = bytesToB64url(enc.encode(JSON.stringify(header))) + '.' +
                       bytesToB64url(enc.encode(JSON.stringify(payload)));

  /* The private key arrives as the bare 32-byte scalar; Web Crypto wants a
     JWK, and x and y come out of the public key we already have. */
  const pub = b64urlToBytes(publicKeyB64);
  const jwk = {
    kty: 'EC', crv: 'P-256', ext: true,
    d: privateKeyB64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, ''),
    x: bytesToB64url(pub.slice(1, 33)),
    y: bytesToB64url(pub.slice(33, 65)),
  };
  const key = await crypto.subtle.importKey('jwk', jwk, { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign']);
  const sig = new Uint8Array(await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' }, key, enc.encode(signingInput)));

  return 'vapid t=' + signingInput + '.' + bytesToB64url(sig) + ', k=' + publicKeyB64;
}

/* ── Who is calling ──────────────────────────────────────────────────
   A Firebase ID token, verified properly: RS256 against Google's published
   certificates, right audience, right issuer, not expired. Then the uid has
   to be on the admin list. ── */
let _certCache = { at: 0, certs: null };
async function googleCerts() {
  if (_certCache.certs && Date.now() - _certCache.at < 3600e3) return _certCache.certs;
  const r = await fetch('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com');
  if (!r.ok) throw new Error('certs');
  const certs = await r.json();
  _certCache = { at: Date.now(), certs };
  return certs;
}
function pemToDer(pem) {
  return b64urlToBytes(pem.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '').replace(/\+/g, '-').replace(/\//g, '_'));
}
async function verifyIdToken(token, projectId) {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  /* A token we cannot even parse is a bad token, not a broken server —
     say 401, not 503. */
  let header, claims;
  try {
    header = JSON.parse(new TextDecoder().decode(b64urlToBytes(parts[0])));
    claims = JSON.parse(new TextDecoder().decode(b64urlToBytes(parts[1])));
  } catch (e) { return null; }
  const now = Math.floor(Date.now() / 1000);

  if (header.alg !== 'RS256') return null;
  if (claims.aud !== projectId) return null;
  if (claims.iss !== 'https://securetoken.google.com/' + projectId) return null;
  if (!claims.sub || claims.exp <= now) return null;

  const certs = await googleCerts();
  const pem = certs[header.kid];
  if (!pem) return null;

  /* The cert is X.509; the key inside it is what verifies the signature. */
  const der = pemToDer(pem);
  const spki = extractSpkiFromCert(der);
  if (!spki) return null;
  const key = await crypto.subtle.importKey('spki', spki,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key,
    b64urlToBytes(parts[2]), enc.encode(parts[0] + '.' + parts[1]));
  return ok ? claims : null;
}
/* Walk the certificate's DER far enough to find the SubjectPublicKeyInfo —
   it is the first SEQUENCE whose first element is the RSA algorithm OID. */
function extractSpkiFromCert(der) {
  const OID = [0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01]; // rsaEncryption
  for (let i = 0; i < der.length - OID.length; i++) {
    let hit = true;
    for (let j = 0; j < OID.length; j++) if (der[i + j] !== OID[j]) { hit = false; break; }
    if (!hit) continue;
    /* Back up to the SEQUENCE that opens the AlgorithmIdentifier, then to
       the one that wraps it and the key: both are 0x30 with a long form. */
    for (let s = i; s >= 2; s--) {
      if (der[s] !== 0x30 || der[s + 1] !== 0x82) continue;
      const len = (der[s + 2] << 8) | der[s + 3];
      const end = s + 4 + len;
      if (end <= der.length && end - s > 200 && der[s + 4] === 0x30) return der.slice(s, end);
    }
  }
  return null;
}

/* ── FCM, for the Android app ────────────────────────────────────────
   The shipped app has no push endpoint and no keys, so none of the RFC 8291
   work above applies to it. It has an FCM token, and FCM's HTTP v1 API wants
   an OAuth access token, which is a service-account JWT exchanged at
   Google's token endpoint. That is the whole of the difference. ── */
function pemToPkcs8(pem) {
  const b64 = pem.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

let _fcmToken = { at: 0, value: null };
async function fcmAccessToken(sa) {
  /* Google issues these for an hour; re-mint a minute early rather than
     racing the expiry. */
  if (_fcmToken.value && Date.now() - _fcmToken.at < 3540e3) return _fcmToken.value;

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT', kid: sa.private_key_id };
  const claims = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };
  const signingInput = bytesToB64url(enc.encode(JSON.stringify(header))) + '.' +
                       bytesToB64url(enc.encode(JSON.stringify(claims)));
  const key = await crypto.subtle.importKey('pkcs8', pemToPkcs8(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const sig = new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, enc.encode(signingInput)));
  const jwt = signingInput + '.' + bytesToB64url(sig);

  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' + encodeURIComponent(jwt),
  });
  const data = await r.json().catch(() => ({}));
  if (!r.ok || !data.access_token) throw new Error('fcm auth: ' + (data.error_description || r.status));
  _fcmToken = { at: Date.now(), value: data.access_token };
  return data.access_token;
}

async function sendFcm(sa, token, msg) {
  const access = await fcmAccessToken(sa);
  const r = await fetch('https://fcm.googleapis.com/v1/projects/' + sa.project_id + '/messages:send', {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + access, 'Content-Type': 'application/json' },
    /* Phones that registered with notifFormat 2 (the current app) get a
       data-only message (functions/_lib/notify/push.js): the app draws one
       notification on the category's channel, honours the person's switches
       and quiet hours, and opens the right screen on tap. Older installs keep
       the notification block they were built for. */
    body: JSON.stringify(fcmMessage(token, (() => {
      const c = categoryFor(msg.type || 'broadcast');
      return { cat: c.cat, type: String(msg.type || 'broadcast'), title: msg.title, body: msg.body, route: c.route, promo: c.promo };
    })(), { legacy: Number(msg.notifFormat) !== 2 })),
  });
  const text = await r.text().catch(() => '');
  /* UNREGISTERED / INVALID_ARGUMENT on the token mean the app was
     uninstalled or the token rotated — the same "delete this one" the web
     side signals with 404/410. */
  const dead = r.status === 404 || /UNREGISTERED|NOT_FOUND/i.test(text);
  return { ok: r.ok, status: r.status, expired: dead, error: r.ok ? undefined : text.slice(0, 200) };
}

/* ── the endpoint ────────────────────────────────────────────────────── */
const json = (obj, status = 200) => new Response(JSON.stringify(obj), {
  status, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
});

export async function onRequestPost(context) {
  const { request } = context;
  const env = { ...(context.env || {}), FIREBASE_PROJECT_ID: (context.env && context.env.FIREBASE_PROJECT_ID) || 'nowssb-34f1b' };

  /* One list of admins for the whole site: Firestore admins/{uid} (or the
     admin custom claim) — the same check /api/admin/* makes. Reading it, and
     the subscriptions, needs the service account. */
  const sa = serviceAccount(env);
  if (!sa) return json({ error: 'Server not configured: FIREBASE_SERVICE_ACCOUNT is missing.', missing: ['FIREBASE_SERVICE_ACCOUNT'] }, 501);

  const auth = request.headers.get('Authorization') || '';
  if (!auth.startsWith('Bearer ')) return json({ error: 'Sign in first.' }, 401);

  let claims;
  try { claims = await verifyIdToken(auth.slice(7), env.FIREBASE_PROJECT_ID); }
  catch (e) { return json({ error: 'Could not check the sign-in.' }, 503); }
  if (!claims) return json({ error: 'That sign-in is not valid.' }, 401);

  let db;
  try { db = restStore(await googleToken(sa), env.FIREBASE_PROJECT_ID); }
  catch (e) { return json({ error: 'Could not reach Firestore.' }, 502); }
  let isAdmin = claims.admin === true;
  if (!isAdmin) { try { isAdmin = !!(await db.get('admins/' + claims.sub)); } catch (e) { isAdmin = false; } }
  if (!isAdmin) return json({ error: 'Not an admin.' }, 403);

  let body;
  try { body = await request.json(); } catch (e) { return json({ error: 'Expected JSON.' }, 400); }
  const title = String((body && body.title) || '').slice(0, 120);
  if (!title) return json({ error: 'A title is required.' }, 400);

  /* Targets are worked out here, never taken from the caller: one person
     (body.uid), or every subscribed phone except the admins' own. */
  const uid = typeof body.uid === 'string' && /^[A-Za-z0-9_-]{6,128}$/.test(body.uid) ? body.uid : '';
  let rows;
  try {
    rows = uid
      ? await db.query({ collection: 'pushSubs', where: [['uid', '==', uid]], limit: 20 })
      : await db.query({ collection: 'pushSubs', limit: 5000 });
  } catch (e) { return json({ error: 'Could not read the subscriptions.' }, 502); }
  const admins = uid ? new Set() : new Set((await db.query({ collection: 'admins', limit: 300 }).catch(() => [])).map((r) => r.id));
  let skippedAdmins = 0;
  const subscriptions = [];
  for (const r of rows) {
    const v = r.data || {};
    if (v.uid && admins.has(v.uid)) { skippedAdmins++; continue; }
    if (v.fcmToken) subscriptions.push({ path: r.path, endpoint: 'fcm:' + v.fcmToken, fcmToken: v.fcmToken, notifFormat: v.notifFormat });
    else if (v.endpoint && v.keys) subscriptions.push({ path: r.path, endpoint: v.endpoint, keys: v.keys });
  }
  if (!subscriptions.length) return json({ sent: 0, failed: 0, expired: [], skippedAdmins, total: 0, results: [] });

  const vapid = !!(env.VAPID_PRIVATE_KEY && env.VAPID_PUBLIC_KEY && env.VAPID_SUBJECT);

  /* What the phone receives — sw.js reads exactly these fields. */
  const payload = JSON.stringify({
    title,
    body: body.body || '',
    type: body.type || '',
    url: body.url || './',
  });

  /* Parsed once, not once per subscription. */
  let fcmSa = null, saError = null;
  const rawFcm = env.FCM_SERVICE_ACCOUNT || env.FIREBASE_SERVICE_ACCOUNT;
  if (rawFcm) {
    try {
      fcmSa = JSON.parse(rawFcm);
      if (!fcmSa.private_key || !fcmSa.client_email || !fcmSa.project_id) throw new Error('missing fields');
    } catch (e) { fcmSa = null; saError = 'FCM_SERVICE_ACCOUNT is not valid service-account JSON.'; }
  }

  const results = await Promise.all(subscriptions.map(async (sub) => {
    const endpoint = sub.endpoint;

    /* The Android app, reached through FCM rather than a push service. */
    if (sub.fcmToken) {
      if (!fcmSa) return { endpoint, path: sub.path, ok: false, error: saError || 'FCM_SERVICE_ACCOUNT is not set.' };
      try {
        const r = await sendFcm(fcmSa, sub.fcmToken, { title, body: body.body || '', type: body.type, url: body.url, notifFormat: sub.notifFormat });
        return { endpoint, path: sub.path, ...r };
      } catch (e) {
        return { endpoint, path: sub.path, ok: false, error: String(e && e.message || e).slice(0, 200) };
      }
    }

    if (!vapid) return { endpoint, path: sub.path, ok: false, error: 'VAPID keys are not set.' };
    try {
      const cipher = await encryptPayload(payload, sub.keys.p256dh, sub.keys.auth);
      const authHeader = await vapidAuth(endpoint, env.VAPID_PUBLIC_KEY, env.VAPID_PRIVATE_KEY, env.VAPID_SUBJECT);
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: {
          Authorization: authHeader,
          'Content-Encoding': 'aes128gcm',
          'Content-Type': 'application/octet-stream',
          TTL: String(body.ttl || 86400),
          Urgency: body.urgency || 'normal',
        },
        body: cipher,
      });
      /* 404/410 mean the push service has retired this subscription. */
      return {
        endpoint, path: sub.path, ok: res.ok, status: res.status,
        expired: res.status === 404 || res.status === 410,
        error: res.ok ? undefined : (await res.text().catch(() => '')).slice(0, 200),
      };
    } catch (e) {
      return { endpoint, path: sub.path, ok: false, error: String(e && e.message || e).slice(0, 200) };
    }
  }));

  /* Retired subscriptions are removed here, so the list never goes stale. */
  const dead = results.filter((r) => r.expired && r.path);
  if (dead.length) await db.commit(dead.map((r) => ({ op: 'delete', path: r.path }))).catch(() => {});

  return json({
    sent: results.filter(r => r.ok).length,
    failed: results.filter(r => !r.ok).length,
    expired: dead.map(r => r.endpoint),
    removed: dead.length,
    skippedAdmins,
    total: subscriptions.length,
    results: results.map(({ path, ...r }) => r),
  });
}

/* Anything other than POST has no business here. */
export async function onRequest(context) {
  if (context.request.method === 'POST') return onRequestPost(context);
  return json({ error: 'POST only.' }, 405);
}
