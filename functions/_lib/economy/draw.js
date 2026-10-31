/* Daily lucky draw (free entry, one per user per day).

   The server is the only source of odds and outcomes. Each entry is drawn
   once, inside the entry transaction, with crypto randomness (rules.rand):
   about 1 in `cfg.draw.denominator` entries wins. A day's draw also has a
   ceiling on winners so the prize pool is bounded. A won prize lands in the
   user's coupons (users/{uid}/coupons) or gift boxes (users/{uid}/boxes).

   Paths (server-only; clients have no write access):
     draws/{drawId}                      { day, entries, winners }
     draws/{drawId}/entries/{uid}        { won, prizeId, claimId }
     drawWins/{claimId}                  private: uid, prize, review
     drawWinners/{claimId}               public list row: displayName, prizeTitle, wonAtMs, review (approved only) */
import { DAY, rand } from './rules.js';
import { EconomyError, grantPrize, inTx, newId, notify } from './core.js';

export const DRAW_DEFAULTS = {
  enabled: true,
  numerator: 1,
  denominator: 150,
  maxWinnersPerDay: 25,
  prizes: [
    { id: 'coupon25', kind: 'coupon', title: '25% off any item', detail: 'A coupon in your Coupons, up to ₹500 off. Valid for 30 days.', prize: { type: 'percentOff', pct: 25, scope: 'any', capINR: 500 } },
    { id: 'giftGold', kind: 'gift', title: 'Gold gift box', detail: 'A sealed gold gift box in your Gifts. Open it any time.', prize: { type: 'giftbox', box: 'gold' } },
  ],
};

export function drawCfg(cfg) {
  const d = { ...DRAW_DEFAULTS, ...((cfg && cfg.draw) || {}) };
  d.denominator = Math.max(2, Math.floor(Number(d.denominator) || 150));
  d.numerator = Math.max(1, Math.min(d.denominator - 1, Math.floor(Number(d.numerator) || 1)));
  d.maxWinnersPerDay = Math.max(0, Math.floor(Number(d.maxWinnersPerDay) || 0));
  if (!Array.isArray(d.prizes) || !d.prizes.length) d.prizes = DRAW_DEFAULTS.prizes;
  return d;
}

/** Day window [start, end) in ms for the configured day offset. */
export function dayWindow(nowMs, cfg) {
  const off = ((cfg && cfg.dayOffsetMinutes) || 0) * 60e3;
  const start = Math.floor((nowMs + off) / DAY) * DAY - off;
  return { start, end: start + DAY };
}

/** Pure: does this roll win? r in [0,1). */
export function rollWins(r, d) { return r < d.numerator / d.denominator; }

export function firstNameInitial(name) {
  const parts = String(name || '').trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return '';
  const first = parts[0].slice(0, 20);
  return parts.length > 1 ? `${first} ${parts[parts.length - 1][0].toUpperCase()}.` : first;
}

const iso = (ms) => new Date(ms).toISOString();
const publicPrize = (p) => (p ? { id: p.id, kind: p.kind === 'coupon' ? 'coupon' : 'gift', title: p.title, detail: p.detail || '' } : null);

function statusOut(ctx, d, drawId, entry) {
  const { end } = dayWindow(ctx.now, ctx.cfg);
  return {
    drawId,
    odds: { text: `About ${d.numerator} in ${d.denominator}`, numerator: d.numerator, denominator: d.denominator },
    closesAt: iso(end),
    // Each entry is drawn the moment it is made, so results are ready then.
    resultsAt: entry ? iso(entry.at || ctx.now) : iso(end),
    open: d.enabled !== false,
    entered: !!entry,
    result: entry ? { won: !!entry.won, prize: entry.won ? publicPrize(d.prizes.find((p) => p.id === entry.prizeId) || entry.prizePublic) : null, claimId: entry.claimId || null } : null,
    prizes: d.prizes.map(publicPrize),
    rulesText: `Free to enter, once a day. About ${d.numerator} in ${d.denominator} entries wins a gift or a coupon, drawn on our server the moment you enter. Prizes go straight into your Gifts or Coupons. Prizes have no cash value. A new draw starts every day.`,
  };
}

export const drawIdFor = (s) => `d${s.day}`;

export async function drawStatus(ctx, uid) {
  const d = drawCfg(ctx.cfg);
  return inTx(ctx, async (s) => {
    const drawId = drawIdFor(s);
    const entry = await s.doc(`draws/${drawId}/entries/${uid}`);
    return statusOut(ctx, d, drawId, entry);
  });
}

