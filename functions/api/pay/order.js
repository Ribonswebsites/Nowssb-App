/* POST /api/pay/order — start a subscription payment.
   Body { plan: 'resonance'|'frequency'|'frequencyX', billing: 'monthly'|'yearly' }
   Needs a Firebase ID token. The amount comes from the server's own price
   list, and the order carries the buyer's uid so /api/pay/verify and the
   webhook know whom to upgrade. Returns { orderId, amount, currency, keyId }. */
import { cors, json, requireUser } from '../../_lib/server.js';
import { CURRENCY, PLANS, missingPayEnv, rzp } from '../../_lib/razorpay.js';

export async function onRequestOptions({ request }) {
  return new Response(null, { status: 204, headers: cors(request) });
}

export async function onRequestPost({ request, env }) {
  const h = cors(request);
  const missing = missingPayEnv(env);
  if (missing.length) return json({ error: 'Payments are not switched on yet. Missing in Cloudflare Pages settings: ' + missing.join(', ') }, 501, h);
  const claims = await requireUser(request, env, h);
  if (claims instanceof Response) return claims;
  let body;
  try { body = await request.json(); } catch (e) { return json({ error: 'Send JSON.' }, 400, h); }
  const plan = PLANS[body.plan];
  const billing = body.billing === 'yearly' ? 'yearly' : 'monthly';
  if (!plan) return json({ error: 'Unknown plan.' }, 400, h);
  try {
    const order = await rzp(env, 'POST', '/orders', {
      amount: plan[billing],
      currency: CURRENCY,
      receipt: ('sub_' + claims.sub.slice(0, 12) + '_' + Date.now()).slice(0, 40),
      notes: { app: 'nowssb-subscription', uid: claims.sub, plan: body.plan, billing, email: claims.email || '' },
    });
    return json({
      orderId: order.id, amount: order.amount, currency: order.currency, keyId: env.RAZORPAY_KEY_ID,
      plan: body.plan, billing, name: plan.name,
    }, 200, h);
  } catch (e) {
    return json({ error: 'Could not start the payment. Try again in a minute.' }, 502, h);
  }
}
