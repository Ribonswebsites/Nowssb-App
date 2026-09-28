// Offline tests for functions/api/play/{verify,rtdn}.js — no network, no real
// keys: throwaway RSA keys are generated here and every Google endpoint is a
// fake. Run: node tools/play/play-functions.test.mjs
import * as verify from '../../functions/api/play/verify.js';
import * as rtdn from '../../functions/api/play/rtdn.js';
import { evaluate } from '../../functions/_lib/play.js';

const enc = new TextEncoder();
const b64u = (buf) => Buffer.from(buf).toString('base64url');
const sha = async (s) => Buffer.from(await crypto.subtle.digest('SHA-256', enc.encode(s))).toString('hex');

async function rsa() {
  const kp = await crypto.subtle.generateKey({ name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' }, true, ['sign', 'verify']);
  const jwk = await crypto.subtle.exportKey('jwk', kp.publicKey);
  const pkcs8 = Buffer.from(await crypto.subtle.exportKey('pkcs8', kp.privateKey)).toString('base64');
  return { kp, jwk, pem: `-----BEGIN PRIVATE KEY-----\n${pkcs8}\n-----END PRIVATE KEY-----\n` };
}
async function jwt(key, kid, claims) {
  const h = b64u(enc.encode(JSON.stringify({ alg: 'RS256', kid, typ: 'JWT' })));
  const c = b64u(enc.encode(JSON.stringify(claims)));
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key.kp.privateKey, enc.encode(h + '.' + c));
  return `${h}.${c}.${b64u(sig)}`;
}

const PROJECT = 'nowssb-34f1b';
const fb = await rsa(); const oidc = await rsa(); const saKey = await rsa();
const now = Math.floor(Date.now() / 1000);
const idToken = (uid, extra = {}) => jwt(fb, 'k1', { aud: PROJECT, iss: 'https://securetoken.google.com/' + PROJECT, sub: uid, iat: now, exp: now + 3600, ...extra });
const PLAY_SA = { client_email: 'play-verify@example.iam.gserviceaccount.com', private_key: saKey.pem, private_key_id: 'x' };
const FB_SA = { client_email: 'firebase-adminsdk@example.iam.gserviceaccount.com', private_key: saKey.pem, private_key_id: 'y' };
const ENV = { PLAY_SERVICE_ACCOUNT_JSON: JSON.stringify(PLAY_SA), FIREBASE_SERVICE_ACCOUNT: JSON.stringify(FB_SA), FIREBASE_PROJECT_ID: PROJECT };

// ── fake Google ──
const db = new Map(); // path -> plain object
const subs = new Map(); // token -> SubscriptionPurchaseV2
const calls = [];
const fromFs = (v) => {
  if ('stringValue' in v) return v.stringValue; if ('booleanValue' in v) return v.booleanValue;
  if ('integerValue' in v) return Number(v.integerValue); if ('nullValue' in v) return null;
  if ('mapValue' in v) return Object.fromEntries(Object.entries(v.mapValue.fields || {}).map(([k, x]) => [k, fromFs(x)]));
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(fromFs); return null;
};
const toFs = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k, typeof v === 'string' ? { stringValue: v } : typeof v === 'boolean' ? { booleanValue: v } : v === null ? { nullValue: null } : { stringValue: String(v) }]));
const DOCS = `projects/${PROJECT}/databases/(default)/documents/`;
globalThis.fetch = async (url, init = {}) => {
  url = String(url); calls.push(url);
  const res = (o, s = 200) => new Response(JSON.stringify(o), { status: s, headers: { 'Content-Type': 'application/json' } });
  if (url.includes('securetoken@system')) return res({ keys: [{ ...fb.jwk, kid: 'k1', alg: 'RS256', use: 'sig' }] });
  if (url.endsWith('/oauth2/v3/certs')) return res({ keys: [{ ...oidc.jwk, kid: 'o1', alg: 'RS256', use: 'sig' }] });
  if (url === 'https://oauth2.googleapis.com/token') return res({ access_token: 'tok', expires_in: 3600 });
  let m = url.match(/subscriptionsv2\/tokens\/(.+)$/);
  if (m) { const s = subs.get(decodeURIComponent(m[1])); return s ? res(s) : res({ error: {} }, 404); }
  m = url.match(/purchases\/subscriptions\/([^/]+)\/tokens\/(.+):acknowledge$/);
  if (m) { const s = subs.get(decodeURIComponent(m[2])); if (s) s.acknowledgementState = 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED'; return res({}); }
  if (url.endsWith(':runQuery')) {
    const q = JSON.parse(init.body).structuredQuery; const want = q.where.fieldFilter.value.stringValue;
    const rows = [...db.entries()].filter(([p, d]) => p.startsWith('users/') && d.subscriptionTokenHash === want)
      .map(([p, d]) => ({ document: { name: DOCS + p, fields: toFs(d) } }));
    return res(rows.length ? rows : [{ readTime: 'x' }]);
  }
  if (url.endsWith(':commit')) {
    const { writes } = JSON.parse(init.body);
    for (const w of writes) { const p = w.update.name.split('/documents/')[1]; if (w.currentDocument && w.currentDocument.exists === false && db.has(p)) return res({ error: { message: 'exists' } }, 409); }
    for (const w of writes) {
      const p = w.update.name.split('/documents/')[1];
      const f = fromFs({ mapValue: { fields: w.update.fields } });
      db.set(p, w.updateMask ? { ...(db.get(p) || {}), ...f } : f);
    }
    return res({});
  }
  m = url.match(/documents\/(.+)$/);
  if (m) { const d = db.get(decodeURIComponent(m[1])); return d ? res({ fields: toFs(d) }) : res({ error: {} }, 404); }
  throw new Error('unexpected fetch ' + url);
};

let pass = 0, fail = 0;
const t = async (name, fn) => { try { await fn(); pass++; console.log('ok  ', name); } catch (e) { fail++; console.log('FAIL', name, e.message); } };
const eq = (a, b, m) => { if (a !== b) throw new Error(`${m || ''} expected ${JSON.stringify(b)} got ${JSON.stringify(a)}`); };
const post = async (mod, body, headers = {}, env = ENV, url = 'https://nowssb.com/api/play/verify') => {
  const r = await mod.onRequestPost({ request: new Request(url, { method: 'POST', headers: { 'Content-Type': 'application/json', ...headers }, body: JSON.stringify(body) }), env });
  return { status: r.status, body: await r.json() };
};
const future = new Date(Date.now() + 30 * 864e5).toISOString();
const past = new Date(Date.now() - 864e5).toISOString();
const mkSub = (o = {}) => ({
  subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE', latestOrderId: 'GPA.1111-2222-3333-44444', startTime: new Date().toISOString(),
  acknowledgementState: 'ACKNOWLEDGEMENT_STATE_PENDING',
  lineItems: [{ productId: 'nowssb_frequency_monthly', expiryTime: future, autoRenewingPlan: { autoRenewEnabled: true } }], ...o,
});

await t('501 names missing env only', async () => {
  const r = await post(verify, {}, {}, { FIREBASE_PROJECT_ID: PROJECT });
  eq(r.status, 501); eq(r.body.missing.join(','), 'PLAY_SERVICE_ACCOUNT_JSON,FIREBASE_SERVICE_ACCOUNT');
  if (JSON.stringify(r.body).includes('PRIVATE')) throw new Error('leaked');
});
await t('401 without sign-in', async () => { eq((await post(verify, { productId: 'nowssb_frequency_monthly', purchaseToken: 'a' })).status, 401); });
await t('401 with token for another project', async () => {
  const bad = await jwt(fb, 'k1', { aud: 'other', iss: 'https://securetoken.google.com/other', sub: 'u', iat: now, exp: now + 60 });
  eq((await post(verify, { productId: 'nowssb_frequency_monthly', purchaseToken: 'a' }, { Authorization: 'Bearer ' + bad })).status, 401);
});
await t('400 unknown product', async () => { eq((await post(verify, { productId: 'x', purchaseToken: 'a' }, { Authorization: 'Bearer ' + await idToken('alice') })).status, 400); });
await t('400 purchase unknown to Play', async () => { eq((await post(verify, { productId: 'nowssb_frequency_monthly', purchaseToken: 'nope' }, { Authorization: 'Bearer ' + await idToken('alice') })).status, 400); });

subs.set('tokA', mkSub({ externalAccountIdentifiers: { obfuscatedExternalAccountId: await sha('alice') } }));
await t('active purchase grants + acknowledges + receipt + log', async () => {
  const r = await post(verify, { productId: 'nowssb_frequency_monthly', purchaseToken: 'tokA' }, { Authorization: 'Bearer ' + await idToken('alice') });
  eq(r.status, 200); eq(r.body.status, 'granted'); eq(r.body.tier, 'frequency');
  const u = db.get('users/alice'); eq(u.isPro, true); eq(u.tier, 'frequency'); eq(u.subscriptionSource, 'play');
  eq(u.subscriptionProductId, 'nowssb_frequency_monthly'); eq(u.subscriptionEndDate, future); eq(u.subscriptionTokenHash, await sha('tokA'));
  eq(db.get('payments/GPA_1111-2222-3333-44444').uid, 'alice');
  eq(db.has('adminLog/play_GPA_1111-2222-3333-44444'), true);
  eq(subs.get('tokA').acknowledgementState, 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED');
  if (JSON.stringify([...db.values()]).includes('tokA')) throw new Error('raw token stored');
});
await t('second call is idempotent (already)', async () => {
  const r = await post(verify, { productId: 'nowssb_frequency_monthly', purchaseToken: 'tokA' }, { Authorization: 'Bearer ' + await idToken('alice') });
  eq(r.status, 200); eq(r.body.status, 'already');
});
await t('other account with obfuscated id mismatch → 403', async () => {
  const r = await post(verify, { productId: 'nowssb_frequency_monthly', purchaseToken: 'tokA' }, { Authorization: 'Bearer ' + await idToken('mallory') });
  eq(r.status, 403); eq(db.get('users/mallory'), undefined);
});
subs.set('tokNoId', mkSub({ latestOrderId: 'GPA.1111-2222-3333-44444' }));
await t('same order claimed by another uid (no obfuscated id) → 403', async () => {
  const r = await post(verify, { productId: 'nowssb_frequency_monthly', purchaseToken: 'tokNoId' }, { Authorization: 'Bearer ' + await idToken('mallory') });
  eq(r.status, 403);
});
subs.set('tokPend', mkSub({ subscriptionState: 'SUBSCRIPTION_STATE_PENDING', latestOrderId: 'GPA.p' }));
await t('pending → 202, nothing granted', async () => {
  const r = await post(verify, { productId: 'nowssb_frequency_monthly', purchaseToken: 'tokPend' }, { Authorization: 'Bearer ' + await idToken('bob') });
  eq(r.status, 202); eq(r.body.pending, true); eq(db.get('users/bob'), undefined);
});
subs.set('tokExp', mkSub({ subscriptionState: 'SUBSCRIPTION_STATE_EXPIRED', latestOrderId: 'GPA.e', lineItems: [{ productId: 'nowssb_resonance_yearly', expiryTime: past }] }));
await t('expired → 402, not Pro', async () => {
  const r = await post(verify, { productId: 'nowssb_resonance_yearly', purchaseToken: 'tokExp' }, { Authorization: 'Bearer ' + await idToken('carol') });
  eq(r.status, 402); eq(db.get('users/carol').isPro, undefined); eq(db.has('payments/GPA_e'), false);
});
await t('grace period + canceled-with-time-left are entitled; on hold is not', async () => {
  eq(evaluate(mkSub({ subscriptionState: 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD' })).entitled, true);
  eq(evaluate(mkSub({ subscriptionState: 'SUBSCRIPTION_STATE_CANCELED' })).entitled, true);
  eq(evaluate(mkSub({ subscriptionState: 'SUBSCRIPTION_STATE_ON_HOLD' })).entitled, false);
  eq(evaluate(mkSub({ subscriptionState: 'SUBSCRIPTION_STATE_CANCELED', lineItems: [{ productId: 'nowssb_frequency_monthly', expiryTime: past }] })).entitled, false);
});
subs.set('tokX', mkSub({ latestOrderId: 'GPA.x', lineItems: [{ productId: 'nowssb_frequencyx_yearly', expiryTime: future }] }));
await t('Frequency X adds blue badge', async () => {
  const r = await post(verify, { productId: 'nowssb_frequencyx_yearly', purchaseToken: 'tokX' }, { Authorization: 'Bearer ' + await idToken('dave') });
  eq(r.status, 200); eq(db.get('users/dave').verifyTier, 'blue'); eq(db.get('users/dave').tier, 'frequencyX');
});

// ── RTDN ──
const RT = 'https://nowssb.com/api/play/rtdn';
const push = async (token, bearer) => post(rtdn, { message: { data: Buffer.from(JSON.stringify({ packageName: 'com.nowssb.app', subscriptionNotification: { notificationType: 2, purchaseToken: token } })).toString('base64') } }, bearer ? { Authorization: 'Bearer ' + bearer } : {}, ENV, RT);
const goodOidc = () => jwt(oidc, 'o1', { aud: RT, iss: 'https://accounts.google.com', email: PLAY_SA.client_email, email_verified: true, iat: now, exp: now + 600 });
await t('rtdn rejects missing / wrong token', async () => {
  eq((await push('tokA')).status, 401);
  eq((await push('tokA', await jwt(oidc, 'o1', { aud: RT, iss: 'https://accounts.google.com', email: 'evil@x', iat: now, exp: now + 600 }))).status, 401);
  eq((await push('tokA', await jwt(oidc, 'o1', { aud: 'https://evil', iss: 'https://accounts.google.com', email: PLAY_SA.client_email, iat: now, exp: now + 600 }))).status, 401);
});
await t('rtdn renewal adds a receipt and extends', async () => {
  const later = new Date(Date.now() + 60 * 864e5).toISOString();
  Object.assign(subs.get('tokA'), { latestOrderId: 'GPA.1111-2222-3333-44444..0', lineItems: [{ productId: 'nowssb_frequency_monthly', expiryTime: later, autoRenewingPlan: { autoRenewEnabled: true } }] });
  const r = await push('tokA', await goodOidc());
  eq(r.status, 200); eq(r.body.results[0], 'granted');
  eq(db.get('users/alice').subscriptionEndDate, later); eq(db.get('payments/GPA_1111-2222-3333-44444__0').uid, 'alice');
});
await t('rtdn expiry switches the Play plan off', async () => {
  Object.assign(subs.get('tokA'), { subscriptionState: 'SUBSCRIPTION_STATE_EXPIRED', lineItems: [{ productId: 'nowssb_frequency_monthly', expiryTime: past }] });
  const r = await push('tokA', await goodOidc());
  eq(r.status, 200); eq(db.get('users/alice').isPro, false); eq(db.get('users/alice').tier, null);
});
await t('rtdn test notification ok', async () => {
  const r = await post(rtdn, { message: { data: Buffer.from(JSON.stringify({ packageName: 'com.nowssb.app', testNotification: { version: '1.0' } })).toString('base64') } }, { Authorization: 'Bearer ' + await goodOidc() }, ENV, RT);
  eq(r.status, 200); eq(r.body.test, true);
});

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
