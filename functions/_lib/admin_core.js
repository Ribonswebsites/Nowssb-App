/* NowssB admin console — what each /api/admin/<action> does.

   Every function gets `deps`:
     db     admin_store interface (REST in production, memory in tests)
     auth   Firebase Auth admin (admin_google.authAdmin) or null
     push   async (token, msg) → { ok, expired } , or null when FCM is not set
     r2     async (prefix) → [{ key, url, size }] , or null when R2 is not set
     admin  { uid, email } — the verified caller
     now    ms
   Every change writes one adminLog row (who, what, target, detail) and one
   activity row in the same commit. Numbers come only from real documents;
   a collection that does not exist counts as zero. */

export class AdminError extends Error {
  constructor(status, message, code = 'error', extra = {}) { super(message); this.status = status; this.code = code; this.extra = extra; }
}
const bad = (m, code = 'invalid') => new AdminError(400, m, code);

export const DAY = 86400000;
export const ONLINE_MS = 5 * 60 * 1000;
export const TIERS = { resonance: 'Resonance', frequency: 'Frequency', frequencyX: 'Frequency X' };
export const BILLING = ['monthly', 'yearly', 'custom'];
export const RESTRICTIONS = {
  community: 'Muted in community (posts, comments, Echo Wall)',
  referrals: 'No invites or referral rewards',
  payouts: 'Payouts paused',
  gifting: 'Cannot send or open gifts',
  earning: 'Cannot earn coins or rewards',
  requests: 'Cannot send word requests',
};
export const GIFT_ITEMS = {
  word: { label: 'A word' },
  meaning: { label: 'A meaning' },
  bundle: { label: '10-word bundle' },
  resonance: { label: 'Resonance · 1 month', plan: 'resonance' },
  frequency: { label: 'Frequency · 1 month', plan: 'frequency' },
  frequency_x: { label: 'Frequency X · 1 month', plan: 'frequencyX' },
};

const str = (v, max = 200) => String(v == null ? '' : v).trim().slice(0, max);
const num = (v, d = 0) => (Number.isFinite(Number(v)) ? Number(v) : d);
export function toMs(v) {
  if (v == null || v === '') return 0;
  if (typeof v === 'number') return v;
  if (v instanceof Date) return v.getTime();
  if (typeof v === 'object' && v.seconds != null) return Number(v.seconds) * 1000;
  const t = Date.parse(String(v));
  return Number.isFinite(t) ? t : (Number.isFinite(Number(v)) ? Number(v) : 0);
}
const cleanUid = (v) => {
  const s = str(v, 128);
  if (!/^[A-Za-z0-9_-]{6,128}$/.test(s)) throw bad('That is not a user id.', 'bad_uid');
  return s;
};

/** Plan as the app reads it (lib/data/play_subscriptions.dart). */
export function planOf(u, now) {
  u = u || {};
  const tier = Object.hasOwn(TIERS, String(u.tier || '')) ? u.tier : '';
  const until = toMs(u.subscriptionEndDate);
  const active = !!(u.isPro === true && tier && (!until || until > now));
  return {
    active, tier: tier || '', name: active ? TIERS[tier] : (tier ? TIERS[tier] + ' (ended)' : 'Free'),
    billing: u.subscriptionBilling || '', until, since: toMs(u.subscriptionStartDate),
    source: u.subscriptionSource || '', expired: !!(tier || u.subscriptionEndDate) && !active && !!until && until <= now,
    autoRenew: u.subscriptionAutoRenew === true, productId: u.subscriptionProductId || '',
  };
}

function logOps(deps, action, target, detail = {}, summary = '') {
  const { db, admin } = deps;
  return [
    { op: 'create', path: `adminLog/${db.newId()}`, data: { action, target, detail, uid: admin.uid, email: admin.email || '', via: 'console', at: null }, serverTime: ['at'] },
    { op: 'create', path: `activity/${db.newId()}`, data: { type: 'admin', action, uid: target, by: admin.email || admin.uid, summary: summary || action, at: null }, serverTime: ['at'] },
  ];
}

function notifyOps(db, uid, title, body, kind = 'admin', extra = {}, now = Date.now()) {
  return [
    { op: 'create', path: `users/${uid}/notifications/${db.newId()}`, data: { title, body, kind, type: kind, read: false, at: new Date(now), createdAt: null, ...extra }, serverTime: ['createdAt'] },
  ];
}

async function pushToUser(deps, uid, msg) {
  if (!deps.push) return { sent: 0, devices: 0, missing: ['FCM_SERVICE_ACCOUNT'] };
  const subs = await deps.db.query({ collection: 'pushSubs', where: [['uid', '==', uid]], limit: 20 });
  let sent = 0;
  const dead = [];
  for (const s of subs) {
    const t = s.data.fcmToken || (String(s.data.endpoint || '').startsWith('fcm:') ? String(s.data.endpoint).slice(4) : '');
    if (!t) continue;
    try {
      const r = await deps.push(t, msg);
      if (r.ok) sent++;
      if (r.expired) dead.push(s.path);
    } catch (e) { /* one bad token never stops the rest */ }
  }
  if (dead.length) await deps.db.commit(dead.map((p) => ({ op: 'delete', path: p }))).catch(() => {});
  return { sent, devices: subs.length };
}

