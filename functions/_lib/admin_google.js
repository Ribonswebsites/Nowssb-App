/* Google + R2 calls the admin console needs, all from a service account
   held only in Cloudflare (never on a phone):
     · Firebase Auth admin REST (Identity Toolkit): list / look up / count
       accounts, disable or enable one.
     · FCM HTTP v1: one push to one device token.
     · Cloudflare R2 (S3 API, SigV4): list objects under a prefix.
   Nothing here logs or returns key material. */
import { enc, googleToken, hex } from './server.js';

export const SCOPE_AUTH = 'https://www.googleapis.com/auth/identitytoolkit https://www.googleapis.com/auth/cloud-platform';
export const SCOPE_FCM = 'https://www.googleapis.com/auth/firebase.messaging';
const IDT = 'https://identitytoolkit.googleapis.com/v1/projects/';

/** Plain user row from an Identity Toolkit record. */
export function authRow(u) {
  return {
    uid: u.localId,
    email: u.email || '',
    name: u.displayName || '',
    phone: u.phoneNumber || '',
    photo: u.photoUrl || '',
    providers: (u.providerUserInfo || []).map((p) => p.providerId).filter(Boolean),
    createdAt: Number(u.createdAt || 0),
    lastLoginAt: Number(u.lastLoginAt || 0),
    lastRefreshAt: u.lastRefreshAt ? Date.parse(u.lastRefreshAt) || 0 : 0,
    disabled: !!u.disabled,
    emailVerified: !!u.emailVerified,
  };
}

export function authAdmin(sa, project, fetchImpl = (...a) => fetch(...a)) {
  const tok = () => googleToken(sa, SCOPE_AUTH);
  async function call(path, body, method = 'POST') {
    const r = await fetchImpl(IDT + project + path, {
      method,
      headers: { Authorization: 'Bearer ' + (await tok()), 'Content-Type': 'application/json' },
      body: method === 'GET' ? undefined : JSON.stringify(body || {}),
    });
    const d = await r.json().catch(() => ({}));
    if (!r.ok) {
      const e = new Error('auth ' + r.status + ' ' + ((d.error && d.error.message) || ''));
      e.status = r.status;
      throw e;
    }
    return d;
  }
  return {
    async lookup(uids) {
      const out = [];
      for (let i = 0; i < uids.length; i += 100) {
        const d = await call('/accounts:lookup', { localId: uids.slice(i, i + 100) });
        out.push(...(d.users || []).map(authRow));
      }
      return out;
    },
    async page(pageToken = '', max = 1000) {
      const q = '?maxResults=' + max + (pageToken ? '&nextPageToken=' + encodeURIComponent(pageToken) : '');
      const d = await call('/accounts:batchGet' + q, null, 'GET');
      return { users: (d.users || []).map(authRow), next: d.nextPageToken || '' };
    },
    /** Every account, up to maxPages × 1000. */
    async all(maxPages = 5) {
      const users = [];
      let next = '';
      let truncated = false;
      for (let i = 0; i < maxPages; i++) {
        const p = await this.page(next);
        users.push(...p.users);
        next = p.next;
        if (!next) break;
        if (i === maxPages - 1) truncated = true;
      }
      return { users, truncated };
    },
    async count() {
      const d = await call('/accounts:query', { returnUserInfo: false });
      return Number(d.recordsCount || 0);
    },
    async setDisabled(uid, disabled) {
      await call('/accounts:update', { localId: uid, disableUser: !!disabled });
      return true;
    },
  };
}

/** One FCM HTTP v1 message to a device token. */
export async function fcmSend(sa, token, msg, fetchImpl = (...a) => fetch(...a)) {
  const access = await googleToken(sa, SCOPE_FCM);
  const r = await fetchImpl('https://fcm.googleapis.com/v1/projects/' + sa.project_id + '/messages:send', {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + access, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: {
        token,
        notification: { title: String(msg.title || ''), body: String(msg.body || '') },
        data: { type: String(msg.type || 'admin'), url: String(msg.url || ''), route: String(msg.route || '') },
        android: { priority: 'HIGH', notification: { channel_id: 'nowssb', color: '#e8d5a3' } },
      },
    }),
  });
  const text = await r.text().catch(() => '');
  const dead = r.status === 404 || /UNREGISTERED|registration-token-not-registered/i.test(text);
  return { ok: r.ok, status: r.status, expired: dead };
}

