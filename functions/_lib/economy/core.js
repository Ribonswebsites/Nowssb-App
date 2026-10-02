/* Shared transaction session + grants used by every program.

   A Session wraps one Firestore transaction: documents are read once,
   edited in memory and written back together; ledger rows are appended
   (never edited — a correction is a new, opposite row). */
import { cleanId } from './fsdb.js';
import { DAY, dayKey, eventMultiplier, monthKey, rand, resolvePrize, drawWeighted, weekKey, toPaise } from './rules.js';

export class EconomyError extends Error {
  constructor(message, status = 400, code = 'failed-precondition', extra = {}) {
    super(message);
    this.status = status;
    this.code = code;
    this.extra = extra;
  }
}
export const fail = (msg, status = 400, code = 'failed-precondition', extra) => { throw new EconomyError(msg, status, code, extra); };

let _seq = 0;
export function newId(now = Date.now(), prefix = '') {
  // Sorts newest-first by document id, so lists need no composite index.
  const desc = (9e12 - Math.floor(now)).toString(36).padStart(9, '0');
  const r = Math.floor(rand() * 36 ** 5).toString(36).padStart(5, '0');
  _seq = (_seq + 1) % 1296;
  return prefix + desc + r + _seq.toString(36).padStart(2, '0');
}

export class Session {
  constructor(t, { db, cfg, now, env }) {
    this.t = t; this.db = db; this.cfg = cfg; this.now = now; this.env = env;
    this.docs = new Map(); this.dirty = new Set(); this.merges = new Map();
    this.creates = []; this.effects = []; // effects: what the phone should animate
  }
  async doc(path) {
    if (!this.docs.has(path)) {
      const d = await this.t.get(path);
      this.docs.set(path, d.exists ? d.data : null);
    }
    return this.docs.get(path);
  }
  async edit(path, init = {}) {
    let d = await this.doc(path);
    if (!d) { d = { ...init }; this.docs.set(path, d); }
    this.dirty.add(path);
    return d;
  }
  /** Field-level merge for documents the owner may also write (users/{uid}). */
  merge(path, fields) {
    this.merges.set(path, { ...(this.merges.get(path) || {}), ...fields });
    const d = this.docs.get(path);
    if (d) Object.assign(d, fields);
  }
  create(path, data) { this.creates.push([path, data]); }
  append(collection, data, idPrefix = '') {
    const id = newId(this.now, idPrefix);
    this.creates.push([`${collection}/${id}`, { ...data, at: this.now }]);
    return id;
  }
  flush() {
    for (const p of this.dirty) this.t.set(p, this.docs.get(p));
    for (const [p, f] of this.merges) this.t.set(p, f, { merge: true });
    for (const [p, d] of this.creates) this.t.create(p, d);
  }
  effect(e) { this.effects.push(e); }
  get day() { return dayKey(this.now, this.cfg); }
  get week() { return weekKey(this.now, this.cfg); }
  get month() { return monthKey(this.now, this.cfg); }
}

/** Runs fn inside a transaction session and flushes it. */
export async function inTx(ctx, fn) {
  return ctx.db.tx(async (t) => {
    const s = new Session(t, ctx);
    const out = await fn(s);
    s.flush();
    return { ...(out || {}), effects: s.effects };
  });
}

/* ── paths ── */
export const P = {
  user: (u) => `users/${u}`,
  wallet: (u) => `users/${u}/wallet/main`,
  day: (u, d) => `users/${u}/earnCaps/${d}`,
  week: (u, w) => `users/${u}/weeks/${w}`,
  month: (u, m) => `users/${u}/months/${m}`,
  referral: (u) => `users/${u}/referral/main`,
  seller: (u) => `users/${u}/sellerStats/main`,
  payout: (u) => `users/${u}/payout/main`,
  partner: (u) => `users/${u}/partner/main`,
  notify: (u) => `users/${u}/notifications`,
};

export function walletInit(now) {
  return { coins: 0, lifetimeCoins: 0, streak: 0, bestStreak: 0, holds: 0, freezes: 0, freezesLeft: 0, lastDayIdx: null,
    practice: 0, playerOpens: 0, purchases: 0, practiceCredits: 0, plan: 'Free', subUntil: 0, stats: {}, badges: [], cosmetics: [],
    seasonXp: {}, seasonClaimed: {}, createdAt: now, lastActiveAt: now };
}

