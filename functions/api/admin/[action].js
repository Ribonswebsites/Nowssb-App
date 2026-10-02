/* POST /api/admin/<action> — the NowssB admin console's server.

   Called by the Flutter admin area (lib/admin/admin_api.dart) with
     Authorization: Bearer <Firebase ID token>, JSON body.
   Only admins (Firestore admins/{uid} or the admin custom claim) get past
   the gate; every change writes adminLog + activity. Logic lives in
   functions/_lib/admin_core.js; gate in functions/_lib/admin_route.js.

   Actions: whoami, stats, users, user, grant-sub, extend-sub, revoke-sub,
   adjust-coins, block, restrict, reset-streak, message, helper,
   fulfil-request, broadcast, payout-decide, gift-codes, gift-void, earn,
   network, feed, ui-assets.

   Cloudflare Pages → Settings → Variables and secrets (Production):
     FIREBASE_SERVICE_ACCOUNT  Firebase Admin service-account JSON (required)
     FCM_SERVICE_ACCOUNT       service-account JSON for push (falls back to the one above)
     R2_ACCOUNT_ID, R2_BUCKET, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY,
     R2_PUBLIC_BASE_URL        for the UI Editor's SVG library (ui/ listing)
   GET answers which of those are missing (names only, never values). */
import { cors, json } from '../../_lib/server.js';
import { ACTIONS } from '../../_lib/admin_core.js';
import { adminConfig, handleAdmin } from '../../_lib/admin_route.js';

export async function onRequestOptions({ request }) {
  return new Response(null, { status: 204, headers: cors(request) });
}

export async function onRequestGet({ request, env, params }) {
  const cfg = adminConfig(env || {});
  return json({ ok: true, service: 'admin', action: params.action, configured: cfg.firestore, push: cfg.push, r2: cfg.r2, missing: cfg.missing, actions: ['whoami', ...Object.keys(ACTIONS)] }, 200, cors(request));
}

export async function onRequestPost(context) {
  return handleAdmin(context);
}
