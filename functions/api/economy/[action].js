/* POST /api/economy/<action> — the NowssB economy (Earn, Rewards, Coupons,
   Gifts, Reference, Partner Program). Cloudflare Pages Function; Firebase
   stays on the free Spark plan (no Cloud Functions).

     Authorization: Bearer <Firebase ID token>   (every action but `config`)
     Body: JSON payload for the action

   The server owns every balance: coins (append-only coinLedger), cash
   (commissionLedger), streaks, quests, draws (server RNG, published odds),
   gift codes, links and attribution. Firestore rules make all of it
   read-only for clients. Settings: Firestore config/economy merged over
   functions/_lib/economy/config.js.

   Missing env → 501 { error, missing, switchingOn: true } (names only). */
import { cors, json, requireUser, serviceAccount } from '../../_lib/server.js';
import { FsDb } from '../../_lib/economy/fsdb.js';
import { DEFAULT_ECONOMY, loadEconomy } from '../../_lib/economy/config.js';
import { EconomyError } from '../../_lib/economy/core.js';
import * as rw from '../../_lib/economy/rewards.js';
import * as cp from '../../_lib/economy/coupons.js';
import * as gf from '../../_lib/economy/gifts.js';
import * as rf from '../../_lib/economy/reference.js';
import * as er from '../../_lib/economy/earn.js';
import * as ck from '../../_lib/economy/checkout.js';
import * as so from '../../_lib/economy/social.js';
import * as ad from '../../_lib/economy/admin.js';
import { economySummary, publicConfig } from '../../_lib/economy/summary.js';
import { settleProduct } from '../../_lib/economy/playorders.js';
import { missingPlayEnv } from '../../_lib/play.js';
import { notificationOutbox } from '../../_lib/notify/push.js';

const paused = (what) => async () => { throw new EconomyError(`${what} is paused under the Play policy. Nothing was charged.`, 400, 'failed-precondition'); };

/** action → handler(ctx, uid, data, claims). Legacy callable names kept so older builds work. */
export const ACTIONS = {
  summary: (c, u) => economySummary(c, u),
  ensureEconomyProfile: async (c, u, d) => { await rf.registerDevice(c, u, d); return economySummary(c, u); },
  registerDevice: rf.registerDevice,
  // Rewards
  claimDailyLogin: rw.claimDailyLogin,
  reportAction: rw.reportAction,
  reportPractice: rw.reportPractice,
  heartbeat: rw.heartbeat,
  claimTimeStep: rw.claimTimeStep,
  openDailyBox: rw.openDailyBox,
  openBox: rw.openBox,
  claimQuest: rw.claimQuest,
  claimWeeklyChest: rw.claimWeeklyChest,
  claimWeeklyGift: rw.claimWeeklyGift,
  claimMonthlyGift: rw.claimMonthlyGift,
  claimMonthlyMark: rw.claimMonthlyMark,
  reportMastery: rw.reportMastery,
  claimMilestone: rw.reportMastery,
  claimSeason: rw.claimSeason,
  league: (c, u, d) => rw.leagueView(c, u, d && d.name),
  claimLeague: rw.claimLeague,
  spendCoins: rw.spendCoins,
  restoreStreak: rw.restoreStreak,
  // Coupons
  dailyScratch: cp.dailyScratch,
  revealScratch: cp.revealScratch,
  scratchCoupon: cp.scratchCoupon,
  buyScratchWithCoins: cp.buyScratchWithCoins,
  claimTicket: cp.claimTicket,
  spin: cp.spin,
  // Gifts
  redeemGift: gf.redeemGift,
  peekGift: gf.peekGift,
  cancelGift: gf.cancelGift,
  issueGift: async () => { throw new EconomyError('To send a gift, buy a gift card in Gifts · Send a Gift. Free gifts stay with the person who earned them.', 400, 'failed-precondition'); },
  // Reference
  getLink: rf.getLink,
  linkHub: rf.linkHub,
  attachReferral: rf.attachReferral,
  applyReferralCode: rf.attachReferral,
  claimSharerStep: rf.claimSharerStep,
  // Earn + Partner
  earnSummary: er.earnSummary,
  appoint: er.appoint,
  answerAppointment: er.answerAppointment,
  savePayoutAccount: er.savePayoutAccount,
  requestPayout: er.requestPayout,
  partnerSummary: er.partnerSummary,
  claimPartnerLevel: er.claimPartnerLevel,
  logPartnerAction: async () => { throw new EconomyError('Partner points come only from real purchases through your links. They appear on their own.', 400, 'failed-precondition'); },
  // Checkout (Play one-time products)
  quote: ck.quote,
  beginCheckout: ck.beginCheckout,
  cancelCheckout: ck.cancelCheckout,
  verifyPlayPurchase: async (c, u, d) => {
    const missing = missingPlayEnv(c.env);
    if (missing.length) throw new EconomyError('Play purchases are not switched on yet. Nothing was charged to your coins.', 501, 'not-configured', { missing });
    const r = await settleProduct(c.env, { uid: u, productId: String(d.productId || ''), purchaseToken: String(d.purchaseToken || ''), checkoutId: d.checkoutId || '' });
    if (r.status >= 400) throw new EconomyError(r.body.error || 'Purchase not confirmed.', r.status, 'failed-precondition');
    return r.body;
  },
  // Community
  createEchoPost: so.createEchoPost,
  commentOnPost: so.commentOnPost,
  toggleEchoLike: so.toggleEchoLike,
  reportEcho: so.reportEcho,
  blockEchoUser: so.blockEchoUser,
  setFollow: so.setFollow,
  updateWordPrint: so.updateWordPrint,
  // Resale is not part of the plan's programs (Play policy): paused.
  createListing: paused('Resale'),
  setFlashSale: paused('Resale'),
  reviewResale: paused('Resale'),
};
const ADMIN = {
  reviewEchoReport: so.reviewEchoReport,
  adminPayout: ad.adminPayout,
  adminMonthlyPool: ad.adminMonthlyPool,
  adminReverse: ad.adminReverse,
};