export async function wallet(s, uid) {
  const w = await s.edit(P.wallet(uid), walletInit(s.now));
  w.stats = w.stats || {}; w.badges = w.badges || []; w.cosmetics = w.cosmetics || [];
  w.seasonXp = w.seasonXp || {}; w.seasonClaimed = w.seasonClaimed || {};
  // 12-month inactivity expiry (Plan B 4.1).
  const idle = s.cfg.rewards.expireAfterInactiveDays * DAY;
  if (w.coins > 0 && w.lastActiveAt && s.now - w.lastActiveAt > idle) {
    s.append('coinLedger', { uid, delta: -w.coins, balance: 0, reason: 'expired', ref: 'inactive' });
    w.coins = 0;
  }
  w.lastActiveAt = s.now;
  return w;
}
export async function today(s, uid) {
  const d = await s.edit(P.day(uid, s.day), { day: s.day, freeCoins: 0, counts: {}, keys: {}, minutes: 0, ladder: [], login: false, scratch: false });
  d.counts = d.counts || {}; d.keys = d.keys || {}; d.ladder = d.ladder || [];
  return d;
}

/**
 * Coins in or out, with a ledger row. Free-activity coins respect the daily
 * ceiling (lower for new accounts) and event multipliers. Returns the amount
 * actually moved.
 */
export async function moveCoins(s, uid, delta, reason, { ref = '', free = false, multiply = free } = {}) {
  const w = await wallet(s, uid);
  let amt = Math.round(delta);
  if (amt > 0 && multiply) amt = Math.round(amt * eventMultiplier(s.now, s.cfg));
  if (amt > 0 && free) {
    const d = await today(s, uid);
    const R = s.cfg.rewards;
    const young = s.now - (w.createdAt || s.now) < R.newAccountDays * DAY;
    const ceiling = young ? R.newAccountCeiling : R.dailyCeiling;
    amt = Math.max(0, Math.min(amt, ceiling - (d.freeCoins || 0)));
    d.freeCoins = (d.freeCoins || 0) + amt;
  }
  if (amt < 0 && w.coins + amt < 0) {
    if (reason.startsWith('reverse')) amt = -w.coins; // a refund cannot push a wallet below zero
    else fail('Not enough coins.', 400, 'failed-precondition', { need: -amt, have: w.coins });
  }
  if (amt === 0) return 0;
  w.coins += amt;
  if (amt > 0) {
    if (reason !== 'checkout-release') w.lifetimeCoins = (w.lifetimeCoins || 0) + amt;
    const sid = s.cfg.rewards.season.id;
    if (reason !== 'reverse' && free) w.seasonXp[sid] = (w.seasonXp[sid] || 0) + amt;
  }
  s.append('coinLedger', { uid, delta: amt, balance: w.coins, reason, ref: String(ref).slice(0, 200) });
  if (amt > 0) s.effect({ kind: 'coins', coins: amt, balance: w.coins, reason });
  return amt;
}

export async function bump(s, uid, metric, by = 1) {
  const w = await wallet(s, uid);
  w.stats[metric] = (w.stats[metric] || 0) + by;
  const wk = await s.edit(P.week(uid, s.week), { week: s.week, counts: {}, activeDays: [], minutesByDay: {} });
  wk.counts = wk.counts || {};
  wk.counts[metric] = (wk.counts[metric] || 0) + by;
  const mo = await s.edit(P.month(uid, s.month), { month: s.month, counts: {}, days: [] });
  mo.counts = mo.counts || {};
  mo.counts[metric] = (mo.counts[metric] || 0) + by;
  return w.stats[metric];
}

export function notify(s, uid, title, body, kind = 'economy', ref = '') {
  s.append(`users/${uid}/notifications`, { title, body, kind, ref, read: false });
}

/* ── plans and passes ── */
const TIER_OF = { basic: 'resonance', plus: 'frequency', standard: 'frequency', premium: 'frequencyX', signature: 'frequencyX' };
export function planOf(user, now) {
  const end = Date.parse((user && user.subscriptionEndDate) || '') || 0;
  const active = !!(user && user.isPro && user.tier && (!end || end > now));
  return { active, own: active && user.subscriptionSource === 'play', tier: active ? user.tier : null, until: end, source: user ? user.subscriptionSource || '' : '' };
}
export function planKeyOfTier(tier, cfg) { return cfg.earn.planMap[tier] || 'basic'; }

