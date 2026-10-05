/* POST /api/admin-alert — a signed-in member's app tells the admins about
   something it just did, so the Admin app's inbox and the admins' phones hear
   of it at once. The server checks the claim against Firestore before it
   raises anything; the member cannot write adminAlerts themselves.

     { kind: 'request', id }   their own requests/{id}, status new
     { kind: 'signup' }        their own Auth account, created < 30 minutes ago
     { kind: 'feedback', id }  their own feedback/{id}

   Payouts and purchases are raised by the server code that records them. */
import { cors, json, requireUser, serviceAccount, googleToken, parseServiceAccount } from '../_lib/server.js';
import { restStore } from '../_lib/admin_store.js';
import { authAdmin, fcmSend } from '../_lib/admin_google.js';
import { raiseAlert } from '../_lib/admin_alerts.js';

const PROJECT = 'nowssb-34f1b';

export async function onRequestOptions({ request }) {
  return new Response(null, { status: 204, headers: cors(request) });
}

export async function handleAlert(request, env, deps = {}) {
  const h = cors(request);
  const e = { ...(env || {}), FIREBASE_PROJECT_ID: (env && env.FIREBASE_PROJECT_ID) || PROJECT };
  const sa = serviceAccount(e);
  if (!deps.db && !sa) return json({ error: 'Not configured.', code: 'not_configured' }, 501, h);
  const claims = deps.claims || await requireUser(request, e, h);
  if (claims instanceof Response) return claims;
  let body = {};
  try { body = JSON.parse((await request.text()) || '{}') || {}; } catch (err) { return json({ error: 'Send JSON.' }, 400, h); }
  const db = deps.db || restStore(await googleToken(sa), e.FIREBASE_PROJECT_ID);
  const pushSa = parseServiceAccount(e.FCM_SERVICE_ACCOUNT) || parseServiceAccount(e.FIREBASE_SERVICE_ACCOUNT);
  const push = deps.push !== undefined ? deps.push : (pushSa ? (t, m) => fcmSend(pushSa, t, m) : null);
  const uid = claims.sub;
  const kind = String(body.kind || '');
  const id = String(body.id || '').slice(0, 80);
  const now = deps.now || Date.now();
  let alert = null;
  if (kind === 'request') {
    if (!/^[A-Za-z0-9_-]{4,80}$/.test(id)) return json({ error: 'Missing request.' }, 400, h);
    const r = await db.get(`requests/${id}`);
    if (!r || r.uid !== uid) return json({ error: 'Not your request.' }, 403, h);
    if (r.status !== 'new') return json({ ok: true, skipped: 'not_new' }, 200, h);
    alert = { kind, ref: id, uid, title: `Word request: ${String(r.word || '').slice(0, 60)}`, body: `${r.name || r.email || 'Someone'} asked for “${String(r.word || '').slice(0, 60)}”${r.notes ? ' — ' + String(r.notes).slice(0, 120) : ''}`, route: 'requests' };
  } else if (kind === 'signup') {
    let created = 0; let email = claims.email || ''; let name = claims.name || '';
    const auth = deps.auth !== undefined ? deps.auth : (sa ? authAdmin(sa, e.FIREBASE_PROJECT_ID) : null);
    if (auth) { try { const a = (await auth.lookup([uid]))[0]; if (a) { created = a.createdAt; email = a.email || email; name = a.name || name; } } catch (err) { /* below */ } }
    if (!created && claims.auth_time) created = Number(claims.auth_time) * 1000;
    if (!created || now - created > 30 * 60000) return json({ ok: true, skipped: 'not_new' }, 200, h);
    alert = { kind, ref: uid, uid, title: 'New sign-up', body: `${name || email || uid} just joined NowssB${body.platform ? ' on ' + String(body.platform).slice(0, 20) : ''}.`, route: 'person:' + uid };
  } else if (kind === 'feedback') {
    if (!/^[A-Za-z0-9_-]{4,80}$/.test(id)) return json({ error: 'Missing feedback.' }, 400, h);
    const f = await db.get(`feedback/${id}`);
    if (!f || f.uid !== uid) return json({ error: 'Not yours.' }, 403, h);
    alert = { kind, ref: id, uid, title: 'New feedback', body: String(f.text || '').slice(0, 200), route: 'activity' };
  } else {
    return json({ error: 'Unknown alert.' }, 400, h);
  }
  const out = await raiseAlert({ db, push }, alert);
  return json({ ok: !!out.ok, duplicate: !!out.duplicate }, 200, h);
}

export async function onRequestPost({ request, env }) {
  try { return await handleAlert(request, env); } catch (err) {
    return json({ error: 'Could not raise the alert.' }, 502, cors(request));
  }
}