/* Admin console gates: users/{uid}.blocked / .restrictions[area] and the
   program switches in config/economy (same areas as lib/data/app_control.dart). */
const AREA = {
  requestPayout: 'payouts', savePayoutAccount: 'payouts',
  redeemGift: 'gifting', cancelGift: 'gifting', peekGift: 'gifting',
  attachReferral: 'referrals', applyReferralCode: 'referrals', claimSharerStep: 'referrals', getLink: 'referrals',
  claimDailyLogin: 'earning', claimQuest: 'earning', claimMilestone: 'earning', reportMastery: 'earning', scratchCoupon: 'earning', reportPractice: 'earning',
  reportAction: 'earning', heartbeat: 'earning', claimTimeStep: 'earning', openDailyBox: 'earning', openBox: 'earning', claimWeeklyChest: 'earning',
  claimWeeklyGift: 'earning', claimMonthlyGift: 'earning', claimMonthlyMark: 'earning', claimSeason: 'earning', claimLeague: 'earning',
  dailyScratch: 'earning', revealScratch: 'earning', claimTicket: 'earning', spin: 'earning', claimPartnerLevel: 'earning',
  createEchoPost: 'community', commentOnPost: 'community', toggleEchoLike: 'community',
};
const COUPON_ACTIONS = new Set(['dailyScratch', 'revealScratch', 'scratchCoupon', 'buyScratchWithCoins', 'claimTicket']);
/** Own property of a plain map, or undefined (never an inherited member). */
function own(map, key) {
  return Object.hasOwn(map, key) ? map[key] : undefined;
}

/** Only a plain-object result is spread into a response, and never one
 *  that is (or carries) the request context, the db or the env. */
function safeOut(out, ctx) {
  if (out == null) return {};
  if (typeof out !== 'object' || Array.isArray(out)) return {};
  const proto = Object.getPrototypeOf(out);
  if (proto !== Object.prototype && proto !== null) return {};
  if (out === ctx || out === ctx.env || out === ctx.db) return {};
  for (const v of Object.values(out)) {
    if (v === ctx || v === ctx.env || v === ctx.db) throw new Error('unsafe result');
  }
  return out;
}

const GIFT_ACTIONS = new Set(['redeemGift', 'cancelGift', 'peekGift']);
export async function gateFor(db, cfg, uid, action, data) {
  const user = (await db.get(`users/${uid}`).catch(() => ({ data: null }))).data || {};
  if (user.blocked === true) return 'This account is paused.';
  const area = own(AREA, action) || (action === 'beginCheckout' && data && data.kind === 'giftcard' ? 'gifting' : null);
  if (area && user.restrictions && user.restrictions[area] === true) return 'This is switched off on this account. Write to us if you think this is a mistake.';
  const sw = cfg.switches || {};
  if (sw.coupons === false && (COUPON_ACTIONS.has(action) || (action === 'beginCheckout' && data && data.kind === 'scratch'))) return 'Coupons are switched off for now.';
  if (sw.gifts === false && (GIFT_ACTIONS.has(action) || (action === 'beginCheckout' && data && data.kind === 'giftcard'))) return 'Gifts are switched off for now.';
  if (cfg.earn && cfg.earn.enabled === false && ['requestPayout', 'appoint', 'answerAppointment'].includes(action)) return 'NowssB Earn is switched off for now.';
  return null;
}

