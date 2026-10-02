/* Google Play Billing verification + granting, shared by /api/play/verify
   and /api/play/rtdn. Not a route (no onRequest exports).

   Secrets come ONLY from Cloudflare Pages env bindings and are never logged:
     PLAY_SERVICE_ACCOUNT_JSON  Google Cloud service account linked in Play
                                Console → Users and permissions (androidpublisher)
     FIREBASE_SERVICE_ACCOUNT   Firebase Admin service account (Firestore REST);
                                FCM_SERVICE_ACCOUNT is used if this is absent
     FIREBASE_PROJECT_ID        nowssb-34f1b */
import {
  SCOPE_ANDROIDPUBLISHER, fsBase, fsCommit, fsFields, fsGet, fsQuery, googleToken,
  parseServiceAccount, serviceAccount, sha256Hex,
} from './server.js';

/** applicationId in tools/flutter-android.mjs (and android-config/google-services.json). */
export const PLAY_PACKAGE_NAME = 'com.nowssb.app';

/** Play Console subscription product ids → plan. Keep in sync with
    flutter_app/lib/data/billing_config.dart. */
export const PLAY_PRODUCTS = {
  nowssb_resonance_monthly: { tier: 'resonance', billing: 'monthly' },
  nowssb_resonance_yearly: { tier: 'resonance', billing: 'yearly' },
  nowssb_frequency_monthly: { tier: 'frequency', billing: 'monthly' },
  nowssb_frequency_yearly: { tier: 'frequency', billing: 'yearly' },
  nowssb_frequencyx_monthly: { tier: 'frequencyX', billing: 'monthly' },
  nowssb_frequencyx_yearly: { tier: 'frequencyX', billing: 'yearly' },
};

/** Names of the env bindings that are missing (names only, never values). */
export function missingPlayEnv(env) {
  const missing = [];
  if (!parseServiceAccount(env.PLAY_SERVICE_ACCOUNT_JSON)) missing.push('PLAY_SERVICE_ACCOUNT_JSON');
  if (!serviceAccount(env)) missing.push('FIREBASE_SERVICE_ACCOUNT');
  if (!env.FIREBASE_PROJECT_ID) missing.push('FIREBASE_PROJECT_ID');
  return missing;
}

const ANDROIDPUBLISHER = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/';

async function playToken(env) {
  return googleToken(parseServiceAccount(env.PLAY_SERVICE_ACCOUNT_JSON), SCOPE_ANDROIDPUBLISHER);
}

/** purchases.subscriptionsv2.get */
export async function getSubscriptionV2(env, purchaseToken) {
  const tok = await playToken(env);
  const r = await fetch(ANDROIDPUBLISHER + PLAY_PACKAGE_NAME + '/purchases/subscriptionsv2/tokens/' + encodeURIComponent(purchaseToken), {
    headers: { Authorization: 'Bearer ' + tok },
  });
  if (r.status === 404 || r.status === 410 || r.status === 400) {
    const e = new Error('Google Play does not know that purchase.');
    e.http = 400;
    throw e;
  }
  if (!r.ok) throw new Error('play get ' + r.status);
  return r.json();
}

/** purchases.subscriptions.acknowledge (only needed while PENDING). */
export async function acknowledgeSubscription(env, productId, purchaseToken) {
  const tok = await playToken(env);
  const r = await fetch(ANDROIDPUBLISHER + PLAY_PACKAGE_NAME + '/purchases/subscriptions/' + encodeURIComponent(productId)
    + '/tokens/' + encodeURIComponent(purchaseToken) + ':acknowledge', {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + tok, 'Content-Type': 'application/json' },
    body: '{}',
  });
  return r.ok;
}

/** States that still give access. CANCELED means auto-renew is off but the
    paid period has not ended yet, so access lasts until expiryTime. */
export const ENTITLED_STATES = new Set([
  'SUBSCRIPTION_STATE_ACTIVE',
  'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
  'SUBSCRIPTION_STATE_CANCELED',
]);

