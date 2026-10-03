// Server fixes from the user-app audit (REPORT #10 #11 #12 #22 #23 #25),
// against the Firestore emulator.
// Run: FIRESTORE_EMULATOR_HOST=127.0.0.1:8089 node tools/economy/batch1-server.test.mjs
import { FsDb } from '../../functions/_lib/economy/fsdb.js';
import { DEFAULT_ECONOMY, deepMerge } from '../../functions/_lib/economy/config.js';
import { DAY, weekKey } from '../../functions/_lib/economy/rules.js';
import { ACTIONS } from '../../functions/api/economy/[action].js';
import { applySale } from '../../functions/_lib/economy/sales.js';
import { buildItems } from '../../functions/_lib/economy/playorders.js';
import { countOpen, countOpenOnce } from '../../functions/_lib/economy/reference.js';
import { leagueAlias } from '../../functions/_lib/economy/rewards.js';

const env = { FIRESTORE_EMULATOR_HOST: process.env.FIRESTORE_EMULATOR_HOST, FIREBASE_PROJECT_ID: 'nowssb-34f1b' };
const db = await FsDb.fromEnv(env);
await fetch(`http://${env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/nowssb-34f1b/databases/(default)/documents`, { method: 'DELETE' });
const cfg = deepMerge(DEFAULT_ECONOMY, {});
let clock = Date.parse('2026-10-05T04:00:00Z');
const ctx = (extra = {}) => ({ db, cfg, now: clock, env, ...extra });
const call = (name, uid, data = {}, extra = {}) => ACTIONS[name](ctx(extra), uid, data);
let pass = 0, fail = 0;
const t = async (name, fn) => { try { await fn(); pass++; console.log('ok  ', name); } catch (e) { fail++; console.log('FAIL', name, e.stack.split('\n').slice(0, 3).join(' | ')); } };
const ok = (c, m) => { if (!c) throw new Error(m || 'assert'); };
const rejects = async (p, re) => { try { await p; } catch (e) { if (re && !re.test(e.message)) throw new Error('wrong error: ' + e.message); return; } throw new Error('expected an error'); };
const put = (path, obj) => db.commit([db.write(path, obj)]);
const coins = async (uid) => ((await db.get(`users/${uid}/wallet/main`)).data || {}).coins || 0;
const nowIso = () => new Date(clock).toISOString();

await put('users/holder', { displayName: 'Holder', createdAt: nowIso() });
await put('users/fresh', { displayName: 'Fresh', createdAt: nowIso() });
await put('users/real', { displayName: 'Real', createdAt: nowIso() });

await t('#10 ref opens: past the per-IP daily limit no more refOpens writes', async () => {
  const link = await call('getLink', 'holder', { kind: 'word', id: 'om', title: 'Om' });
  globalThis.CODE = link.code;
  const ip = 'a'.repeat(64);
  for (let i = 0; i < cfg.reference.openRatePerIpPerDay + 5; i++) await countOpen(db, cfg, link.code, ip, clock);
  const day = new Date(clock + 330 * 60e3).toISOString().slice(0, 10).replace(/-/g, '');
  const r = (await db.get(`refOpens/${day}_${ip.slice(0, 24)}`)).data;
  ok(r.n === cfg.reference.openRatePerIpPerDay, 'n stops at the limit: ' + r.n);
  const l = (await db.get(`refLinks/${link.code}`)).data;
  ok(l.opens === cfg.reference.openRatePerIpPerDay, 'opens ' + l.opens);
});

await t('#10 ref opens: edge cache answers repeats without Firestore', async () => {
  const store = new Map();
  globalThis.caches = { default: { match: async (k) => store.get(k.url)?.clone(), put: async (k, v) => { store.set(k.url, v); } } };
  const ip = 'b'.repeat(64);
  let calls = 0;
  const spy = { ...db, tx: (fn) => { calls++; return db.tx(fn); } };
  Object.setPrototypeOf(spy, Object.getPrototypeOf(db));
  for (let i = 0; i < 10; i++) await countOpenOnce(spy, cfg, CODE, ip, clock);
  delete globalThis.caches;
  ok(calls === 1, 'firestore transactions: ' + calls);
});

await t('#11 welcome set needs a registered install id', async () => {
  const before = await coins('fresh');
  const a = await call('attachReferral', 'fresh', { code: CODE });
  ok(a.attached === true && !a.welcome, 'no welcome without a device');
  ok((await coins('fresh')) === before, 'no welcome coins');
  await call('registerDevice', 'real', { installId: 'phone-real-0001' });
  const b = await call('attachReferral', 'real', { code: CODE });
  ok(b.welcome && b.welcome.length >= 2, 'welcome with a device');
});

