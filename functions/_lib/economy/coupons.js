/* NowssB Coupons — scratch cards (free daily, earned, after-purchase, paid),
   cut-out ticket codes, Daily Spin. The server picks every prize before the
   card is shown; the phone only animates the reveal. Odds are published. */
import { DAY, drawRarity, drawWeighted, oddsPct, rand, resolvePrize } from './rules.js';
import { P, bump, fail, grantPass, grantPrize, inTx, issueScratch, moveCoins, newId, planOf, prizeLabel, today, wallet } from './core.js';
import { checkBadges } from './rewards.js';

/** Daily free scratch: issued and decided now; the reveal grants it. */
export async function dailyScratch(ctx, uid) {
  return inTx(ctx, async (s) => {
    const C = s.cfg.coupons;
    if (!C.dailyScratch) fail('The daily card is off right now.');
    const d = await today(s, uid);
    if (d.scratch) {
      return { already: true, id: d.scratchId || null };
    }
    d.scratch = true;
    const pick = drawWeighted(C.dailyScratchPool);
    const prize = resolvePrize(pick.item.prize);
    const card = await issueScratch(s, uid, 'common', 'daily', { prize });
    d.scratchId = card.id;
    return { id: card.id, rarity: 'common', label: prizeLabel(prize), prize };
  });
}

/** Reveal (scratch) a sealed card: the prize lands on the account. */
export async function revealScratch(ctx, uid, data) {
  const id = String((data && data.id) || '');
  return inTx(ctx, async (s) => {
    const path = `users/${uid}/scratchCards/${id}`;
    const c = await s.doc(path);
    if (!c) fail('Card not found.', 404, 'not-found');
    if (c.status === 'revealed') return { already: true, rarity: c.rarity, label: c.label, prize: c.prize, granted: c.granted || null };
    if (c.status !== 'sealed') fail('This card can’t be scratched.', 400, 'failed-precondition');
    if (c.expiresAt && c.expiresAt < s.now) { const e = await s.edit(path); e.status = 'expired'; fail('This card expired.'); }
    const e = await s.edit(path);
    e.status = 'revealed'; e.revealedAt = s.now;
    const granted = await grantPrize(s, uid, c.prize, 'scratch:' + c.rarity);
    // Paid cards: every card returns at least its price (value floor).
    if (c.paid && c.paid.floorCoins && granted.type !== 'coins') {
      // Non-coin prizes are worth more than the floor by design; nothing extra.
    } else if (c.paid && c.paid.floorCoins && granted.coins < c.paid.floorCoins) {
      granted.topUp = await moveCoins(s, uid, c.paid.floorCoins - granted.coins, 'scratch-floor');
    }
    e.granted = granted;
    s.append('couponLedger', { uid, cardId: id, rarity: c.rarity, paid: !!c.paid, prize: granted.label, ...(granted.type === 'coins' ? { coins: granted.coins + (granted.topUp || 0) } : {}), source: c.source || '' });
    await bump(s, uid, 'scratches');
    await checkBadges(s, uid);
    s.effect({ kind: 'reveal', rarity: c.rarity, label: granted.label });
    return { rarity: c.rarity, label: granted.label, prize: c.prize, granted };
  });
}

/** Legacy `scratchCoupon`: daily card issued and revealed in one go. */
export async function scratchCoupon(ctx, uid, data) {
  if (data && data.id) return revealScratch(ctx, uid, data);
  const d = await dailyScratch(ctx, uid);
  if (d.already) {
    if (d.id) return { ...(await revealScratch(ctx, uid, { id: d.id })), already: true };
    fail('Today’s card is scratched. A new one comes tomorrow.', 400, 'already-exists');
  }
  const r = await revealScratch(ctx, uid, { id: d.id });
  return { ...r, id: d.id, coins: r.granted && r.granted.type === 'coins' ? r.granted.coins : 0 };
}

/** Paid card bought with coins at its published coin price. */
export async function buyScratchWithCoins(ctx, uid, data) {
  const cardId = String((data && data.cardId) || '');
  return inTx(ctx, async (s) => {
    const card = s.cfg.coupons.paid.find((c) => c.id === cardId);
    if (!card) fail('Unknown card.', 400, 'invalid-argument');
    if (!card.coinPrice) fail('This card is not sold for coins.');
    await moveCoins(s, uid, -card.coinPrice, 'spend:scratch-' + card.id);
    const d = drawWeighted(card.odds);
    const prize = resolvePrize(d.item.prize);
    const floorCoins = Math.round((card.coinPrice * s.cfg.coupons.paidValueFloorPct) / 100);
    const c = await issueScratch(s, uid, card.id, 'coins', { prize, paid: { cardId: card.id, coins: card.coinPrice, floorCoins } });
    return { id: c.id, rarity: card.id };
  });
}

/** Published odds of every card (shown before any purchase). */
export function oddsTable(cfg) {
  const C = cfg.coupons;
  return {
    free: Object.fromEntries(Object.entries(C.freePools).map(([r, list]) => [r, list.map((x, i) => ({ label: prizeLabel(x.prize.type === 'coins' ? { type: 'coins', coins: `${x.prize.min}–${x.prize.max}` } : x.prize), pct: oddsPct(list)[i] }))])),
    daily: C.dailyScratchPool.map((x, i) => ({ label: prizeLabel(x.prize.type === 'coins' ? { type: 'coins', coins: `${x.prize.min}–${x.prize.max}` } : x.prize), pct: oddsPct(C.dailyScratchPool)[i] })),
    afterPurchase: C.afterPurchase, afterSubscription: C.afterSubscription,
    paid: C.paid.map((c) => ({ id: c.id, title: c.title, productId: c.productId, priceINR: c.priceINR, coinPrice: c.coinPrice, rarest: c.rarest, odds: c.odds.map((x, i) => ({ label: x.label, pct: oddsPct(c.odds)[i] })) })),
    spin: cfg.spin.slices.map((x, i) => ({ label: x.label, pct: oddsPct(cfg.spin.slices)[i] })),
  };
}