/** Picks the NowssB line item and says whether it gives access now. */
export function evaluate(sub, nowMs = Date.now()) {
  const items = Array.isArray(sub && sub.lineItems) ? sub.lineItems : [];
  let best = null;
  for (const li of items) {
    if (!PLAY_PRODUCTS[li.productId]) continue;
    const exp = Date.parse(li.expiryTime || '');
    if (!best || (exp || 0) > (best.expMs || 0)) best = { ...li, expMs: exp || 0 };
  }
  const state = String((sub && sub.subscriptionState) || 'SUBSCRIPTION_STATE_UNSPECIFIED');
  const plan = best ? PLAY_PRODUCTS[best.productId] : null;
  const entitled = !!(best && plan && ENTITLED_STATES.has(state) && best.expMs > nowMs);
  return {
    state,
    entitled,
    pending: state === 'SUBSCRIPTION_STATE_PENDING',
    productId: best ? best.productId : '',
    tier: plan ? plan.tier : null,
    billing: plan ? plan.billing : null,
    expiryTime: best && best.expMs ? new Date(best.expMs).toISOString() : null,
    autoRenew: !!(best && best.autoRenewingPlan && best.autoRenewingPlan.autoRenewEnabled),
    orderId: String((sub && sub.latestOrderId) || ''),
    startTime: (sub && sub.startTime) || null,
    obfuscatedAccountId: (sub && sub.externalAccountIdentifiers && sub.externalAccountIdentifiers.obfuscatedExternalAccountId) || '',
    linkedPurchaseToken: (sub && sub.linkedPurchaseToken) || '',
    needsAck: (sub && sub.acknowledgementState) === 'ACKNOWLEDGEMENT_STATE_PENDING',
    test: !!(sub && sub.testPurchase),
  };
}

const docId = (s) => String(s).replace(/[^A-Za-z0-9_-]/g, '_').slice(0, 1400);
const VRANK = { blue: 1, silver: 2, gold: 3, diamond: 4 };

/**
 * Writes the subscription to users/{uid} (+ payments/{orderId} once and an
 * adminLog entry the first time an order is seen). Idempotent.
 * Returns { status: 'granted'|'already'|'updated', ... }.
 */
