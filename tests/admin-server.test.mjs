// Offline tests for the admin console server (functions/_lib/admin_*.js).
// Run: node --test tests/admin-server.test.mjs
import test from 'node:test';
import assert from 'node:assert/strict';
import { memStore } from './admin/memstore.mjs';
import * as A from '../functions/_lib/admin_core.js';
import { handleAdmin, adminConfig } from '../functions/_lib/admin_route.js';
import { encodeOps, structuredQuery } from '../functions/_lib/admin_store.js';
import { parseList, authRow } from '../functions/_lib/admin_google.js';

const DAY = 86400000;
const NOW = Date.UTC(2026, 9, 2, 12);
const iso = (t) => new Date(t).toISOString();
const admin = { uid: 'boss', email: 'boss@x.com' };

function fakeAuth(users = []) {
  const calls = [];
  return {
    calls,
    async lookup(uids) { return users.filter((u) => uids.includes(u.uid)); },
    async all() { return { users, truncated: false }; },
    async page() { return { users, next: '' }; },
    async count() { return users.length; },
    async setDisabled(uid, d) { calls.push([uid, d]); return true; },
  };
}
const au = (uid, extra = {}) => ({ uid, email: uid + '@x.com', name: uid.toUpperCase(), phone: '', photo: '', providers: ['google.com'], createdAt: NOW - 3 * DAY, lastLoginAt: NOW - DAY, lastRefreshAt: 0, disabled: false, ...extra });

function deps(db, extra = {}) {
  const sent = [];
  return { db, auth: fakeAuth(), push: async (t, m) => { sent.push([t, m]); return { ok: true, expired: t === 'dead' }; }, r2: null, admin, now: NOW, sent, ...extra };
}
const rowsOf = (db, prefix) => [...db.store.entries()].filter(([k]) => k.startsWith(prefix)).map(([, v]) => v);

test('stats counts only what exists; empty project is all zero', async () => {
  const db = memStore();
  const s = await A.stats(deps(db, { auth: fakeAuth([]) }));
  assert.equal(s.users.profiles, 0);
  assert.equal(s.users.accounts, 0);
  assert.equal(s.subscriptions.active, 0);
  assert.equal(s.coins.issued, 0);
  assert.equal(s.signups.length, 30);
  assert.ok(s.signups.every((d) => d.n === 0));
});

test('stats: online, today, plans, coins, requests, gifts, payouts, sign-ups', async () => {
  const db = memStore({
    'users/a': { lastSeenAt: new Date(NOW - 60e3), isPro: true, tier: 'frequency', subscriptionBilling: 'monthly', subscriptionEndDate: iso(NOW + 10 * DAY), subscriptionSource: 'play' },
    'users/b': { lastSeenAt: new Date(NOW - 3 * DAY), isPro: true, tier: 'resonance', subscriptionBilling: 'yearly', subscriptionEndDate: iso(NOW + 100 * DAY), subscriptionSource: 'admin' },
    'users/c': { lastSeenAt: new Date(NOW - 20 * DAY), isPro: true, tier: 'frequencyX', subscriptionEndDate: iso(NOW - DAY), blocked: true },
    'users/d': { roles: ['helper'] },
    'coinLedger/1': { uid: 'a', delta: 30 }, 'coinLedger/2': { uid: 'a', delta: -10 }, 'coinLedger/3': { uid: 'b', delta: 5 },
    'requests/r1': { status: 'new', word: 'om' }, 'requests/r2': { status: 'done', word: 'ra' },
    'gifts/GFTAAA': { status: 'redeemed' }, 'gifts/GFTBBB': { status: 'unredeemed' },
    'payoutRequests/p1': { status: 'pending_review', amountBase: 600 },
    'payments/x': { uid: 'a', at: new Date(NOW - DAY) },
  });
  const auth = fakeAuth([au('a', { createdAt: NOW - 1000 }), au('b', { createdAt: NOW - 2 * DAY }), au('c', { createdAt: NOW - 40 * DAY })]);
  const s = await A.stats(deps(db, { auth }), { tzOffsetMin: 0 });
  assert.equal(s.users.profiles, 4);
  assert.equal(s.users.accounts, 3);
  assert.equal(s.users.online, 1);
  assert.equal(s.users.signedIn7d >= 2, true);
  assert.equal(s.users.blocked, 1);
  assert.equal(s.users.helpers, 1);
  assert.equal(s.users.signupsToday, 1);
  assert.equal(s.users.signups7d, 2);
  assert.equal(s.subscriptions.active, 2);
  assert.equal(s.subscriptions.lapsedFlagged, 1);
  assert.equal(s.subscriptions.plans.frequency.monthly, 1);
  assert.equal(s.subscriptions.plans.resonance.yearly, 1);
  assert.equal(s.subscriptions.expired, 1);
  assert.equal(s.coins.issued, 35);
  assert.equal(s.coins.spent, 10);
  assert.deepEqual(s.requests, { open: 1, done: 1, total: 2 });
  assert.equal(s.gifts.codes, 2);
  assert.equal(s.gifts.opened, 1);
  assert.equal(s.payouts.pending, 1);
  assert.equal(s.payments.total, 1);
  assert.equal(s.signups.reduce((n, d) => n + d.n, 0), 2);
});

