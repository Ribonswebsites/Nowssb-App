/* ══════════════════════════════════════════════════════════════════════
   GET/POST /api/users — everyone who has actually signed up.

   Why this exists at all
   ----------------------
   The studio's People list read the Firestore `users` collection, and that
   is real data — but it is not the answer to "who signed up". A document
   under users/<uid> exists only because the app wrote one; an account that
   signed in and never got that far has no document, and `lastSeen` only
   exists for people who have opened the app since presence shipped, which
   is why so many rows said "never seen".

   The authoritative list is Firebase Authentication, and a browser cannot
   enumerate it — by design, or any page could scrape your users. It takes
   a service account, which means it takes a server, which is this.

   What it returns is Auth's own record: when the account was created, when
   it last signed in, which provider it used, whether it is disabled. Those
   are facts about signing up and signing in, not inferences from a
   document the app may or may not have written.

   Uses FCM_SERVICE_ACCOUNT — the same secret /api/push already needs, with
   a second scope. Nothing new to configure if push is already working.
   ══════════════════════════════════════════════════════════════════════ */

const enc = new TextEncoder();

const bytesToB64url = (bytes) => {
  let s = '';
  const b = new Uint8Array(bytes);
  for (let i = 0; i < b.length; i++) s += String.fromCharCode(b[i]);
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
};
const b64urlToBytes = (s) => {
  const b64 = (s + '='.repeat((4 - (s.length % 4)) % 4)).replace(/-/g, '+').replace(/_/g, '/');
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
};