/* ═════════════════ Dashboard ═════════════════ */
export async function stats(deps, body = {}) {
  const { db, now } = deps;
  const tz = Math.max(-840, Math.min(840, num(body.tzOffsetMin, 330)));
  const local = now + tz * 60000;
  const dayStart = local - (local % DAY) - tz * 60000;
  const safe = (p) => p.catch((e) => ({ error: String(e.message || e).slice(0, 120) }));
  const c = (collection, where) => safe(db.count({ collection, where }));
  const s = (collection, where, field) => safe(db.sum({ collection, where, field }));
  const [
    profiles, today, week, online, blocked, helpers, subsRows, expired,
    payments, payments30, reqOpen, reqAll, reqDone, coinsIn, coinsOut, ledgerRows,
    gifts, giftsOpened, coupons, payoutsPending, payoutsQueued, payoutsPaid, authAll,
  ] = await Promise.all([
    c('users'),
    c('users', [['lastSeenAt', '>=', new Date(dayStart)]]),
    c('users', [['lastSeenAt', '>=', new Date(now - 7 * DAY)]]),
    c('users', [['lastSeenAt', '>=', new Date(now - ONLINE_MS)]]),
    c('users', [['blocked', '==', true]]),
    c('users', [['roles', 'array-contains', 'helper']]),
    safe(db.query({ collection: 'users', where: [['isPro', '==', true]], select: ['tier', 'subscriptionBilling', 'subscriptionEndDate', 'subscriptionSource', 'isPro'], limit: 5000 })),
    c('users', [['subscriptionEndDate', '<', new Date(now).toISOString()]]),
    c('payments'),
    c('payments', [['at', '>=', new Date(now - 30 * DAY)]]),
    c('requests', [['status', '==', 'new']]),
    c('requests'),
    c('requests', [['status', '==', 'done']]),
    s('coinLedger', [['delta', '>', 0]], 'delta'),
    s('coinLedger', [['delta', '<', 0]], 'delta'),
    c('coinLedger'),
    c('gifts'),
    c('gifts', [['status', '==', 'redeemed']]),
    c('couponLedger'),
    c('payoutRequests', [['status', '==', 'pending_review']]),
    c('payoutRequests', [['status', '==', 'queued']]),
    c('payoutRequests', [['status', '==', 'paid']]),
    deps.auth ? safe(deps.auth.all(5)) : Promise.resolve({ error: 'auth not configured' }),
  ]);
  const val = (x) => (typeof x === 'number' ? x : 0);
  const errors = {};
  const note = (k, x) => { if (x && x.error) errors[k] = x.error; };
  note('subs', subsRows); note('auth', authAll); note('profiles', profiles); note('coins', coinsIn);

  // Subscribers by plan and billing, active vs ended (isPro still true).
  const plans = {};
  for (const t of Object.keys(TIERS)) plans[t] = { name: TIERS[t], monthly: 0, yearly: 0, other: 0, active: 0 };
  let active = 0; let lapsed = 0; const bySource = {};
  for (const r of Array.isArray(subsRows) ? subsRows : []) {
    const p = planOf(r.data, now);
    if (!p.tier) continue;
    if (!p.active) { lapsed++; continue; }
    active++;
    const b = p.billing === 'monthly' || p.billing === 'yearly' ? p.billing : 'other';
    plans[p.tier][b]++;
    plans[p.tier].active++;
    bySource[p.source || 'unknown'] = (bySource[p.source || 'unknown'] || 0) + 1;
  }

  // Sign-ups per day for 30 days, from Firebase Auth (the real sign-up time).
  const days = [];
  for (let i = 29; i >= 0; i--) days.push({ day: new Date(dayStart - i * DAY + tz * 60000).toISOString().slice(0, 10), start: dayStart - i * DAY, n: 0 });
  let authTotal = null; let signups7 = 0; let signupsToday = 0; let authToday = 0; let auth7 = 0;
  if (authAll && Array.isArray(authAll.users)) {
    authTotal = authAll.users.length;
    for (const u of authAll.users) {
      const t = u.createdAt;
      if (t >= dayStart - 29 * DAY) {
        const idx = Math.floor((t - (dayStart - 29 * DAY)) / DAY);
        if (days[idx]) days[idx].n++;
      }
      if (t >= dayStart) signupsToday++;
      if (t >= now - 7 * DAY) signups7++;
      const last = Math.max(u.lastLoginAt, u.lastRefreshAt);
      if (last >= dayStart) authToday++;
      if (last >= now - 7 * DAY) auth7++;
    }
  }
  return {
    ok: true,
    at: now,
    users: {
      accounts: authTotal, accountsTruncated: !!(authAll && authAll.truncated), profiles: val(profiles),
      signedInToday: Math.max(val(today), authToday), signedIn7d: Math.max(val(week), auth7), online: val(online),
      blocked: val(blocked), helpers: val(helpers), signupsToday, signups7d: signups7,
    },
    signups: days.map((d) => ({ day: d.day, n: d.n })),
    subscriptions: { active, lapsedFlagged: lapsed, expired: val(expired), plans, bySource },
    payments: { total: val(payments), last30d: val(payments30) },
    requests: { open: val(reqOpen), done: val(reqDone), total: val(reqAll) },
    coins: { issued: val(coinsIn), spent: Math.abs(val(coinsOut)), entries: val(ledgerRows) },
    gifts: { codes: val(gifts), opened: val(giftsOpened), coupons: val(coupons) },
    payouts: { pending: val(payoutsPending), queued: val(payoutsQueued), paid: val(payoutsPaid) },
    errors,
  };
}

/* ═════════════════ People ═════════════════ */
function userRow(a, u, now) {
  u = u || {};
  a = a || {};
  const seen = Math.max(toMs(u.lastSeenAt), toMs(u.lastSeen), a.lastRefreshAt || 0);
  return {
    uid: a.uid || u.uid || '',
    name: a.name || u.displayName || u.name || '',
    email: a.email || u.email || '',
    phone: a.phone || u.phone || u.phoneNumber || '',
    photo: a.photo || u.photoURL || '',
    providers: a.providers || [],
    createdAt: a.createdAt || toMs(u.createdAt),
    lastLoginAt: a.lastLoginAt || toMs(u.lastLogin),
    lastSeen: seen,
    online: seen > now - ONLINE_MS,
    disabled: !!a.disabled,
    blocked: u.blocked === true,
    helper: Array.isArray(u.roles) && u.roles.includes('helper'),
    restrictions: Object.keys(u.restrictions || {}).filter((k) => u.restrictions[k] === true),
    plan: planOf(u, now),
    platform: u.lastPlatform || '',
    build: u.lastBuild || '',
    hasProfile: !!Object.keys(u).length,
  };
}

const matches = (row, q) => {
  if (!q) return true;
  const n = q.toLowerCase();
  return [row.uid, row.email, row.name, row.phone].some((v) => String(v || '').toLowerCase().includes(n))
    || (n.replace(/[^0-9]/g, '').length >= 5 && String(row.phone || '').replace(/[^0-9]/g, '').includes(n.replace(/[^0-9]/g, '')));
};

