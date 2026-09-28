/* POST /api/pay/verify — finish a subscription payment.
   Body { razorpay_order_id, razorpay_payment_id, razorpay_signature } from
   Razorpay Checkout's handler. Needs the buyer's Firebase ID token.
   1. checks the checkout signature (HMAC-SHA256 of order_id|payment_id with
      RAZORPAY_KEY_SECRET),
   2. fetches the payment and order from Razorpay: captured, right amount,
      order made by /api/pay/order for THIS uid,
   3. writes the plan to users/{uid} + payments/{paymentId} + adminLog in one
      Firestore commit. Safe to call twice: the second call answers 'already'. */
import { cors, json, requireUser } from '../../_lib/server.js';
import { checkoutSignatureOk, confirmAndGrant, missingPayEnv } from '../../_lib/razorpay.js';

export async function onRequestOptions({ request }) {
  return new Response(null, { status: 204, headers: cors(request) });
}

export async function onRequestPost({ request, env }) {
  const h = cors(request);
  const missing = missingPayEnv(env);
  if (missing.length) return json({ error: 'Payments are not switched on yet. Missing in Cloudflare Pages settings: ' + missing.join(', ') }, 501, h);
  const claims = await requireUser(request, env, h);
  if (claims instanceof Response) return claims;
  let b;
  try { b = await request.json(); } catch (e) { return json({ error: 'Send JSON.' }, 400, h); }
  const orderId = String(b.razorpay_order_id || '');
  const paymentId = String(b.razorpay_payment_id || '');
  const signature = String(b.razorpay_signature || '');
  if (!/^order_\w+$/.test(orderId) || !/^pay_\w+$/.test(paymentId) || !signature) {
    return json({ error: 'Missing payment details.' }, 400, h);
  }
  if (!(await checkoutSignatureOk(env, orderId, paymentId, signature))) {
    return json({ error: 'The payment signature does not match.' }, 400, h);
  }
  try {
    const r = await confirmAndGrant(env, { paymentId, orderId, expectUid: claims.sub, source: 'verify' });
    return json({ ok: true, ...r }, 200, h);
  } catch (e) {
    if (e.http) return json({ error: e.message }, e.http, h);
    return json({ error: 'Could not confirm the payment yet. It is safe to try again; if you were charged it will be applied.' }, 502, h);
  }
}
