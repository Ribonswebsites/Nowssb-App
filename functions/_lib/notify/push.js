/* Phone notifications from the server, one per real event.

   The app (flutter_app/lib/features/notifications) reads these FCM messages:
   they are DATA-ONLY on purpose. A message with a `notification` block is
   drawn by Android itself while the app is in the background, which means
   the phone cannot apply the person's category switches, quiet hours or
   de-duplication, and the app's background handler drew a second copy on
   top of it. Data-only, high priority, lets the app decide and draw exactly
   one notification on the right channel with the right deep link.

     data.nwsb   '1' — marks the new format
     data.cat    category id (gifts, rewards, requests, subscription, inbox, offers)
     data.type   the server's kind (gift, earn, reference, plan, …)
     data.title / data.body
     data.route  where a tap goes (see notif_router.dart)
     data.nid    stable id — the phone shows each nid once
     data.promo  '1' for promotional sends; admins never get those

   Sources:
     · /api/economy/<action> — every users/{uid}/notifications document the
       action's transaction committed (gift opened, a friend joined with your
       link, team invites, sales, payouts …) is pushed after the commit, via
       [notificationOutbox].
     · /api/play/rtdn — subscription renewed / cancelled / on hold / grace /
       expired / recovered ([subscriptionEvent]).

   Env: FCM_SERVICE_ACCOUNT (falls back to FIREBASE_SERVICE_ACCOUNT, same as
   the admin console's push). Without either, nothing is pushed and nothing
   fails — the inbox document is still written and the app shows it. */
import { fsPlain, googleToken, parseServiceAccount } from '../server.js';

const SCOPE_FCM = 'https://www.googleapis.com/auth/firebase.messaging';

/** Server notification kind → app category + where a tap lands. */
export function categoryFor(kind) {
  const k = String(kind || '').toLowerCase();
  if (k === 'gift' || k.startsWith('gift')) return { cat: 'gifts', route: 'gifts', promo: false };
  if (k === 'request_done' || k === 'arrivals') return { cat: 'requests', route: 'requests', promo: false };
  if (k === 'plan' || k.startsWith('sub')) return { cat: 'subscription', route: 'subscription', promo: false };
  if (k === 'reference') return { cat: 'rewards', route: 'reference', promo: false };
  if (k === 'earn' || k === 'payout') return { cat: 'rewards', route: 'earn', promo: false };
  if (k === 'economy' || k === 'coins' || k === 'reward' || k === 'badge') return { cat: 'rewards', route: 'rewards', promo: false };
  if (k === 'broadcast' || k === 'offer' || k === 'offers' || k === 'promo') return { cat: 'offers', route: 'store', promo: true };
  return { cat: 'inbox', route: 'inbox', promo: false };
}

export function adminUidsFromEnv(env) {
  return new Set(String((env && env.ADMIN_UIDS) || '').split(',').map((s) => s.trim()).filter(Boolean));
}

/** Admins: a document at admins/{uid} — the one admin source for the whole
    site (console, /api/admin, /api/push). ADMIN_UIDS is no longer read. */
export async function isAdminUid(env, db, uid) {
  if (!uid) return false;
  try {
    const a = await db.get(`admins/${uid}`);
    return !!(a && (a.exists === true || (a.exists === undefined && a)));
  } catch (e) { return false; }
}

export function pushAccount(env) {
  return parseServiceAccount(env && env.FCM_SERVICE_ACCOUNT) || parseServiceAccount(env && env.FIREBASE_SERVICE_ACCOUNT);
}

/**
 * The FCM v1 body for one token. Pure, so it can be tested.
 * [legacy] (installs that never registered notifFormat 2: older app builds,
 * the retired Capacitor shell) also gets the notification block those builds
 * were made for, on the channel they create.
 */