export async function drawEnter(ctx, uid, data = {}, claims = {}) {
  const d = drawCfg(ctx.cfg);
  if (d.enabled === false) throw new EconomyError('The lucky draw is switched off for now.', 403, 'restricted');
  return inTx(ctx, async (s) => {
    const drawId = drawIdFor(s);
    if (data.drawId && String(data.drawId) !== drawId) throw new EconomyError('That draw has closed. Today\'s draw is open now.', 409, 'failed-precondition', { drawId });
    const entryPath = `draws/${drawId}/entries/${uid}`;
    const existing = await s.doc(entryPath);
    if (existing) return statusOut(ctx, d, drawId, existing); // safe to repeat
    const day = await s.edit(`draws/${drawId}`, { day: s.day, entries: 0, winners: 0, createdAt: s.now });
    day.entries = (day.entries || 0) + 1;
    const won = (day.winners || 0) < d.maxWinnersPerDay && rollWins(rand(), d);
    const entry = { uid, won, at: s.now, prizeId: null, claimId: null };
    if (won) {
      const prize = d.prizes[Math.floor(rand() * d.prizes.length) % d.prizes.length];
      day.winners = (day.winners || 0) + 1;
      const granted = await grantPrize(s, uid, prize.prize, 'luckyDraw');
      const claimId = newId(s.now, 'dw');
      entry.prizeId = prize.id; entry.claimId = claimId; entry.prizePublic = publicPrize(prize);
      const showName = data.showName === true;
      const displayName = (showName && firstNameInitial(claims.name)) || 'A NowssB member';
      s.create(`drawWins/${claimId}`, { uid, drawId, prizeId: prize.id, prizeTitle: prize.title, kind: prize.kind, granted: granted || null, displayName, review: null, at: s.now });
      s.create(`drawWinners/${claimId}`, { drawId, displayName, prizeTitle: prize.title, kind: prize.kind, wonAtMs: s.now, review: null });
      notify(s, uid, 'You won the lucky draw', `${prize.title} is in your ${prize.kind === 'coupon' ? 'Coupons' : 'Gifts'}.`, 'draw', claimId);
      s.effect({ kind: 'draw', won: true, prizeId: prize.id });
    }
    s.create(entryPath, entry);
    return statusOut(ctx, d, drawId, entry);
  });
}

export async function drawWinners(ctx, uid, data = {}) {
  const limit = Math.max(1, Math.min(50, Math.floor(Number(data.limit) || 20)));
  const cursor = Number(data.cursor);
  const where = Number.isFinite(cursor) && cursor > 0 ? [['wonAtMs', '<', cursor]] : [];
  const rows = await ctx.db.query('drawWinners', where, { limit: limit + 1, orderBy: ['wonAtMs', 'desc'] });
  const page = rows.slice(0, limit);
  return {
    winners: page.map((r) => ({
      id: r.id,
      displayName: r.data.displayName || 'A NowssB member',
      prizeTitle: r.data.prizeTitle || 'Prize',
      wonAt: iso(Number(r.data.wonAtMs) || 0),
      ...(r.data.review && r.data.review.status === 'approved' ? { review: { text: String(r.data.review.text || ''), ...(r.data.review.stars ? { stars: r.data.review.stars } : {}) } } : {}),
    })),
    nextCursor: rows.length > limit ? String(page[page.length - 1].data.wonAtMs) : null,
  };
}

export async function drawReview(ctx, uid, data = {}) {
  const claimId = String(data.claimId || '');
  const text = String(data.text || '').trim();
  if (!/^[a-z0-9]{6,60}$/i.test(claimId)) throw new EconomyError('That prize was not found.', 404, 'not-found');
  if (!text) throw new EconomyError('Write a few words first.', 400, 'invalid-argument');
  if (text.length > 280) throw new EconomyError('Keep it under 280 characters.', 400, 'invalid-argument');
  let stars = null;
  if (data.stars != null) {
    stars = Math.floor(Number(data.stars));
    if (!(stars >= 1 && stars <= 5)) throw new EconomyError('Stars go from 1 to 5.', 400, 'invalid-argument');
  }
  return inTx(ctx, async (s) => {
    const win = await s.doc(`drawWins/${claimId}`);
    if (!win || win.uid !== uid) throw new EconomyError('Only the winner of this prize can review it.', 403, 'permission-denied');
    const w = await s.edit(`drawWins/${claimId}`);
    w.review = { text, stars, status: 'pending', at: s.now };
    return { status: 'pending' };
  });
}

/** Admin: approve or reject a winner's review. Approved ones show on the winners list. */
export async function reviewDrawReview(ctx, uid, data = {}) {
  const claimId = String(data.claimId || '');
  const approve = data.approve === true;
  return inTx(ctx, async (s) => {
    const win = await s.doc(`drawWins/${claimId}`);
    if (!win || !win.review) throw new EconomyError('No review to moderate.', 404, 'not-found');
    const w = await s.edit(`drawWins/${claimId}`);
    w.review = { ...w.review, status: approve ? 'approved' : 'rejected', moderatedBy: uid, moderatedAt: s.now };
    const row = await s.edit(`drawWinners/${claimId}`);
    row.review = approve ? { text: w.review.text, stars: w.review.stars || null, status: 'approved' } : null;
    return { status: w.review.status };
  });
}
