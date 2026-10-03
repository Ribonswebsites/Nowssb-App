/* NowssB Gifts — bought gift cards (send, schedule, claim, cancel within the
   cooling-off window) and the gift history. Free time gifts live in
   rewards.js (daily box, weekly/monthly gift). Coins are never giftable. */
import { DAY, rand } from './rules.js';
import { P, bump, fail, grantPrize, inTx, notify, prizeLabel, wallet } from './core.js';
import { checkBadges } from './rewards.js';

const A = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
export function giftCode() {
  let s = 'NWSB-';
  for (let i = 0; i < 8; i++) { if (i === 4) s += '-'; s += A[Math.floor(rand() * A.length)]; }
  return s;
}

/** Called by the purchase pipeline once Play has cleared the payment. */
export async function createGiftCard(s, uid, card, meta, orderId) {
  const G = s.cfg.gifts;
  const code = giftCode();
  const deliverAt = Math.max(s.now, Number(meta.deliverAt) || 0);
  const doc = {
    code, cardId: card.id, title: card.title, item: card.item, priceINR: card.priceINR, fromUid: uid,
    fromName: String(meta.fromName || '').slice(0, 40), toName: String(meta.toName || '').slice(0, 40),
    message: String(meta.message || '').slice(0, 280), design: String(meta.design || 'lotus').slice(0, 30),
    deliverAt, status: 'active', orderId, at: s.now, expiresAt: s.now + G.cardValidityDays * DAY,
    coolingUntil: s.now + G.coolingOffDays * DAY,
    redeemableAt: card.priceINR >= G.highValueINR ? s.now + G.highValueDelayHours * 3600e3 : s.now,
  };
  s.create(`giftCards/${code}`, doc);
  s.append('giftLedger', { code, uid, senderUid: uid, itemId: card.id, cents: Math.round((card.priceINR || 0) * 100), status: 'issued', source: 'play', orderId });
  s.create(`users/${uid}/giftsSent/${code}`, { code, title: card.title, toName: doc.toName, status: 'active', at: s.now, deliverAt, expiresAt: doc.expiresAt });
  const w = await wallet(s, uid);
  w.stats.gifts_sent = (w.stats.gifts_sent || 0) + 1;
  await checkBadges(s, uid);
  s.effect({ kind: 'giftcard', code, title: card.title });
  return { code, title: card.title, deliverAt, expiresAt: doc.expiresAt };
}

/** What an admin-console gift code (gifts/{GFT…}) holds. */
export const ADMIN_GIFT_PRIZES = {
  word: { type: 'token', item: 'word' },
  meaning: { type: 'token', item: 'meaning' },
  bundle: { type: 'token', item: 'bundle10' },
  resonance: { type: 'pass', tier: 'basic', days: 30 },
  frequency: { type: 'pass', tier: 'plus', days: 30 },
  frequency_x: { type: 'pass', tier: 'premium', days: 30 },
};

/** Codes made in the admin console (Earn & gifts · Make codes). One use. */
async function redeemAdminGift(ctx, uid, code) {
  return inTx(ctx, async (s) => {
    const path = `gifts/${code}`;
    const g = await s.doc(path);
    if (!g) fail('That gift code was not found.', 404, 'not-found');
    if (g.status === 'redeemed') fail(g.redeemedBy === uid ? 'You already opened this gift.' : 'This gift was already claimed.', 400, 'already-exists');
    if (g.status !== 'unredeemed') fail('This gift is no longer active.');
    const exp = typeof g.expiresAt === 'number' ? g.expiresAt : Date.parse(g.expiresAt || '') || 0;
    if (exp && exp < s.now) fail('This gift expired.');
    if (g.recipientEmail) {
      // The verified email on the sign-in token, never users/{uid}.email
      // (that field is editable by the account itself).
      const c = ctx.claims || {};
      const email = c.email && c.email_verified === true ? String(c.email).toLowerCase() : '';
      if (!email) fail('Verify your email address to open this gift.', 403, 'permission-denied');
      if (email !== String(g.recipientEmail).trim().toLowerCase()) fail('This gift code was made for a different account.', 403, 'permission-denied');
    }
    const prize = ADMIN_GIFT_PRIZES[g.item || g.itemId];
    if (!prize) fail('This gift holds something the app does not know yet. Update NowssB.');
    const e = await s.edit(path);
    const granted = await grantPrize(s, uid, prize, 'gift:' + code);
    e.status = 'redeemed'; e.redeemedBy = uid; e.redeemedAt = s.now; e.granted = granted.label;
    s.create(`users/${uid}/giftsReceived/${code}`, { code, title: g.label || 'A gift from NowssB', fromName: 'NowssB', message: g.note || '', design: 'gold', granted: granted.label, at: s.now });
    s.append('giftLedger', { code, uid, senderUid: g.senderUid || '', itemId: g.item || g.itemId, cents: 0, status: 'redeemed', source: 'admin', campaign: g.campaign || '', at: s.now });
    await bump(s, uid, 'gifts_received');
    s.effect({ kind: 'giftopen', title: g.label || 'A gift', design: 'gold', label: granted.label });
    return { title: g.label || 'A gift from NowssB', message: g.note || '', fromName: 'NowssB', design: 'gold', granted };
  });
}