test('people: search by email, name, uid and phone; filters', async () => {
  const db = memStore({ 'users/alice123': { blocked: true, lastSeenAt: new Date(NOW - 1000) }, 'users/bob4567': { isPro: true, tier: 'resonance', subscriptionEndDate: iso(NOW + DAY) } });
  const auth = fakeAuth([au('alice123', { phone: '+919876543210' }), au('bob4567', { name: 'Bob Marley' })]);
  const d = deps(db, { auth });
  assert.equal((await A.listUsers(d, { q: 'alice123@x' })).rows.length, 1);
  assert.equal((await A.listUsers(d, { q: 'marley' })).rows[0].uid, 'bob4567');
  assert.equal((await A.listUsers(d, { q: '98765 43210' })).rows[0].uid, 'alice123');
  assert.equal((await A.listUsers(d, { q: 'bob45' })).rows[0].plan.active, true);
  const blocked = await A.listUsers(d, { filter: 'blocked' });
  assert.deepEqual(blocked.rows.map((r) => r.uid), ['alice123']);
  assert.equal((await A.listUsers(d, { filter: 'online' })).rows[0].online, true);
  assert.deepEqual((await A.listUsers(d, { filter: 'plan', tier: 'resonance' })).rows.map((r) => r.uid), ['bob4567']);
  const noAuth = await A.listUsers(deps(db, { auth: null }), {});
  assert.equal(noAuth.source, 'firestore');
  assert.equal(noAuth.rows.length, 2);
});

test('subscription grant, extend and revoke write the fields the app reads', async () => {
  const db = memStore({ 'users/u1234567': { displayName: 'U' } });
  const d = deps(db);
  await assert.rejects(A.grantSub(d, { uid: 'u1234567', tier: 'gold', days: 30 }), /Resonance/);
  const g = await A.grantSub(d, { uid: 'u1234567', tier: 'frequency', billing: 'monthly', days: 30 });
  assert.equal(g.plan.active, true);
  let u = db.store.get('users/u1234567');
  assert.equal(u.isPro, true);
  assert.equal(u.tier, 'frequency');
  assert.equal(u.subscriptionSource, 'admin');
  assert.equal(u.subscriptionEndDate, iso(NOW + 30 * DAY));
  await A.extendSub(d, { uid: 'u1234567', days: 10 });
  u = db.store.get('users/u1234567');
  assert.equal(u.subscriptionEndDate, iso(NOW + 40 * DAY));
  await A.grantSub(d, { uid: 'u1234567', tier: 'frequencyX', until: iso(NOW + 365 * DAY) });
  assert.equal(db.store.get('users/u1234567').tier, 'frequencyX');
  const r = await A.revokeSub(d, { uid: 'u1234567' });
  assert.equal(r.plan.active, false);
  assert.equal(db.store.get('users/u1234567').isPro, false);
  const logs = rowsOf(db, 'adminLog/').map((x) => x.action);
  assert.deepEqual(logs.sort(), ['sub.extend', 'sub.grant', 'sub.grant', 'sub.revoke']);
  assert.ok(rowsOf(db, 'adminLog/').every((x) => x.uid === 'boss' && x.at));
  assert.ok(rowsOf(db, 'users/u1234567/notifications/').length >= 2);
});

