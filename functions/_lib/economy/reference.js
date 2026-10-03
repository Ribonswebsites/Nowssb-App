/* NowssB Reference — one personal link per person per word / plan / meaning,
   the friend discount and fair attribution (first valid link inside the hold
   window, locked at the first purchase). Self, same-device, same-payout and
   circle purchases are blocked from referral pay (checked in sales.js). */
import { DAY, linkCode, skuKey } from './rules.js';
import { P, fail, grantPass, grantPrize, inTx, issueScratch, moveCoins, notify, planOf, wallet } from './core.js';
import { sha256Hex } from '../server.js';

const slugify = (s) => String(s || '').toLowerCase().normalize('NFKD').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 48);

export async function baseCode(uid) { return linkCode(uid, 'any'); }

async function ensureBase(s, uid) {
  const r = await s.edit(P.referral(uid), {});
  if (!r.code) {
    r.code = await baseCode(uid);
    r.createdAt = s.now;
    const lp = `refLinks/${r.code}`;
    if (!(await s.doc(lp))) s.create(lp, { code: r.code, uid, sku: 'any', kind: 'any', itemId: '', title: 'NowssB', slug: 'app', opens: 0, installs: 0, signups: 0, buyers: 0, sales: 0, at: s.now });
    s.create(`referralCodes/${r.code}`, { uid, at: s.now });
  }
  return r;
}

/** Mint (or return) my link for one item. */
export async function getLink(ctx, uid, data) {
  const kind = String((data && data.kind) || 'any').toLowerCase();
  const id = String((data && data.id) || '');
  const title = String((data && data.title) || '').slice(0, 80);
  if (!['any', 'word', 'meaning', 'plan', 'subscription', 'bundle', 'signature', 'ebook', 'stage', 'giftcard'].includes(kind)) fail('Unknown item kind.', 400, 'invalid-argument');
  return inTx(ctx, async (s) => {
    await ensureBase(s, uid);
    const sku = skuKey(kind, id);
    const code = await linkCode(uid, sku);
    const path = `refLinks/${code}`;
    let l = await s.doc(path);
    const slug = slugify(data && data.slug || title || id) || 'app';
    if (!l) {
      l = { code, uid, sku, kind, itemId: id, title, slug, opens: 0, installs: 0, signups: 0, buyers: 0, sales: 0, at: s.now };
      s.create(path, l);
      if (!(await s.doc(`referralCodes/${code}`))) s.create(`referralCodes/${code}`, { uid, sku, at: s.now });
    }
    const base = s.cfg.reference.linkBase;
    return { code, url: `${base}${l.slug || slug}?r=${code}`, sku, title: l.title || title };
  });
}

/** Phone registers its install id (hashed) so same-device referrals are blocked. */
export async function registerDevice(ctx, uid, data) {
  const raw = String((data && data.installId) || '');
  if (raw.length < 8) return { ok: true };
  const h = (await sha256Hex('nowssb-device|' + raw)).slice(0, 40);
  return inTx(ctx, async (s) => {
    const d = await s.edit(`devices/${h}`, { uids: [], at: s.now });
    d.uids = d.uids || [];
    if (!d.uids.includes(uid)) d.uids = [...d.uids, uid].slice(-20);
    const w = await wallet(s, uid);
    w.devices = w.devices || [];
    if (!w.devices.includes(h)) w.devices = [...w.devices, h].slice(-10);
    return { ok: true, device: h.slice(0, 6) };
  });
}

/**
 * Attach a referral code to the signed-in account (install referrer,
 * a tapped link, or typed). First valid link in the hold window wins
 * (or the latest when attribution = 'last'); a lock never moves.
 */