function pemToPkcs8(pem) {
  const b64 = pem.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

/* ── A Google access token from the service account ──────────────────
   Same exchange /api/push does, with the identitytoolkit scope instead of
   firebase.messaging. Cached for the hour Google issues them for. ── */
let _tok = { at: 0, value: null };
async function accessToken(sa) {
  if (_tok.value && Date.now() - _tok.at < 3540e3) return _tok.value;
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT', kid: sa.private_key_id };
  const claims = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/identitytoolkit https://www.googleapis.com/auth/cloud-platform',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now, exp: now + 3600,
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
  const d = await r.json().catch(() => ({}));
  if (!r.ok || !d.access_token) throw new Error('auth: ' + (d.error_description || r.status));
  _tok = { at: Date.now(), value: d.access_token };
  return d.access_token;
}

/* ── Who is calling ──────────────────────────────────────────────────
   The same Firebase ID token check /api/push uses: RS256 against Google's
   published certificates, right audience, right issuer, not expired, then
   the uid has to be on the admin list. ── */
let _certCache = { at: 0, certs: null };
async function googleCerts() {
  if (_certCache.certs && Date.now() - _certCache.at < 3600e3) return _certCache.certs;
  const r = await fetch('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com');
  if (!r.ok) throw new Error('certs');
  const certs = await r.json();
  _certCache = { at: Date.now(), certs };
  return certs;
}
function extractSpkiFromCert(der) {
  const OID = [0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01];
  for (let i = 0; i < der.length - OID.length; i++) {
    let hit = true;
    for (let j = 0; j < OID.length; j++) if (der[i + j] !== OID[j]) { hit = false; break; }
    if (!hit) continue;
    for (let s = i; s >= 2; s--) {
      if (der[s] !== 0x30 || der[s + 1] !== 0x82) continue;
      const len = (der[s + 2] << 8) | der[s + 3];
      const end = s + 4 + len;
      if (end <= der.length && end - s > 200 && der[s + 4] === 0x30) return der.slice(s, end);
    }
  }
  return null;
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
  if (!claims.sub || claims.exp <= now) return null;

  const certs = await googleCerts();
  const pem = certs[header.kid];
  if (!pem) return null;
  const der = b64urlToBytes(pem.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '').replace(/\+/g, '-').replace(/\//g, '_'));
  const spki = extractSpkiFromCert(der);
  if (!spki) return null;
  const key = await crypto.subtle.importKey('spki', spki,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key,
    b64urlToBytes(parts[2]), enc.encode(parts[0] + '.' + parts[1]));
  return ok ? claims : null;
}

const json = (obj, status = 200) => new Response(JSON.stringify(obj), {
  status, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
});

async function handle(context) {
  const { request, env } = context;

  for (const k of ['ADMIN_UIDS', 'FIREBASE_PROJECT_ID']) {
    if (!env[k]) return json({ error: 'Server not configured: ' + k + ' is missing.' }, 500);
  }
  if (!env.FCM_SERVICE_ACCOUNT) {
    return json({ error: 'FCM_SERVICE_ACCOUNT is not set. Firebase console → Project settings → Service accounts → Generate new private key, then paste the whole JSON into the Cloudflare Pages environment variables.' }, 501);
  }

  const auth = request.headers.get('Authorization') || '';
  if (!auth.startsWith('Bearer ')) return json({ error: 'Sign in first.' }, 401);

  let claims;
  try { claims = await verifyIdToken(auth.slice(7), env.FIREBASE_PROJECT_ID); }
  catch (e) { return json({ error: 'Could not check the sign-in.' }, 503); }
  if (!claims) return json({ error: 'That sign-in is not valid.' }, 401);

  const admins = env.ADMIN_UIDS.split(',').map(s => s.trim()).filter(Boolean);
  if (!admins.includes(claims.sub)) return json({ error: 'Not an admin.' }, 403);

  let sa;
  try {
    sa = JSON.parse(env.FCM_SERVICE_ACCOUNT);
    if (!sa.private_key || !sa.client_email || !sa.project_id) throw new Error('missing fields');
  } catch (e) {
    return json({ error: 'FCM_SERVICE_ACCOUNT is not valid service-account JSON.' }, 500);
  }

  let token;
  try { token = await accessToken(sa); }
  catch (e) { return json({ error: String(e.message || e) }, 502); }

  /* accounts:batchGet pages 1000 at a time. Everything is returned — the
     studio decides what to show — but the page size is capped so a very
     large project cannot hang the request. */
  const out = [];
  let nextPageToken = '';
  for (let page = 0; page < 10; page++) {
    const url = 'https://identitytoolkit.googleapis.com/v1/projects/' + sa.project_id +
                '/accounts:batchGet?maxResults=1000' + (nextPageToken ? '&nextPageToken=' + encodeURIComponent(nextPageToken) : '');
    const r = await fetch(url, { headers: { Authorization: 'Bearer ' + token } });
    const d = await r.json().catch(() => ({}));
    if (!r.ok) return json({ error: (d.error && d.error.message) || ('identitytoolkit ' + r.status) }, 502);
    (d.users || []).forEach(u => {
      out.push({
        uid: u.localId,
        email: u.email || null,
        emailVerified: !!u.emailVerified,
        name: u.displayName || null,
        photo: u.photoUrl || null,
        phone: u.phoneNumber || null,
        /* Auth reports these in milliseconds, as strings. */
        createdAt: u.createdAt ? Number(u.createdAt) : null,
        lastLoginAt: u.lastLoginAt ? Number(u.lastLoginAt) : null,
        lastRefreshAt: u.lastRefreshAt ? Date.parse(u.lastRefreshAt) || null : null,
        disabled: !!u.disabled,
        providers: (u.providerUserInfo || []).map(p => p.providerId),
      });
    });
    nextPageToken = d.nextPageToken || '';
    if (!nextPageToken) break;
  }

  out.sort((a, b) => (b.lastLoginAt || b.createdAt || 0) - (a.lastLoginAt || a.createdAt || 0));
  return json({ count: out.length, users: out });
}

export const onRequestGet = handle;
export const onRequestPost = handle;
export async function onRequest(context) {
  const m = context.request.method;
  if (m === 'GET' || m === 'POST') return handle(context);
  return json({ error: 'GET or POST only.' }, 405);
}