export function fcmMessage(token, n, { legacy = false } = {}) {
  const data = {
    nwsb: '1',
    cat: String(n.cat || 'inbox'),
    type: String(n.type || ''),
    title: String(n.title || 'NowssB').slice(0, 120),
    body: String(n.body || '').slice(0, 400),
    route: String(n.route || ''),
    nid: String(n.nid || ''),
    promo: n.promo ? '1' : '0',
    at: String(n.at || Date.now()),
  };
  const android = { priority: 'HIGH', ttl: (n.ttlSec || 86400) + 's' };
  if (data.nid) android.collapse_key = data.nid.slice(0, 64);
  if (data.route === '' && n.url) data.url = String(n.url);
  if (legacy) {
    android.notification = { channel_id: 'nowssb', color: '#e8d5a3' };
    return { message: { token, notification: { title: data.title, body: data.body }, data, android } };
  }
  return { message: { token, data, android } };
}

async function sendOne(sa, token, n, fetchImpl, legacy, accessToken) {
  const access = accessToken ? await accessToken() : await googleToken(sa, SCOPE_FCM);
  const r = await fetchImpl('https://fcm.googleapis.com/v1/projects/' + sa.project_id + '/messages:send', {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + access, 'Content-Type': 'application/json' },
    body: JSON.stringify(fcmMessage(token, n, { legacy })),
  });
  const text = await r.text().catch(() => '');
  return { ok: r.ok, expired: r.status === 404 || /UNREGISTERED|registration-token-not-registered/i.test(text) };
}

/** Every FCM token saved for [uid] (pushSubs, written by the app). */
async function tokensFor(db, uid) {
  const rows = await db.query('pushSubs', [['uid', '==', uid]], { limit: 20 });
  const out = [];
  for (const r of rows) {
    const d = r.data || {};
    const t = d.fcmToken || (String(d.endpoint || '').startsWith('fcm:') ? String(d.endpoint).slice(4) : '');
    if (t && !out.some((x) => x.token === t)) out.push({ token: t, path: r.path, legacy: Number(d.notifFormat) !== 2 });
  }
  return out;
}

/**
 * Push one notification to every phone of [uid]. Promotional sends skip
 * admins. Never throws; returns { sent, skipped }.
 */
export async function pushToUid(env, db, uid, n, { fetchImpl = (...a) => fetch(...a), account, accessToken } = {}) {
  try {
    const sa = account !== undefined ? account : pushAccount(env);
    if (!sa || !uid) return { sent: 0, skipped: 'not-configured' };
    if (n.promo && await isAdminUid(env, db, uid)) return { sent: 0, skipped: 'admin' };
    const toks = await tokensFor(db, uid);
    let sent = 0;
    const dead = [];
    for (const t of toks) {
      try {
        const r = await sendOne(sa, t.token, n, fetchImpl, t.legacy, accessToken);
        if (r.ok) sent++;
        if (r.expired) dead.push(t.path);
      } catch (e) { /* one bad token never stops the rest */ }
    }
    if (dead.length && db.commit) {
      await db.commit(dead.map((p) => ({ delete: db.name ? db.name(p) : p }))).catch(() => {});
    }
    return { sent, devices: toks.length };
  } catch (e) {
    return { sent: 0, skipped: 'error' };
  }
}

const NOTIF_PATH = /\/documents\/users\/([^/]+)\/notifications\/([^/]+)$/;

/** users/{uid}/notifications writes inside a Firestore REST write list. */
export function notificationsIn(writes) {
  const out = [];
  for (const w of writes || []) {
    const name = w && w.update && w.update.name;
    if (!name) continue;
    const m = NOTIF_PATH.exec(name);
    if (!m) continue;
    const d = fsPlain({ mapValue: { fields: w.update.fields || {} } }) || {};
    out.push({ uid: decodeURIComponent(m[1]), id: decodeURIComponent(m[2]), data: d });
  }
  return out;
}

/**
 * Watches an FsDb for notification documents written by a request and
 * pushes them once the write has committed. Only the attempt that actually
 * committed counts (transactions retry on contention).
 *
 *   const outbox = notificationOutbox(db);
 *   … run the action …
 *   waitUntil(outbox.flush(env));
 */
