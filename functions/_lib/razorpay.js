/* Razorpay + subscription granting, shared by /api/pay/order, /api/pay/verify
   and /api/pay/webhook. Not a route. */
import { fsBase, fsCommit, fsFields, fsGet, googleToken, hmacHex, safeEqual, serviceAccount } from './server.js';

/* Prices the SERVER charges, in USD cents — the same numbers the website
   shows (app/js/part032.js SS_PLANS). The browser never sends an amount. */
export const PLANS = {
  resonance: { name: 'Resonance', monthly: 499, yearly: 4999 },
  frequency: { name: 'Frequency', monthly: 999, yearly: 9999 },
  frequencyX: { name: 'Frequency X', monthly: 1999, yearly: 19999 },
};
export const CURRENCY = 'USD';

export function missingPayEnv(env, extra = []) {
  return ['RAZORPAY_KEY_ID', 'RAZORPAY_KEY_SECRET', 'FIREBASE_PROJECT_ID', ...extra].filter((k) => !env[k])
    .concat(serviceAccount(env) ? [] : ['FIREBASE_SERVICE_ACCOUNT']);
}

export async function rzp(env, method, path, body) {
  const r = await fetch('https://api.razorpay.com/v1' + path, {
    method,
    headers: {
      Authorization: 'Basic ' + btoa(env.RAZORPAY_KEY_ID + ':' + env.RAZORPAY_KEY_SECRET),
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const d = await r.json().catch(() => ({}));
  if (!r.ok) {
    const e = new Error('razorpay ' + r.status + ': ' + (d.error && d.error.description || ''));
    e.status = r.status;
    throw e;
  }
  return d;
}

/** Checkout signature: HMAC_SHA256(order_id + "|" + payment_id, key_secret). */
export async function checkoutSignatureOk(env, orderId, paymentId, signature) {
  return safeEqual(await hmacHex(env.RAZORPAY_KEY_SECRET, orderId + '|' + paymentId), signature);
}

/** Webhook signature: HMAC_SHA256(raw body, webhook secret). */
export async function webhookSignatureOk(secret, rawBody, signature) {
  return safeEqual(await hmacHex(secret, rawBody), signature);
}

const addPeriod = (from, billing) => {
  const d = new Date(from.getTime());
  if (billing === 'yearly') d.setUTCFullYear(d.getUTCFullYear() + 1);
  else d.setUTCMonth(d.getUTCMonth() + 1);
  return d;
};
const docId = (s) => String(s).replace(/[^A-Za-z0-9_-]/g, '_');

/**
 * Confirms a payment with Razorpay and grants the plan, once per payment id.
 *   paymentId — Razorpay payment id
 *   expectUid — when given (the verify endpoint), the order must belong to it
 * Returns { status: 'granted'|'already', uid, tier, billing, subscriptionEndDate, paymentId }
 * Throws Error with .http for client-visible failures.
 */
export async function confirmAndGrant(env, { paymentId, orderId, expectUid, source }) {
  const fail = (http, msg) => { const e = new Error(msg); e.http = http; return e; };
  const payment = await rzp(env, 'GET', '/payments/' + encodeURIComponent(paymentId));
  if (orderId && payment.order_id !== orderId) throw fail(400, 'That payment is not for this order.');
  orderId = payment.order_id;
  if (!orderId) throw fail(400, 'That payment has no order.');
  const order = await rzp(env, 'GET', '/orders/' + encodeURIComponent(orderId));
  const notes = order.notes || {};
  const uid = notes.uid;
  const tier = notes.plan;
  const billing = notes.billing === 'yearly' ? 'yearly' : 'monthly';
  const plan = PLANS[tier];
  if (!uid || !plan || notes.app !== 'nowssb-subscription') throw fail(400, 'That order was not created by NowssB.');
  if (expectUid && uid !== expectUid) throw fail(403, 'That payment belongs to another account.');
  const price = plan[billing];
  if (order.amount !== price || order.currency !== CURRENCY) throw fail(400, 'The order amount does not match the plan.');
  if (payment.amount !== order.amount || payment.currency !== order.currency) throw fail(400, 'The payment amount does not match the order.');

  let p = payment;
  if (p.status === 'authorized') {
    // Account set to manual capture: capture it now, for exactly the order amount.
    p = await rzp(env, 'POST', '/payments/' + encodeURIComponent(paymentId) + '/capture', { amount: order.amount, currency: order.currency });
  }
  if (p.status !== 'captured') throw fail(402, 'The payment is not complete (' + p.status + ').');

  const sa = serviceAccount(env);
  const project = env.FIREBASE_PROJECT_ID;
  const token = await googleToken(sa);
  const payRef = 'payments/' + docId(paymentId);
  const existing = await fsGet(token, project, payRef);
  if (existing) return { status: 'already', ...existing.result, paymentId };

  const user = (await fsGet(token, project, 'users/' + encodeURIComponent(uid))) || {};
  const now = new Date();
  // Renewing the same plan early adds on to the time left; anything else starts today.
  const curEnd = user.subscriptionEndDate ? new Date(user.subscriptionEndDate) : null;
  const base = curEnd && !isNaN(curEnd) && curEnd > now && user.tier === tier ? curEnd : now;
  const end = addPeriod(base, billing);
  const result = { uid, tier, billing, subscriptionEndDate: end.toISOString() };
  const userFields = {
    isPro: true,
    tier,
    subscriptionBilling: billing,
    subscriptionStartDate: now.toISOString(),
    subscriptionEndDate: end.toISOString(),
    subscriptionPaymentId: paymentId,
    subscriptionOrderId: orderId,
    subscriptionSource: 'razorpay',
    subscriptionAmount: order.amount,
    subscriptionCurrency: order.currency,
  };
  // Frequency X includes the Blue verification badge; never lower a higher one.
  const VRANK = { blue: 1, silver: 2, gold: 3, diamond: 4 };
  if (tier === 'frequencyX' && (VRANK[user.verifyTier] || 0) < VRANK.blue) userFields.verifyTier = 'blue';
  const base_ = fsBase(project);
  const logId = 'pay_' + docId(paymentId);
  const commit = await fsCommit(token, project, [
    {
      update: {
        name: `${base_}/${payRef}`,
        fields: fsFields({
          uid, tier, billing, amount: order.amount, currency: order.currency, orderId, paymentId,
          method: p.method || '', email: p.email || notes.email || '', source: source || 'verify',
          status: 'granted', result,
        }),
      },
      currentDocument: { exists: false },
      updateTransforms: [{ fieldPath: 'at', setToServerValue: 'REQUEST_TIME' }],
    },
    {
      update: { name: `${base_}/users/${uid}`, fields: fsFields(userFields) },
      updateMask: { fieldPaths: Object.keys(userFields) },
      updateTransforms: [{ fieldPath: 'subscriptionUpdatedAt', setToServerValue: 'REQUEST_TIME' }],
    },
    {
      update: {
        name: `${base_}/adminLog/${logId}`,
        fields: fsFields({
          action: 'payment.subscription', target: uid, uid: 'server', email: 'razorpay',
          detail: { tier, billing, amount: order.amount, currency: order.currency, paymentId, orderId, source: source || 'verify' },
        }),
      },
      updateTransforms: [{ fieldPath: 'at', setToServerValue: 'REQUEST_TIME' }],
    },
  ]);
  if (!commit.ok) {
    // Lost a race with the webhook (or a double tap): the payment doc exists now.
    const again = await fsGet(token, project, payRef);
    if (again) return { status: 'already', ...again.result, paymentId };
    throw new Error('firestore commit ' + commit.status + ' ' + (commit.error && commit.error.message || ''));
  }
  return { status: 'granted', ...result, paymentId };
}
