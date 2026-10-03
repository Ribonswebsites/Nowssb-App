// Pure rule tests (no network): node tools/economy/economy-rules.test.mjs
import { DEFAULT_ECONOMY as cfg, deepMerge } from '../../functions/_lib/economy/config.js';
import * as R from '../../functions/_lib/economy/rules.js';
import { oddsTable } from '../../functions/_lib/economy/coupons.js';
import { buildItems } from '../../functions/_lib/economy/playorders.js';
import * as router from '../../functions/api/economy/[action].js';

let pass = 0, fail = 0;
const t = async (name, fn) => { try { await fn(); pass++; console.log('ok  ', name); } catch (e) { fail++; console.log('FAIL', name, e.message); } };
const eq = (a, b, m = '') => { if (JSON.stringify(a) !== JSON.stringify(b)) throw new Error(`${m} expected ${JSON.stringify(b)} got ${JSON.stringify(a)}`); };
const ok = (c, m) => { if (!c) throw new Error(m || 'assert'); };
const plan = (tier) => ({ active: true, own: true, tier });

await t('money lock: ₹200 Gold sale with leg (plan worked example)', () => {
  const m = R.moneyLock({ exTaxINR: 200, words: 2, ownPct: 38, leg1Pct: 3, cfg });
  eq([m.reserve, m.net, m.own, m.leg1, m.promoter], [40, 160, 60.8, 4.8, 65.6]);
  ok(m.companyPct >= cfg.lock.companyFloorPct, 'company keeps ≥ 35%');
});
await t('money lock: real store fee above 20% raises the reserve', () => {
  const m = R.moneyLock({ exTaxINR: 100, realFeeINR: 30, ownPct: 15, cfg });
  eq([m.reserve, m.net, m.own], [30, 70, 10.5]);
});
await t('money lock: ₹15 floor per word, cap shrinks legs first', () => {
  const m = R.moneyLock({ exTaxINR: 49, words: 1, ownPct: 15, leg1Pct: 7, leg2Pct: 3, cfg });
  ok(m.own >= 15 || m.shrunk.includes('floor'), 'floor applied or yielded');
  ok(m.promoter <= m.cap + 0.01, 'never above the 65% cap');
});
await t('money lock: renewals pay half', () => {
  const a = R.moneyLock({ exTaxINR: 500, ownPct: 30, cfg });
  const b = R.moneyLock({ exTaxINR: 500, ownPct: 30, renewal: true, cfg });
  eq(b.own, a.own / 2);
});
await t('ranks by words + plan gate (gifted plan never counts)', () => {
  eq(R.rankIndexForWords(0, cfg), 0); eq(R.rankIndexForWords(100, cfg), 1); eq(R.rankIndexForWords(3000, cfg), 5);
  const s1 = R.standing({ wordsLifetime: 600, plan: plan('resonance'), cfg });
  eq(s1.rank, 'officer', 'Exec needs top plan'); ok(s1.planShort);
  const s2 = R.standing({ wordsLifetime: 600, plan: plan('frequencyX'), cfg });
  eq([s2.rank, s2.ratePct], ['executive1', 30]);
  const s3 = R.standing({ wordsLifetime: 600, plan: { active: true, own: false, tier: 'frequencyX' }, cfg });
  eq([s3.canEarn, s3.ratePct], [false, 0]);
});
await t('appointment: provisional 60 days, 10-word check, step down when missed', () => {
  const now = Date.now();
  const p = R.standing({ wordsLifetime: 3, appointed: { rank: 'officer', at: now - 5 * R.DAY, wordsAtAppoint: 0 }, plan: plan('resonance'), now, cfg });
  eq([p.rank, p.provisional, p.appoints], ['officer', true, []]);
  const late = R.standing({ wordsLifetime: 3, appointed: { rank: 'executive1', at: now - 70 * R.DAY, wordsAtAppoint: 0 }, plan: plan('frequencyX'), now, cfg });
  eq(late.rank, 'officer', 'missed check steps down one rank');
});
await t('keeping a rank: 90-day minimum', () => {
  const now = Date.now();
  const s = R.standing({ wordsLifetime: 150, words90: 3, rankSince: now - 100 * R.DAY, plan: plan('resonance'), now, cfg });
  eq([s.rank, s.steppedDown], ['assistant', true]);
});
await t('targets crossed', () => eq(R.targetsCrossed(95, 520, cfg).map((x) => x.words), [100, 500]));
await t('cart: link → coupon → coins within caps, Play tier remainder', () => {
  const q = R.quoteCheckout({ listINR: 200, kind: 'word', linkPct: 10, coupon: { type: 'percentOff', pct: 20, capINR: 35, scope: 'word' }, coinsBalance: 5000, cfg });
  ok(q.ok); ok(q.linkOffINR === 20 && q.couponOffINR === 35, 'link then coupon');
  ok(q.linkOffINR + q.couponOffINR + q.coinsINR + q.absorbedINR <= 100, 'total ≤ 50%');
  ok(cfg.cart.payTiersINR.includes(q.payINR), 'tier'); eq(q.productId, 'nowssb_tier_' + q.payINR);
});
await t('cart: coins never pay a whole bill; cap by band', () => {
  const q = R.quoteCheckout({ listINR: 99, kind: 'word', coinsBalance: 99999, cfg });
  ok(q.payINR > 0); ok(q.coinsINR <= 99 * 0.3 + 0.01, '30% band');
  const sub = R.quoteCheckout({ listINR: 999, kind: 'subscription', coinsBalance: 99999, cfg });
  ok(sub.coinsINR <= 999 * 0.4 + 0.01);
});
await t('coupon scopes', () => { ok(R.couponFits({ scope: 'word' }, 'stage')); ok(!R.couponFits({ scope: 'any' }, 'giftcard')); ok(!R.couponFits({ scope: 'meaning' }, 'word')); });
await t('streak: holds every 14 days (max 2), freeze covers a miss, break resets', () => {
  let s = { streak: 13, holds: 0, freezes: 0 };
  const a = R.stepStreak({ lastDayIdx: 10, todayIdx: 11, ...s, cfg }); eq([a.streak, a.holds], [14, 1]);
  const b = R.stepStreak({ lastDayIdx: 11, todayIdx: 13, streak: 14, holds: 1, freezes: 0, cfg }); eq([b.streak, b.holds, b.broken], [15, 0, false]);
  const c = R.stepStreak({ lastDayIdx: 11, todayIdx: 15, streak: 14, holds: 1, freezes: 0, cfg }); eq([c.streak, c.broken], [1, true]);
});
await t('login coins 5..15', () => { eq(R.loginCoins(1, cfg), 5); eq(R.loginCoins(100, cfg), 15); });
await t('draws are weighted and odds published sum to 100', () => {
  const o = oddsTable(cfg);
  for (const p of o.paid) ok(Math.abs(p.odds.reduce((a, x) => a + x.pct, 0) - 100) < 0.05, p.id);
  ok(Math.abs(o.spin.reduce((a, x) => a + x.pct, 0) - 100) < 0.05);
  const n = { a: 0, b: 0 };
  for (let i = 0; i < 4000; i++) n[R.drawWeighted([{ w: 75, k: 'a' }, { w: 25, k: 'b' }]).item.k]++;
  ok(n.a > 2700 && n.a < 3300, 'roughly 75%');
});
await t('season + chest + partner levels + badges ≥ 100', () => {
  eq(R.seasonTier(450, cfg), 3); eq(R.seasonReward(10, true).giftbox, 'silver');
  eq(R.weeklyChestCoins(7, cfg), 200);
  eq(R.partnerLevel(1500, cfg).title, 'Glow'); eq(R.partnerPointsFor('subscription', 'premium', cfg), 34);
  ok(R.badgeCatalog().length >= 100);
});
await t('links: one per person per item, stable', async () => {
  const a = await R.linkCode('u1', R.skuKey('word', 'om')); const b = await R.linkCode('u1', R.skuKey('word', 'om')); const c = await R.linkCode('u2', R.skuKey('word', 'om'));
  eq(a, b); ok(a !== c); eq(a.length, 9);
});
await t('settings doc deep-merge (admin edits win, arrays replace)', () => {
  const m = deepMerge(cfg, { lock: { payoutCapPct: 55 }, spin: { freePerDay: 2 } });
  eq([m.lock.payoutCapPct, m.lock.storeReservePct, m.spin.freePerDay, m.spin.slices.length], [55, 20, 2, cfg.spin.slices.length]);
});
await t('play products map to items', () => {
  eq(buildItems(cfg, 'nowssb_scratch_rare', null).kind, 'scratch');
  eq(buildItems(cfg, 'nowssb_gift_word', { meta: {} }).words, 1);
  eq(buildItems(cfg, 'nowssb_tier_99', null), null, 'tier needs a checkout');
  eq(buildItems(cfg, 'nowssb_tier_99', { kind: 'cart', items: [{ id: 'word:om', kind: 'Word', title: 'Om' }, { id: 'meaning:om', kind: 'Meaning' }] }).words, 2);
});
await t('router: 501 switching-on when the service account is missing', async () => {
  const r = await router.onRequestPost({ request: new Request('https://nowssb.com/api/economy/claimDailyLogin', { method: 'POST', body: '{}' }), env: { FIREBASE_PROJECT_ID: 'nowssb-34f1b' }, params: { action: 'claimDailyLogin' } });
  eq(r.status, 501); const j = await r.json(); eq([j.code, j.switchingOn, j.missing], ['not-configured', true, ['FIREBASE_SERVICE_ACCOUNT']]);
  const g = await router.onRequestGet({ request: new Request('https://nowssb.com/api/economy/config'), env: {}, params: { action: 'config' } });
  const gj = await g.json(); eq(gj.live, false); ok(gj.config.odds.paid.length === 3);
  const u = await router.onRequestPost({ request: new Request('https://nowssb.com/api/economy/nope', { method: 'POST', body: '{}' }), env: {}, params: { action: 'nope' } });
  eq(u.status, 404);
});
console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