export async function attachReferral(ctx, uid, data) {
  const code = String((data && data.code) || '').toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 20);
  const source = String((data && data.source) || 'typed').slice(0, 20);
  if (!code) fail('Enter a code.', 400, 'invalid-argument');
  if (data && data.installId) await registerDevice(ctx, uid, data).catch(() => null);
  return inTx(ctx, async (s) => {
    const R = s.cfg.reference;
    let link = await s.doc(`refLinks/${code}`);
    if (!link) {
      const legacy = await s.doc(`referralCodes/${code}`);
      if (!legacy) fail('That code was not found.', 404, 'not-found');
      link = { code, uid: legacy.uid, sku: legacy.sku || 'any' };
    }
    if (link.uid === uid) fail('That is your own link. Share it with a friend instead.');
    const w = await wallet(s, uid);
    const ownerWallet = (await s.doc(P.wallet(link.uid))) || {};
    const shared = (w.devices || []).some((d) => (ownerWallet.devices || []).includes(d));
    if (shared) fail('This link belongs to an account on the same phone. Referral rewards need a different person.');
    const r = await s.edit(P.referral(uid), {});
    if (r.lockedTo) return { attached: false, locked: true, note: 'Your first purchase already locked a link to your account.' };
    const holdValid = r.hold && s.now - r.hold.at < R.holdDays * DAY;
    if (holdValid && R.attribution === 'first' && r.hold.code !== code) return { attached: false, held: true, note: 'A friend’s link is already holding your account.' };
    const fresh = !holdValid || r.hold.code !== code;
    r.hold = { code, ownerUid: link.uid, sku: link.sku || 'any', at: s.now, source };
    r.referredBy = link.uid;
    if (fresh) {
      const rr = await s.edit(`referrals/${uid}`, { referrerUid: link.uid, at: s.now });
      if (!rr.purchases) { rr.referrerUid = link.uid; rr.code = code; rr.source = source; rr.heldAt = s.now; rr.subscribed = !!rr.subscribed; }
      s.append('referralLedger', { referrerUid: link.uid, uid, reason: 'Link attached', code, cents: 0 });
      const le = await s.edit(`refLinks/${code}`, link);
      if (source === 'install') le.installs = (le.installs || 0) + 1;
      const user = (await s.doc(P.user(uid))) || {};
      const created = Date.parse(user.createdAt || '') || w.createdAt || s.now;
      if (s.now - created < 2 * DAY) le.signups = (le.signups || 0) + 1;
      notify(s, link.uid, 'A friend joined with your link', 'You earn when they buy — the link holds them for 30 days.', 'reference');
    }
    // Welcome set for the friend: new accounts only (same 14 days as the
    // welcome ticket), once per account and device.
    const acct = (await s.doc(P.user(uid))) || {};
    // Oldest of the server wallet date and the profile date: editing the
    // profile can only make an account look older, never newer.
    const born = Math.min(w.createdAt || s.now, Date.parse(acct.createdAt || '') || Infinity);
    const young = s.now - born <= 14 * DAY;
    if (r.newAccount == null) r.newAccount = young;
    let welcome = null;
    if (!r.welcomeAt && young) {
      let deviceUsed = false;
      for (const d of w.devices || []) {
        const dv = await s.doc(`devices/${d}`);
        if (dv && dv.welcomeAt && dv.welcomeUid !== uid) deviceUsed = true;
      }
      if (!(R.welcome.oncePerDevice && deviceUsed)) {
        r.welcomeAt = s.now;
        for (const d of w.devices || []) { const dv = await s.edit(`devices/${d}`, { uids: [] }); dv.welcomeAt = s.now; dv.welcomeUid = uid; }
        const items = [{ type: 'coins', coins: await moveCoins(s, uid, R.welcome.coins, 'welcome'), label: `${R.welcome.coins} coins` }];
        items.push(await issueScratch(s, uid, R.welcome.scratch, 'welcome'));
        const user = (await s.doc(P.user(uid))) || {};
        if (R.welcome.ebookDaysIfTrialEnded && !planOf(user, s.now).active) items.push(await grantPass(s, uid, 'ebook', R.welcome.ebookDaysIfTrialEnded, { source: 'welcome' }));
        welcome = items;
      }
    }
    return { attached: true, holdDays: R.holdDays, discount: R.friendDiscount, welcome };
  });
}

/** Public, unauthenticated: a link was opened (website / preview page). */
export async function countOpen(db, cfg, code, ipHash, now = Date.now()) {
  const c = String(code || '').toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 20);
  if (!c) return { ok: false };
  return db.tx(async (t) => {
    const l = await t.get(`refLinks/${c}`);
    if (!l.exists) return { ok: false };
    const day = new Date(now + 330 * 60e3).toISOString().slice(0, 10).replace(/-/g, '');
    const rp = `refOpens/${day}_${ipHash.slice(0, 24)}`;
    const r = await t.get(rp);
    const n = (r.exists ? r.data.n : 0) + 1;
    t.set(rp, { n, at: now });
    if (n <= cfg.reference.openRatePerIpPerDay) t.set(`refLinks/${c}`, { opens: (l.data.opens || 0) + 1 }, { merge: true });
    return { ok: true, title: l.data.title || '', kind: l.data.kind, itemId: l.data.itemId || '' };
  });
}