export async function listUsers(deps, body = {}) {
  const { db, now } = deps;
  const q = str(body.q, 120);
  const filter = str(body.filter, 20) || 'all';
  const tier = str(body.tier, 20);
  const from = toMs(body.joinedFrom);
  const to = toMs(body.joinedTo);
  const limit = Math.max(1, Math.min(100, num(body.limit, 40)));
  const offset = Math.max(0, num(body.offset, 0));
  let rows = [];
  let source = 'auth';
  let truncated = false;
  let note = '';

  const fsFilters = {
    plan: [['isPro', '==', true]],
    blocked: [['blocked', '==', true]],
    online: [['lastSeenAt', '>=', new Date(now - ONLINE_MS)]],
    today: [['lastSeenAt', '>=', new Date(now - DAY)]],
    helper: [['roles', 'array-contains', 'helper']],
    expired: [['subscriptionEndDate', '<', new Date(now).toISOString()]],
  };
  if (fsFilters[filter]) {
    source = 'firestore';
    const docs = await db.query({ collection: 'users', where: fsFilters[filter], limit: 1000 });
    let auths = [];
    if (deps.auth && docs.length) {
      try { auths = await deps.auth.lookup(docs.map((d) => d.id).slice(0, 500)); } catch (e) { note = 'Sign-in details unavailable: ' + e.message; }
    }
    const byUid = new Map(auths.map((a) => [a.uid, a]));
    rows = docs.map((d) => userRow(byUid.get(d.id) || { uid: d.id }, d.data, now));
    if (filter === 'plan') rows = rows.filter((r) => r.plan.active && (!tier || r.plan.tier === tier));
  } else if (deps.auth) {
    try {
      const all = await deps.auth.all(5);
      truncated = all.truncated;
      rows = all.users.map((a) => userRow(a, null, now));
    } catch (e) {
      note = 'Firebase Auth listing failed (' + e.message + '); showing Firestore profiles.';
      rows = null;
    }
  } else {
    rows = null;
    note = 'Firebase Auth listing needs the service account; showing Firestore profiles.';
  }
  if (rows === null) {
    source = 'firestore';
    const docs = await db.query({ collection: 'users', limit: 1000 });
    rows = docs.map((d) => userRow({ uid: d.id }, d.data, now));
  }
  rows = rows.filter((r) => matches(r, q) && (!from || r.createdAt >= from) && (!to || r.createdAt <= to));
  // A search that looks like a uid also tries the exact document.
  if (q && !rows.length && /^[A-Za-z0-9_-]{20,128}$/.test(q)) {
    const u = await db.get(`users/${q}`);
    if (u) rows = [userRow({ uid: q }, u, now)];
  }
  rows.sort((a, b) => (b.createdAt - a.createdAt) || (b.lastSeen - a.lastSeen));
  const total = rows.length;
  const page = rows.slice(offset, offset + limit);
  // Fill Firestore fields (plan, blocked, presence) for the auth-sourced page.
  if (source === 'auth' && page.length) {
    const docs = await db.getMany(page.map((r) => `users/${r.uid}`));
    for (let i = 0; i < page.length; i++) {
      const u = docs.get(`users/${page[i].uid}`);
      if (u) page[i] = userRow({ ...page[i], lastRefreshAt: page[i].lastSeen }, u, now);
    }
  }
  return { ok: true, total, offset, limit, rows: page, source, truncated, note };
}

export async function userProfile(deps, body = {}) {
  const { db, now } = deps;
  const uid = cleanUid(body.uid);
  const L = (collection, where, limit = 60) => db.query({ collection, where, limit }).catch(() => []);
  const [user, wallet, referral, payout, partner, coins, cash, invited, invitedBy, giftsSent, giftsOpened,
    coupons, owned, payments, requests, log, payouts, activity, subs] = await Promise.all([
    db.get(`users/${uid}`),
    db.get(`users/${uid}/wallet/main`),
    db.get(`users/${uid}/referral/main`),
    db.get(`users/${uid}/payout/main`),
    db.get(`users/${uid}/partner/main`),
    L('coinLedger', [['uid', '==', uid]], 200),
    L('cashLedger', [['uid', '==', uid]], 100),
    L('referrals', [['referrerUid', '==', uid]], 200),
    db.get(`referrals/${uid}`),
    L('gifts', [['senderUid', '==', uid]], 50),
    L('gifts', [['redeemedBy', '==', uid]], 50),
    L('couponLedger', [['uid', '==', uid]], 50),
    db.query({ parent: `users/${uid}`, collection: 'owned', limit: 200 }).catch(() => []),
    L('payments', [['uid', '==', uid]], 50),
    L('requests', [['uid', '==', uid]], 50),
    L('adminLog', [['target', '==', uid]], 100),
    L('payoutRequests', [['uid', '==', uid]], 30),
    L('activity', [['uid', '==', uid]], 60),
    L('pushSubs', [['uid', '==', uid]], 10),
  ]);
  let auth = null;
  let authNote = '';
  if (deps.auth) {
    try { auth = (await deps.auth.lookup([uid]))[0] || null; } catch (e) { authNote = e.message; }
  } else authNote = 'Firebase Auth details need the service account.';
  if (!user && !auth) throw new AdminError(404, 'No account with that id.', 'not_found');
  const byNew = (f) => (a, b) => toMs(b.data[f]) - toMs(a.data[f]);
  const rows = (list, f = 'at', n = 60) => list.sort(byNew(f)).slice(0, n).map((r) => ({ id: r.id, ...r.data, at: toMs(r.data[f]) }));
  const u = user || {};
  return {
    ok: true,
    row: userRow(auth || { uid }, u, now),
    auth: auth || null,
    authNote,
    user: {
      displayName: u.displayName || '', username: u.username || '', createdAt: toMs(u.createdAt), lastSeen: Math.max(toMs(u.lastSeenAt), toMs(u.lastSeen)),
      lastPlatform: u.lastPlatform || '', lastApp: u.lastApp || '', lastBuild: u.lastBuild || '', lastDevice: u.lastDevice || '', lastOs: u.lastOs || '',
      country: u.country || '', blocked: u.blocked === true, blockedReason: u.blockedReason || '', blockedAt: toMs(u.blockedAt), blockedBy: u.blockedBy || '',
      restrictions: u.restrictions || {}, roles: Array.isArray(u.roles) ? u.roles : [], verifyTier: u.verifyTier || '',
    },
    plan: planOf(u, now),
    wallet: wallet ? { coins: num(wallet.coins), streak: num(wallet.streak), longestStreak: num(wallet.longestStreak), lifetimeEarned: num(wallet.lifetimeEarned), freezesOwned: num(wallet.freezesOwned), wordCredits: num(wallet.wordCredits), meaningCredits: num(wallet.meaningCredits), lastLoginYmd: wallet.lastLoginYmd || '' } : null,
    coinLedger: rows(coins, 'at', 80),
    cashLedger: rows(cash, 'at', 40),
    referral: referral ? { code: referral.code || '', tier: referral.tier || '', unitsSold: num(referral.unitsSold), signups: num(referral.signups), subscribers: num(referral.subscribers), paidReferralCount: num(referral.paidReferralCount), referredBy: referral.referredBy || '', referredByUid: referral.referredByUid || '' } : null,
    invitedBy: invitedBy ? { uid: invitedBy.referrerUid || '', at: toMs(invitedBy.at || invitedBy.createdAt), subscribed: invitedBy.subscribed === true } : null,
    invited: rows(invited, 'at', 100).map((r) => ({ uid: r.id, at: r.at, subscribed: r.subscribed === true, rewarded: r.rewarded === true })),
    payout: payout ? { cashBalance: num(payout.cashBalance), pendingCents: num(payout.pendingCents), paidCents: num(payout.paidCents), lifetimeCents: num(payout.lifetimeCents), upi: payout.upi || '', country: payout.country || '', rail: payout.payoutRail || '' } : null,
    payouts: rows(payouts, 'at', 30),
    partner: partner || null,
    gifts: { sent: rows(giftsSent, 'createdAt', 50), opened: rows(giftsOpened, 'redeemedAt', 50) },
    coupons: rows(coupons, 'at', 50),
    owned: owned.map((r) => ({ id: r.id, ...r.data, at: toMs(r.data.at) })).sort((a, b) => b.at - a.at).slice(0, 100),
    payments: rows(payments, 'at', 50),
    requests: rows(requests, 'at', 50),
    adminLog: rows(log, 'at', 100),
    activity: rows(activity, 'at', 60),
    devices: subs.map((s) => ({ platform: s.data.platform || '', country: s.data.country || '', updatedAt: toMs(s.data.updatedAt) })),
  };
}

