// A Play one-time purchase is acknowledged only after the grant succeeds.
// Runs against the Firestore emulator with Google Play's API faked in-process
// (a throwaway RSA key, generated here, signs the fake service-account JWT).
// Run: FIRESTORE_EMULATOR_HOST=127.0.0.1:8089 node tools/economy/play-ack.test.mjs
import { generateKeyPairSync } from 'node:crypto';
import { FsDb } from '../../functions/_lib/economy/fsdb.js';
import { settleProduct } from '../../functions/_lib/economy/playorders.js';
import { sha256Hex } from '../../functions/_lib/server.js';

const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const env = {
  FIRESTORE_EMULATOR_HOST: process.env.FIRESTORE_EMULATOR_HOST, FIREBASE_PROJECT_ID: 'nowssb-34f1b',
  PLAY_SERVICE_ACCOUNT_JSON: JSON.stringify({ client_email: 'test@example.iam', private_key_id: 't', private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }) }),
};
const db = await FsDb.fromEnv(env);
await fetch(`http://${env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/nowssb-34f1b/databases/(default)/documents`, { method: 'DELETE' });

const acks = [];
let purchase = {};
const realFetch = globalThis.fetch;
globalThis.fetch = async (url, init) => {
  const u = String(url);
  if (u.startsWith('https://oauth2.googleapis.com/token')) return new Response(JSON.stringify({ access_token: 'fake' }), { status: 200 });
  if (u.includes('androidpublisher.googleapis.com')) {
    if (u.endsWith(':acknowledge')) { acks.push(u); return new Response('{}', { status: 200 }); }
    if (u.includes('/orders/')) return new Response('{}', { status: 404 });
    return new Response(JSON.stringify(purchase), { status: 200 });
  }
  return realFetch(url, init);
};

let pass = 0, fail = 0;
const t = async (name, fn) => { try { await fn(); pass++; console.log('ok  ', name); } catch (e) { fail++; console.log('FAIL', name, e.stack.split('\n').slice(0, 3).join(' | ')); } };
const ok = (c, m) => { if (!c) throw new Error(m || 'assert'); };

const uid = 'ackbuyer';
const acct = await sha256Hex(uid);

await t('no checkout for a cart tier product: 400 and NOT acknowledged', async () => {
  acks.length = 0;
  purchase = { purchaseState: 0, acknowledgementState: 0, orderId: 'GPA.1111-0000-0000-00001', obfuscatedExternalAccountId: acct, purchaseType: 0 };
  const r = await settleProduct(env, { uid, productId: 'nowssb_tier_99', purchaseToken: 'tok-lost-checkout' });
  ok(r.status === 400, 'status ' + r.status);
  ok(acks.length === 0, 'acknowledged before validation: ' + acks.length);
});

await t('purchase bound to another account: 403 and NOT acknowledged', async () => {
  acks.length = 0;
  purchase = { purchaseState: 0, acknowledgementState: 0, orderId: 'GPA.1111-0000-0000-00002', obfuscatedExternalAccountId: 'someone-else', purchaseType: 0 };
  const r = await settleProduct(env, { uid, productId: 'nowssb_tier_99', purchaseToken: 'tok-other' });
  ok(r.status === 403, 'status ' + r.status);
  ok(acks.length === 0, 'acknowledged: ' + acks.length);
});

await t('valid cart checkout: granted, then acknowledged once', async () => {
  acks.length = 0;
  await db.commit([db.write('checkouts/ck1', { uid, kind: 'cart', productId: 'nowssb_tier_99', status: 'open', at: Date.now(), payINR: 99, coins: 0, items: [{ id: 'word:om', kind: 'word', title: 'Om', price: 99, qty: 1 }] })]);
  purchase = { purchaseState: 0, acknowledgementState: 0, orderId: 'GPA.1111-0000-0000-00003', obfuscatedExternalAccountId: acct, purchaseType: 0 };
  const r = await settleProduct(env, { uid, productId: 'nowssb_tier_99', purchaseToken: 'tok-good', checkoutId: 'ck1' });
  ok(r.status === 200 && r.body.ok, 'status ' + r.status + ' ' + JSON.stringify(r.body));
  ok((await db.get(`users/${uid}/owned/word_om`)).exists, 'owned written');
  ok(acks.length === 1, 'acks ' + acks.length);
});

await t('retry after a grant whose ack failed: acknowledged on the "already" path', async () => {
  acks.length = 0;
  const r = await settleProduct(env, { uid, productId: 'nowssb_tier_99', purchaseToken: 'tok-good', checkoutId: 'ck1' });
  ok(r.status === 200 && r.body.already, JSON.stringify(r.body));
  ok(acks.length === 1, 'acks ' + acks.length);
});

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
