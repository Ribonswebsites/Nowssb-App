// Offline test of functions/api/pay/* with fetch mocked (Google JWKs, OAuth,
// Razorpay, Firestore). No network, no dependencies:  node tools/pay/pay-functions.test.mjs
import { createHmac, generateKeyPairSync, createSign } from 'node:crypto';
import { writeFileSync, mkdtempSync, cpSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

// Load the functions as ES modules from a temp copy (the repo has no "type":"module").
const root = join(dirname(fileURLToPath(import.meta.url)), '../..');
const tmp = mkdtempSync(join(tmpdir(), 'payfn-'));
cpSync(join(root, 'functions'), join(tmp, 'functions'), { recursive: true });
writeFileSync(join(tmp, 'package.json'), '{"type":"module"}');
const load = (p) => import(pathToFileURL(join(tmp, 'functions', p)).href);
const order = await load('api/pay/order.js');
const verify = await load('api/pay/verify.js');
const webhook = await load('api/pay/webhook.js');

const b64u = (b) => Buffer.from(b).toString('base64url');
const idKeys = generateKeyPairSync('rsa', { modulusLength: 2048 });
const saKeys = generateKeyPairSync('rsa', { modulusLength: 2048 });
const jwk = { ...idKeys.publicKey.export({ format: 'jwk' }), kid: 'k1', alg: 'RS256', use: 'sig' };
function idToken(uid, extra = {}) {
  const now = Math.floor(Date.now() / 1000);
  const h = b64u(JSON.stringify({ alg: 'RS256', kid: 'k1' }));
  const c = b64u(JSON.stringify({ aud: 'nowssb-34f1b', iss: 'https://securetoken.google.com/nowssb-34f1b', sub: uid, iat: now, exp: now + 3600, email: uid + '@x', ...extra }));
  const s = createSign('RSA-SHA256').update(h + '.' + c).sign(idKeys.privateKey);
  return h + '.' + c + '.' + b64u(s);
}
const SA = JSON.stringify({ type: 'service_account', project_id: 'nowssb-34f1b', private_key_id: 'test', client_email: 'sa@test', private_key: saKeys.privateKey.export({ format: 'pem', type: 'pkcs8' }) });
const env = { RAZORPAY_KEY_ID: 'rzp_test_1', RAZORPAY_KEY_SECRET: 'sek', RAZORPAY_WEBHOOK_SECRET: 'whsek', FIREBASE_PROJECT_ID: 'nowssb-34f1b', FIREBASE_SERVICE_ACCOUNT: SA };

// ── fake world ──
const rz = { orders: {}, payments: {} };
const fsdb = {};
const calls = [];
let n = 0;
globalThis.fetch = async (url, init = {}) => {
  url = String(url); calls.push(init.method + ' ' + url);
  const J = (o, s = 200) => new Response(JSON.stringify(o), { status: s, headers: { 'content-type': 'application/json' } });
  const body = init.body ? (typeof init.body === 'string' && init.body.startsWith('{') ? JSON.parse(init.body) : init.body) : null;
  if (url.includes('/jwk/securetoken')) return J({ keys: [jwk] });
  if (url === 'https://oauth2.googleapis.com/token') return J({ access_token: 'gtok', expires_in: 3600 });
  if (url.startsWith('https://api.razorpay.com/v1/')) {
    if (init.headers.Authorization !== 'Basic ' + btoa('rzp_test_1:sek')) return J({ error: { description: 'auth' } }, 401);
    const p = url.slice('https://api.razorpay.com/v1'.length);
    if (p === '/orders' && init.method === 'POST') { const id = 'order_T' + (++n); rz.orders[id] = { id, ...body, status: 'created' }; return J(rz.orders[id]); }
    let m;
    if ((m = p.match(/^\/orders\/(.+)$/))) return rz.orders[m[1]] ? J(rz.orders[m[1]]) : J({ error: {} }, 404);
    if ((m = p.match(/^\/payments\/([^/]+)\/capture$/))) { rz.payments[m[1]].status = 'captured'; return J(rz.payments[m[1]]); }
    if ((m = p.match(/^\/payments\/(.+)$/))) return rz.payments[m[1]] ? J(rz.payments[m[1]]) : J({ error: {} }, 404);
  }
  if (url.startsWith('https://firestore.googleapis.com/v1/')) {
    const pre = 'https://firestore.googleapis.com/v1/projects/nowssb-34f1b/databases/(default)/documents';
    if (url === pre + ':commit') {
      for (const w of body.writes) {
        const path = w.update.name.split('/documents/')[1];
        if (w.currentDocument && w.currentDocument.exists === false && fsdb[path]) return J({ error: { message: 'exists' } }, 409);
      }
      for (const w of body.writes) {
        const path = w.update.name.split('/documents/')[1];
        const cur = fsdb[path] || {};
        const next = w.updateMask ? { ...cur, ...w.update.fields } : { ...w.update.fields };
        for (const t of w.updateTransforms || []) next[t.fieldPath] = { timestampValue: new Date().toISOString() };
        fsdb[path] = next;
      }
      return J({ writeResults: [] });
    }
    const path = url.slice(pre.length + 1);
    return fsdb[decodeURIComponent(path)] ? J({ fields: fsdb[decodeURIComponent(path)] }) : J({ error: {} }, 404);
  }
  throw new Error('unexpected fetch ' + url);
};

const req = (path, body, headers = {}) => new Request('https://nowssb.com' + path, {
  method: 'POST', headers: { 'Content-Type': 'application/json', Origin: 'https://nowssb.com', ...headers },
  body: typeof body === 'string' ? body : JSON.stringify(body),
});
const auth = (uid) => ({ Authorization: 'Bearer ' + idToken(uid) });
const sig = (o, p, k = 'sek') => createHmac('sha256', k).update(o + '|' + p).digest('hex');
let pass = 0, fail = 0;
async function t(name, fn) { try { await fn(); pass++; console.log('ok  ', name); } catch (e) { fail++; console.log('FAIL', name, '-', e.message); } }
const eq = (a, b, m = '') => { if (a !== b) throw new Error(`${m} expected ${JSON.stringify(b)} got ${JSON.stringify(a)}`); };
const call = async (mod, path, body, headers, e = env) => { const r = await mod.onRequestPost({ request: req(path, body, headers), env: e }); return { s: r.status, d: await r.json(), h: r.headers }; };
const field = (path, k) => { const v = fsdb[path] && fsdb[path][k]; return v && (v.stringValue ?? v.booleanValue ?? (v.integerValue !== undefined ? Number(v.integerValue) : v.timestampValue)); };

await t('501 lists missing vars', async () => { const r = await call(order, '/api/pay/order', { plan: 'frequency' }, auth('alice'), { FIREBASE_PROJECT_ID: 'nowssb-34f1b' }); eq(r.s, 501); if (!/RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, FIREBASE_SERVICE_ACCOUNT/.test(r.d.error)) throw new Error(r.d.error); });
await t('FCM_SERVICE_ACCOUNT accepted as fallback', async () => { const e = { ...env, FIREBASE_SERVICE_ACCOUNT: undefined, FCM_SERVICE_ACCOUNT: SA }; const r = await call(order, '/api/pay/order', { plan: 'resonance', billing: 'monthly' }, auth('alice'), e); eq(r.s, 200); });
await t('order needs sign-in', async () => { eq((await call(order, '/api/pay/order', { plan: 'frequency' }, {})).s, 401); });
await t('order rejects forged token', async () => { eq((await call(order, '/api/pay/order', { plan: 'frequency' }, { Authorization: 'Bearer ' + idToken('alice').slice(0, -4) + 'AAAA' })).s, 401); });
await t('order rejects wrong audience', async () => { eq((await call(order, '/api/pay/order', { plan: 'frequency' }, { Authorization: 'Bearer ' + idToken('alice', { aud: 'other' }) })).s, 401); });
await t('order rejects unknown plan', async () => { eq((await call(order, '/api/pay/order', { plan: 'free' }, auth('alice'))).s, 400); });

let o1;
await t('order uses server price + uid notes', async () => {
  const r = await call(order, '/api/pay/order', { plan: 'frequency', billing: 'yearly', amount: 1 }, auth('alice'));
  eq(r.s, 200); eq(r.d.amount, 9999); eq(r.d.currency, 'USD'); eq(r.d.keyId, 'rzp_test_1');
  eq(r.h.get('Access-Control-Allow-Origin'), 'https://nowssb.com');
  o1 = r.d.orderId; eq(rz.orders[o1].notes.uid, 'alice'); eq(rz.orders[o1].notes.plan, 'frequency');
});
rz.payments.pay_A1 = { id: 'pay_A1', order_id: null, amount: 9999, currency: 'USD', status: 'captured', method: 'card', email: 'alice@x' };
await t('verify bad signature 400', async () => { rz.payments.pay_A1.order_id = o1; eq((await call(verify, '/api/pay/verify', { razorpay_order_id: o1, razorpay_payment_id: 'pay_A1', razorpay_signature: sig(o1, 'pay_A1', 'wrong') }, auth('alice'))).s, 400); eq(fsdb['users/alice'], undefined); });
await t('verify by another account 403', async () => { eq((await call(verify, '/api/pay/verify', { razorpay_order_id: o1, razorpay_payment_id: 'pay_A1', razorpay_signature: sig(o1, 'pay_A1') }, auth('mallory'))).s, 403); eq(fsdb['users/mallory'], undefined); });
await t('verify grants plan', async () => {
  const r = await call(verify, '/api/pay/verify', { razorpay_order_id: o1, razorpay_payment_id: 'pay_A1', razorpay_signature: sig(o1, 'pay_A1') }, auth('alice'));
  eq(r.s, 200, JSON.stringify(r.d)); eq(r.d.status, 'granted'); eq(r.d.tier, 'frequency');
  eq(field('users/alice', 'isPro'), true); eq(field('users/alice', 'tier'), 'frequency'); eq(field('users/alice', 'subscriptionSource'), 'razorpay');
  eq(field('users/alice', 'subscriptionPaymentId'), 'pay_A1'); eq(field('payments/pay_A1', 'uid'), 'alice');
  const days = (new Date(field('users/alice', 'subscriptionEndDate')) - Date.now()) / 864e5; if (days < 364 || days > 367) throw new Error('end ' + days);
  if (!fsdb['adminLog/pay_pay_A1']) throw new Error('no adminLog');
});
await t('verify again is idempotent', async () => {
  const end = field('users/alice', 'subscriptionEndDate');
  const r = await call(verify, '/api/pay/verify', { razorpay_order_id: o1, razorpay_payment_id: 'pay_A1', razorpay_signature: sig(o1, 'pay_A1') }, auth('alice'));
  eq(r.s, 200); eq(r.d.status, 'already'); eq(field('users/alice', 'subscriptionEndDate'), end);
});
await t('webhook for same payment is idempotent', async () => {
  const raw = JSON.stringify({ event: 'payment.captured', payload: { payment: { entity: rz.payments.pay_A1 } } });
  const r = await webhook.onRequestPost({ request: req('/api/pay/webhook', raw, { 'X-Razorpay-Signature': createHmac('sha256', 'whsek').update(raw).digest('hex') }), env });
  eq(r.status, 200); eq((await r.json()).status, 'already');
});

let o2;
await t('amount mismatch refused', async () => {
  o2 = (await call(order, '/api/pay/order', { plan: 'frequencyX', billing: 'monthly' }, auth('bob'))).d.orderId;
  rz.payments.pay_B1 = { id: 'pay_B1', order_id: o2, amount: 100, currency: 'USD', status: 'captured' };
  eq((await call(verify, '/api/pay/verify', { razorpay_order_id: o2, razorpay_payment_id: 'pay_B1', razorpay_signature: sig(o2, 'pay_B1') }, auth('bob'))).s, 400);
});
await t('payment for different order refused', async () => {
  rz.payments.pay_B2 = { id: 'pay_B2', order_id: o1, amount: 9999, currency: 'USD', status: 'captured' };
  eq((await call(verify, '/api/pay/verify', { razorpay_order_id: o2, razorpay_payment_id: 'pay_B2', razorpay_signature: sig(o2, 'pay_B2') }, auth('bob'))).s, 400);
});
await t('failed payment refused (402)', async () => {
  rz.payments.pay_B3 = { id: 'pay_B3', order_id: o2, amount: 1999, currency: 'USD', status: 'failed' };
  eq((await call(verify, '/api/pay/verify', { razorpay_order_id: o2, razorpay_payment_id: 'pay_B3', razorpay_signature: sig(o2, 'pay_B3') }, auth('bob'))).s, 402);
  eq(fsdb['users/bob'], undefined);
});
await t('webhook bad signature 400', async () => {
  const raw = JSON.stringify({ event: 'payment.captured', payload: { payment: { entity: { id: 'pay_B4', order_id: o2 } } } });
  const r = await webhook.onRequestPost({ request: req('/api/pay/webhook', raw, { 'X-Razorpay-Signature': 'nope' }), env });
  eq(r.status, 400);
});
await t('webhook grants authorized payment (captures) + blue badge', async () => {
  rz.payments.pay_B4 = { id: 'pay_B4', order_id: o2, amount: 1999, currency: 'USD', status: 'authorized' };
  const raw = JSON.stringify({ event: 'payment.authorized_ignored', x: 1 });
  const ign = await webhook.onRequestPost({ request: req('/api/pay/webhook', raw, { 'X-Razorpay-Signature': createHmac('sha256', 'whsek').update(raw).digest('hex') }), env });
  eq((await ign.json()).ignored, 'payment.authorized_ignored');
  const raw2 = JSON.stringify({ event: 'order.paid', payload: { payment: { entity: rz.payments.pay_B4 }, order: { entity: rz.orders[o2] } } });
  const r = await webhook.onRequestPost({ request: req('/api/pay/webhook', raw2, { 'X-Razorpay-Signature': createHmac('sha256', 'whsek').update(raw2).digest('hex') }), env });
  eq(r.status, 200); eq((await r.json()).status, 'granted');
  eq(rz.payments.pay_B4.status, 'captured'); eq(field('users/bob', 'tier'), 'frequencyX'); eq(field('users/bob', 'verifyTier'), 'blue');
  eq(field('payments/pay_B4', 'source'), 'webhook');
});
await t('early renewal extends from current end', async () => {
  const before = new Date(field('users/bob', 'subscriptionEndDate'));
  const o3 = (await call(order, '/api/pay/order', { plan: 'frequencyX', billing: 'monthly' }, auth('bob'))).d.orderId;
  rz.payments.pay_B5 = { id: 'pay_B5', order_id: o3, amount: 1999, currency: 'USD', status: 'captured' };
  eq((await call(verify, '/api/pay/verify', { razorpay_order_id: o3, razorpay_payment_id: 'pay_B5', razorpay_signature: sig(o3, 'pay_B5') }, auth('bob'))).s, 200);
  const days = (new Date(field('users/bob', 'subscriptionEndDate')) - before) / 864e5; if (days < 27 || days > 32) throw new Error('extended ' + days);
});
await t('webhook ignores non-NowssB order', async () => {
  rz.orders.order_OTHER = { id: 'order_OTHER', amount: 500, currency: 'USD', notes: {} };
  rz.payments.pay_X = { id: 'pay_X', order_id: 'order_OTHER', amount: 500, currency: 'USD', status: 'captured' };
  const raw = JSON.stringify({ event: 'payment.captured', payload: { payment: { entity: rz.payments.pay_X } } });
  const r = await webhook.onRequestPost({ request: req('/api/pay/webhook', raw, { 'X-Razorpay-Signature': createHmac('sha256', 'whsek').update(raw).digest('hex') }), env });
  eq(r.status, 200); eq(fsdb['payments/pay_X'], undefined);
});
console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
