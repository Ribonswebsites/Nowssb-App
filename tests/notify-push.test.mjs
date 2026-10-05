// node --test tests/notify-push.test.mjs — server notification fan-out.
import test from 'node:test';
import assert from 'node:assert/strict';
import { fsFields } from '../functions/_lib/server.js';
import {
  categoryFor, fcmMessage, notificationOutbox, notificationsIn, pushToUid, subscriptionEvent, subscriptionMessage,
} from '../functions/_lib/notify/push.js';

const ROOT = 'projects/p/databases/(default)/documents';
function fakeDb({ subs = [], admins = [], existing = new Set() } = {}) {
  const db = {
    commits: [],
    name: (p) => `${ROOT}/${p}`,
    write(path, obj, { create = false } = {}) {
      const w = { update: { name: this.name(path), fields: fsFields(obj) } };
      if (create) w.currentDocument = { exists: false };
      return w;
    },
    async get(path) { return { exists: admins.some((a) => path === `admins/${a}`), data: null }; },
    async query(collection, where) {
      if (collection !== 'pushSubs') return [];
      const uid = where[0][2];
      return subs.filter((s) => s.uid === uid).map((s, i) => ({ id: 's' + i, path: 'pushSubs/s' + i, data: s }));
    },
    async commit(writes) {
      for (const w of writes) {
        if (w.currentDocument && w.update && existing.has(w.update.name)) throw new Error('already');
        if (w.update) existing.add(w.update.name);
      }
      db.commits.push(writes);
      return {};
    },
    async tx(fn) {
      // First attempt aborts (contention), second commits — like FsDb.
      for (let attempt = 0; attempt < 2; attempt++) {
        const writes = [];
        const t = { writes, set: (p, o) => writes.push(db.write(p, o)), create: (p, o) => writes.push(db.write(p, o, { create: true })) };
        const r = await fn(t);
        if (attempt === 0) continue;
        db.commits.push(writes);
        return r;
      }
    },
  };
  return db;
}
const SA = { project_id: 'p', client_email: 'x@y', private_key: 'k' };

function fetchSpy() {
  const sent = [];
  const f = async (url, init) => {
    if (String(url).includes('oauth2')) return new Response(JSON.stringify({ access_token: 'a' }));
    sent.push(JSON.parse(init.body));
    return new Response('{}', { status: 200 });
  };
  return { sent, f };
}

test('server kinds map to the app categories', () => {
  assert.deepEqual(categoryFor('gift'), { cat: 'gifts', route: 'gifts', promo: false });
  assert.equal(categoryFor('request_done').cat, 'requests');
  assert.equal(categoryFor('plan').cat, 'subscription');
  assert.equal(categoryFor('reference').route, 'reference');
  assert.equal(categoryFor('broadcast').promo, true);
  assert.equal(categoryFor('admin').cat, 'inbox');
});

test('current app: data-only; older installs keep the notification block', () => {
  const m = fcmMessage('tok', { cat: 'gifts', title: 'T', body: 'B', nid: 'n_1' }).message;
  assert.equal(m.notification, undefined);
  assert.equal(m.data.nwsb, '1');
  assert.equal(m.data.cat, 'gifts');
  assert.equal(m.android.priority, 'HIGH');
  assert.equal(m.android.collapse_key, 'n_1');
  const l = fcmMessage('tok', { cat: 'gifts', title: 'T', body: 'B' }, { legacy: true }).message;
  assert.equal(l.notification.title, 'T');
  assert.equal(l.data.title, 'T');
});

test('outbox pushes only the attempt that committed, once per document', async () => {
  const db = fakeDb({ subs: [{ uid: 'u1', fcmToken: 't1', notifFormat: 2 }, { uid: 'u2', fcmToken: 't2' }] });
  const outbox = notificationOutbox(db);
  let n = 0;
  await db.tx(async (t) => {
    n++;
    t.create(`users/u1/notifications/a${n}`, { title: 'Your gift was opened', body: 'Asha opened it.', kind: 'gift' });
    t.set('users/u2/wallet/main', { coins: 1 });
  });
  await db.commit([db.write('users/u2/notifications/z', { title: 'A friend joined', body: 'x', kind: 'reference' })]);
  assert.equal(outbox.pending.length, 2);
  assert.equal(outbox.pending[0].id, 'a2');
  const { sent, f } = fetchSpy();
  const r = await outbox.flush({}, { fetchImpl: f, account: SA, accessToken: async () => 'a' });
  assert.equal(r.sent, 2);
  assert.equal(sent[0].message.data.cat, 'gifts');
  assert.equal(sent[0].message.data.nid, 'n_a2');
  assert.equal(sent[0].message.notification, undefined);
  assert.equal(sent[1].message.data.route, 'reference');
  assert.ok(sent[1].message.notification, 'a phone without notifFormat 2 gets the old format');
  assert.equal((await outbox.flush({}, { fetchImpl: f, account: SA, accessToken: async () => 'a' })).sent, 0);
});

