/* One read for every program screen: balances, today's loops, quests,
   cards, gifts, links, Partner points and the public part of the settings. */
import { DAY, dayIndex, monthKey, seasonTier, weekKey, loginCoins } from './rules.js';
import { P, inTx, planOf, grantPass } from './core.js';
import { ladderState, badgeList } from './rewards.js';
import { oddsTable } from './coupons.js';

export function publicConfig(cfg) {
  const R = cfg.rewards;
  return {
    version: cfg.version, coinsPerRupee: cfg.coinsPerRupee,
    rewards: { dailyCeiling: R.dailyCeiling, login: R.login, streakMilestones: R.streakMilestones, streakHold: R.streakHold, streakRestore: R.streakRestore, comeback: R.comeback, actions: R.actions, timeLadder: R.timeLadder, weeklyQuests: R.weeklyQuests, weeklyChest: R.weeklyChest, weeklyGift: R.weeklyGift, monthlyQuest: R.monthlyQuest, monthlyGift: R.monthlyGift, monthlyMark: R.monthlyMark, starterQuests: R.starterQuests, mastery: R.mastery, sets: R.sets, buying: R.buying, season: R.season, leagues: R.leagues, spend: R.spend, events: R.events, eventMultiplier: R.eventMultiplier, expireAfterInactiveDays: R.expireAfterInactiveDays },
    cart: { coinCapBands: cfg.cart.coinCapBands, subscriptionCoinPct: cfg.cart.subscriptionCoinPct, maxTotalDiscountPct: cfg.cart.maxTotalDiscountPct, order: cfg.cart.order, payTiersINR: cfg.cart.payTiersINR },
    odds: oddsTable(cfg),
    coupons: { rarities: cfg.coupons.rarities, paidAdultsOnly: cfg.coupons.paidAdultsOnly, paidMonthlyLimitINR: cfg.coupons.paidMonthlyLimitINR, freeExpiryDays: cfg.coupons.freeExpiryDays, codes: Object.fromEntries(Object.entries(cfg.coupons.codes).map(([k, v]) => [k, { type: v.type, label: v.label, how: v.how || '', winPct: v.winPct || null }])) },
    spin: { costCoins: cfg.spin.costCoins, perDay: cfg.spin.perDay, slices: cfg.spin.slices.map((x) => ({ label: x.label, w: x.w })) },
    gifts: { boxes: Object.fromEntries(Object.entries(cfg.gifts.boxes).map(([k, b]) => [k, { title: b.title, minutes: b.minutes || null }])), cards: cfg.gifts.cards.map((c) => ({ id: c.id, title: c.title, productId: c.productId, priceINR: c.priceINR })), cardValidityDays: cfg.gifts.cardValidityDays, coolingOffDays: cfg.gifts.coolingOffDays, freeClaimDays: cfg.gifts.freeClaimDays },
    products: cfg.products,
    reference: { linkBase: cfg.reference.linkBase, holdDays: cfg.reference.holdDays, attribution: cfg.reference.attribution, friendDiscount: cfg.reference.friendDiscount, welcome: cfg.reference.welcome, activation: cfg.reference.activation, sharerLadder: cfg.reference.sharerLadder },
    partner: cfg.partner,
    earn: { enabled: cfg.earn.enabled, ranks: cfg.earn.ranks, targets: cfg.earn.targets, provisionalDays: cfg.earn.provisionalDays, provisionalMinWords: cfg.earn.provisionalMinWords, fastStartDays: cfg.earn.fastStartDays, fastStartBonusPct: cfg.earn.fastStartBonusPct, monthlyPoolPct: cfg.earn.monthlyPoolPct, monthlyPoolTop: cfg.earn.monthlyPoolTop, keepWindowDays: cfg.earn.keepWindowDays, payout: { minINR: cfg.earn.payout.minINR, payoutDay: cfg.earn.payout.payoutDay, launchModeManual: cfg.earn.payout.launchModeManual }, wordWeights: cfg.earn.wordWeights, planMap: cfg.earn.planMap },
    lock: cfg.lock,
    countries: cfg.countries,
  };
}