export function missingEconomyEnv(env) {
  const missing = [];
  if (!env.FIRESTORE_EMULATOR_HOST && !serviceAccount(env)) missing.push('FIREBASE_SERVICE_ACCOUNT');
  if (!env.FIREBASE_PROJECT_ID) missing.push('FIREBASE_PROJECT_ID');
  return missing;
}

export async function onRequestOptions({ request }) {
  return new Response(null, { status: 204, headers: cors(request) });
}

export async function onRequestGet(ctx) {
  // GET /api/economy/config — published odds, ladders and caps (no sign-in).
  const h = cors(ctx.request);
  if (ctx.params.action !== 'config') return json({ error: 'Use POST.' }, 405, h);
  if (missingEconomyEnv(ctx.env).length) return json({ live: false, config: publicConfig(DEFAULT_ECONOMY) }, 200, h);
  try {
    const db = await FsDb.fromEnv(ctx.env);
    return json({ live: true, config: publicConfig(await loadEconomy(db)) }, 200, { ...h, 'Cache-Control': 'public, max-age=60' });
  } catch (e) {
    return json({ live: false, config: publicConfig(DEFAULT_ECONOMY) }, 200, h);
  }
}

export async function onRequestPost({ request, env, params, waitUntil }) {
  const h = cors(request);
  const action = String(params.action || '');
  if (action === 'config') return onRequestGet({ request, env, params });
  // Own-property lookups only: 'constructor', 'toString', '__proto__' …
  // must never resolve to Object.prototype members.
  const isAdminAction = Object.hasOwn(ADMIN, action);
  const fn = own(ACTIONS, action) || own(ADMIN, action);
  if (typeof fn !== 'function') return json({ error: 'Unknown action.', code: 'not-found' }, 404, h);
  const missing = missingEconomyEnv(env);
  if (missing.length) {
    return json({ error: 'Rewards are switching on. Nothing was lost — try again soon.', code: 'not-configured', switchingOn: true, missing }, 501, h);
  }
  const claims = await requireUser(request, env, h);
  if (claims instanceof Response) return claims;
  const uid = claims.sub;
  let data = {};
  try { data = (await request.json()) || {}; } catch (e) { data = {}; }
  try {
    const db = await FsDb.fromEnv(env);
    const outbox = notificationOutbox(db); // phone push for every inbox row this action commits
    const cfg = await loadEconomy(db);
    const ctx = { db, cfg, now: Date.now(), env, claims, country: (request.cf && request.cf.country) || request.headers.get('CF-IPCountry') || '' };
    if (isAdminAction && !(await ad.isAdmin(db, uid, claims))) return json({ error: 'Admins only.', code: 'permission-denied' }, 403, h);
    if (!isAdminAction) {
      const stop = await gateFor(db, cfg, uid, action, data);
      if (stop) return json({ ok: false, error: stop, code: 'restricted' }, 403, h);
    }
    const out = await fn(ctx, uid, data, claims);
    if (action === 'requestPayout' && out && out.id) {
      // Admin app inbox + admins' phones (best effort, never blocks).
      try {
        const { raiseAlertFromEnv } = await import('../../_lib/admin_alerts.js');
        await raiseAlertFromEnv(env, { kind: 'payout', ref: out.id, uid, title: `Payout request ₹${Number(out.amountINR || 0).toFixed(2)}`, body: `${claims.email || claims.name || uid} asked for a payout of ₹${Number(out.amountINR || 0).toFixed(2)}.`, route: 'payouts' });
      } catch (e) { /* alerts are best effort */ }
    }
    const sending = outbox.flush(env).catch(() => {});
    if (typeof waitUntil === 'function') waitUntil(sending); else await sending;
    return json({ ok: true, ...safeOut(out, ctx) }, 200, h);
  } catch (e) {
    if (e instanceof EconomyError || (e && e.status && e.code)) {
      return json({ ok: false, error: e.message, code: e.code, ...(e.extra || {}) }, e.status || 400, h);
    }
    if (e && e.code === 'already-exists') return json({ ok: false, error: 'That was already done.', code: 'already-exists' }, 409, h);
    return json({ ok: false, error: 'That did not go through. Try again.', code: 'internal' }, 500, h);
  }
}