/** A gifted or won plan pass. Never satisfies a rank's own-plan rule. */
export async function grantPass(s, uid, tierKey, days, { source = 'gift', needsNoPlan = false, elseCoins = 0, freePlanDays = false } = {}) {
  const user = (await s.doc(P.user(uid))) || {};
  const plan = planOf(user, s.now);
  const wal = await wallet(s, uid);
  if (tierKey === 'ebook') {
    const cur = Date.parse(user.ebookPassUntil || '') || 0;
    const until = new Date(Math.max(cur, s.now) + days * DAY).toISOString();
    s.merge(P.user(uid), { ebookPassUntil: until });
    s.append(`users/${uid}/passes`, { tier: 'ebook', days, until, source });
    return { type: 'pass', tier: 'ebook', days, until, label: `${days}-day ebook pass` };
  }
  if (freePlanDays) {
    const last = wal.lastFreePlanDaysAt || 0;
    if (s.now - last < s.cfg.gifts.freePlanDaysEvery * DAY) {
      if (elseCoins) { await moveCoins(s, uid, elseCoins, 'pass-swap:' + source); return { type: 'coins', coins: elseCoins, label: `${elseCoins} coins (one free plan-days gift every ${s.cfg.gifts.freePlanDaysEvery} days)` }; }
      return { type: 'none', label: 'Free plan days already given this month.' };
    }
  }
  if (plan.active && (needsNoPlan || plan.own)) {
    if (needsNoPlan || elseCoins) {
      if (elseCoins) { await moveCoins(s, uid, elseCoins, 'pass-swap:' + source); return { type: 'coins', coins: elseCoins, label: `${elseCoins} coins (you already hold a plan)` }; }
    }
    // Banked: it starts when the paid plan ends (activated lazily by the summary).
    s.append(`users/${uid}/passes`, { tier: tierKey, days, status: 'banked', source });
    return { type: 'pass', tier: tierKey, days, banked: true, label: `${days}-day ${tierKey} pass (banked until your plan ends)` };
  }
  const tier = TIER_OF[tierKey] || 'resonance';
  const base = plan.active ? Math.max(plan.until, s.now) : s.now;
  const until = new Date(base + days * DAY).toISOString();
  s.merge(P.user(uid), { isPro: true, tier: plan.active && plan.tier ? plan.tier : tier, subscriptionEndDate: until, subscriptionSource: 'gift' });
  s.append(`users/${uid}/passes`, { tier: tierKey, days, until, status: 'active', source });
  if (freePlanDays) wal.lastFreePlanDaysAt = s.now;
  wal.plan = wal.plan && wal.plan !== 'Free' ? wal.plan : tierKey;
  return { type: 'pass', tier: tierKey, days, until, label: `${days}-day ${tierKey} pass` };
}

/* ── prizes ── */
const ITEM_LABEL = {
  stage: 'Stage token', 'stage-fragment': 'Stage fragment', 'stage1-sample': 'Stage 1 sample word', 'stage1-signature': 'Stage 1 of a Signature word',
  'stage1-2': 'Stages 1–2 of a word', 'stage1-3': 'Stages 1–3 of a word', word: 'Word token', bundle10: '10-word bundle', 'signature-full': 'Signature word, all stages',
  'signature-early': 'Signature word, early stages', 'major-2000': 'Major item (₹2,000+)', 'soundbath-preview': 'Sound Bath preview',
};
export function prizeLabel(p) {
  if (!p) return 'Nothing this time';
  if (p.type === 'coins') return `${p.coins} coins`;
  if (p.type === 'percentOff') return `${p.pct}% off ${p.scope === 'any' ? 'any item' : 'a ' + p.scope}${p.capINR ? `, cap ₹${p.capINR}` : ''}`;
  if (p.type === 'token') return ITEM_LABEL[p.item] || p.item;
  if (p.type === 'pass') return `${p.days}-day ${p.tier === 'plus' ? 'Standard' : p.tier[0].toUpperCase() + p.tier.slice(1)} pass`;
  if (p.type === 'scratch') return `${p.rarity[0].toUpperCase() + p.rarity.slice(1)} scratch card`;
  if (p.type === 'giftbox') return `${p.box[0].toUpperCase() + p.box.slice(1)} gift box`;
  if (p.type === 'cosmetic') return 'Profile mark';
  if (p.type === 'restore') return 'Streak Restore';
  return p.label || 'Prize';
}