export async function linkHub(ctx, uid) {
  const links = await ctx.db.query('refLinks', [['uid', '==', uid]], { limit: 200 });
  const friends = await ctx.db.query('friends', [], { parent: `users/${uid}`, limit: 200 });
  return inTx(ctx, async (s) => {
    const r = await ensureBase(s, uid);
    const seller = (await s.doc(P.seller(uid))) || {};
    const R = s.cfg.reference;
    const claimed = r.ladderClaimed || [];
    const n = seller.friendsCount || 0;
    return {
      code: r.code,
      url: `${R.linkBase}app?r=${r.code}`,
      hold: r.hold && s.now - r.hold.at < R.holdDays * DAY ? { days: Math.ceil((r.hold.at + R.holdDays * DAY - s.now) / DAY) } : null,
      locked: !!r.lockedTo,
      links: links.map((l) => ({ code: l.id, title: l.data.title, kind: l.data.kind, itemId: l.data.itemId, url: `${R.linkBase}${l.data.slug || 'app'}?r=${l.id}`, opens: l.data.opens || 0, installs: l.data.installs || 0, signups: l.data.signups || 0, buyers: l.data.buyers || 0, sales: l.data.sales || 0 })).sort((a, b) => b.buyers - a.buyers || b.opens - a.opens),
      friends: friends.map((f) => ({ name: f.data.name || 'Friend', purchases: f.data.purchases || 0, firstAt: f.data.firstAt || 0 })),
      friendsCount: n,
      ladder: R.sharerLadder.map((st) => ({ ...st, reached: n >= st.friends, claimed: claimed.includes(st.friends) })),
      discount: R.friendDiscount,
    };
  });
}

export async function claimSharerStep(ctx, uid, data) {
  const friends = Number(data && data.friends);
  return inTx(ctx, async (s) => {
    const st = s.cfg.reference.sharerLadder.find((x) => x.friends === friends);
    if (!st) fail('Unknown step.', 400, 'invalid-argument');
    const seller = (await s.doc(P.seller(uid))) || {};
    if ((seller.friendsCount || 0) < st.friends) fail(`${st.friends} friends need to buy through your links first.`);
    const r = await s.edit(P.referral(uid), {});
    r.ladderClaimed = r.ladderClaimed || [];
    if (r.ladderClaimed.includes(st.friends)) return { already: true };
    r.ladderClaimed.push(st.friends);
    const items = [];
    if (st.coins) items.push({ type: 'coins', coins: await moveCoins(s, uid, st.coins, 'sharer-' + st.friends), label: `${st.coins} coins` });
    if (st.coupon) items.push(await issueScratch(s, uid, st.coupon, 'sharer-' + st.friends));
    if (st.cosmetic) items.push(await grantPrize(s, uid, { type: 'cosmetic', id: st.cosmetic }, 'sharer'));
    if (st.badge) items.push(await grantPrize(s, uid, { type: 'badge', id: st.badge }, 'sharer'));
    if (st.passOr) items.push(await grantPass(s, uid, st.passOr.tier, st.passOr.days, { source: 'sharer-' + st.friends }));
    if (st.early) { const w = await wallet(s, uid); w.earlyHours = Math.max(w.earlyHours || 0, st.early); items.push({ type: 'early', label: `New words ${st.early} h early` }); }
    return { items };
  });
}

/** The buyer's link holder for a purchase (or null) and whether the friend discount applies. */
export function holderOf(ref, cfg, now) {
  if (!ref) return null;
  if (ref.lockedTo) return ref.lockedTo;
  if (ref.hold && now - ref.hold.at < cfg.reference.holdDays * DAY) return ref.hold;
  return null;
}
export function friendDiscountPct(ref, kind, cfg, now) {
  const h = holderOf(ref, cfg, now);
  if (!h) return 0;
  const F = cfg.reference.friendDiscount;
  if (['word', 'meaning', 'stage', 'signature'].includes(kind) && (ref.friendWordBuys || 0) < F.wordFirstN) return F.wordPct;
  return 0;
}
