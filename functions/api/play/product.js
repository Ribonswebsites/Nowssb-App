/* POST /api/play/product — confirm a Google Play ONE-TIME product and
   settle it through the economy pipeline (functions/_lib/economy/sales.js).

     Authorization: Bearer <Firebase ID token>
     Body { productId, purchaseToken, checkoutId? }

   purchases.products.get → must be PURCHASED, bound to sha256(uid) when the
   app set it; acknowledged here; the Orders API gives the real price, tax
   and store fee for the money lock. Idempotent by Play order id. The app
   consumes the purchase after a 200. Missing env → 501 naming the vars. */
import { cors, json, requireUser } from '../../_lib/server.js';
import { missingPlayEnv } from '../../_lib/play.js';
import { settleProduct } from '../../_lib/economy/playorders.js';

export async function onRequestOptions({ request }) {
  return new Response(null, { status: 204, headers: cors(request) });
}

export async function onRequestPost({ request, env }) {
  const h = cors(request);
  const missing = missingPlayEnv(env);
  if (missing.length) {
    return json({ error: 'Play purchases are not switched on yet. Missing in Cloudflare Pages settings: ' + missing.join(', '), missing, code: 'not-configured' }, 501, h);
  }
  const claims = await requireUser(request, env, h);
  if (claims instanceof Response) return claims;
  let b;
  try { b = await request.json(); } catch (e) { return json({ error: 'Send JSON.' }, 400, h); }
  const productId = String((b && b.productId) || '');
  const purchaseToken = String((b && b.purchaseToken) || '');
  if (!/^nowssb_[a-z0-9_]{2,60}$/.test(productId)) return json({ error: 'Unknown product.' }, 400, h);
  if (!purchaseToken || purchaseToken.length > 4096) return json({ error: 'Missing purchase token.' }, 400, h);
  try {
    const r = await settleProduct(env, { uid: claims.sub, productId, purchaseToken, checkoutId: String((b && b.checkoutId) || '') });
    return json(r.body, r.status, h);
  } catch (e) {
    if (e.http) return json({ error: e.message }, e.http, h);
    return json({ error: 'Could not confirm the purchase with Google Play yet. It is safe to try again.' }, 502, h);
  }
}