/* ═════════════════ Actions on a person ═════════════════ */
async function mustUser(db, uid) {
  const u = await db.get(`users/${uid}`);
  return u || {};
}

export async function grantSub(deps, body = {}) {
  const { db, now, admin } = deps;
  const uid = cleanUid(body.uid);
  const tier = str(body.tier, 20);
  if (!Object.hasOwn(TIERS, String(tier))) throw bad('Pick Resonance, Frequency or Frequency X.');
  const billing = BILLING.includes(body.billing) ? body.billing : 'custom';
  let end;
  if (body.until) {
    end = toMs(body.until);
    if (!end || end <= now) throw bad('Pick an end date in the future.');
  } else {
    const days = Math.round(num(body.days));
    if (days < 1 || days > 3660) throw bad('Days must be 1 to 3660.');
    end = now + days * DAY;
  }
  const u = await mustUser(db, uid);
  const before = planOf(u, now);
  const fields = {
    isPro: true, tier, subscriptionBilling: billing, subscriptionEndDate: new Date(end).toISOString(), subscriptionSource: 'admin',
    subscriptionGrantedBy: admin.email || admin.uid, subscriptionUpdatedAt: null,
  };
  if (!before.active || !u.subscriptionStartDate) fields.subscriptionStartDate = new Date(now).toISOString();
  const detail = { tier, billing, until: fields.subscriptionEndDate, before: before.active ? `${before.tier} until ${new Date(before.until || now).toISOString()}` : 'none', reason: str(body.reason, 200) };
  const ops = [
    { op: 'merge', path: `users/${uid}`, data: fields, serverTime: ['subscriptionUpdatedAt'] },
    ...logOps(deps, 'sub.grant', uid, detail, `Granted ${TIERS[tier]} until ${fields.subscriptionEndDate.slice(0, 10)}`),
  ];
  if (body.notify !== false) ops.push(...notifyOps(db, uid, `${TIERS[tier]} is on`, `Your ${TIERS[tier]} plan is active until ${fields.subscriptionEndDate.slice(0, 10)}.`, 'plan', {}, now));
  await db.commit(ops);
  return { ok: true, plan: planOf({ ...u, ...fields }, now), warning: before.active && before.source === 'play' ? 'This person also has a Google Play subscription; Play renewals will overwrite this grant.' : '' };
}

export async function extendSub(deps, body = {}) {
  const { db, now } = deps;
  const uid = cleanUid(body.uid);
  const days = Math.round(num(body.days));
  if (days < 1 || days > 3660) throw bad('Days must be 1 to 3660.');
  const u = await mustUser(db, uid);
  const p = planOf(u, now);
  const tier = p.tier || str(body.tier, 20);
  if (!Object.hasOwn(TIERS, String(tier))) throw bad('This person has no plan to extend. Grant one first.');
  const end = Math.max(p.until || now, now) + days * DAY;
  const fields = { isPro: true, tier, subscriptionEndDate: new Date(end).toISOString(), subscriptionUpdatedAt: null };
  if (!p.source || !p.active) fields.subscriptionSource = 'admin';
  await db.commit([
    { op: 'merge', path: `users/${uid}`, data: fields, serverTime: ['subscriptionUpdatedAt'] },
    ...logOps(deps, 'sub.extend', uid, { days, until: fields.subscriptionEndDate, reason: str(body.reason, 200) }, `Extended ${TIERS[tier]} by ${days} days`),
    ...notifyOps(db, uid, 'Plan extended', `Your ${TIERS[tier]} plan now runs until ${fields.subscriptionEndDate.slice(0, 10)}.`, 'plan', {}, now),
  ]);
  return { ok: true, plan: planOf({ ...u, ...fields }, now) };
}

export async function revokeSub(deps, body = {}) {
  const { db, now } = deps;
  const uid = cleanUid(body.uid);
  const u = await mustUser(db, uid);
  const p = planOf(u, now);
  const fields = { isPro: false, tier: null, subscriptionEndDate: new Date(now).toISOString(), subscriptionSource: 'admin_revoked', subscriptionUpdatedAt: null };
  await db.commit([
    { op: 'merge', path: `users/${uid}`, data: fields, serverTime: ['subscriptionUpdatedAt'] },
    ...logOps(deps, 'sub.revoke', uid, { before: p.tier || 'none', source: p.source, reason: str(body.reason, 200) }, 'Plan revoked'),
  ]);
  return { ok: true, plan: planOf({ ...u, ...fields }, now), warning: p.source === 'play' ? 'This was a Google Play subscription. Revoking here does not cancel billing in Play; a Play renewal turns it back on. Refund or cancel it in Play Console.' : '' };
}