const list = async (db, parent, coll, where = [], limit = 50) => (await db.query(coll, where, { parent, limit })).map((r) => ({ id: r.id, ...r.data }));

export async function economySummary(ctx, uid) {
  const { db, cfg, now } = ctx;
  const day = (await import('./rules.js')).dayKey(now, cfg);
  const wk = weekKey(now, cfg);
  const mo = monthKey(now, cfg);
  const prevWk = weekKey(now - 7 * DAY, cfg);
  const [w, d, wd, pwd, md, ref, partner, seller, user] = await Promise.all([
    db.get(P.wallet(uid)), db.get(P.day(uid, day)), db.get(P.week(uid, wk)), db.get(P.week(uid, prevWk)), db.get(P.month(uid, mo)),
    db.get(P.referral(uid)), db.get(P.partner(uid)), db.get(P.seller(uid)), db.get(P.user(uid)),
  ]);
  const base = `users/${uid}`;
  const [cards, coupons, tokens, boxes, passes, sent, received] = await Promise.all([
    list(db, base, 'scratchCards', [['status', '==', 'sealed']], 60),
    list(db, base, 'coupons', [['status', '==', 'active']], 60),
    list(db, base, 'tokens', [['status', '==', 'active']], 60),
    list(db, base, 'boxes', [['status', '==', 'sealed']], 30),
    list(db, base, 'passes', [], 30),
    list(db, base, 'giftsSent', [], 30),
    list(db, base, 'giftsReceived', [], 30),
  ]);
  const coinRows = await db.query('coinLedger', [['uid', '==', uid]], { limit: 200 }).catch(() => []);
  const ms = (v) => (typeof v === 'number' ? v : v instanceof Date ? v.getTime() : Date.parse(v || '') || 0);
  const recentCoins = coinRows.map((r) => ({ id: r.id, ...(r.data || {}), at: ms((r.data || {}).at) })).sort((a, b) => (b.at || 0) - (a.at || 0)).slice(0, 12)
    .map((r) => ({ delta: r.delta || 0, reason: String(r.reason || ''), balance: r.balance ?? null, at: r.at || 0 }));
  const W = w.data || {};
  const D = d.data || {};
  const WK = wd.data || {};
  const MO = md.data || {};
  const R = cfg.rewards;
  const stats = W.stats || {};
  const weekMetric = (m) => m === 'activeDays' ? (WK.activeDays || []).length : m === 'minutes' ? Math.floor(Object.values(WK.minutesByDay || {}).reduce((a, b) => a + b, 0)) : (WK.counts || {})[m] || 0;
  const claimedW = WK.claimed || [];
  const weekGiftOk = (doc) => doc && !(doc.claimed || []).includes('gift') && Object.values(doc.minutesByDay || {}).filter((m) => m >= R.weeklyGift.minutesPerDay).length >= R.weeklyGift.activeDays;
  const sid = R.season.id;
  const xp = (W.seasonXp || {})[sid] || 0;
  const plan = planOf(user.data || {}, now);
  // Banked passes start when no plan is active.
  const banked = passes.filter((p) => p.status === 'banked');
  if (!plan.active && banked.length) {
    await inTx(ctx, async (s) => {
      const b = banked[0];
      s.t.set(`users/${uid}/passes/${b.id}`, { status: 'started', startedAt: now }, { merge: true });
      await grantPass(s, uid, b.tier, b.days, { source: 'banked' });
    }).catch(() => null);
  }
  const todayIdx = dayIndex(now, cfg);
  const broken = W.brokenStreak && todayIdx - W.brokenStreak.dayIdx <= R.streakRestore.maxMissedDays ? W.brokenStreak : null;
  return {
    live: true,
    now,
    wallet: { coins: W.coins || 0, lifetimeCoins: W.lifetimeCoins || 0, streak: W.streak || 0, bestStreak: W.bestStreak || 0, holds: W.holds || 0, freezes: W.freezes || 0, restores: W.restores || 0, brokenStreak: broken, practiceCredits: W.practiceCredits || 0, cosmetics: W.cosmetics || [], badges: (W.badges || []).length, earlyHours: W.earlyHours || 0, coinsBackBonusPct: W.coinsBackBonusPct || 0, leagueTier: W.leagueTier || R.leagues.tiers[0], nextLogin: loginCoins((W.streak || 0) + 1, cfg) },
    today: { day, login: !!D.login, scratch: !!D.scratch, scratchId: D.scratchId || null, freeCoins: D.freeCoins || 0, ceiling: R.dailyCeiling, minutes: Math.floor(D.minutes || 0), ladder: ladderState(D, cfg), boxOpened: D.boxOpened || null, spins: (D.counts || {}).spin || 0, actions: Object.entries(R.actions).map(([id, a]) => ({ id, title: a.title, coins: a.coins, per: a.per || 'day', limit: a.limit || 1, done: a.per === 'once' ? ((W.done || {})[id] ? 1 : 0) : (D.counts || {})[id] || 0 })) },
    quests: {
      starter: (R.starterQuests || []).map((q) => ({ ...q, value: Number(W[q.metric]) || Number(stats[q.metric]) || 0, claimed: !!(W.done || {})['q:' + q.id] })),
      weekly: R.weeklyQuests.map((q) => ({ ...q, value: weekMetric(q.metric), claimed: claimedW.includes(q.id) })),
      chest: { open: claimedW.includes('chest'), ready: R.weeklyQuests.every((q) => claimedW.includes(q.id)) },
      weeklyGift: { ready: weekGiftOk(WK) || weekGiftOk(pwd.data), daysAt20: Object.values(WK.minutesByDay || {}).filter((m) => m >= R.weeklyGift.minutesPerDay).length, claimed: claimedW.includes('gift') },
      monthly: { ...R.monthlyQuest, value: (MO.counts || {})[R.monthlyQuest.metric] || 0, claimed: (MO.claimed || []).includes(R.monthlyQuest.id) },
      monthlyGift: { activeDays: (MO.days || []).length, goal: R.monthlyGift.activeDays, claimed: (MO.claimed || []).includes('gift') },
    },
    season: { id: sid, title: R.season.title, xp, tier: seasonTier(xp, cfg), xpPerTier: R.season.xpPerTier, tiers: R.season.tiers, claimed: (W.seasonClaimed || {})[sid] || [], premium: plan.active, endsAt: R.season.endsAt },
    stats,
    badges: badgeList(W),
    scratchCards: cards.filter((c) => !c.expiresAt || c.expiresAt > now).map((c) => ({ id: c.id, rarity: c.rarity, label: 'Sealed card', source: c.source, paid: !!c.paid, at: c.at, expiresAt: c.expiresAt })),
    coupons: coupons.filter((c) => !c.expiresAt || c.expiresAt > now).map((c) => ({ id: c.id, label: c.label, pct: c.pct, capINR: c.capINR, scope: c.scope, source: c.source, expiresAt: c.expiresAt })),
    tokens: tokens.map((t) => ({ id: t.id, item: t.item, label: t.label, source: t.source, at: t.at })),
    boxes: boxes.map((b) => ({ id: b.id, box: b.box, source: b.source, expiresAt: b.expiresAt })),
    passes: passes.map((p) => ({ tier: p.tier, days: p.days, until: p.until || null, status: p.status || 'active', source: p.source })).slice(0, 20),
    gifts: { sent: sent.sort((a, b) => b.at - a.at), received: received.sort((a, b) => b.at - a.at) },
    plan: { active: plan.active, own: plan.own, tier: plan.tier, ebookPassUntil: (user.data || {}).ebookPassUntil || null },
    referral: { code: (ref.data || {}).code || null, held: !!((ref.data || {}).hold && now - ref.data.hold.at < cfg.reference.holdDays * DAY), locked: !!(ref.data || {}).lockedTo, friendWordBuys: (ref.data || {}).friendWordBuys || 0 },
    partner: { points: (partner.data || {}).points || 0, pending: (partner.data || {}).pending || 0, perk: (partner.data || {}).perk || '' },
    recentCoins,
    earn: { title: (seller.data || {}).tier || cfg.earn.ranks[0].title, words: (seller.data || {}).wordsLifetime || 0, friends: (seller.data || {}).friendsCount || 0 },
    config: publicConfig(cfg),
  };
}
