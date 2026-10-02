/* Pure economy rules — no I/O. Every number comes from the settings doc
   (config.js DEFAULT_ECONOMY merged with Firestore config/economy). Unit
   tested in tools/economy/economy-rules.test.mjs. */

export const DAY = 86400e3;
const round2 = (n) => Math.round(n * 100) / 100;
export const toPaise = (inr) => Math.round(inr * 100);
export const fromPaise = (p) => p / 100;

/* ── calendar (days roll at the configured offset, IST by default) ── */
export function shifted(nowMs, cfg) { return new Date(nowMs + (cfg.dayOffsetMinutes || 0) * 60e3); }
export function dayKey(nowMs, cfg) {
  const d = shifted(nowMs, cfg);
  return d.getUTCFullYear() + String(d.getUTCMonth() + 1).padStart(2, '0') + String(d.getUTCDate()).padStart(2, '0');
}
export function monthKey(nowMs, cfg) { return dayKey(nowMs, cfg).slice(0, 6); }
export function dayIndex(nowMs, cfg) { return Math.floor((nowMs + (cfg.dayOffsetMinutes || 0) * 60e3) / DAY); }
export function weekKey(nowMs, cfg) {
  // ISO-like week starting Monday, keyed by the Monday's day index.
  const di = dayIndex(nowMs, cfg);
  const weekday = (di + 3) % 7; // 1970-01-01 was a Thursday → Monday = 0
  return 'W' + (di - weekday);
}
export function weekdayOf(nowMs, cfg) { return shifted(nowMs, cfg).getUTCDay(); } // 0 = Sunday
export function hourOf(nowMs, cfg) { return shifted(nowMs, cfg).getUTCHours(); }

/* ── randomness (server only; the phone never rolls) ── */
export function rand() {
  const a = new Uint32Array(2);
  crypto.getRandomValues(a);
  return (a[0] * 2 ** 21 + (a[1] >>> 11)) / 2 ** 53;
}
export function drawWeighted(list, r = rand()) {
  const total = list.reduce((s, x) => s + (Number(x.w) || 0), 0);
  if (!(total > 0)) return { item: list[0], index: 0 };
  let roll = r * total;
  for (let i = 0; i < list.length; i++) {
    roll -= Number(list[i].w) || 0;
    if (roll < 0) return { item: list[i], index: i };
  }
  return { item: list[list.length - 1], index: list.length - 1 };
}
export function oddsPct(list) {
  const total = list.reduce((s, x) => s + (Number(x.w) || 0), 0) || 1;
  return list.map((x) => round2(((Number(x.w) || 0) * 100) / total));
}
/** A prize template → concrete prize (coins amount fixed now). */
export function resolvePrize(p, r = rand()) {
  if (!p) return null;
  if (p.type === 'coins') {
    const min = Math.round(p.min ?? p.coins ?? 0);
    const max = Math.round(p.max ?? min);
    return { type: 'coins', coins: min + Math.floor(r * (max - min + 1)) };
  }
  return { ...p };
}
export function drawRarity(odds, r = rand()) {
  const list = Object.entries(odds).map(([rarity, w]) => ({ rarity, w }));
  return drawWeighted(list, r).item.rarity;
}

/* ── coins in a cart (Plan B 4.3) ── */
export function coinCapPct(listINR, kind, cfg) {
  if (kind === 'subscription') return cfg.cart.subscriptionCoinPct;
  for (const b of cfg.cart.coinCapBands) if (listINR <= b.maxINR) return b.pct;
  return cfg.cart.coinCapBands[cfg.cart.coinCapBands.length - 1].pct;
}

/**
 * Checkout quote. Order: link discount, then coupon, then coins. Everything
 * together stays within maxTotalDiscountPct of the list price, coins within
 * the band cap, and the remainder is charged as a Play price tier.
 */