export async function issueScratch(s, uid, rarity, source, { paid = null, prize = null } = {}) {
  const C = s.cfg.coupons;
  let p = prize;
  let index = -1;
  if (!p) {
    const pool = C.freePools[rarity] || C.freePools.common;
    const d = drawWeighted(pool);
    index = d.index;
    p = resolvePrize(d.item.prize);
  }
  const id = newId(s.now, 'sc');
  s.create(`users/${uid}/scratchCards/${id}`, {
    rarity, source, paid: paid || null, prize: p, label: prizeLabel(p), poolIndex: index, status: 'sealed',
    at: s.now, expiresAt: s.now + C.freeExpiryDays * DAY,
  });
  s.effect({ kind: 'scratch', id, rarity });
  return { type: 'scratch', id, rarity, label: prizeLabel({ type: 'scratch', rarity }) };
}

/** Puts any prize on the account. Returns a display row. */
export async function grantPrize(s, uid, prize, source) {
  const p = resolvePrize(prize);
  if (!p) return { type: 'none', label: 'Nothing this time' };
  switch (p.type) {
    case 'coins': {
      const n = await moveCoins(s, uid, p.coins, source);
      return { type: 'coins', coins: n, label: `${n} coins` };
    }
    case 'percentOff': {
      const id = newId(s.now, 'cp');
      s.create(`users/${uid}/coupons/${id}`, { ...p, label: prizeLabel(p), status: 'active', source, at: s.now, expiresAt: s.now + s.cfg.coupons.percentOffExpiryDays * DAY });
      s.effect({ kind: 'coupon', id });
      return { type: 'percentOff', id, label: prizeLabel(p), pct: p.pct, scope: p.scope };
    }
    case 'token': {
      const id = newId(s.now, 'tk');
      s.create(`users/${uid}/tokens/${id}`, { item: p.item, label: prizeLabel(p), status: 'active', source, at: s.now });
      return { type: 'token', id, item: p.item, label: prizeLabel(p) };
    }
    case 'pass': return grantPass(s, uid, p.tier, p.days, { source, needsNoPlan: !!p.needsNoPlan, elseCoins: p.elseCoins || 0, freePlanDays: !!p.freePlanDays });
    case 'scratch': return issueScratch(s, uid, p.rarity, source);
    case 'giftbox': {
      const id = newId(s.now, 'bx');
      s.create(`users/${uid}/boxes/${id}`, { box: p.box, status: 'sealed', source, at: s.now, expiresAt: s.now + s.cfg.gifts.freeClaimDays * DAY * 4 });
      return { type: 'giftbox', id, box: p.box, label: prizeLabel(p) };
    }
    case 'cosmetic': {
      const w = await wallet(s, uid);
      if (!w.cosmetics.includes(p.id)) w.cosmetics.push(p.id);
      return { type: 'cosmetic', id: p.id, label: 'Profile mark' };
    }
    case 'badge': {
      const w = await wallet(s, uid);
      if (!w.badges.includes(p.id)) w.badges.push(p.id);
      return { type: 'badge', id: p.id, label: 'Badge' };
    }
    case 'restore': {
      const w = await wallet(s, uid);
      w.restores = (w.restores || 0) + 1;
      return { type: 'restore', label: 'Streak Restore' };
    }
    default: return { type: 'none', label: 'Nothing this time' };
  }
}
/** Extras written as strings in the settings doc: badge:x, giftbox:gold, pass:premium:7, early:48 */
export async function grantExtra(s, uid, extra, source) {
  const [k, a, b] = String(extra).split(':');
  if (k === 'badge') return grantPrize(s, uid, { type: 'badge', id: a }, source);
  if (k === 'giftbox') return grantPrize(s, uid, { type: 'giftbox', box: a }, source);
  if (k === 'pass') return grantPass(s, uid, a, Number(b) || 7, { source });
  if (k === 'early') { const w = await wallet(s, uid); w.earlyHours = Math.max(w.earlyHours || 0, Number(a) || 24); return { type: 'early', hours: Number(a), label: `New words ${a} h early` }; }
  return null;
}
export const paise = toPaise;
export { cleanId };