export async function redeemGift(ctx, uid, data) {
  const code = String((data && data.code) || '').toUpperCase().replace(/\s+/g, '');
  if (/^GFT[A-Z0-9]{4,16}$/.test(code)) return redeemAdminGift(ctx, uid, code);
  if (!/^NWSB-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(code)) fail('Gift codes look like NWSB-XXXX-XXXX.', 400, 'invalid-argument');
  return inTx(ctx, async (s) => {
    const G = s.cfg.gifts;
    const path = `giftCards/${code}`;
    const g = await s.doc(path);
    if (!g) fail('That gift code was not found.', 404, 'not-found');
    if (g.status === 'redeemed') fail(g.redeemedBy === uid ? 'You already opened this gift.' : 'This gift was already claimed.', 400, 'already-exists');
    if (g.status !== 'active') fail('This gift is no longer active.');
    if (g.expiresAt < s.now) fail('This gift expired.');
    if (g.fromUid === uid) fail('Send this code to the person it is for — a gift can’t be opened by its buyer.');
    if (g.deliverAt > s.now) fail('This gift opens on ' + new Date(g.deliverAt + 330 * 60e3).toISOString().slice(0, 10) + '.');
    if (g.redeemableAt > s.now) fail('High-value gifts open 24 hours after purchase (fraud check). Try again soon.');
    const w = await wallet(s, uid);
    if (s.now - (w.createdAt || s.now) < G.newAccountHoldHours * 3600e3 && g.priceINR >= G.highValueINR) fail('New accounts can open high-value gifts after 24 hours.');
    const e = await s.edit(path);
    e.status = 'redeemed'; e.redeemedBy = uid; e.redeemedAt = s.now;
    const granted = await grantPrize(s, uid, g.item, 'gift:' + code);
    e.granted = granted.label;
    s.append('giftLedger', { code, uid, senderUid: g.fromUid, itemId: g.item && g.item.type ? g.item.type : String(g.item || ''), cents: Math.round((g.priceINR || 0) * 100), status: 'redeemed', source: 'play', at: s.now });
    s.create(`users/${uid}/giftsReceived/${code}`, { code, title: g.title, fromName: g.fromName || '', message: g.message || '', design: g.design, granted: granted.label, at: s.now });
    const sent = await s.edit(`users/${g.fromUid}/giftsSent/${code}`, { code });
    sent.status = 'redeemed'; sent.redeemedAt = s.now;
    notify(s, g.fromUid, 'Your gift was opened', `${g.toName || 'Your friend'} opened ${g.title}.`, 'gift', code);
    await bump(s, uid, 'gifts_received');
    s.effect({ kind: 'giftopen', title: g.title, design: g.design, label: granted.label });
    return { title: g.title, message: g.message, fromName: g.fromName, design: g.design, granted };
  });
}

/** Look inside a gift code before opening it (read-only; nothing moves). */
export async function peekGift(ctx, uid, data) {
  const code = String((data && data.code) || '').toUpperCase().replace(/\s+/g, '');
  return inTx(ctx, async (s) => {
    if (/^GFT[A-Z0-9]{4,16}$/.test(code)) {
      const g = await s.doc(`gifts/${code}`);
      if (!g) fail('That gift code was not found.', 404, 'not-found');
      const prize = ADMIN_GIFT_PRIZES[g.item || g.itemId];
      return { code, title: g.label || 'A gift from NowssB', fromName: 'NowssB', message: g.note || '', inside: prize ? prizeLabel(prize) : (g.label || 'A gift'), status: g.status === 'unredeemed' ? 'ready' : g.status, mine: g.redeemedBy === uid };
    }
    if (!/^NWSB-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(code)) fail('Gift codes look like NWSB-XXXX-XXXX.', 400, 'invalid-argument');
    const g = await s.doc(`giftCards/${code}`);
    if (!g) fail('That gift code was not found.', 404, 'not-found');
    const status = g.status !== 'active' ? g.status : g.expiresAt < s.now ? 'expired' : g.deliverAt > s.now || g.redeemableAt > s.now ? 'later' : 'ready';
    return { code, title: g.title, fromName: g.fromName || '', message: g.message || '', design: g.design || 'gold', inside: g.item ? prizeLabel(g.item) : g.title, status, opensAt: Math.max(g.deliverAt || 0, g.redeemableAt || 0) || null, mine: g.redeemedBy === uid, yours: g.fromUid === uid };
  });
}

/** Cooling-off: an unopened gift can be cancelled for a refund within 7 days. */
export async function cancelGift(ctx, uid, data) {
  const code = String((data && data.code) || '').toUpperCase();
  return inTx(ctx, async (s) => {
    const g = await s.doc(`giftCards/${code}`);
    if (!g || g.fromUid !== uid) fail('Gift not found.', 404, 'not-found');
    if (g.status !== 'active') fail('Only an unopened gift can be cancelled.');
    if (s.now > g.coolingUntil) fail(`Gifts can be cancelled within ${s.cfg.gifts.coolingOffDays} days of purchase.`);
    const e = await s.edit(`giftCards/${code}`);
    e.status = 'cancelled'; e.cancelledAt = s.now;
    const sent = await s.edit(`users/${uid}/giftsSent/${code}`, { code });
    sent.status = 'cancelled';
    s.append('adminLog', { type: 'gift_refund_requested', uid, code, orderId: g.orderId, priceINR: g.priceINR });
    return { status: 'cancelled', note: 'Refund is issued to your Play account by the team within 3 working days.' };
  });
}

/** Void when the payment was refunded or charged back. */
export async function voidGiftForOrder(s, orderId, code) {
  if (!code) return;
  const g = await s.doc(`giftCards/${code}`);
  if (!g) return;
  const e = await s.edit(`giftCards/${code}`);
  if (g.status === 'redeemed') e.status = 'reversed';
  else e.status = 'void';
  e.voidedAt = s.now; e.voidOrder = orderId;
  return g;
}
