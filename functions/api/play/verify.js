/* POST /api/play/verify — confirm a Google Play subscription and unlock it.

   Called by the Android app (flutter_app/lib/data/play_subscriptions.dart)
   after Play reports a purchase or a restore.
     Authorization: Bearer <Firebase ID token>
     Body { productId, purchaseToken }

   1. Verifies the Firebase ID token (Google securetoken keys, project
      FIREBASE_PROJECT_ID).
   2. Asks the Google Play Developer API (purchases.subscriptionsv2.get,
      package com.nowssb.app) with PLAY_SERVICE_ACCOUNT_JSON.
   3. Requires a NowssB product, state ACTIVE / IN_GRACE_PERIOD (or CANCELED
      with paid time left) and — when the app set it — an
      obfuscatedExternalAccountId equal to sha256(uid).
   4. Acknowledges the purchase if Play still has it pending.
   5. Writes users/{uid} subscription fields + payments/{orderId} (create
      once) + adminLog through Firestore REST with FIREBASE_SERVICE_ACCOUNT.
   Missing env → 501 naming the missing variables (names only). */
import { cors, json, requireUser } from '../../_lib/server.js';
import {
  PLAY_PRODUCTS, acknowledgeSubscription, applyToUser, evaluate, getSubscriptionV2, missingPlayEnv, sha256Hex,
} from '../../_lib/play.js';

export async function onRequestOptions({ request }) {
  return new Response(null, { status: 204, headers: cors(request) });
}

export async function onRequestPost({ request, env }) {
  const h = cors(request);
  const missing = missingPlayEnv(env);
  if (missing.length) {
    return json({ error: 'Play purchases are not switched on yet. Missing in Cloudflare Pages settings: ' + missing.join(', '), missing }, 501, h);
  }
  const claims = await requireUser(request, env, h);
  if (claims instanceof Response) return claims;
  const uid = claims.sub;

  let b;
  try { b = await request.json(); } catch (e) { return json({ error: 'Send JSON.' }, 400, h); }
  const productId = String((b && b.productId) || '');
  const purchaseToken = String((b && b.purchaseToken) || '');
  if (!PLAY_PRODUCTS[productId]) return json({ error: 'Unknown product.' }, 400, h);
  if (!purchaseToken || purchaseToken.length > 4096) return json({ error: 'Missing purchase token.' }, 400, h);

  try {
    const sub = await getSubscriptionV2(env, purchaseToken);
    const ev = evaluate(sub);
    if (!ev.productId) return json({ error: 'That purchase is not a NowssB subscription.' }, 400, h);
    if (ev.obfuscatedAccountId && ev.obfuscatedAccountId !== (await sha256Hex(uid))) {
      return json({ error: 'That purchase belongs to another account.' }, 403, h);
    }
    if (ev.pending) {
      return json({ ok: false, pending: true, state: ev.state, error: 'The payment is still pending with Google Play.' }, 202, h);
    }
    const tokenHash = await sha256Hex(purchaseToken);
    if (!ev.entitled) {
      const r = await applyToUser(env, { uid, ev, tokenHash, source: 'verify' });
      return json({ ok: false, ...r, error: 'That subscription is not active (' + ev.state.replace('SUBSCRIPTION_STATE_', '').toLowerCase() + ').' }, 402, h);
    }
    if (ev.needsAck) await acknowledgeSubscription(env, ev.productId, purchaseToken);
    const r = await applyToUser(env, { uid, ev, tokenHash, source: 'verify' });
    return json({ ok: true, ...r }, 200, h);
  } catch (e) {
    if (e.http) return json({ error: e.message }, e.http, h);
    return json({ error: 'Could not confirm the purchase with Google Play yet. It is safe to try again.' }, 502, h);
  }
}
