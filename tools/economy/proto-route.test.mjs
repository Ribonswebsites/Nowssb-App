// H-001: prototype names must never resolve to an action (admin or user).
import { webcrypto as crypto } from 'node:crypto';
import assert from 'node:assert/strict';
const kp = await crypto.subtle.generateKey({ name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' }, true, ['sign', 'verify']);
const jwk = { ...(await crypto.subtle.exportKey('jwk', kp.publicKey)), kid: 'k1', alg: 'RS256' };
const pk = Buffer.from(await crypto.subtle.exportKey('pkcs8', kp.privateKey)).toString('base64');
const pem = `-----BEGIN PRIVATE KEY-----\n${pk}\n-----END PRIVATE KEY-----\n`;
const b64u = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const now = Math.floor(Date.now() / 1000);
async function token(sub) {
  const hd = b64u({ alg: 'RS256', kid: 'k1' });
  const cl = b64u({ aud: 'p', iss: 'https://securetoken.google.com/p', sub, iat: now, exp: now + 3600, auth_time: now });
  const sig = Buffer.from(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', kp.privateKey, new TextEncoder().encode(hd + '.' + cl))).toString('base64url');
  return hd + '.' + cl + '.' + sig;
}
globalThis.fetch = async (url) => {
  url = String(url);
  if (url.includes('jwk/securetoken') || url.includes('securetoken')) return new Response(JSON.stringify({ keys: [jwk] }));
  if (url.includes('oauth2.googleapis.com/token')) return new Response(JSON.stringify({ access_token: 'ya29.SECRET' }));
  if (url.includes('/admins/')) return new Response(JSON.stringify({ name: 'x', fields: {} }));
  if (url.includes(':batchGet') || url.includes(':runQuery')) return new Response('[]');
  return new Response('{}', { status: 404 });
};
const { onRequestPost } = await import('../../functions/api/economy/[action].js');
const env = { FIREBASE_PROJECT_ID: 'p', FIREBASE_SERVICE_ACCOUNT: JSON.stringify({ client_email: 'sa@x', private_key: pem, private_key_id: 'pk' }), R2_SECRET_ACCESS_KEY: 'R2-SECRET', ADMIN_UIDS: 'admin1' };
let n = 0;
for (const who of ['admin1', 'user1']) {
  for (const action of ['constructor', 'toString', '__proto__', 'hasOwnProperty', 'valueOf']) {
    const req = new Request('https://nowssb.com/api/economy/' + action, { method: 'POST', headers: { Authorization: 'Bearer ' + (await token(who)) }, body: '{}' });
    const r = await onRequestPost({ request: req, env, params: { action } });
    const txt = await r.text();
    assert.equal(r.status, 404, `${who} ${action} → ${r.status}`);
    assert.ok(!txt.includes('SECRET') && !txt.includes('PRIVATE KEY'), 'no secret in body');
    n++;
  }
}
console.log(`proto-route: ${n} pass`);