await t('#12 abandoned Signature gift-card checkout does not burn the quarterly lock', async () => {
  const a = await call('beginCheckout', 'holder', { kind: 'giftcard', cardId: 'signature3', toName: 'A' });
  await call('cancelCheckout', 'holder', { checkoutId: a.checkoutId });
  const w = (await db.get('users/holder/wallet/main')).data;
  ok(!w.lastSig3, 'lastSig3 not set by an abandoned checkout');
  const b = await call('beginCheckout', 'holder', { kind: 'giftcard', cardId: 'signature3', toName: 'B' });
  // A second begin for the same card replaces the open one instead of blocking.
  const c = await call('beginCheckout', 'holder', { kind: 'giftcard', cardId: 'signature3', toName: 'C' });
  ok((await db.get(`checkouts/${b.checkoutId}`)).data.status === 'released', 'older open checkout replaced');
  const ck = (await db.get(`checkouts/${c.checkoutId}`)).data;
  await applySale(ctx(), { orderId: 'GPA.9000-0001', buyerUid: 'holder', productId: ck.productId, payINR: 168, taxINR: 0, checkout: { id: c.checkoutId }, ...buildItems(cfg, ck.productId, ck) });
  const w2 = (await db.get('users/holder/wallet/main')).data;
  ok(w2.lastSig3 === clock && w2.giftSends.n === 1, 'lock applied after payment');
  await rejects(call('beginCheckout', 'holder', { kind: 'giftcard', cardId: 'signature3' }), /once a quarter/);
});

await t('#22 coin-bought paid card: country, 18+ and monthly limit apply', async () => {
  await db.commit([db.write('users/real/wallet/main', { coins: 20000 }, { merge: true })]);
  await rejects(call('buyScratchWithCoins', 'real', { cardId: 'common' }, { country: 'IN' }), /18\+/);
  await rejects(call('buyScratchWithCoins', 'real', { cardId: 'common', adult: true, country: 'NL' }, { country: 'NL' }), /country/);
  const r = await call('buyScratchWithCoins', 'real', { cardId: 'common', adult: true }, { country: 'IN' });
  ok(r.id, 'bought');
  const w = (await db.get('users/real/wallet/main')).data;
  ok(w.paidCardSpentINR === 49, 'counts toward the monthly limit: ' + w.paidCardSpentINR);
  await db.commit([db.write('users/real/wallet/main', { paidCardSpentINR: cfg.coupons.paidMonthlyLimitINR }, { merge: true })]);
  await rejects(call('buyScratchWithCoins', 'real', { cardId: 'common' }, { country: 'IN' }), /Monthly limit/);
});

await t('#25 an expired card is marked expired (not rolled back)', async () => {
  await put('users/real/scratchCards/old1', { status: 'sealed', rarity: 'common', prize: { type: 'coins', coins: 5 }, expiresAt: clock - 1000 });
  await rejects(call('revealScratch', 'real', { id: 'old1' }), /expired/);
  ok((await db.get('users/real/scratchCards/old1')).data.status === 'expired');
});

await t('#23 leagues: one doc per entrant, ranked by query, alias only', async () => {
  ok(leagueAlias('Ribon Patil') === 'Ribon P.' && leagueAlias('x@y.com') === 'Listener' && leagueAlias('') === 'Listener');
  const wk = weekKey(clock, cfg);
  for (const [u, n, xp] of [['l1', 'Asha Rao', 30], ['l2', 'Bilal Khan', 10], ['l3', 'Chen', 20]]) {
    await put(`users/${u}/earnCaps/${new Date(clock + 330 * 60e3).toISOString().slice(0, 10).replace(/-/g, '')}`, { freeCoins: xp });
    const v = await call('league', u, { name: n });
    ok(v.xp === xp, 'xp ' + v.xp);
  }
  const me = await call('league', 'l3', { name: 'Chen' });
  ok(me.rank === 2 && me.size === 3, `rank ${me.rank} size ${me.size}`);
  ok(me.top[0].name === 'Asha R.' && !JSON.stringify(me.top).includes('l1'), 'aliases, no uids');
  const tier = cfg.rewards.leagues.tiers[0];
  ok((await db.get(`leagues/${wk}_${tier}/entries/l1`)).exists, 'entry doc');
  ok(!(await db.get(`leagues/${wk}_${tier}`)).exists, 'no shared board doc');
  clock += 7 * DAY;
  const c = await call('claimLeague', 'l1');
  ok(c.rank === 1 && c.coins === (cfg.rewards.leagues.prizes[0] || 0), JSON.stringify(c));
  await rejects(call('claimLeague', 'l1'), /claimed/);
  await rejects(call('claimLeague', 'nobody'), /not in a league/);
});

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
