/* Admin alerts — the Admin app's inbox (Firestore adminAlerts/{id}) and a
   phone push to every admin's device (pushSubs whose uid is on admins/).

   raiseAlert(deps, alert) works with the admin_store interface (REST in
   production, memory in tests). The id is deterministic (kind + ref), so the
   same event raised twice is one alert and one push. Never throws. */
import { restStore } from './admin_store.js';
import { googleToken, parseServiceAccount, serviceAccount } from './server.js';
import { fcmSend } from './admin_google.js';

export const ALERT_KINDS = {
  request: 'New word request',
  payout: 'Payout request',
  signup: 'New sign-up',
  purchase: 'New purchase',
  feedback: 'New feedback',
  deletion: 'Account deletion request',
};

const s = (v, n = 200) => String(v == null ? '' : v).trim().slice(0, n);
const idOf = (kind, ref) => (kind + '_' + String(ref || '')).replace(/[^A-Za-z0-9_-]/g, '_').slice(0, 140);

export async function raiseAlert(deps, alert = {}) {
  const { db, push } = deps;
  const kind = ALERT_KINDS[alert.kind] ? alert.kind : '';
  if (!kind || !db) return { ok: false, reason: 'bad_kind' };
  const id = idOf(kind, alert.ref);
  try {
    if (await db.get(`adminAlerts/${id}`)) return { ok: true, id, duplicate: true, pushed: 0 };
    const title = s(alert.title, 80) || ALERT_KINDS[kind];
    const body = s(alert.body, 300);
    await db.commit([{ op: 'create', path: `adminAlerts/${id}`, data: { kind, ref: s(alert.ref, 140), uid: s(alert.uid, 128), title, body, route: s(alert.route, 80), seen: false, at: null }, serverTime: ['at'] }]);
    let pushed = 0;
    if (push) {
      const admins = await db.query({ collection: 'admins', limit: 300 }).catch(() => []);
      for (const a of admins) {
        const subs = await db.query({ collection: 'pushSubs', where: [['uid', '==', a.id]], limit: 10 }).catch(() => []);
        for (const sub of subs) {
          const t = sub.data.fcmToken || (String(sub.data.endpoint || '').startsWith('fcm:') ? String(sub.data.endpoint).slice(4) : '');
          if (!t) continue;
          try { const r = await push(t, { title: 'Admin · ' + title, body, type: 'admin_alert', route: 'admin:' + kind }); if (r.ok) pushed++; } catch (e) { /* next */ }
        }
      }
    }
    return { ok: true, id, pushed };
  } catch (e) {
    return { ok: false, reason: String((e && e.message) || e).slice(0, 120) };
  }
}

/** Same, from a Pages Function with only `env` (service account in env). */
export async function raiseAlertFromEnv(env, alert, project = 'nowssb-34f1b') {
  try {
    const sa = serviceAccount(env || {});
    if (!sa) return { ok: false, reason: 'not_configured' };
    const db = restStore(await googleToken(sa), (env && env.FIREBASE_PROJECT_ID) || project);
    const pushSa = parseServiceAccount(env.FCM_SERVICE_ACCOUNT) || parseServiceAccount(env.FIREBASE_SERVICE_ACCOUNT);
    return await raiseAlert({ db, push: pushSa ? (t, m) => fcmSend(pushSa, t, m) : null }, alert);
  } catch (e) {
    return { ok: false, reason: String((e && e.message) || e).slice(0, 120) };
  }
}
