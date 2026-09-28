/* POST /api/pay/webhook — Razorpay webhook (payment.captured, order.paid).
   Grants the plan even if the buyer closed the page before /api/pay/verify
   ran. Signed with RAZORPAY_WEBHOOK_SECRET (Razorpay Dashboard → Webhooks);
   same idempotent grant as verify, keyed on the payment id. */
import { json } from '../../_lib/server.js';
import { confirmAndGrant, missingPayEnv, webhookSignatureOk } from '../../_lib/razorpay.js';

export async function onRequestPost({ request, env }) {
  const missing = missingPayEnv(env, ['RAZORPAY_WEBHOOK_SECRET']);
  if (missing.length) return json({ error: 'Webhook not configured: ' + missing.join(', ') }, 501);
  const raw = await request.text();
  const sig = request.headers.get('X-Razorpay-Signature') || '';
  if (!(await webhookSignatureOk(env.RAZORPAY_WEBHOOK_SECRET, raw, sig))) return json({ error: 'bad signature' }, 400);
  let evt;
  try { evt = JSON.parse(raw); } catch (e) { return json({ error: 'bad json' }, 400); }
  if (evt.event !== 'payment.captured' && evt.event !== 'order.paid') return json({ ok: true, ignored: evt.event });
  const payment = evt.payload && evt.payload.payment && evt.payload.payment.entity;
  const order = evt.payload && evt.payload.order && evt.payload.order.entity;
  if (!payment || !payment.id) return json({ ok: true, ignored: 'no payment' });
  // Only our subscription orders; anything else (other products) is not ours to grant.
  const notes = (order && order.notes) || payment.notes || {};
  if (notes.app && notes.app !== 'nowssb-subscription') return json({ ok: true, ignored: 'not a subscription' });
  try {
    const r = await confirmAndGrant(env, { paymentId: payment.id, orderId: payment.order_id, source: 'webhook' });
    return json({ ok: true, status: r.status });
  } catch (e) {
    // Not ours / not payable: answer 200 so Razorpay stops retrying. Anything else: 500 so it retries.
    return json({ error: e.message }, e.http ? 200 : 500);
  }
}
