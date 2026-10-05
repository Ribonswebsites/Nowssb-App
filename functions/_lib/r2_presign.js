/* Shared Cloudflare R2 (S3 API) SigV4 query-string PUT presign.
   Used by account avatar uploads. Admin upload-url.js keeps its own copy
   so admin behaviour stays untouched. WebCrypto only — no npm deps. */

export const enc = new TextEncoder();

export const R2_VARS = [
  'R2_ACCOUNT_ID',
  'R2_BUCKET',
  'R2_ACCESS_KEY_ID',
  'R2_SECRET_ACCESS_KEY',
  'R2_PUBLIC_BASE_URL',
];

export const hex = (buf) => [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');

export async function sha256Hex(s) {
  return hex(await crypto.subtle.digest('SHA-256', enc.encode(s)));
}

async function hmac(key, s) {
  const k = await crypto.subtle.importKey(
    'raw',
    typeof key === 'string' ? enc.encode(key) : key,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  return crypto.subtle.sign('HMAC', k, enc.encode(s));
}

/** RFC 3986 encoding, as SigV4 wants it. */
export const rfc3986 = (s) => encodeURIComponent(s).replace(/[!'()*]/g, (c) => '%' + c.charCodeAt(0).toString(16).toUpperCase());

/**
 * One-time HTTPS PUT URL for a single R2 object.
 * Optional signedHeaders: { 'content-type': '...', 'content-length': '123' }
 * — keys must be lowercase; values are included in the signature so the
 * client cannot upload a different type or size.
 */
export async function presignPut({
  accountId,
  bucket,
  accessKeyId,
  secret,
  key,
  expires = 900,
  now = new Date(),
  signedHeaders = {},
  extraQuery = {},
}) {
  const host = accountId + '.r2.cloudflarestorage.com';
  const region = 'auto';
  const service = 's3';
  const amzDate = now.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
  const day = amzDate.slice(0, 8);
  const scope = day + '/' + region + '/' + service + '/aws4_request';
  const path = '/' + bucket + '/' + key.split('/').map(rfc3986).join('/');

  const headerNames = ['host', ...Object.keys(signedHeaders).map((h) => h.toLowerCase())]
    .filter((v, i, a) => a.indexOf(v) === i)
    .sort();
  const headerMap = { host, ...Object.fromEntries(Object.entries(signedHeaders).map(([k, v]) => [k.toLowerCase(), String(v)])) };
  const canonicalHeaders = headerNames.map((n) => n + ':' + headerMap[n].trim() + '\n').join('');
  const signedHeadersStr = headerNames.join(';');

  const q = {
    'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
    'X-Amz-Content-Sha256': 'UNSIGNED-PAYLOAD',
    'X-Amz-Credential': accessKeyId + '/' + scope,
    'X-Amz-Date': amzDate,
    'X-Amz-Expires': String(expires),
    'X-Amz-SignedHeaders': signedHeadersStr,
    ...extraQuery,
  };
  const query = Object.keys(q).sort().map((k) => rfc3986(k) + '=' + rfc3986(q[k])).join('&');
  const canonical = ['PUT', path, query, canonicalHeaders, signedHeadersStr, 'UNSIGNED-PAYLOAD'].join('\n');
  const toSign = ['AWS4-HMAC-SHA256', amzDate, scope, await sha256Hex(canonical)].join('\n');
  let k = await hmac('AWS4' + secret, day);
  k = await hmac(k, region);
  k = await hmac(k, service);
  k = await hmac(k, 'aws4_request');
  const sig = hex(await hmac(k, toSign));
  return 'https://' + host + path + '?' + query + '&X-Amz-Signature=' + sig;
}

/** Public HTTPS URL for an object key under R2_PUBLIC_BASE_URL. */
export function publicObjectUrl(baseUrl, key) {
  const base = String(baseUrl || '').replace(/\/+$/, '');
  return base + '/' + String(key).split('/').map(encodeURIComponent).join('/');
}