export function quoteCheckout({ listINR, kind, linkPct = 0, coupon = null, coinsBalance = 0, coinsWanted = null, cfg }) {
  const list = round2(Math.max(0, listINR));
  const maxOff = round2((list * cfg.cart.maxTotalDiscountPct) / 100);
  const linkOff = round2(Math.min((list * linkPct) / 100, maxOff));
  let couponOff = 0;
  if (coupon && coupon.type === 'percentOff' && couponFits(coupon, kind)) {
    couponOff = round2(Math.min(((list - linkOff) * coupon.pct) / 100, coupon.capINR ?? Infinity, maxOff - linkOff));
  }
  const afterDisc = round2(list - linkOff - couponOff);
  const coinCapINR = round2(Math.min((list * coinCapPct(list, kind, cfg)) / 100, maxOff - linkOff - couponOff, afterDisc));
  const perRupee = cfg.coinsPerRupee;
  const wantINR = coinsWanted == null ? Infinity : Math.max(0, coinsWanted) / perRupee;
  const coinTargetINR = Math.max(0, Math.min(coinCapINR, Math.floor(coinsBalance) / perRupee, wantINR));
  const tiers = [...cfg.cart.payTiersINR].sort((a, b) => a - b);
  // Smallest tier that the allowed coins can bring the bill down to.
  const floorPay = round2(afterDisc - coinTargetINR);
  let tier = tiers.find((t) => t >= floorPay - 1e-9 && t <= afterDisc + 1e-9);
  if (tier === undefined) {
    // No tier inside [floorPay, afterDisc]: charge the largest tier under the bill (NowssB absorbs the gap, Net shrinks).
    const under = tiers.filter((t) => t <= afterDisc + 1e-9);
    tier = under.length ? under[under.length - 1] : null;
  }
  if (tier === null) return { ok: false, error: 'This price is below the smallest Play tier.' };
  const coinsINR = round2(Math.max(0, Math.min(coinTargetINR, afterDisc - tier)));
  const absorbed = round2(Math.max(0, afterDisc - coinsINR - tier));
  return {
    ok: true,
    listINR: list,
    linkOffINR: linkOff,
    couponOffINR: couponOff,
    coinsINR,
    coins: Math.round(coinsINR * perRupee),
    absorbedINR: absorbed,
    payINR: tier,
    productId: 'nowssb_tier_' + tier,
    coinCapPct: coinCapPct(list, kind, cfg),
  };
}
export function couponFits(coupon, kind) {
  const s = coupon.scope || 'any';
  if (s === 'any') return kind !== 'giftcard' && kind !== 'scratch';
  if (s === 'word') return kind === 'word' || kind === 'stage';
  if (s === 'meaning') return kind === 'meaning';
  if (s === 'signature') return kind === 'signature';
  if (s === 'bundle') return kind === 'bundle';
  if (s === 'subscription') return kind === 'subscription';
  return s === kind;
}

/* ── the money lock ── */
/**
 * Splits one cleared sale. All amounts INR.
 *  exTaxINR   what the buyer paid, minus tax (after link/coupon/coins)
 *  realFeeINR Google's real fee when known (developerRevenue); else null
 *  words      word-equivalents in the sale (for the ₹15 floor)
 *  ownPct     seller's direct rate incl. fast-start (0 when not eligible)
 *  leg1Pct / leg2Pct  sponsor bonuses (0 when not eligible)
 *  renewal    halves every rate (Plan A)
 */