test('coins go through the ledger; cannot go below zero', async () => {
  const db = memStore({ 'users/u1234567/wallet/main': { coins: 50 } });
  const d = deps(db);
  await assert.rejects(A.adjustCoins(d, { uid: 'u1234567', delta: 10 }), /why/);
  const r = await A.adjustCoins(d, { uid: 'u1234567', delta: 25, reason: 'Contest' });
  assert.equal(r.balance, 75);
  await assert.rejects(A.adjustCoins(d, { uid: 'u1234567', delta: -100, reason: 'x' }), /only have 75/);
  await A.adjustCoins(d, { uid: 'u1234567', delta: -5, reason: 'Fix' });
  const rows = rowsOf(db, 'coinLedger/');
  assert.equal(rows.length, 2);
  assert.deepEqual(rows.map((x) => x.balanceAfter).sort(), [70, 75]);
  assert.equal(db.store.get('users/u1234567/wallet/main').coins, 70);
  assert.equal(db.store.get('users/u1234567/wallet/main').lifetimeEarned, 25);
});

test('block disables the Auth account and sets the flag; admins cannot be blocked', async () => {
  const db = memStore({ 'users/u1234567': {}, 'admins/other12': { at: 1 } });
  const d = deps(db);
  const r = await A.setBlocked(d, { uid: 'u1234567', reason: 'spam' });
  assert.equal(r.auth, 'disabled');
  assert.deepEqual(d.auth.calls, [['u1234567', true]]);
  assert.equal(db.store.get('users/u1234567').blocked, true);
  await A.setBlocked(d, { uid: 'u1234567', blocked: false });
  assert.equal(db.store.get('users/u1234567').blocked, false);
  await assert.rejects(A.setBlocked(d, { uid: 'other12' }), /admin/);
  const noSa = await A.setBlocked(deps(db, { auth: null }), { uid: 'u1234567' });
  assert.match(noSa.auth, /FIREBASE_SERVICE_ACCOUNT/);
});

test('restrictions keep only known switches; streak reset; helper role; message pushes', async () => {
  const db = memStore({ 'users/u1234567': {}, 'users/u1234567/wallet/main': { coins: 3, streak: 12 }, 'pushSubs/t1': { uid: 'u1234567', fcmToken: 'tok' }, 'pushSubs/t2': { uid: 'u1234567', fcmToken: 'dead' } });
  const d = deps(db);
  const r = await A.setRestrictions(d, { uid: 'u1234567', restrictions: { community: true, payouts: true, hack: true } });
  assert.deepEqual(r.restrictions, { community: true, payouts: true });
  assert.equal((await A.resetStreak(d, { uid: 'u1234567' })).was, 12);
  assert.equal(db.store.get('users/u1234567/wallet/main').streak, 0);
  assert.deepEqual((await A.setHelper(d, { uid: 'u1234567' })).roles, ['helper']);
  assert.deepEqual((await A.setHelper(d, { uid: 'u1234567', on: false })).roles, []);
  const m = await A.messageUser(d, { uid: 'u1234567', title: 'Hi', body: 'There' });
  assert.equal(m.push.sent, 2);
  assert.equal(db.store.has('pushSubs/t2'), false, 'expired token removed');
  const noPush = await A.messageUser(deps(db, { push: null }), { uid: 'u1234567', title: 'Hi' });
  assert.deepEqual(noPush.push.missing, ['FCM_SERVICE_ACCOUNT']);
});

test('fulfil request marks done and tells the requester', async () => {
  const db = memStore({ 'requests/req0001': { uid: 'u1234567', word: 'Om', status: 'new' } });
  const r = await A.fulfilRequest(deps(db), { id: 'req0001', wordKey: 'om' });
  assert.equal(r.told, true);
  assert.equal(db.store.get('requests/req0001').status, 'done');
  assert.equal(db.store.get('requests/req0001').fulfilledWord, 'om');
  const n = rowsOf(db, 'users/u1234567/notifications/');
  assert.equal(n[0].wordKey, 'om');
});

