/* Google Play one-time products + the Orders API (real price, tax and the
   store's real fee), and the glue from cleared Play payments to the
   economy pipeline (sales.js). */
import { SCOPE_ANDROIDPUBLISHER, googleToken, parseServiceAccount, sha256Hex } from '../server.js';
import { PLAY_PACKAGE_NAME } from '../play.js';
import { FsDb, cleanId } from './fsdb.js';
import { loadEconomy } from './config.js';
import { applySale, reverseSale, kindOfBagItem } from './sales.js';
import { pick } from './core.js';

const AP = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/';
const money = (m) => (m ? Number(m.units || 0) + Number(m.nanos || 0) / 1e9 : 0);

async function tok(env) { return googleToken(parseServiceAccount(env.PLAY_SERVICE_ACCOUNT_JSON), SCOPE_ANDROIDPUBLISHER); }

/** purchases.products.get */
export async function getProductPurchase(env, productId, token) {
  const r = await fetch(`${AP}${PLAY_PACKAGE_NAME}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(token)}`, { headers: { Authorization: 'Bearer ' + (await tok(env)) } });
  if (r.status === 404 || r.status === 410 || r.status === 400) { const e = new Error('Google Play does not know that purchase.'); e.http = 400; throw e; }
  if (!r.ok) throw new Error('play product get ' + r.status);
  return r.json();
}
export async function ackProduct(env, productId, token) {
  const r = await fetch(`${AP}${PLAY_PACKAGE_NAME}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(token)}:acknowledge`, { method: 'POST', headers: { Authorization: 'Bearer ' + (await tok(env)), 'Content-Type': 'application/json' }, body: '{}' });
  return r.ok;
}
/** orders.get → INR amounts ex-tax and the real store fee (null when Play does not say). */
export async function orderAmounts(env, orderId, cfg) {
  try {
    const r = await fetch(`${AP}${PLAY_PACKAGE_NAME}/orders/${encodeURIComponent(orderId)}`, { headers: { Authorization: 'Bearer ' + (await tok(env)) } });
    if (!r.ok) return null;
    const o = await r.json();
    const cur = (o.total && o.total.currencyCode) || 'INR';
    const fx = pick(cfg.fxToINR, cur) || null;
    if (!fx) return null;
    const total = money(o.total);
    const tax = money(o.tax);
    const dev = o.developerRevenueInBuyerCurrency ? money(o.developerRevenueInBuyerCurrency) : null;
    const exTax = Math.max(0, total - tax);
    return { currency: cur, totalINR: total * fx, taxINR: tax * fx, exTaxINR: exTax * fx, realFeeINR: dev == null ? null : Math.max(0, exTax - dev) * fx, country: (o.buyerAddress && o.buyerAddress.buyerCountry) || '' };
  } catch (e) {
    return null;
  }
}

