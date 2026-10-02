/* Request handling for /api/admin/<action>. The route file only re-exports
   this, so the offline tests can inject a store, auth and push.

   Gate, in order: the service account is configured (else 501 naming the
   missing variables), a valid Firebase ID token, and that uid is an admin
   (custom claim admin:true, or a document at admins/{uid}). */
import { cors, googleToken, json, parseServiceAccount, requireUser, serviceAccount } from './server.js';
import { restStore } from './admin_store.js';
import { R2_VARS, authAdmin, fcmSend, r2List } from './admin_google.js';
import { ACTIONS, AdminError } from './admin_core.js';

export const DEFAULT_PROJECT = 'nowssb-34f1b';

/** Names (never values) of what each part of the console needs. */
export function adminConfig(env = {}) {
  const fs = !!serviceAccount(env);
  const fcm = !!(parseServiceAccount(env.FCM_SERVICE_ACCOUNT) || parseServiceAccount(env.FIREBASE_SERVICE_ACCOUNT));
  const r2Missing = R2_VARS.filter((k) => !env[k]);
  const missing = [];
  if (!parseServiceAccount(env.FIREBASE_SERVICE_ACCOUNT)) missing.push('FIREBASE_SERVICE_ACCOUNT');
  if (!parseServiceAccount(env.FCM_SERVICE_ACCOUNT)) missing.push('FCM_SERVICE_ACCOUNT');
  if (!parseServiceAccount(env.PLAY_SERVICE_ACCOUNT_JSON)) missing.push('PLAY_SERVICE_ACCOUNT_JSON');
  missing.push(...r2Missing);
  return { firestore: fs, push: fcm, r2: !r2Missing.length, r2Missing, missing };
}

export async function handleAdmin({ request, env, params }, deps = {}) {
  const h = cors(request);
  const action = String((params && params.action) || '');
  if (!Object.prototype.hasOwnProperty.call(ACTIONS, action) && action !== 'whoami') {
    return json({ error: 'Unknown admin action.', code: 'unknown_action' }, 404, h);
  }
  const e = { ...(env || {}), FIREBASE_PROJECT_ID: (env && env.FIREBASE_PROJECT_ID) || DEFAULT_PROJECT };
  const cfg = adminConfig(e);
  if (!deps.db && !cfg.firestore) {
    return json({
      error: 'The admin server is not switched on yet. Add FIREBASE_SERVICE_ACCOUNT in Cloudflare Pages → Settings → Variables and secrets (Production).',
      code: 'not_configured', missing: ['FIREBASE_SERVICE_ACCOUNT'], config: cfg,
    }, 501, h);
  }
  const claims = deps.claims || await requireUser(request, e, h);
  if (claims instanceof Response) return claims;
  let db;
  try {
    db = deps.db || restStore(await googleToken(serviceAccount(e)), e.FIREBASE_PROJECT_ID);
  } catch (err) {
    return json({ error: 'Could not reach Firestore with the service account.', code: 'server' }, 502, h);
  }
  let isAdmin = claims.admin === true;
  if (!isAdmin) {
    try { isAdmin = !!(await db.get(`admins/${claims.sub}`)); } catch (err) { isAdmin = false; }
  }
  if (!isAdmin) return json({ error: 'Not an admin.', code: 'forbidden' }, 403, h);

  let body = {};
  try {
    const text = await request.text();
    body = text ? JSON.parse(text) : {};
    if (!body || typeof body !== 'object' || Array.isArray(body)) body = {};
  } catch (err) {
    return json({ error: 'Send JSON.' }, 400, h);
  }
  if (action === 'whoami') return json({ ok: true, uid: claims.sub, email: claims.email || '', config: cfg }, 200, h);

  const sa = serviceAccount(e);
  const pushSa = parseServiceAccount(e.FCM_SERVICE_ACCOUNT) || parseServiceAccount(e.FIREBASE_SERVICE_ACCOUNT);
  const full = {
    db,
    auth: deps.auth !== undefined ? deps.auth : (sa ? authAdmin(sa, e.FIREBASE_PROJECT_ID) : null),
    push: deps.push !== undefined ? deps.push : (pushSa ? (token, msg) => fcmSend(pushSa, token, msg) : null),
    r2: deps.r2 !== undefined ? deps.r2 : (cfg.r2 ? (prefix) => r2List(e, prefix) : null),
    r2Missing: cfg.r2Missing,
    admin: { uid: claims.sub, email: claims.email || '' },
    now: deps.now || Date.now(),
  };
  try {
    const out = await ACTIONS[action](full, body);
    return json({ ...out, config: action === 'stats' ? cfg : undefined }, 200, h);
  } catch (err) {
    if (err instanceof AdminError) return json({ error: err.message, code: err.code, ...err.extra }, err.status, h);
    console.log('admin ' + action + ' failed: ' + String((err && err.message) || err).slice(0, 200));
    return json({ error: 'That did not go through: ' + String((err && err.message) || 'server error').slice(0, 160), code: 'server' }, 502, h);
  }
}