test('broadcast pages through tokens, filters by plan, and 501s without FCM', async () => {
  const seed = { 'users/p1aaaaaa': { isPro: true, tier: 'frequency', subscriptionEndDate: iso(NOW + DAY) } };
  for (let i = 0; i < 45; i++) seed['pushSubs/s' + i] = { uid: i === 0 ? 'p1aaaaaa' : 'free' + i, fcmToken: 't' + i, updatedAt: 1000 + i };
  const db = memStore(seed);
  const d = deps(db);
  const a = await A.broadcast(d, { audience: 'all', title: 'Hello' });
  assert.equal(a.sent, 40);
  assert.ok(a.next);
  const b = await A.broadcast(d, { audience: 'all', title: 'Hello', cursor: a.next, broadcastId: a.broadcastId });
  assert.equal(b.sent, 5);
  assert.equal(b.next, '');
  assert.equal(db.store.get('broadcasts/' + a.broadcastId).sent, 45);
  const p = await A.broadcast(deps(db), { audience: 'plan', tier: 'frequency', title: 'Plan' });
  assert.equal(p.sent, 1);
  await assert.rejects(A.broadcast(deps(db, { push: null }), { audience: 'all', title: 'x' }), (e) => e.status === 501 && e.extra.missing[0] === 'FCM_SERVICE_ACCOUNT');
});

test('payouts: approve, paid with UTR, reject refunds through cashLedger', async () => {
  const db = memStore({
    'payoutRequests/p1': { uid: 'u1234567', amountBase: 700, status: 'pending_review' },
    'payoutRequests/p2': { uid: 'u1234567', amountBase: 300, status: 'pending_review' },
    'users/u1234567/payout/main': { cashBalance: 0, pendingCents: 1000, paidCents: 0 },
  });
  const d = deps(db);
  assert.equal((await A.decidePayout(d, { id: 'p1', decision: 'approve' })).status, 'approved');
  await assert.rejects(A.decidePayout(d, { id: 'p1', decision: 'paid' }), /UTR/);
  await A.decidePayout(d, { id: 'p1', decision: 'paid', utr: '123456789012' });
  await assert.rejects(A.decidePayout(d, { id: 'p1', decision: 'reject', note: 'x' }), /Already paid/);
  await A.decidePayout(d, { id: 'p2', decision: 'reject', note: 'UPI id invalid' });
  const pay = db.store.get('users/u1234567/payout/main');
  assert.deepEqual([pay.cashBalance, pay.pendingCents, pay.paidCents], [300, 0, 700]);
  assert.equal(rowsOf(db, 'cashLedger/')[0].delta, 300);
});

test('gift codes are created unredeemed and can be voided', async () => {
  const db = memStore();
  const d = deps(db);
  const r = await A.createGiftCodes(d, { item: 'resonance', count: 3, expiresDays: 30, campaign: 'Diwali' });
  assert.equal(r.codes.length, 3);
  assert.ok(r.codes.every((c) => /^GFT[A-Z2-9]{6}$/.test(c)));
  const g = db.store.get('gifts/' + r.codes[0]);
  assert.equal(g.status, 'unredeemed');
  assert.equal(g.expiresAt, NOW + 30 * DAY);
  await A.voidGift(d, { code: r.codes[0] });
  assert.equal(db.store.get('gifts/' + r.codes[0]).status, 'void');
  await assert.rejects(A.createGiftCodes(d, { item: 'gold', count: 1 }), /Pick/);
});

test('feed merges sources newest first; profile gathers everything', async () => {
  const db = memStore({
    'users/u1234567': { displayName: 'U', lastBuild: '512', lastPlatform: 'android' },
    'activity/a1': { type: 'login', uid: 'u1234567', summary: 'Signed in', at: new Date(NOW - 1000) },
    'requests/r1': { uid: 'u1234567', word: 'Om', status: 'new', at: NOW - 5000 },
    'payments/p1': { uid: 'u1234567', tier: 'frequency', billing: 'monthly', at: new Date(NOW - 9000) },
    'coinLedger/c1': { uid: 'u1234567', delta: 10, balanceAfter: 10, reason: 'Daily', at: new Date(NOW - 2000) },
    'referrals/friend001': { referrerUid: 'u1234567', subscribed: true },
  });
  const f = await A.feed(deps(db));
  assert.deepEqual(f.rows.map((r) => r.type), ['login', 'request', 'purchase']);
  const p = await A.userProfile(deps(db, { auth: fakeAuth([au('u1234567')]) }), { uid: 'u1234567' });
  assert.equal(p.user.lastBuild, '512');
  assert.equal(p.coinLedger.length, 1);
  assert.equal(p.invited[0].uid, 'friend001');
  assert.deepEqual(p.row.providers, ['google.com']);
  await assert.rejects(A.userProfile(deps(db, { auth: fakeAuth([]) }), { uid: 'nobody00' }), /No account/);
  const net = await A.network(deps(db), { uid: 'u1234567' });
  assert.equal(net.level1.length, 1);
});