/** Builds the economy order for a one-time product + its checkout, then runs the pipeline. */
export async function settleProduct(env, { uid, productId, purchaseToken, checkoutId, now = Date.now() }) {
  const db = await FsDb.fromEnv(env);
  const cfg = await loadEconomy(db);
  const p = await getProductPurchase(env, productId, purchaseToken);
  if (p.purchaseState === 2) return { status: 202, body: { ok: false, pending: true, error: 'The payment is still pending with Google Play.' } };
  if (p.purchaseState !== 0) return { status: 402, body: { ok: false, error: 'That purchase was cancelled.' } };
  if (p.obfuscatedExternalAccountId && p.obfuscatedExternalAccountId !== (await sha256Hex(uid))) return { status: 403, body: { error: 'That purchase belongs to another account.' } };
  const orderId = String(p.orderId || '');
  if (!orderId) return { status: 400, body: { error: 'Play did not return an order id.' } };
  // Acknowledge only after the grant below succeeds (or was already made).
  // A purchase that fails any check stays unacknowledged, so Google Play
  // refunds it automatically after 3 days.
  const ack = async () => { if (p.acknowledgementState === 0) await ackProduct(env, productId, purchaseToken).catch(() => false); };
  const tokenHash = await sha256Hex(purchaseToken);
  // Bind the token to this account once.
  const rec = await db.get(`playReceipts/${tokenHash.slice(0, 40)}`);
  if (rec.exists && rec.data.uid !== uid) return { status: 403, body: { error: 'That purchase belongs to another account.' } };
  const already = await db.get(`sales/${cleanId(orderId)}`);
  if (already.exists) { await ack(); return { status: 200, body: { ok: true, already: true, orderId } }; }

  // Find the checkout (explicit id, else the newest open one for this product).
  let ck = null;
  if (checkoutId) { const c = await db.get(`checkouts/${cleanId(checkoutId)}`); if (c.exists && c.data.uid === uid) ck = { id: cleanId(checkoutId), ...c.data }; }
  if (!ck) {
    const rows = await db.query('checkouts', [['uid', '==', uid], ['productId', '==', productId], ['status', '==', 'open']], { limit: 10 });
    rows.sort((a, b) => b.data.at - a.data.at);
    if (rows[0]) ck = { id: rows[0].id, ...rows[0].data };
  }
  if (ck && ck.productId !== productId) return { status: 400, body: { error: 'That purchase does not match the checkout.' } };
  const amounts = await orderAmounts(env, orderId, cfg);
  const priceINR = ck ? ck.payINR : guessPrice(cfg, productId);
  const exTax = amounts ? amounts.exTaxINR : Math.round((priceINR / 1.18) * 100) / 100; // GST-inclusive fallback
  const order = { orderId, buyerUid: uid, productId, payINR: Math.round(exTax * 100) / 100, taxINR: amounts ? amounts.taxINR : priceINR - exTax, realFeeINR: amounts ? amounts.realFeeINR : null, test: p.purchaseType === 0, checkout: ck ? { id: ck.id, friendPct: ck.friendPct || 0 } : null };
  const built = buildItems(cfg, productId, ck);
  if (!built) return { status: 400, body: { error: 'Start this purchase from the app so we know what it is for.' } };
  Object.assign(order, built);
  await db.commit([db.write(`playReceipts/${tokenHash.slice(0, 40)}`, { uid, productId, orderId, kind: 'product', at: now })]).catch(() => null);
  await db.commit([db.write(`accountIndex/${(await sha256Hex(uid))}`, { uid }, {})]).catch(() => null);
  const r = await applySale({ db, cfg, now, env }, order);
  await ack();
  return { status: 200, body: { ok: true, ...r, productId, consume: true } };
}
function guessPrice(cfg, productId) {
  const m = productId.match(/^nowssb_tier_(\d+)$/);
  if (m) return Number(m[1]);
  const pc = cfg.coupons.paid.find((c) => c.productId === productId); if (pc) return pc.priceINR;
  const gc = cfg.gifts.cards.find((c) => c.productId === productId); if (gc) return gc.priceINR;
  const pr = pick(cfg.products, productId); if (pr) return pr.priceINR;
  return 0;
}
export function buildItems(cfg, productId, ck) {
  const W = cfg.earn.wordWeights;
  const pc = cfg.coupons.paid.find((c) => c.productId === productId);
  if (pc) return { kind: 'scratch', words: 0, items: [{ paidCard: pc, kind: 'scratch', title: pc.title }] };
  const gc = cfg.gifts.cards.find((c) => c.productId === productId);
  if (gc) return { kind: 'giftcard', words: W[gc.earnKind] || 0, items: [{ giftCard: gc, kind: gc.earnKind, title: gc.title, meta: (ck && ck.meta) || {} }] };
  const pr = pick(cfg.products, productId);
  if (pr) return { kind: pr.kind, words: W[pr.kind] || 0, items: [{ grant: pr.grant, kind: pr.kind, title: pr.title }] };
  if (/^nowssb_tier_\d+$/.test(productId)) {
    if (!ck || ck.kind !== 'cart') return null;
    const items = (ck.items || []).map((it) => ({ id: it.id, kind: kindOfBagItem(it), title: it.title, qty: it.qty || 1 }));
    const words = items.reduce((a, it) => a + (W[it.kind] || 0) * (it.qty || 1), 0);
    const kinds = [...new Set(items.map((i) => i.kind))];
    return { kind: kinds.length === 1 ? kinds[0] : 'mixed', words, items };
  }
  return null;
}

/** Subscription order cleared (first order or a renewal) — from /api/play/verify and RTDN. */
export async function settleSubscriptionOrder(env, { uid, ev, now = Date.now() }) {
  if (!ev || !ev.orderId || !ev.entitled) return null;
  const db = await FsDb.fromEnv(env);
  const cfg = await loadEconomy(db);
  const m = String(ev.orderId).match(/\.\.(\d+)$/);
  const renewalIndex = m ? Number(m[1]) + 1 : 0; // GPA.x..0 is the first renewal
  const amounts = await orderAmounts(env, ev.orderId, cfg);
  const planKey = pick(cfg.earn.planMap, ev.tier) || 'basic';
  const months = ev.billing === 'yearly' ? 12 * (renewalIndex + 1) : renewalIndex + 1;
  await db.commit([db.write(`accountIndex/${(await sha256Hex(uid))}`, { uid }, {})]).catch(() => null);
  return applySale({ db, cfg, now, env }, {
    orderId: ev.orderId, buyerUid: uid, productId: ev.productId, kind: 'subscription', planKey,
    items: [{ kind: 'subscription', title: ev.tier + ' ' + ev.billing }], words: 0,
    payINR: amounts ? Math.round(amounts.exTaxINR * 100) / 100 : 0, taxINR: amounts ? amounts.taxINR : 0, realFeeINR: amounts ? amounts.realFeeINR : null,
    isRenewal: renewalIndex > 0, renewalMonths: months, test: !!ev.test, needsPrice: !amounts,
  });
}

/** Refund / chargeback / revoke (RTDN voidedPurchaseNotification). */
export async function settleVoided(env, orderId, reason) {
  const db = await FsDb.fromEnv(env);
  const cfg = await loadEconomy(db);
  return reverseSale({ db, cfg, now: Date.now(), env }, orderId, reason);
}

/** RTDN oneTimeProductNotification: settle with the account bound to the purchase. */
export async function settleOneTimeFromRtdn(env, { sku, purchaseToken }) {
  const p = await getProductPurchase(env, sku, purchaseToken);
  if (p.purchaseState !== 0 || !p.obfuscatedExternalAccountId) return { ignored: 'no account on purchase' };
  const db = await FsDb.fromEnv(env);
  const idx = await db.get(`accountIndex/${p.obfuscatedExternalAccountId}`);
  if (!idx.exists) return { ignored: 'account not indexed yet' };
  return (await settleProduct(env, { uid: idx.data.uid, productId: sku, purchaseToken })).body;
}