export async function adjustCoins(deps, body = {}) {
  const { db, now, admin } = deps;
  const uid = cleanUid(body.uid);
  const delta = Math.round(num(body.delta));
  const reason = str(body.reason, 140);
  if (!delta || Math.abs(delta) > 1000000) throw bad('Enter a coin amount (not zero).');
  if (!reason) throw bad('Say why — it is shown in their coin history.');
  let balance = 0;
  const entry = db.newId();
  await db.runTransaction(async (tx) => {
    const w = (await tx.get(`users/${uid}/wallet/main`)) || {};
    const next = num(w.coins) + delta;
    if (next < 0) throw new AdminError(409, `They only have ${num(w.coins)} coins.`, 'insufficient_coins');
    balance = next;
    tx.create(`coinLedger/${entry}`, { uid, delta, balanceAfter: next, reason: 'Admin: ' + reason, refId: 'admin:' + admin.uid, by: admin.email || admin.uid, at: new Date(now) });
    const patch = { coins: next, updatedAt: now };
    if (delta > 0) patch.lifetimeEarned = num(w.lifetimeEarned) + delta;
    tx.set(`users/${uid}/wallet/main`, patch, { merge: true });
  });
  await db.commit([
    ...logOps(deps, 'coins.adjust', uid, { delta, reason, balance, entry }, `${delta > 0 ? '+' : ''}${delta} coins (${reason})`),
    ...(body.notify === false ? [] : notifyOps(db, uid, delta > 0 ? `${delta} coins added` : `${-delta} coins removed`, reason, 'coins', {}, now)),
  ]);
  return { ok: true, balance, entry };
}

export async function setBlocked(deps, body = {}) {
  const { db, now, admin } = deps;
  const uid = cleanUid(body.uid);
  const on = body.blocked !== false;
  if (on && uid === admin.uid) throw bad('You cannot block yourself.');
  if (on && (await db.get(`admins/${uid}`))) throw bad('That account is an admin. Remove it from admins first.');
  let authResult = 'skipped';
  if (deps.auth) {
    try { await deps.auth.setDisabled(uid, on); authResult = on ? 'disabled' : 'enabled'; } catch (e) { authResult = 'failed: ' + e.message; }
  } else authResult = 'needs FIREBASE_SERVICE_ACCOUNT';
  const reason = str(body.reason, 300);
  const fields = on
    ? { blocked: true, blockedAt: null, blockedBy: admin.email || admin.uid, blockedReason: reason }
    : { blocked: false, blockedReason: '', unblockedAt: null, unblockedBy: admin.email || admin.uid };
  await db.commit([
    { op: 'merge', path: `users/${uid}`, data: fields, serverTime: [on ? 'blockedAt' : 'unblockedAt'] },
    ...logOps(deps, on ? 'user.block' : 'user.unblock', uid, { reason, auth: authResult }, on ? 'Blocked' : 'Unblocked'),
  ]);
  return { ok: true, blocked: on, auth: authResult };
}

export async function setRestrictions(deps, body = {}) {
  const { db } = deps;
  const uid = cleanUid(body.uid);
  const want = body.restrictions && typeof body.restrictions === 'object' ? body.restrictions : {};
  const r = {};
  for (const k of Object.keys(RESTRICTIONS)) if (want[k] === true) r[k] = true;
  await db.commit([
    { op: 'merge', path: `users/${uid}`, data: { restrictions: r, restrictionsUpdatedAt: null }, serverTime: ['restrictionsUpdatedAt'] },
    ...logOps(deps, 'user.restrict', uid, { on: Object.keys(r).join(',') || 'none', reason: str(body.reason, 200) }, Object.keys(r).length ? 'Restricted: ' + Object.keys(r).join(', ') : 'Restrictions cleared'),
  ]);
  return { ok: true, restrictions: r };
}

export async function resetStreak(deps, body = {}) {
  const { db, now } = deps;
  const uid = cleanUid(body.uid);
  const w = (await db.get(`users/${uid}/wallet/main`)) || {};
  await db.commit([
    { op: 'merge', path: `users/${uid}/wallet/main`, data: { streak: 0, lastLoginYmd: '', streakResetAt: now, lastBrokenStreak: num(w.streak) } },
    ...logOps(deps, 'streak.reset', uid, { was: num(w.streak), reason: str(body.reason, 200) }, `Streak reset (was ${num(w.streak)})`),
  ]);
  return { ok: true, was: num(w.streak) };
}

export async function messageUser(deps, body = {}) {
  const { db, now } = deps;
  const uid = cleanUid(body.uid);
  const title = str(body.title, 80);
  const text = str(body.body, 600);
  if (!title) throw bad('A title is required.');
  await db.commit([
    ...notifyOps(db, uid, title, text, 'admin', { from: 'NowssB' }, now),
    ...logOps(deps, 'user.message', uid, { title, push: body.push !== false }, 'Message: ' + title),
  ]);
  const push = body.push === false ? { sent: 0, devices: 0, skipped: true } : await pushToUser(deps, uid, { title, body: text, type: 'admin' });
  return { ok: true, inApp: true, push };
}

export async function setHelper(deps, body = {}) {
  const { db } = deps;
  const uid = cleanUid(body.uid);
  const on = body.on !== false;
  const u = await mustUser(db, uid);
  const roles = new Set(Array.isArray(u.roles) ? u.roles : []);
  if (on) roles.add('helper'); else roles.delete('helper');
  await db.commit([
    { op: 'merge', path: `users/${uid}`, data: { roles: [...roles] } },
    ...logOps(deps, on ? 'role.helper.add' : 'role.helper.remove', uid, {}, on ? 'Marked helper' : 'Helper removed'),
  ]);
  return { ok: true, roles: [...roles] };
}