export function notificationOutbox(db) {
  const committed = [];
  const origTx = db.tx.bind(db);
  const origCommit = db.commit.bind(db);
  db.tx = async (fn, opts) => {
    let attempt = [];
    const result = await origTx(async (t) => {
      attempt = [];
      const r = await fn(t);
      attempt = notificationsIn(t.writes);
      return r;
    }, opts);
    committed.push(...attempt);
    return result;
  };
  db.commit = async (writes) => {
    const r = await origCommit(writes);
    committed.push(...notificationsIn(writes));
    return r;
  };
  return {
    get pending() { return committed.slice(); },
    async flush(env, opts = {}) {
      const items = committed.splice(0, committed.length);
      const seen = new Set();
      let sent = 0;
      for (const it of items) {
        const key = it.uid + '/' + it.id;
        if (seen.has(key)) continue;
        seen.add(key);
        const kind = it.data.kind || it.data.type || 'economy';
        const c = categoryFor(kind);
        const r = await pushToUid(env, db, it.uid, {
          cat: c.cat, type: kind, route: c.route, promo: c.promo,
          title: it.data.title || 'NowssB', body: it.data.body || '', nid: 'n_' + it.id,
        }, opts);
        sent += r.sent || 0;
      }
      return { sent, items: seen.size };
    },
  };
}

const PLAN_NAMES = { resonance: 'Resonance', frequency: 'Frequency', frequencyX: 'Frequency X' };
const day = (iso) => (iso ? String(iso).slice(0, 10) : '');

/**
 * Play RTDN subscriptionNotification.notificationType → what the person is
 * told. Types without anything worth saying (purchased: the app already
 * shows it; deferred; price change) return null.
 */
export function subscriptionMessage(type, ev) {
  const plan = PLAN_NAMES[ev && ev.tier] || 'NowssB';
  const until = day(ev && ev.expiryTime);
  switch (Number(type)) {
    case 1: return { title: `${plan} is back on`, body: 'Your payment went through and your plan is active again.' };
    case 2: return { title: `${plan} renewed`, body: until ? `Thank you. Your plan now runs until ${until}.` : 'Thank you. Your plan renewed.' };
    case 3: return { title: 'Auto-renew is off', body: until ? `${plan} stays on until ${until}. You can turn renewal back on in Google Play.` : `${plan} will not renew.` };
    case 5: return { title: 'Your plan is on hold', body: 'Google Play could not take the payment. Update your payment method in Play to get your plan back.' };
    case 6: return { title: 'Payment problem', body: `Google Play could not renew ${plan}. Fix the payment method in Play to keep it — it is still on for now.` };
    case 7: return { title: `${plan} will renew`, body: 'Auto-renew is back on. Thank you for staying.' };
    case 10: return { title: `${plan} is paused`, body: 'Your plan is paused in Google Play and resumes on the date you chose.' };
    case 12: return { title: 'Your plan was revoked', body: 'Google Play revoked this subscription. Write to us if you think this is a mistake.' };
    case 13: return { title: `${plan} has ended`, body: 'Your plan expired. Your words and progress are still here whenever you want to come back.' };
    default: return null;
  }
}

/**
 * One RTDN event → one inbox document + one push, at most once. The inbox
 * document id is derived from the event, and is created only if absent, so a
 * Pub/Sub redelivery neither duplicates the inbox nor pushes twice.
 */
export async function subscriptionEvent(env, db, uid, type, ev, tokenHash, opts = {}) {
  const msg = subscriptionMessage(type, ev);
  if (!msg || !uid) return { sent: 0, skipped: 'nothing-to-say' };
  const id = ('sub_' + type + '_' + String(tokenHash || '').slice(0, 16) + '_' + String((ev && ev.expiryTime) || '').replace(/[^0-9]/g, '').slice(0, 14)).slice(0, 120);
  try {
    await db.commit([db.write(`users/${uid}/notifications/${id}`, {
      title: msg.title, body: msg.body, kind: 'subscription', type: 'subscription', read: false, at: Date.now(),
    }, { create: true })]);
  } catch (e) {
    return { sent: 0, skipped: 'already' };
  }
  return pushToUid(env, db, uid, { cat: 'subscription', type: 'subscription', route: 'subscription', promo: false, title: msg.title, body: msg.body, nid: 'n_' + id }, opts);
}
