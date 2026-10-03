/* Checkout: link discount → coupon → coins (capped), remainder charged as a
   Play one-time product. Coins and the coupon are held while the Play sheet
   is open and released if it is abandoned. Coins never buy cash, never pay a
   whole bill, and paid cards / gift cards take no coins or coupons. */
import { DAY, couponFits, quoteCheckout } from './rules.js';
import { P, fail, inTx, moveCoins, newId, pick, wallet } from './core.js';
import { friendDiscountPct } from './reference.js';
import { kindOfBagItem } from './sales.js';
import { paidCardCheck } from './coupons.js';

const CONTENT = ['word', 'meaning', 'signature', 'ebook'];
const BAG_PREFIX = [...CONTENT, 'stage', 'bundle'];
const own = (o, k) => o != null && Object.prototype.hasOwnProperty.call(o, k);

function tierFor(cfg, kind, price) {
  const tiers = (cfg.cart.contentTiersINR || {})[kind] || [];
  if (!tiers.length) return Math.ceil(price);
  for (const t of tiers) if (t >= price) return t;
  return tiers[tiers.length - 1];
}

/* The server's own price for a bag line: the admin's per-item price
   (config/store items), else the kind default; ebooks may carry their
   catalogue price, but only as one of the ebook price points. */
export function serverPrice(cfg, store, kind, id, clientPrice) {
  const items = (store && store.items) || {};
  const defs = (store && store.defaults) || {};
  if (own(items, id) && Number.isFinite(Number(items[id]))) {
    const v = Number(items[id]);
    return v <= 0 ? 0 : tierFor(cfg, kind, v);
  }
  if (kind === 'ebook' && ((cfg.cart.contentTiersINR || {}).ebook || []).includes(clientPrice)) return clientPrice;
  const d = own(defs, kind) && Number.isFinite(Number(defs[kind])) ? Number(defs[kind]) : (cfg.cart.contentDefaultINR || {})[kind] || 99;
  return tierFor(cfg, kind, d);
}

export function cartFrom(cfg, items, store) {
  if (!Array.isArray(items) || !items.length) fail('Your bag is empty.', 400, 'invalid-argument');
  if (items.length > 20) fail('Up to 20 items per checkout.', 400, 'invalid-argument');
  let list = 0;
  const clean = items.map((it) => {
    const id = String((it && it.id) || '').slice(0, 120);
    const prefix = id.includes(':') ? id.slice(0, id.indexOf(':')).toLowerCase() : '';
    if (!BAG_PREFIX.includes(prefix) || id.length <= prefix.length + 1) fail('That item can\u2019t be bought here.', 400, 'invalid-argument');
    // The kind comes from the item id, never from the phone.
    const kind = prefix;
    const said = kindOfBagItem(it);
    if (it.kind != null && String(it.kind).trim() !== '' && said !== kind) fail('That item doesn\u2019t match its kind.', 400, 'invalid-argument');
    const sent = Number(it.price);
    if (!Number.isFinite(sent)) fail('Price missing.', 400, 'invalid-argument');
    let price;
    if (CONTENT.includes(kind)) {
      price = serverPrice(cfg, store, kind, id, sent);
      if (Math.abs(price - sent) > 0.5) fail('Prices changed. Open your bag again to see the new price.', 409, 'failed-precondition');
    } else {
      price = sent;
      const lo = cfg.cart.priceFloorINR[kind] ?? 1; const hi = cfg.cart.priceCeilINR[kind] ?? 5000;
      if (!(price >= lo && price <= hi)) fail(`Price for ${it.title || kind} is out of range.`, 400, 'invalid-argument');
    }
    const qty = Math.max(1, Math.min(10, Math.floor(Number(it.qty) || 1)));
    list += price * qty;
    return { id, kind, title: String(it.title || '').slice(0, 80), price, qty };
  });
  const kinds = [...new Set(clean.map((i) => i.kind))];
  return { items: clean, listINR: Math.round(list * 100) / 100, kind: kinds.length === 1 ? kinds[0] : 'mixed' };
}

async function releaseExpired(s, uid) {
  const rows = await s.t.query('checkouts', [['uid', '==', uid], ['status', '==', 'open']], { limit: 10 });
  for (const r of rows) {
    if (r.data.expiresAt > s.now) continue;
    await release(s, uid, r.id, r.data, 'expired');
  }
  return rows.filter((r) => r.data.expiresAt > s.now);
}
async function release(s, uid, id, data, why) {
  const c = await s.edit(`checkouts/${id}`);
  c.status = 'released'; c.releasedAt = s.now; c.releaseWhy = why;
  if (data.coins > 0) await moveCoins(s, uid, data.coins, 'checkout-release', { ref: id });
  if (data.couponId) { const cp = await s.edit(`users/${uid}/coupons/${data.couponId}`); if (cp.status === 'held') cp.status = 'active'; }
}

