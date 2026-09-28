/* POST /api/play/rtdn — Google Play Real-time Developer Notifications.

   Play Console → Monetization setup → Real-time developer notifications
   publishes to a Pub/Sub topic; a PUSH subscription on that topic posts here:
     https://nowssb.com/api/play/rtdn
   with "Enable authentication" on, using the SAME service account as
   PLAY_SERVICE_ACCOUNT_JSON and the audience left as this URL (the default).

   Every request must carry that Google-signed OIDC token (checked against
   Google's certs: audience = this URL, email = the Play service account).
   The message only says "something changed for this purchase token"; the
   subscription itself is re-read from the Google Play Developer API and the
   user is found by users.subscriptionTokenHash (sha256 of the token, written
   by /api/play/verify; an upgrade's linkedPurchaseToken is followed too).
   Renewals add a payments/{orderId} receipt; expiry / hold / pause / revoke
   switch the Play plan off (isPro false, tier null).

   Answers 2xx for anything handled or ignorable so Pub/Sub stops retrying,
   401 for a bad token, 501 when env vars are missing, 5xx to retry later. */
import { json, parseServiceAccount, verifyGoogleOidc } from '../../_lib/server.js';
import {
  PLAY_PACKAGE_NAME, applyToUser, evaluate, getSubscriptionV2, missingPlayEnv, sha256Hex, usersForTokenHashes,
} from '../../_lib/play.js';

export async function onRequestPost({ request, env }) {
  const missing = missingPlayEnv(env);
  if (missing.length) return json({ error: 'Missing in Cloudflare Pages settings: ' + missing.join(', '), missing }, 501);

  const auth = request.headers.get('Authorization') || '';
  const url = new URL(request.url);
  const audience = url.origin + url.pathname;
  let claims = null;
  try { claims = auth.startsWith('Bearer ') ? await verifyGoogleOidc(auth.slice(7), audience) : null; } catch (e) {
    return json({ error: 'Could not check the token.' }, 503);
  }
  const playSa = parseServiceAccount(env.PLAY_SERVICE_ACCOUNT_JSON);
  if (!claims || claims.email !== playSa.client_email || claims.email_verified === false) {
    return json({ error: 'Not a trusted Pub/Sub push.' }, 401);
  }

  let msg;
  try {
    const body = await request.json();
    const data = body && body.message && body.message.data;
    msg = JSON.parse(atob(String(data || '')));
  } catch (e) {
    return json({ ok: true, ignored: 'unreadable message' }, 200);
  }
  if (msg.testNotification) return json({ ok: true, test: true }, 200);
  if (msg.packageName !== PLAY_PACKAGE_NAME) return json({ ok: true, ignored: 'other package' }, 200);
  const n = msg.subscriptionNotification;
  if (!n || !n.purchaseToken) return json({ ok: true, ignored: 'not a subscription notification' }, 200);

  try {
    let sub;
    try { sub = await getSubscriptionV2(env, n.purchaseToken); } catch (e) {
      if (e.http) return json({ ok: true, ignored: 'unknown purchase' }, 200);
      throw e;
    }
    const ev = evaluate(sub);
    if (!ev.productId) return json({ ok: true, ignored: 'not a NowssB product' }, 200);
    if (ev.pending) return json({ ok: true, pending: true }, 200);
    const tokenHash = await sha256Hex(n.purchaseToken);
    const linkedHash = ev.linkedPurchaseToken ? await sha256Hex(ev.linkedPurchaseToken) : '';
    const uids = await usersForTokenHashes(env, [tokenHash, linkedHash]);
    if (!uids.length) {
      // The app has not called /api/play/verify for this token yet; it will,
      // and that call grants it. Nothing to do here.
      return json({ ok: true, ignored: 'no account for this purchase yet' }, 200);
    }
    const results = [];
    for (const uid of uids.slice(0, 3)) {
      if (ev.obfuscatedAccountId && ev.obfuscatedAccountId !== (await sha256Hex(uid))) continue;
      try {
        results.push((await applyToUser(env, { uid, ev, tokenHash, source: 'rtdn:' + n.notificationType })).status);
      } catch (e) {
        if (!e.http) throw e;
        results.push('skipped');
      }
    }
    return json({ ok: true, type: n.notificationType, results }, 200);
  } catch (e) {
    return json({ error: 'Try again later.' }, 503);
  }
}