/** Rarity of the free card after a purchase, by spend. */
export function afterPurchaseRarity(cfg, payINR, isSub) {
  const C = cfg.coupons;
  if (isSub) return drawRarity(C.afterSubscription);
  const band = C.afterPurchase.find((b) => payINR <= b.maxINR) || C.afterPurchase[C.afterPurchase.length - 1];
  return drawRarity(band.odds);
}

/* ── cut-out tickets (codes on Home and Coupons) ── */
export async function claimTicket(ctx, uid, data) {
  const code = String((data && data.code) || '').toUpperCase().trim();
  return inTx(ctx, async (s) => {
    const T = s.cfg.coupons.codes[code];
    if (!T) fail('That code is not active.', 404, 'not-found');
    const w = await wallet(s, uid);
    w.tickets = w.tickets || {};
    const last = w.tickets[code] || 0;
    if (T.type === 'locked') return { locked: true, label: T.label, how: T.how };
    if (T.type === 'action') return { action: T.action, label: T.label, how: 'Do the activity and the coins land on their own.' };
    if (T.type === 'chance') {
      const d = await today(s, uid);
      if (d.keys['chance:' + code]) fail('One try a day on this card. Come back tomorrow.', 400, 'already-exists');
      d.keys['chance:' + code] = 1;
      const win = rand() * 100 < T.winPct;
      if (!win) return { win: false, label: T.label, winPct: T.winPct };
      const g = await grantPrize(s, uid, T.prize, 'chance:' + code);
      return { win: true, granted: g, label: g.label, winPct: T.winPct };
    }
    if (T.type === 'welcome') {
      if (w.welcomeAt) fail('Your welcome set is already on your account.', 400, 'already-exists');
      if (s.now - (w.createdAt || s.now) > 14 * DAY) fail('The welcome set is for new accounts.');
      w.welcomeAt = s.now;
      const items = [{ type: 'coins', coins: await moveCoins(s, uid, 20, 'welcome-ticket'), label: '20 coins' }, await issueScratch(s, uid, 'common', 'welcome')];
      return { items };
    }
    if (last && (!T.onceEveryDays || s.now - last < T.onceEveryDays * DAY)) fail('You already claimed this ticket.', 400, 'already-exists');
    if (T.type === 'pass') {
      const user = (await s.doc(P.user(uid))) || {};
      if (T.needsTrialEnded && planOf(user, s.now).active) fail('This pass is for after a trial ends.');
      w.tickets[code] = s.now;
      const g = await grantPass(s, uid, T.tier, T.days, { source: 'ticket:' + code, needsNoPlan: !!T.needsNoPlan, freePlanDays: true });
      return { granted: g, label: g.label };
    }
    w.tickets[code] = s.now;
    const g = await grantPrize(s, uid, { type: T.type, pct: T.pct, capINR: T.capINR, scope: T.scope }, 'ticket:' + code);
    return { granted: g, label: g.label, couponId: g.id };
  });
}

/* ── Daily Spin ── */
export async function spin(ctx, uid) {
  return inTx(ctx, async (s) => {
    const S = s.cfg.spin;
    const d = await today(s, uid);
    if ((d.counts.spin || 0) >= S.perDay) fail('One spin a day. The wheel resets at midnight.', 400, 'already-exists');
    d.counts.spin = (d.counts.spin || 0) + 1;
    if (S.costCoins) await moveCoins(s, uid, -S.costCoins, 'spend:spin');
    const pick = drawWeighted(S.slices);
    const g = await grantPrize(s, uid, pick.item.prize, 'spin');
    const w = await wallet(s, uid);
    w.stats.spins = (w.stats.spins || 0) + 1;
    await checkBadges(s, uid);
    return { slice: pick.index, label: pick.item.label, granted: g, cost: S.costCoins };
  });
}

/** Paid-card guard used before the Play sheet opens (18+, country, monthly limit). */
export async function paidCardCheck(s, uid, card, data) {
  const C = s.cfg.coupons;
  const user = (await s.doc(P.user(uid))) || {};
  const country = String((data && data.country) || user.country || 'IN').toUpperCase();
  if (C.paidBlockedCountries.includes(country) || !s.cfg.countries.paidCouponsOpen.includes(country)) fail('Paid cards are not offered in your country. Free cards still work.');
  if (C.paidAdultsOnly && !(data && data.adult) && !user.adultConfirmedAt) fail('Paid cards are for adults (18+). Confirm your age to continue.', 400, 'failed-precondition', { needsAdult: true });
  if (data && data.adult && !user.adultConfirmedAt) s.merge(P.user(uid), { adultConfirmedAt: new Date(s.now).toISOString() });
  const w = await wallet(s, uid);
  const mk = s.month;
  const spent = (w.paidCardMonth === mk ? w.paidCardSpentINR : 0) || 0;
  if (spent + card.priceINR > C.paidMonthlyLimitINR) fail(`Monthly limit for paid cards is ₹${C.paidMonthlyLimitINR}.`);
  return { country };
}
export { newId, DAY };