export function moneyLock({ exTaxINR, realFeeINR = null, words = 0, ownPct = 0, leg1Pct = 0, leg2Pct = 0, renewal = false, cfg }) {
  const L = cfg.lock;
  const exTax = Math.max(0, exTaxINR);
  const reserve = round2(Math.max((exTax * L.storeReservePct) / 100, realFeeINR == null ? 0 : realFeeINR));
  const net = round2(Math.max(0, exTax - reserve));
  const f = renewal ? L.renewalRateFactor : 1;
  let own = round2((net * ownPct * f) / 100);
  let floorApplied = false;
  const floor = round2(L.floorPerWordINR * words);
  if (ownPct > 0 && !renewal && words > 0 && own < floor) { own = floor; floorApplied = true; }
  let leg1 = round2((net * leg1Pct * f) / 100);
  let leg2 = round2((net * leg2Pct * f) / 100);
  const cap = round2((net * L.payoutCapPct) / 100);
  const ownBase = round2((net * ownPct * f) / 100);
  let shrunk = [];
  const total = () => round2(own + leg1 + leg2);
  for (const step of L.shrinkOrder) {
    if (total() <= cap) break;
    const over = round2(total() - cap);
    if (step === 'leg2') { const cut = Math.min(leg2, over); leg2 = round2(leg2 - cut); if (cut) shrunk.push('leg2'); }
    if (step === 'leg1') { const cut = Math.min(leg1, over); leg1 = round2(leg1 - cut); if (cut) shrunk.push('leg1'); }
    if (step === 'floor' && floorApplied) { const cut = Math.min(own - ownBase, over); own = round2(own - cut); if (cut) shrunk.push('floor'); }
  }
  if (total() > cap) { own = round2(Math.max(0, cap - leg1 - leg2)); shrunk.push('own'); }
  const promoter = total();
  return {
    exTax: round2(exTax), reserve, net, own, leg1, leg2, promoter, cap,
    company: round2(net - promoter), companyPct: net ? round2(((net - promoter) * 100) / net) : 100,
    floorApplied, shrunk,
  };
}

/* ── ranks ── */
export function rankIndexForWords(words, cfg) {
  const ranks = cfg.earn.ranks;
  let idx = 0;
  for (let i = 0; i < ranks.length; i++) if (words >= ranks[i].minWords) idx = i;
  return idx;
}
export function planMeets(rank, plan, cfg) {
  // plan: { active: bool, own: bool (paid by the holder, not gifted), tier }
  if (!plan || !plan.active || !plan.own) return false;
  if (rank.plan === 'any') return true;
  if (rank.plan === 'top') return cfg.earn.topTiers.includes(plan.tier);
  return true;
}
/**
 * Effective standing from lifetime words, the rolling window, an
 * appointment, the holder's own paid plan and the fast track.
 */
export function standing({ wordsLifetime = 0, words90 = 0, appointed = null, fastTrack = null, plan = null, rankSince = 0, firstSaleAt = 0, now = Date.now(), cfg }) {
  const ranks = cfg.earn.ranks;
  const E = cfg.earn;
  let byWords = rankIndexForWords(wordsLifetime, cfg);
  let idx = byWords;
  let provisional = false;
  let provisionalUntil = 0;
  let appointedIdx = -1;
  if (appointed && appointed.rank) {
    appointedIdx = ranks.findIndex((r) => r.id === appointed.rank);
    if (appointedIdx > idx) {
      const until = (appointed.at || 0) + E.provisionalDays * DAY;
      const sold = Math.max(0, wordsLifetime - (appointed.wordsAtAppoint || 0));
      if (now < until) { idx = appointedIdx; provisional = sold < E.provisionalMinWords; provisionalUntil = until; }
      else if (sold >= E.provisionalMinWords) idx = appointedIdx; // confirmed by the 10-word check
      else idx = Math.max(byWords, appointedIdx - 1); // missed → steps down one rank
    }
  }
  if (fastTrack) {
    const ft = ranks.findIndex((r) => r.id === fastTrack);
    if (ft > idx) idx = ft;
  }
  const titleIdx = idx;
  // Keeping a rank: minimum words per rolling 90 days (after the first 90 days at that rank).
  let steppedDown = false;
  if (idx > 0 && rankSince && now - rankSince > E.keepWindowDays * DAY && words90 < ranks[idx].keep90) { idx -= 1; steppedDown = true; }
  // The plan each rank needs. A gifted plan never counts (own paid only).
  let rateIdx = idx;
  while (rateIdx > 0 && !planMeets(ranks[rateIdx], plan, cfg)) rateIdx -= 1;
  const canEarn = !E.requirePaidPlanToEarn || planMeets(ranks[0], plan, cfg);
  const rank = ranks[rateIdx];
  let ratePct = canEarn ? rank.ratePct : 0;
  if (canEarn && provisional && rateIdx === appointedIdx) ratePct = (ratePct * E.provisionalRatePct) / 100;
  const fastStart = canEarn && firstSaleAt && now - firstSaleAt < E.fastStartDays * DAY ? E.fastStartBonusPct : (canEarn && !firstSaleAt ? E.fastStartBonusPct : 0);
  const nextIdx = Math.min(ranks.length - 1, byWords + 1);
  return {
    rankIndex: rateIdx,
    rank: rank.id,
    title: ranks[titleIdx].title,
    titleRank: ranks[titleIdx].id,
    metal: ranks[titleIdx].metal,
    ratePct: round2(ratePct),
    fastStartPct: fastStart,
    canEarn,
    provisional,
    provisionalUntil,
    steppedDown,
    planShort: rateIdx < idx,
    leg: canEarn ? rank.leg : [0, 0],
    coinsPerSale: rank.coinsPerSale,
    appoints: provisional ? [] : ranks[titleIdx].appoints,
    teamMax: ranks[titleIdx].teamMax,
    nextWords: byWords >= ranks.length - 1 ? null : ranks[nextIdx].minWords,
    nextTitle: byWords >= ranks.length - 1 ? null : ranks[nextIdx].title,
    keep90: ranks[idx].keep90,
  };
}
export function targetsCrossed(before, after, cfg) {
  return cfg.earn.targets.filter((t) => before < t.words && after >= t.words);
}