/** Price preview (no holds). */
export async function quote(ctx, uid, data) {
  return inTx(ctx, async (s) => buildQuote(s, uid, data));
}
async function buildQuote(s, uid, data) {
  const cart = cartFrom(s.cfg, data && data.items, (await s.doc('config/store')) || {});
  const w = await wallet(s, uid);
  const ref = (await s.doc(P.referral(uid))) || null;
  const linkPct = friendDiscountPct(ref, cart.kind, s.cfg, s.now);
  let coupon = null;
  if (data && data.couponId) {
    const c = await s.doc(`users/${uid}/coupons/${data.couponId}`);
    if (!c || c.status !== 'active' || (c.expiresAt && c.expiresAt < s.now)) fail('That coupon is not active.');
    if (!couponFits(c, cart.kind)) fail(`That coupon works on ${c.scope === 'any' ? 'any item' : c.scope} purchases.`);
    coupon = c;
  }
  const q = quoteCheckout({ listINR: cart.listINR, kind: cart.kind, linkPct, coupon, coinsBalance: w.coins, coinsWanted: data && data.coins != null ? Number(data.coins) : null, cfg: s.cfg });
  if (!q.ok) fail(q.error);
  // Coupons that would fit, for the picker.
  return { ...q, cart, friendPct: linkPct, coinsBalance: w.coins, couponId: coupon ? data.couponId : null };
}

/** Holds coins + coupon and returns the Play product to charge. */
export async function beginCheckout(ctx, uid, data) {
  const kind = String((data && data.kind) || 'cart');
  return inTx(ctx, async (s) => {
    const open = await releaseExpired(s, uid);
    if (open.length >= 3) for (const r of open) await release(s, uid, r.id, r.data, 'replaced');
    const id = newId(s.now, 'ck');
    const base = { uid, kind, status: 'open', at: s.now, expiresAt: s.now + s.cfg.cart.checkoutTtlMinutes * 60e3 };
    if (kind === 'cart') {
      const q = await buildQuote(s, uid, data);
      if (q.coins > 0) await moveCoins(s, uid, -q.coins, 'checkout-hold', { ref: id });
      if (q.couponId) { const cp = await s.edit(`users/${uid}/coupons/${q.couponId}`); cp.status = 'held'; cp.heldBy = id; }
      s.create(`checkouts/${id}`, { ...base, productId: q.productId, payINR: q.payINR, listINR: q.listINR, coins: q.coins, couponId: q.couponId || null, friendPct: q.friendPct, items: q.cart.items, quote: { linkOffINR: q.linkOffINR, couponOffINR: q.couponOffINR, coinsINR: q.coinsINR, absorbedINR: q.absorbedINR } });
      return { checkoutId: id, productId: q.productId, payINR: q.payINR, quote: q };
    }
    if (kind === 'scratch') {
      const card = s.cfg.coupons.paid.find((c) => c.id === String(data.cardId || ''));
      if (!card) fail('Unknown card.', 400, 'invalid-argument');
      await paidCardCheck(s, uid, card, data);
      s.create(`checkouts/${id}`, { ...base, productId: card.productId, payINR: card.priceINR, coins: 0, items: [{ id: 'scratch:' + card.id, kind: 'scratch', title: card.title }] });
      return { checkoutId: id, productId: card.productId, payINR: card.priceINR };
    }
    if (kind === 'giftcard') {
      const card = s.cfg.gifts.cards.find((c) => c.id === String(data.cardId || ''));
      if (!card) fail('Unknown gift card.', 400, 'invalid-argument');
      const w = await wallet(s, uid);
      const d = s.day;
      w.giftSends = w.giftSends && w.giftSends.day === d ? w.giftSends : { day: d, n: 0 };
      if (w.giftSends.n >= s.cfg.gifts.maxSendPerDay) fail(`Up to ${s.cfg.gifts.maxSendPerDay} gift cards a day.`);
      if (card.oncePerQuarter && w.lastSig3 && s.now - w.lastSig3 < 91 * DAY) fail('The Signature day card can be sent once a quarter.');
      const deliverAt = Number(data.deliverAt) || 0;
      if (deliverAt && deliverAt > s.now + 365 * DAY) fail('Pick a delivery date within a year.');
      w.giftSends.n += 1;
      if (card.oncePerQuarter) w.lastSig3 = s.now;
      const meta = { toName: String(data.toName || '').slice(0, 40), fromName: String(data.fromName || '').slice(0, 40), message: String(data.message || '').slice(0, 280), design: String(data.design || 'lotus').slice(0, 30), deliverAt };
      s.create(`checkouts/${id}`, { ...base, productId: card.productId, payINR: card.priceINR, coins: 0, meta, items: [{ id: 'gift:' + card.id, kind: 'giftcard', title: card.title }] });
      return { checkoutId: id, productId: card.productId, payINR: card.priceINR };
    }
    if (kind === 'product') {
      const pid = String(data.productId || '');
      const pr = pick(s.cfg.products, pid);
      if (!pr) fail('Unknown product.', 400, 'invalid-argument');
      s.create(`checkouts/${id}`, { ...base, productId: pid, payINR: pr.priceINR, coins: 0, items: [{ id: 'product:' + pid, kind: pr.kind, title: pr.title }] });
      return { checkoutId: id, productId: pid, payINR: pr.priceINR };
    }
    fail('Unknown checkout.', 400, 'invalid-argument');
  });
}

export async function cancelCheckout(ctx, uid, data) {
  const id = String((data && data.checkoutId) || '');
  return inTx(ctx, async (s) => {
    const c = await s.doc(`checkouts/${id}`);
    if (!c || c.uid !== uid) fail('Checkout not found.', 404, 'not-found');
    if (c.status !== 'open') return { status: c.status };
    await release(s, uid, id, c, 'cancelled');
    return { status: 'released', coins: c.coins || 0 };
  });
}