export async function applyToUser(env, { uid, ev, tokenHash, source }) {
  const project = env.FIREBASE_PROJECT_ID;
  const fsTok = await googleToken(serviceAccount(env));
  const base = fsBase(project);
  const user = (await fsGet(fsTok, project, 'users/' + encodeURIComponent(uid))) || {};
  const payRef = ev.orderId ? 'payments/' + docId(ev.orderId) : '';
  const existing = payRef ? await fsGet(fsTok, project, payRef) : null;
  if (existing && existing.uid && existing.uid !== uid) {
    const e = new Error('That purchase belongs to another account.');
    e.http = 403;
    throw e;
  }
  const userFields = ev.entitled
    ? {
      isPro: true,
      tier: ev.tier,
      subscriptionBilling: ev.billing,
      subscriptionEndDate: ev.expiryTime,
      subscriptionSource: 'play',
      subscriptionProductId: ev.productId,
      subscriptionTokenHash: tokenHash,
      subscriptionOrderId: ev.orderId,
      subscriptionState: ev.state,
      subscriptionAutoRenew: ev.autoRenew,
    }
    : {
      // Only the Play subscription is switched off; an admin grant is left alone.
      ...(user.subscriptionSource === 'play' ? { isPro: false, tier: null } : {}),
      subscriptionEndDate: ev.expiryTime,
      subscriptionState: ev.state,
      subscriptionAutoRenew: ev.autoRenew,
      subscriptionTokenHash: tokenHash,
    };
  if (ev.entitled && !user.subscriptionStartDate) userFields.subscriptionStartDate = ev.startTime || new Date().toISOString();
  // Frequency X includes the Blue verification badge; never lower a higher one.
  if (ev.entitled && ev.tier === 'frequencyX' && (VRANK[user.verifyTier] || 0) < VRANK.blue) userFields.verifyTier = 'blue';

  const writes = [];
  const firstTime = ev.entitled && payRef && !existing;
  if (firstTime) {
    writes.push({
      update: {
        name: `${base}/${payRef}`,
        fields: fsFields({
          uid, tier: ev.tier, billing: ev.billing, productId: ev.productId, orderId: ev.orderId,
          tokenHash, state: ev.state, expiryTime: ev.expiryTime, source: 'play', via: source || 'verify',
          test: ev.test, status: 'granted',
        }),
      },
      currentDocument: { exists: false },
      updateTransforms: [{ fieldPath: 'at', setToServerValue: 'REQUEST_TIME' }],
    });
  }
  writes.push({
    update: { name: `${base}/users/${uid}`, fields: fsFields(userFields) },
    updateMask: { fieldPaths: Object.keys(userFields) },
    updateTransforms: [{ fieldPath: 'subscriptionUpdatedAt', setToServerValue: 'REQUEST_TIME' }],
  });
  if (firstTime || !ev.entitled) {
    const logId = (firstTime ? 'play_' + docId(ev.orderId) : 'play_' + tokenHash.slice(0, 24) + '_' + Date.now());
    writes.push({
      update: {
        name: `${base}/adminLog/${logId}`,
        fields: fsFields({
          action: ev.entitled ? 'payment.subscription' : 'subscription.ended', target: uid, uid: 'server', email: 'google-play',
          detail: { tier: ev.tier, billing: ev.billing, productId: ev.productId, orderId: ev.orderId, state: ev.state, source: source || 'verify' },
        }),
      },
      updateTransforms: [{ fieldPath: 'at', setToServerValue: 'REQUEST_TIME' }],
    });
  }
  const commit = await fsCommit(fsTok, project, writes);
  if (!commit.ok) {
    // Lost a race (double tap, or the RTDN arrived at the same moment): the
    // payment doc exists now — write the user fields alone.
    if (firstTime) {
      const again = await fsGet(fsTok, project, payRef);
      if (again && again.uid === uid) {
        const retry = await fsCommit(fsTok, project, writes.slice(1, 2));
        if (retry.ok) return { status: 'already', ...summary(ev) };
      }
    }
    throw new Error('firestore commit ' + commit.status);
  }
  let economy = null;
  if (firstTime && env.ECONOMY_HOOKS !== 'off') {
    // A cleared subscription order (first or renewal) feeds the economy:
    // buyer coins / scratch card, the link holder's commission through the
    // money lock, Partner points. Never blocks the plan grant.
    try {
      const { settleSubscriptionOrder } = await import('./economy/playorders.js');
      const r = await settleSubscriptionOrder(env, { uid, ev });
      economy = r ? { ok: true, ownerCredited: !!r.ownerCredited } : null;
    } catch (e) {
      economy = { ok: false };
    }
  }
  return { status: firstTime ? 'granted' : ev.entitled ? 'already' : 'updated', ...summary(ev), ...(economy ? { economy } : {}) };
}

function summary(ev) {
  return {
    entitled: ev.entitled, tier: ev.tier, billing: ev.billing, productId: ev.productId,
    subscriptionEndDate: ev.expiryTime, state: ev.state, autoRenew: ev.autoRenew,
  };
}

/** users whose stored subscriptionTokenHash is one of these hashes. */
export async function usersForTokenHashes(env, hashes) {
  const project = env.FIREBASE_PROJECT_ID;
  const fsTok = await googleToken(serviceAccount(env));
  const out = [];
  for (const h of hashes.filter(Boolean)) {
    const rows = await fsQuery(fsTok, project, 'users', {
      fieldFilter: { field: { fieldPath: 'subscriptionTokenHash' }, op: 'EQUAL', value: { stringValue: h } },
    }, 3);
    for (const r of rows) {
      const uid = r.name.split('/').pop();
      if (!out.includes(uid)) out.push(uid);
    }
  }
  return out;
}

export { sha256Hex };