test('route: 501 lists the missing secret, 401 without token, 403 for non-admins, 200 for admins', async () => {
  const req = (body = {}, auth = '') => new Request('https://nowssb.com/api/admin/stats', { method: 'POST', headers: auth ? { Authorization: auth } : {}, body: JSON.stringify(body) });
  let r = await handleAdmin({ request: req(), env: {}, params: { action: 'stats' } });
  assert.equal(r.status, 501);
  assert.deepEqual((await r.json()).missing, ['FIREBASE_SERVICE_ACCOUNT']);
  const db = memStore({ 'admins/boss': { at: 1 } });
  r = await handleAdmin({ request: req(), env: {}, params: { action: 'stats' } }, { db });
  assert.equal(r.status, 401);
  r = await handleAdmin({ request: req(), env: {}, params: { action: 'stats' } }, { db, claims: { sub: 'eve' } });
  assert.equal(r.status, 403);
  r = await handleAdmin({ request: req({ uid: 'u1234567', delta: 5, reason: 'x' }), env: {}, params: { action: 'adjust-coins' } }, { db, claims: { sub: 'boss', email: 'b@x' }, auth: null, push: null, r2: null, now: NOW });
  assert.equal(r.status, 200);
  assert.equal((await r.json()).balance, 5);
  r = await handleAdmin({ request: req(), env: {}, params: { action: 'nope' } }, { db });
  assert.equal(r.status, 404);
  r = await handleAdmin({ request: req({ uid: 'u1234567', delta: -50, reason: 'x' }), env: {}, params: { action: 'adjust-coins' } }, { db, claims: { sub: 'x', admin: true }, auth: null, push: null, r2: null });
  assert.equal(r.status, 409);
  const cfg = adminConfig({});
  assert.ok(cfg.missing.includes('FCM_SERVICE_ACCOUNT') && cfg.missing.includes('R2_BUCKET'));
});

test('ui-assets without R2 still lists override URLs and names the missing vars', async () => {
  const db = memStore({ 'ui_overrides/a': { url: 'https://media.nowssb.com/ui/x/1.svg' } });
  const r = await A.uiAssets(deps(db, { r2Missing: ['R2_BUCKET'] }), { prefix: 'ui/' });
  assert.deepEqual(r.overrides, ['https://media.nowssb.com/ui/x/1.svg']);
  assert.deepEqual(r.missing, ['R2_BUCKET']);
  const r2 = await A.uiAssets(deps(db, { r2: async () => [{ key: 'ui/a.svg', url: 'u1' }, { key: 'ui/b.webp', url: 'u2' }] }), { prefix: 'ui/', ext: 'svg' });
  assert.deepEqual(r2.items.map((x) => x.key), ['ui/a.svg']);
});

test('REST encoding: server timestamps, merge masks, create preconditions, queries', () => {
  const w = encodeOps('B', [
    { op: 'merge', path: 'users/u', data: { a: 1, at: null }, serverTime: ['at'] },
    { op: 'create', path: 'x/y', data: { d: new Date(0) } },
    { op: 'delete', path: 'z/1' },
  ]);
  assert.deepEqual(w[0].updateMask.fieldPaths, ['a']);
  assert.equal(w[0].updateTransforms[0].setToServerValue, 'REQUEST_TIME');
  assert.equal(w[1].currentDocument.exists, false);
  assert.equal(w[1].update.fields.d.timestampValue, '1970-01-01T00:00:00.000Z');
  assert.equal(w[2].delete, 'B/z/1');
  const q = structuredQuery({ collection: 'users', where: [['isPro', '==', true], ['roles', 'array-contains', 'helper']], orderBy: [['at', 'desc']], limit: 5, select: ['tier'] });
  assert.equal(q.where.compositeFilter.filters[1].fieldFilter.op, 'ARRAY_CONTAINS');
  assert.equal(q.orderBy[0].direction, 'DESCENDING');
  assert.equal(q.select.fields[0].fieldPath, 'tier');
  const l = parseList('<ListBucketResult><IsTruncated>false</IsTruncated><Contents><Key>ui/a.svg</Key><Size>12</Size></Contents></ListBucketResult>');
  assert.deepEqual(l.items[0], { key: 'ui/a.svg', size: 12, modified: '' });
  assert.equal(authRow({ localId: 'u', createdAt: '5', providerUserInfo: [{ providerId: 'password' }] }).providers[0], 'password');
});