test('promotional pushes skip admins (admins/{uid} only)', async () => {
  const db = fakeDb({ subs: [{ uid: 'adm', fcmToken: 't' }, { uid: 'env', fcmToken: 't3' }, { uid: 'u', fcmToken: 't2' }], admins: ['adm'] });
  const { sent, f } = fetchSpy();
  const promo = { cat: 'offers', promo: true, title: 'Sale', body: '' };
  assert.equal((await pushToUid({}, db, 'adm', promo, { fetchImpl: f, account: SA, accessToken: async () => 'a' })).skipped, 'admin');
  // ADMIN_UIDS is not an admin source any more: one list, admins/{uid}.
  assert.equal((await pushToUid({ ADMIN_UIDS: 'env' }, db, 'env', promo, { fetchImpl: f, account: SA, accessToken: async () => 'a' })).sent, 1);
  assert.equal((await pushToUid({}, db, 'adm', { ...promo, promo: false, cat: 'inbox' }, { fetchImpl: f, account: SA, accessToken: async () => 'a' })).sent, 1);
  assert.equal((await pushToUid({}, db, 'u', promo, { fetchImpl: f, account: SA, accessToken: async () => 'a' })).sent, 1);
  assert.equal(sent.length, 3);
});

test('no FCM account: nothing pushed, nothing thrown', async () => {
  const r = await pushToUid({}, fakeDb(), 'u', { title: 'x' });
  assert.equal(r.skipped, 'not-configured');
});

test('RTDN events: one inbox row + one push per event, redeliveries ignored', async () => {
  const db = fakeDb({ subs: [{ uid: 'u', fcmToken: 't', notifFormat: 2 }] });
  const { sent, f } = fetchSpy();
  const ev = { tier: 'frequency', expiryTime: '2026-11-03T10:00:00.000Z' };
  const a = await subscriptionEvent({}, db, 'u', 2, ev, 'abcdef0123456789zz', { fetchImpl: f, account: SA, accessToken: async () => 'a' });
  const b = await subscriptionEvent({}, db, 'u', 2, ev, 'abcdef0123456789zz', { fetchImpl: f, account: SA, accessToken: async () => 'a' });
  assert.equal(a.sent, 1);
  assert.equal(b.skipped, 'already');
  assert.equal(sent.length, 1);
  assert.equal(sent[0].message.data.title, 'Frequency renewed');
  assert.equal(notificationsIn(db.commits[0]).length, 1);
  assert.equal(subscriptionMessage(4, ev), null);
  assert.match(subscriptionMessage(3, ev).body, /2026-11-03/);
});

test('admin console broadcast skips admins and passes the phone format through', async () => {
  const { memStore } = await import('./admin/memstore.mjs');
  const A = await import('../functions/_lib/admin_core.js');
  const db = memStore({
    'admins/boss0001': { at: 1 },
    'pushSubs/a': { uid: 'boss0001', fcmToken: 'ta', updatedAt: 1 },
    'pushSubs/b': { uid: 'user0001', fcmToken: 'tb', updatedAt: 2, notifFormat: 2 },
  });
  const got = [];
  const d = { db, push: async (t, m) => { got.push([t, m]); return { ok: true }; }, admin: { uid: 'boss0001', email: 'b@x' }, now: Date.now() };
  const r = await A.broadcast(d, { audience: 'all', title: 'Sale' });
  assert.equal(r.sent, 1);
  assert.equal(r.skipped, 1);
  assert.deepEqual(got.map((g) => g[0]), ['tb']);
  assert.equal(got[0][1].notifFormat, 2);
  const one = await A.broadcast(d, { audience: 'user', uid: 'boss0001', title: 'Direct' });
  assert.equal(one.sent, 1, 'a push to one chosen admin still goes');
});