/* ── R2 (S3 API) — list objects ── */
const rfc3986 = (s) => encodeURIComponent(s).replace(/[!'()*]/g, (c) => '%' + c.charCodeAt(0).toString(16).toUpperCase());
async function hmac(key, s) {
  const k = await crypto.subtle.importKey('raw', typeof key === 'string' ? enc.encode(key) : key, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return crypto.subtle.sign('HMAC', k, enc.encode(s));
}
const sha256Hex = async (s) => hex(await crypto.subtle.digest('SHA-256', enc.encode(s)));

export async function presign({ method = 'GET', accountId, bucket, accessKeyId, secret, key = '', query = {}, expires = 300, now = new Date() }) {
  const host = accountId + '.r2.cloudflarestorage.com';
  const amzDate = now.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
  const day = amzDate.slice(0, 8);
  const scope = day + '/auto/s3/aws4_request';
  const path = '/' + bucket + (key ? '/' + key.split('/').map(rfc3986).join('/') : '');
  const q = {
    ...query,
    'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
    'X-Amz-Content-Sha256': 'UNSIGNED-PAYLOAD',
    'X-Amz-Credential': accessKeyId + '/' + scope,
    'X-Amz-Date': amzDate,
    'X-Amz-Expires': String(expires),
    'X-Amz-SignedHeaders': 'host',
  };
  const qs = Object.keys(q).sort().map((k) => rfc3986(k) + '=' + rfc3986(q[k])).join('&');
  const canonical = [method, path, qs, 'host:' + host + '\n', 'host', 'UNSIGNED-PAYLOAD'].join('\n');
  const toSign = ['AWS4-HMAC-SHA256', amzDate, scope, await sha256Hex(canonical)].join('\n');
  let k = await hmac('AWS4' + secret, day);
  k = await hmac(k, 'auto');
  k = await hmac(k, 's3');
  k = await hmac(k, 'aws4_request');
  return 'https://' + host + path + '?' + qs + '&X-Amz-Signature=' + hex(await hmac(k, toSign));
}

export const R2_VARS = ['R2_ACCOUNT_ID', 'R2_BUCKET', 'R2_ACCESS_KEY_ID', 'R2_SECRET_ACCESS_KEY', 'R2_PUBLIC_BASE_URL'];

/** Parses a ListObjectsV2 XML body. */
export function parseList(xml) {
  const items = [];
  const re = /<Contents>([\s\S]*?)<\/Contents>/g;
  let m;
  const tag = (s, t) => { const x = new RegExp('<' + t + '>([\\s\\S]*?)</' + t + '>').exec(s); return x ? x[1] : ''; };
  while ((m = re.exec(xml))) {
    items.push({ key: tag(m[1], 'Key').replace(/&amp;/g, '&'), size: Number(tag(m[1], 'Size') || 0), modified: tag(m[1], 'LastModified') });
  }
  const truncated = tag(xml, 'IsTruncated') === 'true';
  const next = tag(xml, 'NextContinuationToken');
  return { items, truncated, next };
}

export async function r2List(env, prefix, { maxPages = 5, fetchImpl = (...a) => fetch(...a) } = {}) {
  const base = String(env.R2_PUBLIC_BASE_URL).replace(/\/+$/, '');
  const out = [];
  let token = '';
  for (let i = 0; i < maxPages; i++) {
    const query = { 'list-type': '2', prefix, 'max-keys': '1000' };
    if (token) query['continuation-token'] = token;
    const url = await presign({ accountId: env.R2_ACCOUNT_ID, bucket: env.R2_BUCKET, accessKeyId: env.R2_ACCESS_KEY_ID, secret: env.R2_SECRET_ACCESS_KEY, query });
    const r = await fetchImpl(url);
    if (!r.ok) throw new Error('r2 list ' + r.status);
    const page = parseList(await r.text());
    out.push(...page.items.map((x) => ({ ...x, url: base + '/' + x.key.split('/').map(encodeURIComponent).join('/') })));
    if (!page.truncated || !page.next) break;
    token = page.next;
  }
  return out;
}