/* ═════════════════ Requests ═════════════════ */
export async function fulfilRequest(deps, body = {}) {
  const { db, now, admin } = deps;
  const id = str(body.id, 80);
  if (!/^[A-Za-z0-9_-]{4,80}$/.test(id)) throw bad('Missing request.');
  const r = await db.get(`requests/${id}`);
  if (!r) throw new AdminError(404, 'That request is gone.', 'not_found');
  const wordKey = str(body.wordKey, 80);
  const word = str(body.word, 80) || r.word || wordKey;
  const ops = [
    { op: 'merge', path: `requests/${id}`, data: { status: 'done', doneAt: now, fulfilledWord: wordKey, fulfilledBy: admin.email || admin.uid, adminNote: str(body.note, 300) } },
    ...logOps(deps, 'request.done', id, { word, wordKey, uid: r.uid || '' }, `Request “${word}” fulfilled`),
  ];
  const uid = typeof r.uid === 'string' && r.uid ? r.uid : '';
  const title = `“${word}” is ready`;
  const text = str(body.message, 300) || 'The word you asked for is now in NowssB. Open it from your notifications.';
  if (uid) ops.push(...notifyOps(db, uid, title, text, 'request_done', { word, wordKey, requestId: id }, now));
  await db.commit(ops);
  const push = uid ? await pushToUser(deps, uid, { title, body: text, type: 'request_done', route: wordKey ? 'word:' + wordKey : '' }) : { sent: 0, devices: 0 };
  return { ok: true, told: !!uid, push };
}

/* ═════════════════ Broadcast ═════════════════ */
export async function broadcast(deps, body = {}) {
  const { db, now } = deps;
  const title = str(body.title, 80);
  const text = str(body.body, 400);
  const audience = ['all', 'plan', 'user', 'free'].includes(body.audience) ? body.audience : '';
  if (!title) throw bad('A title is required.');
  if (!audience) throw bad('Pick who gets it.');
  if (!deps.push) throw new AdminError(501, 'Push is not switched on. Add FCM_SERVICE_ACCOUNT in Cloudflare Pages → Settings → Variables (Production).', 'not_configured', { missing: ['FCM_SERVICE_ACCOUNT'] });
  const id = str(body.broadcastId, 40) || db.newId();
  const first = !body.cursor;
  let targets = null;
  if (audience === 'user') {
    const uid = cleanUid(body.uid);
    targets = new Set([uid]);
  } else if (audience === 'plan' || audience === 'free') {
    const subs = await db.query({ collection: 'users', where: [['isPro', '==', true]], select: ['tier', 'subscriptionEndDate', 'isPro'], limit: 5000 });
    const tier = str(body.tier, 20);
    targets = new Set(subs.filter((s) => { const p = planOf(s.data, now); return p.active && (!tier || p.tier === tier); }).map((s) => s.id));
  }
  const PAGE = 40;
  let rows;
  if (audience === 'user') {
    rows = await db.query({ collection: 'pushSubs', where: [['uid', '==', [...targets][0]]], limit: 20 });
  } else {
    rows = await db.query({ collection: 'pushSubs', orderBy: [['updatedAt', 'asc']], startAfter: body.cursor ? [num(body.cursor)] : null, limit: PAGE });
  }
  let sent = 0; let failed = 0; let skipped = 0;
  const dead = [];
  for (const r of rows) {
    const uid = r.data.uid || '';
    if (audience === 'plan' && !targets.has(uid)) { skipped++; continue; }
    if (audience === 'free' && targets.has(uid)) { skipped++; continue; }
    const t = r.data.fcmToken || (String(r.data.endpoint || '').startsWith('fcm:') ? String(r.data.endpoint).slice(4) : '');
    if (!t) { skipped++; continue; }
    try {
      const res = await deps.push(t, { title, body: text, type: 'broadcast', route: str(body.route, 80) });
      if (res.ok) sent++; else failed++;
      if (res.expired) dead.push(r.path);
    } catch (e) { failed++; }
  }
  const last = rows.length ? rows[rows.length - 1].data.updatedAt : null;
  const next = audience !== 'user' && rows.length === PAGE && last != null ? String(num(last)) : '';
  const ops = dead.map((p) => ({ op: 'delete', path: p }));
  if (first) {
    ops.push({ op: 'set', path: `broadcasts/${id}`, data: { title, body: text, audience, tier: str(body.tier, 20), uid: str(body.uid, 128), by: deps.admin.email || deps.admin.uid, at: null, sent, failed }, serverTime: ['at'] });
    ops.push(...logOps(deps, 'push.broadcast', audience === 'user' ? str(body.uid, 128) : audience + (body.tier ? ':' + body.tier : ''), { title, id }, 'Push: ' + title));
  } else {
    const cur = (await db.get(`broadcasts/${id}`)) || {};
    ops.push({ op: 'merge', path: `broadcasts/${id}`, data: { sent: num(cur.sent) + sent, failed: num(cur.failed) + failed } });
  }
  await db.commit(ops);
  return { ok: true, broadcastId: id, sent, failed, skipped, removed: dead.length, next };
}