/* ── partner program ── */
export function partnerLevel(points, cfg) {
  let lvl = null;
  for (const l of cfg.partner.levels) if (points >= l.points) lvl = l;
  return lvl;
}
export function partnerPointsFor(kind, planKey, cfg) {
  const P = cfg.partner.points;
  if (kind === 'subscription') return P[planKey] || 0;
  return P[kind] || 0;
}

/* ── rewards ── */
export function loginCoins(streak, cfg) {
  const L = cfg.rewards.login;
  return Math.min(L.max, L.base + Math.floor(Math.max(0, streak - 1) / L.perStreakDays));
}
/**
 * Streak step for a new active day. Returns { streak, holdsUsed, holds, broken }.
 * A missed day is covered by a streak-hold or a freeze; two holds at most.
 */
export function stepStreak({ lastDayIdx = null, todayIdx, streak = 0, holds = 0, freezes = 0, cfg }) {
  if (lastDayIdx === todayIdx) return { streak, holds, freezes, same: true };
  if (lastDayIdx === null || lastDayIdx === undefined) return { streak: 1, holds, freezes, broken: false };
  const missed = todayIdx - lastDayIdx - 1;
  let h = holds; let f = freezes; let used = 0;
  if (missed > 0) {
    if (missed <= h + f) {
      const fromF = Math.min(f, missed); f -= fromF; h -= missed - fromF; used = missed;
    } else {
      return { streak: 1, holds: h, freezes: f, broken: true, missed };
    }
  }
  let s = streak + 1;
  if (s % cfg.rewards.streakHold.everyDays === 0) h = Math.min(cfg.rewards.streakHold.max, h + 1);
  return { streak: s, holds: h, freezes: f, used, broken: false };
}
export function eventMultiplier(nowMs, cfg) {
  let m = cfg.rewards.eventMultiplier || 1;
  for (const e of cfg.rewards.events || []) {
    const s = Date.parse(e.startsAt || '') || 0;
    const t = Date.parse(e.endsAt || '') || Infinity;
    if (nowMs < s || nowMs > t) continue;
    if (Array.isArray(e.weekdays) && e.weekdays.length && !e.weekdays.includes(weekdayOf(nowMs, cfg))) continue;
    m = Math.max(m, Number(e.multiplier) || 1);
  }
  return m;
}
export function seasonTier(xp, cfg) {
  const s = cfg.rewards.season;
  return Math.min(s.tiers, Math.floor(xp / s.xpPerTier));
}
export function seasonReward(n, premium) {
  const coins = (20 + 5 * n) * (premium ? 2 : 1);
  const out = { coins };
  if (n % 5 === 0) out.scratch = n >= 25 ? 'epic' : n >= 15 ? 'rare' : 'common';
  if (premium && n % 10 === 0) out.giftbox = n >= 30 ? 'diamond' : n >= 20 ? 'gold' : 'silver';
  return out;
}
export function weeklyChestCoins(activeDays, cfg) {
  const c = cfg.rewards.weeklyChest;
  return Math.round(c.minCoins + ((c.maxCoins - c.minCoins) * Math.min(7, activeDays)) / 7);
}

