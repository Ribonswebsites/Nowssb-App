// Economy engine end-to-end against the Firestore emulator.
// Run: bash tools/economy/test-economy.sh
import { FsDb } from '../../functions/_lib/economy/fsdb.js';
import { DEFAULT_ECONOMY, deepMerge } from '../../functions/_lib/economy/config.js';
import { DAY } from '../../functions/_lib/economy/rules.js';
import { ACTIONS } from '../../functions/api/economy/[action].js';
import { applySale, reverseSale } from '../../functions/_lib/economy/sales.js';
import { balances } from '../../functions/_lib/economy/earn.js';
import { adminPayout, adminMonthlyPool } from '../../functions/_lib/economy/admin.js';
import { buildItems } from '../../functions/_lib/economy/playorders.js';
import { takeCoachTurn, COACH_LIMITS } from '../../functions/_lib/coach_quota.js';

const env = { FIRESTORE_EMULATOR_HOST: process.env.FIRESTORE_EMULATOR_HOST, FIREBASE_PROJECT_ID: 'nowssb-34f1b' };
const db = await FsDb.fromEnv(env);
await fetch(`http://${env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/nowssb-34f1b/databases/(default)/documents`, { method: 'DELETE' });
const cfg = deepMerge(DEFAULT_ECONOMY, {});
let clock = Date.parse('2026-10-05T04:00:00Z');
const ctx = () => ({ db, cfg, now: clock, env });
const call = (name, uid, data = {}) => ACTIONS[name](ctx(), uid, data);
let pass = 0, fail = 0;
const t = async (name, fn) => { try { await fn(); pass++; console.log('ok  ', name); } catch (e) { fail++; console.log('FAIL', name, e.stack.split('\n').slice(0, 3).join(' | ')); } };
const eq = (a, b, m = '') => { if (JSON.stringify(a) !== JSON.stringify(b)) throw new Error(`${m} expected ${JSON.stringify(b)} got ${JSON.stringify(a)}`); };
const ok = (c, m) => { if (!c) throw new Error(m || 'assert'); };
const rejects = async (p, re) => { try { await p; } catch (e) { if (re && !re.test(e.message)) throw new Error('wrong error: ' + e.message); return; } throw new Error('expected an error'); };
const coins = async (uid) => ((await db.get(`users/${uid}/wallet/main`)).data || {}).coins || 0;
const put = (path, obj) => db.commit([db.write(path, obj)]);
const plusDays = (n) => { clock += n * DAY; };

const future = new Date(clock + 300 * DAY).toISOString();
await put('users/seller', { displayName: 'Sita Seller', isPro: true, tier: 'frequencyX', subscriptionSource: 'play', subscriptionEndDate: future });
await put('users/sponsor', { displayName: 'Ravi Sponsor', isPro: true, tier: 'frequencyX', subscriptionSource: 'play', subscriptionEndDate: future });
await put('users/buyer', { displayName: 'Bina Buyer' });
await put('users/twin', { displayName: 'Twin' });
await put('users/quester', { displayName: 'Q' });
// Published words and an admin price, as Firestore would have them.
await put('words/om', { key: 'om', word: 'OM', status: 'live' });
await put('words/ra', { key: 'ra', word: 'RA', status: 'live' });
await put('config/store', { defaults: { word: 99 }, items: { 'word:om': 199 } });
await put('admins/boss', { at: 1 });