/* ═════════════════ Earn & Gifts ═════════════════ */
export async function decidePayout(deps, body = {}) {
  const { db, now, admin } = deps;
  const id = str(body.id, 80);
  const decision = str(body.decision, 12);
  if (!['approve', 'paid', 'reject'].includes(decision)) throw bad('Decision must be approve, paid or reject.');
  const note = str(body.note, 300);
  const utr = str(body.utr, 60);
  if (decision === 'paid' && !utr) throw bad('Enter the UPI reference (UTR) of the transfer.');
  if (decision === 'reject' && !note) throw bad('Say why, so the person knows.');
  let out;
  await db.runTransaction(async (tx) => {
    const p = await tx.get(`payoutRequests/${id}`);
    if (!p) throw new AdminError(404, 'That payout request is gone.', 'not_found');
    const st = p.status || '';
    const open = ['pending_review', 'queued', 'approved'];
    if (!open.includes(st)) throw new AdminError(409, `Already ${st}.`, 'closed');
    if (decision === 'approve' && st === 'approved') throw new AdminError(409, 'Already approved.', 'closed');
    const amt = num(p.amountBase);
    const pay = (await tx.get(`users/${p.uid}/payout/main`)) || {};
    if (decision === 'approve') {
      tx.set(`payoutRequests/${id}`, { status: 'approved', approvedAt: new Date(now), approvedBy: admin.email || admin.uid, note }, { merge: true });
    } else if (decision === 'paid') {
      tx.set(`payoutRequests/${id}`, { status: 'paid', paidAt: new Date(now), paidBy: admin.email || admin.uid, utr, note }, { merge: true });
      tx.set(`users/${p.uid}/payout/main`, { pendingCents: Math.max(0, num(pay.pendingCents) - amt), paidCents: num(pay.paidCents) + amt, updatedAt: now }, { merge: true });
    } else {
      const next = num(pay.cashBalance) + amt;
      tx.set(`payoutRequests/${id}`, { status: 'rejected', rejectedAt: new Date(now), rejectedBy: admin.email || admin.uid, note }, { merge: true });
      tx.create(`cashLedger/${db.newId()}`, { uid: p.uid, delta: amt, balanceAfter: next, reason: 'Payout returned', refId: id, at: new Date(now) });
      tx.set(`users/${p.uid}/payout/main`, { cashBalance: next, pendingCents: Math.max(0, num(pay.pendingCents) - amt), updatedAt: now }, { merge: true });
    }
    out = { uid: p.uid, amount: amt, from: st };
  });
  const msg = {
    approve: ['Payout approved', 'Your payout is approved and will be sent to your UPI id.'],
    paid: ['Payout sent', `Your payout was sent to your UPI id. Reference ${utr}.`],
    reject: ['Payout not approved', `Your balance is back in NowssB Earn. ${note}`],
  }[decision];
  await db.commit([
    ...logOps(deps, 'payout.' + decision, id, { uid: out.uid, amountCents: out.amount, utr, note }, `Payout ${decision} (${(out.amount / 100).toFixed(2)} USD)`),
    ...notifyOps(db, out.uid, msg[0], msg[1], 'payout', { refId: id }, now),
  ]);
  return { ok: true, id, status: { approve: 'approved', paid: 'paid', reject: 'rejected' }[decision], ...out };
}

function giftCode() {
  const abc = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const b = crypto.getRandomValues(new Uint8Array(6));
  return 'GFT' + [...b].map((x) => abc[x % abc.length]).join('');
}

export async function createGiftCodes(deps, body = {}) {
  const { db, now, admin } = deps;
  const item = str(body.item, 20);
  if (!Object.hasOwn(GIFT_ITEMS, String(item))) throw bad('Pick what the gift holds.');
  const count = Math.round(num(body.count, 1));
  if (count < 1 || count > 50) throw bad('Make 1 to 50 codes at a time.');
  const days = Math.round(num(body.expiresDays, 90));
  if (days < 1 || days > 730) throw bad('Expiry must be 1 to 730 days.');
  const email = str(body.recipientEmail, 120).toLowerCase();
  const note = str(body.note, 140);
  const campaign = str(body.campaign, 60);
  const codes = [];
  const ops = [];
  for (let i = 0; i < count; i++) {
    const code = giftCode();
    codes.push(code);
    ops.push({ op: 'create', path: `gifts/${code}`, data: {
      code, item, itemId: item, label: GIFT_ITEMS[item].label, note, senderUid: admin.uid, senderName: 'NowssB', source: 'admin', campaign,
      recipientEmail: email, status: 'unredeemed', createdAt: now, expiresAt: now + days * DAY,
    } });
    ops.push({ op: 'create', path: `giftLedger/${db.newId()}`, data: { code, senderUid: admin.uid, itemId: item, cents: 0, status: 'issued', source: 'admin', campaign, at: new Date(now) } });
  }
  ops.push(...logOps(deps, 'gift.codes', campaign || item, { item, count, days, email }, `${count} gift code${count > 1 ? 's' : ''}: ${GIFT_ITEMS[item].label}`));
  await db.commit(ops);
  return { ok: true, codes, item, expiresAt: now + days * DAY };
}

export async function voidGift(deps, body = {}) {
  const { db } = deps;
  const code = str(body.code, 20).toUpperCase().replace(/[^A-Z0-9]/g, '');
  const g = await db.get(`gifts/${code}`);
  if (!g) throw new AdminError(404, 'No such code.', 'not_found');
  if (g.status !== 'unredeemed') throw new AdminError(409, `Already ${g.status}.`, 'closed');
  await db.commit([
    { op: 'merge', path: `gifts/${code}`, data: { status: 'void', voidedBy: deps.admin.email || deps.admin.uid, voidedAt: deps.now } },
    ...logOps(deps, 'gift.void', code, { label: g.label || '' }, 'Gift code voided'),
  ]);
  return { ok: true };
}

export async function earnOverview(deps) {
  const { db, now } = deps;
  const L = (o) => db.query(o).catch(() => []);
  const [referrals, refLedger, payouts, gifts, coupons, cfg, partners] = await Promise.all([
    L({ collection: 'referrals', limit: 2000 }),
    L({ collection: 'referralLedger', orderBy: [['at', 'desc']], limit: 60 }),
    L({ collection: 'payoutRequests', orderBy: [['at', 'desc']], limit: 150 }),
    L({ collection: 'gifts', orderBy: [['createdAt', 'desc']], limit: 150 }),
    L({ collection: 'couponLedger', orderBy: [['at', 'desc']], limit: 60 }),
    db.get('config/economy').catch(() => null),
    L({ collection: 'partnerLedger', orderBy: [['at', 'desc']], limit: 40 }),
  ]);
  const byRef = new Map();
  for (const r of referrals) {
    const k = r.data.referrerUid;
    if (!k) continue;
    const e = byRef.get(k) || { uid: k, invited: 0, subscribed: 0 };
    e.invited++;
    if (r.data.subscribed) e.subscribed++;
    byRef.set(k, e);
  }
  const top = [...byRef.values()].sort((a, b) => (b.subscribed - a.subscribed) || (b.invited - a.invited)).slice(0, 25);
  if (deps.auth && top.length) {
    try {
      const names = new Map((await deps.auth.lookup(top.map((t) => t.uid))).map((a) => [a.uid, a]));
      for (const t of top) { const a = names.get(t.uid); if (a) { t.name = a.name; t.email = a.email; } }
    } catch (e) { /* names are a nicety */ }
  }
  const rows = (list, f = 'at') => list.map((r) => ({ id: r.id, ...r.data, at: toMs(r.data[f]) }));
  return {
    ok: true,
    network: { referrals: referrals.length, referrers: byRef.size, subscribed: referrals.filter((r) => r.data.subscribed).length, top },
    referralLedger: rows(refLedger),
    payouts: rows(payouts),
    gifts: rows(gifts, 'createdAt'),
    coupons: rows(coupons),
    partner: rows(partners),
    config: cfg || null,
    now,
  };
}