/* ── badges: 100+ achievements generated from families ── */
const FAMILIES = [
  ['streak', 'Streak', 'days in a row', [3, 7, 14, 21, 30, 60, 100, 150, 200, 365]],
  ['minutes', 'Listener', 'minutes in the app', [30, 60, 120, 300, 600, 1000, 2000, 3000, 5000, 10000]],
  ['logins', 'Regular', 'days opened', [5, 10, 25, 50, 75, 100, 150, 200, 300, 500]],
  ['read_meaning', 'Reader', 'meanings read', [5, 10, 25, 50, 100, 200, 300, 500, 750, 1000]],
  ['pronounce80', 'Clear Voice', 'scores of 80+', [5, 10, 25, 50, 100, 200, 300, 500, 750, 1000]],
  ['sound_bath', 'Sound Bather', 'Sound Baths', [3, 10, 25, 50, 100, 150, 200, 300, 400, 500]],
  ['shares', 'Sharer', 'words shared', [1, 3, 5, 10, 25, 50, 100, 200, 300, 500]],
  ['purchases', 'Collector', 'purchases', [1, 3, 5, 10, 20, 30, 50, 75, 100, 150]],
  ['scratches', 'Lucky Hand', 'cards scratched', [1, 5, 10, 25, 50, 100, 150, 200, 300, 500]],
  ['quests', 'Quester', 'quests done', [1, 5, 10, 25, 50, 75, 100, 150, 200, 300]],
  ['mastery', 'Master', 'word levels gained', [5, 10, 25, 50, 100, 150, 200, 300, 400, 500]],
  ['gifts_sent', 'Giver', 'gifts sent', [1, 3, 5, 10, 20, 30, 50, 75, 100, 150]],
];
const SINGLES = [
  ['early_bird', 'Early Bird', 'Opened before 7 am', 'early', 1],
  ['night_owl', 'Night Owl', 'Opened after 11 pm', 'night', 1],
  ['explorer', 'Explorer', 'Visited all six programs in a day', 'explorer', 1],
  ['weekend', 'Weekender', 'Active on a Saturday and Sunday', 'weekend', 1],
  ['comeback', 'Comeback', 'Came back after a week away', 'comebacks', 1],
  ['first_gift', 'First Gift', 'Opened a gift box', 'boxes', 1],
  ['spinner', 'Spinner', 'Spun the Daily Spin', 'spins', 1],
  ['seller', 'First Sale', 'A friend bought through your link', 'friends', 1],
];
export function badgeCatalog() {
  const out = [];
  for (const [metric, name, unit, steps] of FAMILIES) {
    steps.forEach((n, i) => out.push({ id: `${metric}-${n}`, title: `${name} ${['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'][i]}`, line: `${n} ${unit}`, metric, goal: n, coins: Math.min(200, 10 + i * 20) }));
  }
  for (const [id, title, line, metric, goal] of SINGLES) out.push({ id, title, line, metric, goal, coins: 20 });
  return out;
}
export function newBadges(stats, have, cfg) {
  const got = new Set(have || []);
  return badgeCatalog().filter((b) => !got.has(b.id) && (Number(stats[b.metric]) || 0) >= b.goal);
}

/* ── reference ── */
export async function linkCode(uid, sku) {
  const d = await crypto.subtle.digest('SHA-256', new TextEncoder().encode('nowssb-ref|' + uid + '|' + (sku || 'any')));
  const A = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const b = new Uint8Array(d);
  let s = '';
  for (let i = 0; i < 9; i++) s += A[b[i] % A.length];
  return s;
}
export function skuKey(kind, id) {
  const k = String(kind || 'any').toLowerCase().replace(/[^a-z]/g, '');
  const i = String(id || '').toLowerCase().replace(/[^a-z0-9_-]/g, '').slice(0, 60);
  return i ? `${k}:${i}` : k;
}