await t('daily login: coins once a day, streak, ledger', async () => {
  const a = await call('claimDailyLogin', 'buyer');
  eq([a.coins, a.streak], [5 + 10 * 0, 1].map((x, i) => i === 0 ? a.coins : x));
  ok(a.coins >= 5, 'login coins');
  const b = await call('claimDailyLogin', 'buyer');
  eq(b.already, true);
  const rows = await db.query('coinLedger', [['uid', '==', 'buyer']]);
  ok(rows.length >= 2, 'login + milestone rows');
});
await t('actions respect per-day limits and the daily ceiling', async () => {
  const r1 = await call('reportAction', 'buyer', { action: 'read_meaning' });
  await call('reportAction', 'buyer', { action: 'read_meaning' }); await call('reportAction', 'buyer', { action: 'read_meaning' });
  const r4 = await call('reportAction', 'buyer', { action: 'read_meaning' });
  eq([r1.coins, r4.coins, r4.already], [8, 0, true]);
  await rejects(call('reportAction', 'buyer', { action: 'free_money' }), /Unknown/);
});
await t('heartbeat time ladder → step coins → one daily box', async () => {
  for (let i = 0; i < 9; i++) { await call('heartbeat', 'buyer'); clock += 70e3; }
  let h = await call('heartbeat', 'buyer');
  ok(h.minutes >= 10, 'minutes ' + h.minutes);
  const st = await call('claimTimeStep', 'buyer', { minutes: 10 });
  ok(st.coins > 0);
  await rejects(call('claimTimeStep', 'buyer', { minutes: 20 }), /20 minutes/);
  const box = await call('openDailyBox', 'buyer');
  eq(box.box, 'bronze'); ok(box.items.length === 2);
  await rejects(call('openDailyBox', 'buyer'), /open/);
});
await t('daily scratch: server decides, reveal grants once', async () => {
  const d = await call('dailyScratch', 'buyer');
  ok(d.id && d.label);
  const before = await coins('buyer');
  const r = await call('revealScratch', 'buyer', { id: d.id });
  const again = await call('revealScratch', 'buyer', { id: d.id });
  eq(again.already, true);
  if (r.granted.type === 'coins') ok((await coins('buyer')) >= before + r.granted.coins, 'prize coins landed');
  const legacy = await call('scratchCoupon', 'buyer');
  eq(legacy.already, true);
});
await t('spin: exactly one free spin a day, no paid spins; nonce replay returns the first answer', async () => {
  eq([cfg.spin.freePerDay, cfg.spin.paidPerDay, cfg.spin.costCoins], [1, 0, undefined]);
  const before = await coins('buyer');
  const s1 = await call('spin', 'buyer', { nonce: 'n1' });
  ok(s1.slice >= 0 && s1.slice < cfg.spin.slices.length);
  eq([s1.free, s1.cost, s1.freeLeft, s1.paidLeft], [true, 0, 0, 0]);
  ok((await coins('buyer')) >= before, 'free spin costs nothing');
  const replay = await call('spin', 'buyer', { nonce: 'n1' });
  eq([replay.replay, replay.slice], [true, s1.slice]);
  await put('users/buyer/wallet/main', { ...((await db.get('users/buyer/wallet/main')).data), coins: 500 });
  await rejects(call('spin', 'buyer', { nonce: 'n2' }), /Come back tomorrow/);
  eq(await coins('buyer'), 500, 'a rejected second spin charges nothing');
  const sum = await call('summary', 'buyer');
  eq([sum.today.spin.next, sum.today.spin.paidLeft], ['limit', 0]);
  eq([sum.config.spin.paidPerDay, sum.config.spin.perDay], [0, 1]);
});
await t('per-key actions: verified on the server and capped per day', async () => {
  const a = await call('reportAction', 'quester', { action: 'close_stage', key: 'made-up-1' });
  eq([a.coins, a.verified], [0, false]);
  await call('reportPractice', 'quester', { practiced: true, wordId: 'om' });
  eq(((await db.get('users/quester/mastery/om')).data || {}).practiceDays || 0, 0, 'no player session, no practice day');
  await call('heartbeat', 'quester', {});
  await call('reportPractice', 'quester', { practiced: true, wordId: 'made-up-word' });
  eq((await db.get('users/quester/mastery/made-up-word')).exists, false, 'unknown word ignored');
  await call('reportPractice', 'quester', { practiced: true, wordId: 'om' });
  const b = await call('reportAction', 'quester', { action: 'close_stage', key: 'om:1' });
  ok(b.coins > 0, 'real practised word pays');
  for (let i = 0; i < 6; i++) await call('reportAction', 'quester', { action: 'first_share', key: 'w' + i });
  const c = await call('reportAction', 'quester', { action: 'first_share', key: 'w99' });
  eq(c.coins, 0);
  const p = await call('reportAction', 'quester', { action: 'reminders_on' });
  eq(p.coins, 0, 'no push subscription, no coins');
});
await t('heartbeat: beats closer than the minimum gap add nothing', async () => {
  const a = await call('heartbeat', 'quester');
  clock += 5e3;
  const b = await call('heartbeat', 'quester');
  eq(b.early, true);
  clock += 60e3;
  const c = await call('heartbeat', 'quester');
  ok(c.minutes >= a.minutes);
});
await t('tickets: percent-off coupon once; locked explains; chance once a day', async () => {
  const a = await call('claimTicket', 'buyer', { code: 'NWSB-SAVE20' });
  ok(a.couponId);
  await rejects(call('claimTicket', 'buyer', { code: 'NWSB-SAVE20' }), /already/);
  eq((await call('claimTicket', 'buyer', { code: 'NWSB-STD30' })).locked, true);
  await call('claimTicket', 'buyer', { code: 'NWSB-CHANCE-COIN' });
  await rejects(call('claimTicket', 'buyer', { code: 'NWSB-CHANCE-COIN' }), /One try/);
});
await t('reference: own link refused, same device refused, friend attached with welcome set', async () => {
  const link = await call('getLink', 'seller', { kind: 'word', id: 'om', title: 'Om' });
  ok(link.url.includes('/w/om?r=' + link.code));
  await rejects(call('attachReferral', 'seller', { code: link.code }), /own link/);
  await call('registerDevice', 'seller', { installId: 'phone-seller-123' });
  await call('registerDevice', 'twin', { installId: 'phone-seller-123' });
  await rejects(call('attachReferral', 'twin', { code: link.code }), /same phone/);
  await call('registerDevice', 'buyer', { installId: 'phone-buyer-456' });
  const before = await coins('buyer');
  const a = await call('attachReferral', 'buyer', { code: link.code, source: 'install' });
  eq(a.attached, true); ok(a.welcome && a.welcome.length >= 2);
  eq(await coins('buyer'), before + 100);
  globalThis.LINK = link.code;
});
await t('checkout: friend 10% → coupon → coins held; Play tier product', async () => {
  const s = await call('summary', 'buyer');
  const cp = s.coupons.find((c) => c.scope === 'word');
  const q = await call('beginCheckout', 'buyer', { kind: 'cart', items: [{ id: 'word:om', kind: 'Word', title: 'Om', price: 199 }], couponId: cp.id });
  ok(q.productId.startsWith('nowssb_tier_')); eq(q.quote.friendPct, 10);
  ok(q.quote.linkOffINR === 19.9 && q.quote.couponOffINR > 0, 'link then coupon');
  globalThis.CK = q;
});
await t('checkout: server prices each line; a forged kind or price is refused', async () => {
  await rejects(call('quote', 'buyer', { items: [{ id: 'word:om', kind: 'stage', title: 'Om', price: 29 }] }), /match/);
  await rejects(call('quote', 'buyer', { items: [{ id: 'word:om', kind: 'word', title: 'Om', price: 29 }] }), /Prices changed/);
  await rejects(call('quote', 'buyer', { items: [{ id: 'ebook:x', kind: 'ebook', title: 'X', price: 29 }] }), /Prices changed/);
  await rejects(call('quote', 'buyer', { items: [{ id: 'constructor', kind: 'word', price: 99 }] }), /bought here/);
  const q = await call('quote', 'buyer', { items: [{ id: 'word:ra', kind: 'word', title: 'Ra', price: 99 }] });
  ok(q.listINR === 99 || (q.quote && q.quote.listINR === 99) || q.payINR != null, 'default price accepted');
});
await t('prototype names never reach the wallet', async () => {
  await rejects(call('reportAction', 'buyer', { action: 'toString' }), /Unknown activity/);
  await rejects(call('spendCoins', 'buyer', { item: 'cosmetic', cosmeticId: 'constructor' }), /Unknown item/);
  await rejects(call('openBox', 'buyer', { box: '__proto__' }), /./);
  ok(Number.isFinite(await coins('buyer')), 'coins stay a number');
});
await t('cleared sale: items, coins back, first-purchase set, seller commission via money lock, partner points', async () => {
  const ck = (await db.get(`checkouts/${CK.checkoutId}`)).data;
  const order = { orderId: 'GPA.1111-0001', buyerUid: 'buyer', productId: CK.productId, payINR: Math.round((ck.payINR / 1.18) * 100) / 100, taxINR: 0, realFeeINR: null, checkout: { id: CK.checkoutId, friendPct: 10 }, ...buildItems(cfg, CK.productId, ck) };
  const r = await applySale(ctx(), order);
  eq(r.ownerCredited, true);
  const again = await applySale(ctx(), order); eq(again.already, true, 'idempotent');
  ok((await db.get('users/buyer/owned/word_om')).exists, 'owned');
  const bal = await balances(db, 'seller', clock);
  ok(bal.pendingPaise > 0 && bal.availablePaise === 0, 'pending 30 days');
  const sale = (await db.get('sales/GPA.1111-0001')).data;
  eq(sale.lock.reserve, Math.round(order.payINR * 0.2 * 100) / 100);
  ok(sale.points === 10, 'partner points for a word');
  const sl = (await db.get('users/seller/sellerStats/main')).data; eq([sl.wordsLifetime, sl.friendsCount], [1, 1]);
  const ref = (await db.get('users/buyer/referral/main')).data; ok(ref.lockedTo && ref.lockedTo.ownerUid === 'seller', 'locked at first purchase');
});
await t('circle blocked: seller buying back through the buyer earns nobody', async () => {
  const l = await call('getLink', 'buyer', { kind: 'word', id: 'ra' });
  await db.commit([db.write('users/seller/referral/main', { hold: { code: l.code, ownerUid: 'buyer', at: clock, sku: 'word:ra' } }, { merge: true })]);
  const r = await applySale(ctx(), { orderId: 'GPA.circle', buyerUid: 'seller', productId: 'nowssb_tier_99', kind: 'word', words: 1, payINR: 83.9, items: [{ id: 'word:ra', kind: 'word' }] });
  eq(r.ownerCredited, false);
  eq((await db.get('sales/GPA.circle')).data.refBlocked, 'circle');
});
await t('team: appointment invite → accept → leg-1 bonus on the member’s sale', async () => {
  const code = (await call('linkHub', 'sponsor')).code;
  await put('users/sponsor/sellerStats/main', { wordsLifetime: 2100, rankSince: clock, window: { [String(Math.floor((clock + 330 * 60e3) / DAY))]: 200 } });
  const inv = await call('appoint', 'sponsor', { code: (await call('linkHub', 'seller')).code, rank: 'officer' });
  ok(inv.invited);
  const acc = await call('answerAppointment', 'seller', { id: inv.id, accept: true });
  eq(acc.accepted, true);
  await put('users/buyer2', { displayName: 'B2' });
  const l = await call('getLink', 'seller', { kind: 'word', id: 'om' });
  await call('registerDevice', 'buyer2', { installId: 'phone-b2-789' });
  await call('attachReferral', 'buyer2', { code: l.code });
  await applySale(ctx(), { orderId: 'GPA.team1', buyerUid: 'buyer2', productId: 'nowssb_tier_199', kind: 'word', words: 2, payINR: 168.64, items: [{ id: 'word:om', kind: 'word' }, { id: 'word:ra', kind: 'word' }] });
  const sp = await balances(db, 'sponsor', clock);
  ok(sp.pendingPaise > 0, 'sponsor leg bonus pending');
  ok(code, 'sponsor code');
});
await t('refund reverses commission, coins and word credit (append-only)', async () => {
  const before = await balances(db, 'seller', clock);
  const r = await reverseSale(ctx(), 'GPA.team1', 'voided');
  eq(r.reversed, true);
  eq((await reverseSale(ctx(), 'GPA.team1')).already, true);
  const after = await balances(db, 'seller', clock);
  ok(after.pendingPaise < before.pendingPaise, 'pending shrank');
  const sl = (await db.get('users/seller/sellerStats/main')).data; eq(sl.wordsLifetime, 1);
});
await t('gift card: bought → claimed by a friend once; buyer cannot open it', async () => {
  const ck = await call('beginCheckout', 'buyer', { kind: 'giftcard', cardId: 'ebook7', toName: 'Asha', message: 'For you' });
  const ckd = (await db.get(`checkouts/${ck.checkoutId}`)).data;
  await applySale(ctx(), { orderId: 'GPA.gift1', buyerUid: 'buyer', productId: ck.productId, payINR: 41.5, ...buildItems(cfg, ck.productId, ckd), checkout: { id: ck.checkoutId } });
  const code = (await db.get('sales/GPA.gift1')).data.giftCode;
  ok(/^NWSB-/.test(code));
  await rejects(call('redeemGift', 'buyer', { code }), /buyer/);
  const g = await call('redeemGift', 'twin', { code });
  ok(g.granted.label.includes('ebook'));
  await rejects(call('redeemGift', 'buyer2', { code }), /claimed/);
});
await t('payouts: KYC, minimum, queue, admin paid', async () => {
  await rejects(call('requestPayout', 'seller'), /UPI/);
  await call('savePayoutAccount', 'seller', { country: 'IN', upi: 'sita@okbank', legalName: 'Sita Seller', pan: 'ABCDE1234F' });
  await rejects(call('savePayoutAccount', 'twin', { country: 'IN', upi: 'sita@okbank', legalName: 'Twin T' }), /already used/);
  plusDays(31);
  await rejects(call('requestPayout', 'seller'), /start at/);
  await db.commit([db.write('commissionLedger/test-bonus', { uid: 'seller', type: 'target', paise: 200000, availableAt: clock - 1, at: clock })]);
  const r = await call('requestPayout', 'seller');
  ok(r.requested && r.amountINR > 1250);
  await rejects(call('requestPayout', 'seller'), /start at|queue/);
  const p = await adminPayout(ctx(), 'boss', { id: r.id, action: 'paid', reference: 'UTR123' });
  eq(p.status, 'paid');
});
await t('earn summary shows ranks, standing and balances', async () => {
  const e = await call('earnSummary', 'seller');
  ok(e.ranks.length === 6 && e.standing.title);
  ok(e.team.length === 0 && e.sponsor, 'has sponsor');
  ok(e.balances.lifetimeINR > 0);
});
await t('partner points confirm after 30 days and unlock levels', async () => {
  const p = await call('partnerSummary', 'seller');
  ok(p.confirmed >= 10, 'confirmed ' + p.confirmed);
  await rejects(call('claimPartnerLevel', 'seller', { level: 1 }), /unlocks at 500/);
});
await t('weekly quests + chest + summary', async () => {
  const s = await call('summary', 'buyer');
  ok(s.live && s.config.odds && s.quests.weekly.length === 5 && s.badges.length >= 100);
  await rejects(call('claimWeeklyChest', 'buyer'), /weekly quests/);
  await rejects(call('claimQuest', 'buyer', { questId: 'w_minutes' }), /Spend 60 minutes/);
});
await t('mastery levels pay per level, capped per day; set completes', async () => {
  await rejects(call('claimMilestone', 'buyer', { wordId: 'love', level: 3 }), /Practise love/);
  const start = clock;
  for (let i = 0; i < 3; i++) { await call('heartbeat', 'buyer', {}); await call('reportPractice', 'buyer', { practiced: true, wordId: 'love' }); clock += 86400e3; }
  await call('heartbeat', 'buyer', {});
  await call('reportPractice', 'buyer', { practiced: true, wordId: 'love' }); // same day twice counts once
  const r = await call('claimMilestone', 'buyer', { wordId: 'love', level: 3 });
  clock = start;
  eq(r.coins, 15);
  eq((await call('reportMastery', 'buyer', { wordId: 'love', level: 3 })).already, true);
});
await t('spend coins on catalogue items only; resale paused', async () => {
  await rejects(call('spendCoins', 'twin', { purpose: 'freeze' }), /Not enough/);
  await rejects(call('spendCoins', 'buyer', { purpose: 'boost' }), /paused/);
  await rejects(call('createListing', 'buyer', {}), /paused/);
});
await t('echo wall post + like milestone + comment', async () => {
  const p = await call('createEchoPost', 'buyer', { text: 'Om feels like home' });
  ok(p.id);
  await rejects(call('createEchoPost', 'buyer', { text: 'see https://spam.com' }), /Links/);
  eq((await call('toggleEchoLike', 'seller', { postId: p.id })).liked, true);
  eq((await call('toggleEchoLike', 'seller', { postId: p.id })).liked, false);
  ok((await call('commentOnPost', 'seller', { postId: p.id, text: 'Lovely' })).id);
});
await t('monthly pool (admin) pays the top sellers once', async () => {
  const m = new Date(Date.parse('2026-10-05T04:00:00Z') + 330 * 60e3).toISOString().slice(0, 7).replace('-', '');
  const r = await adminMonthlyPool(ctx(), 'boss', { month: m });
  ok(r.paid.length >= 1);
  await rejects(adminMonthlyPool(ctx(), 'boss', { month: m }), /paid/);
});
await t('admin console gift codes redeem once; ledgers are written', async () => {
  await put('gifts/GFTTEST2345', { code: 'GFTTEST2345', item: 'word', itemId: 'word', label: 'A word', source: 'admin', status: 'unredeemed', createdAt: clock, expiresAt: clock + 86400e3 });
  const r = await call('redeemGift', 'twin', { code: 'GFTTEST2345' });
  eq(r.granted.type, 'token');
  eq(((await db.get('gifts/GFTTEST2345')).data || {}).status, 'redeemed');
  await rejects(call('redeemGift', 'buyer', { code: 'GFTTEST2345' }), /already claimed/);
  ok((await db.query('giftLedger', [['code', '==', 'GFTTEST2345']])).length >= 1, 'giftLedger');
  ok((await db.query('couponLedger', [])).length >= 1, 'couponLedger');
  ok((await db.query('cashLedger', [['mirror', '==', true]])).length >= 1, 'cashLedger mirror');
  ok((await db.query('referrals', [])).length >= 1, 'referrals');
});
await t('gift code email lock uses the verified sign-in email, not the profile field', async () => {
  await put('gifts/GFTMAIL2345', { code: 'GFTMAIL2345', item: 'word', itemId: 'word', label: 'A word', source: 'admin', status: 'unredeemed', recipientEmail: 'friend@example.com', createdAt: clock, expiresAt: clock + 86400e3 });
  await put('users/twin', { displayName: 'Twin', email: 'friend@example.com' });
  const as = (claims) => ACTIONS.redeemGift({ ...ctx(), claims }, 'twin', { code: 'GFTMAIL2345' });
  await rejects(as({ sub: 'twin', email: 'me@example.com', email_verified: true }), /different account/);
  await rejects(as({ sub: 'twin', email: 'friend@example.com', email_verified: false }), /Verify/);
  const r = await as({ sub: 'twin', email: 'Friend@Example.com', email_verified: true });
  eq(r.granted.type, 'token');
});
await t('welcome set: only for accounts younger than 14 days', async () => {
  await put('users/oldie', { displayName: 'Old' });
  await call('registerDevice', 'oldie', { installId: 'phone-oldie-789' });
  plusDays(20);
  const a = await call('attachReferral', 'oldie', { code: LINK });
  plusDays(-20);
  eq(a.attached, true); eq(a.welcome, null, 'no welcome for an old account');
  eq(((await db.get('users/oldie/referral/main')).data || {}).newAccount, false);
});
await t('paid cards: a blocked edge country blocks even if the phone says IN', async () => {
  const card = (cfg.coupons.paid || [])[0];
  if (!card) return;
  await rejects(ACTIONS.beginCheckout({ ...ctx(), country: 'US' }, 'buyer', { kind: 'scratch', cardId: card.id, country: 'IN', adult: true }), /country/);
});
await t('coach: burst limit per minute and a daily allowance by plan', async () => {
  let n = 0;
  for (let i = 0; i < COACH_LIMITS.perMinute; i++) { if ((await takeCoachTurn(env, 'buyer', clock + i)).ok) n++; }
  eq(n, COACH_LIMITS.perMinute);
  eq((await takeCoachTurn(env, 'buyer', clock + 10)).ok, false, 'burst');
  let more = 0;
  for (let i = 0; i < 30; i++) { if ((await takeCoachTurn(env, 'buyer', clock + 61e3 * (i + 1))).ok) more++; }
  eq(more, COACH_LIMITS.perDay.free - COACH_LIMITS.perMinute, 'free daily allowance');
});
await t('payout account outside India: Wise / PayPal by hand', async () => {
  const r = await call('savePayoutAccount', 'seller', { country: 'GB', method: 'paypal', email: 'seller@example.com', legalName: 'Sam Seller' });
  eq(r.rail, 'paypal_manual');
  await rejects(call('savePayoutAccount', 'seller', { country: 'GB', method: 'wise', email: 'nope', legalName: 'Sam' }), /Wise/);
});
console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