export async function network(deps, body = {}) {
  const { db } = deps;
  const uid = cleanUid(body.uid);
  const [l1, up] = await Promise.all([
    db.query({ collection: 'referrals', where: [['referrerUid', '==', uid]], limit: 300 }),
    db.get(`referrals/${uid}`),
  ]);
  const l1ids = l1.map((r) => r.id);
  const l2 = [];
  for (let i = 0; i < l1ids.length && i < 300; i += 30) {
    l2.push(...(await db.query({ collection: 'referrals', where: [['referrerUid', 'in', l1ids.slice(i, i + 30)]], limit: 500 })));
  }
  const ids = [...new Set([uid, ...l1ids, ...l2.map((r) => r.id), up && up.referrerUid].filter(Boolean))];
  let names = new Map();
  if (deps.auth && ids.length) { try { names = new Map((await deps.auth.lookup(ids.slice(0, 300))).map((a) => [a.uid, a])); } catch (e) { /* optional */ } }
  const who = (id) => ({ uid: id, name: (names.get(id) || {}).name || '', email: (names.get(id) || {}).email || '' });
  return {
    ok: true,
    me: who(uid),
    upline: up && up.referrerUid ? who(up.referrerUid) : null,
    level1: l1.map((r) => ({ ...who(r.id), subscribed: r.data.subscribed === true, at: toMs(r.data.at || r.data.createdAt) })),
    level2: l2.map((r) => ({ ...who(r.id), via: r.data.referrerUid, subscribed: r.data.subscribed === true, at: toMs(r.data.at || r.data.createdAt) })),
  };
}

/* ═════════════════ Activity feed ═════════════════ */
export async function feed(deps, body = {}) {
  const { db } = deps;
  const n = Math.max(10, Math.min(60, num(body.limit, 40)));
  const L = (collection, f = 'at') => db.query({ collection, orderBy: [[f, 'desc']], limit: n }).catch(() => []);
  const [act, log, pay, req, payout, gifts, coupons] = await Promise.all([
    L('activity'), L('adminLog'), L('payments'), L('requests'), L('payoutRequests'), L('gifts', 'createdAt'), L('couponLedger'),
  ]);
  const out = [];
  for (const r of act) out.push({ id: 'a_' + r.id, type: r.data.type === 'admin' ? 'admin' : (r.data.type || 'event'), title: r.data.summary || r.data.type, uid: r.data.uid || '', by: r.data.by || '', detail: r.data.platform || r.data.build || '', at: toMs(r.data.at) });
  for (const r of log) if (r.data.via !== 'console') out.push({ id: 'l_' + r.id, type: String(r.data.action || '').startsWith('payment') ? 'purchase' : 'admin', title: r.data.action, uid: r.data.target || '', by: r.data.email || r.data.uid || '', detail: r.data.detail ? Object.entries(r.data.detail).map(([k, v]) => `${k}: ${typeof v === 'object' ? JSON.stringify(v) : v}`).join(' · ').slice(0, 160) : '', at: toMs(r.data.at) });
  for (const r of pay) out.push({ id: 'p_' + r.id, type: 'purchase', title: `${TIERS[r.data.tier] || r.data.productId || 'Purchase'} ${r.data.billing || ''}`.trim(), uid: r.data.uid || '', by: r.data.source || 'play', detail: r.data.orderId || '', at: toMs(r.data.at) });
  for (const r of req) out.push({ id: 'r_' + r.id, type: 'request', title: `Request: ${r.data.word || ''}`, uid: r.data.uid || '', by: r.data.email || r.data.name || '', detail: r.data.status || '', at: toMs(r.data.at) });
  for (const r of payout) out.push({ id: 'o_' + r.id, type: 'payout', title: `Payout ${((num(r.data.amountBase)) / 100).toFixed(2)} ${r.data.currency || 'USD'}`, uid: r.data.uid || '', by: r.data.upi || '', detail: r.data.status || '', at: toMs(r.data.at) });
  for (const r of gifts) out.push({ id: 'g_' + r.id, type: 'gift', title: `Gift ${r.data.label || r.data.item || ''} (${r.data.status || ''})`, uid: r.data.senderUid || '', by: r.data.senderName || '', detail: r.data.code || r.id, at: toMs(r.data.redeemedAt || r.data.createdAt) });
  for (const r of coupons) out.push({ id: 'c_' + r.id, type: 'coupon', title: `Coupon ${r.data.rarity || ''} ${r.data.coins ? '+' + r.data.coins + ' coins' : ''}`.trim(), uid: r.data.uid || '', by: '', detail: '', at: toMs(r.data.at) });
  out.sort((a, b) => b.at - a.at);
  return { ok: true, rows: out.slice(0, n * 3) };
}

/* ═════════════════ UI assets ═════════════════ */
export async function uiAssets(deps, body = {}) {
  const prefix = str(body.prefix, 80) || 'ui/';
  if (!/^(ui|images|video|audio)\//.test(prefix)) throw bad('Only ui/, images/, video/ or audio/ can be listed.');
  const fromOverrides = (await deps.db.query({ collection: 'ui_overrides', limit: 1000 }).catch(() => []))
    .map((r) => r.data.url).filter((u) => typeof u === 'string' && u.startsWith('http'));
  if (!deps.r2) return { ok: true, items: [], overrides: [...new Set(fromOverrides)], missing: deps.r2Missing || [] };
  const items = await deps.r2(prefix);
  const ext = str(body.ext, 8).toLowerCase();
  return { ok: true, items: items.filter((x) => !ext || x.key.toLowerCase().endsWith('.' + ext)), overrides: [...new Set(fromOverrides)], missing: [] };
}

export const ACTIONS = {
  stats, users: listUsers, user: userProfile,
  'grant-sub': grantSub, 'extend-sub': extendSub, 'revoke-sub': revokeSub,
  'adjust-coins': adjustCoins, block: setBlocked, restrict: setRestrictions, 'reset-streak': resetStreak,
  message: messageUser, helper: setHelper,
  'fulfil-request': fulfilRequest, broadcast,
  'payout-decide': decidePayout, 'gift-codes': createGiftCodes, 'gift-void': voidGift,
  earn: earnOverview, network, feed, 'ui-assets': uiAssets,
};
