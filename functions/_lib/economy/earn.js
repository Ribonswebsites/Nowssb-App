/* NowssB Earn — ranks, team (two paid legs), appointments, balances and
   the manual UPI payout queue. Cash comes only from cleared Play sales
   (sales.js); nothing here creates money. */
import { DAY, dayIndex, partnerLevel, standing } from './rules.js';
import { P, fail, grantExtra, grantPass, grantPrize, inTx, issueScratch, moveCoins, notify, planOf, wallet } from './core.js';
import { sha256Hex } from '../server.js';

export function words90(seller, now, cfg) {
  const di = dayIndex(now, cfg);
  let n = 0;
  for (const [k, v] of Object.entries((seller && seller.window) || {})) if (di - Number(k) < cfg.earn.keepWindowDays) n += Number(v) || 0;
  return n;
}
export async function standingOf(s, uid) {
  const seller = (await s.doc(P.seller(uid))) || {};
  const user = (await s.doc(P.user(uid))) || {};
  const plan = planOf(user, s.now);
  const st = standing({
    wordsLifetime: seller.wordsLifetime || 0, words90: words90(seller, s.now, s.cfg), appointed: seller.appointed || null,
    fastTrack: seller.fastTrack || null, plan, rankSince: seller.rankSince || 0, firstSaleAt: seller.firstSaleAt || 0, now: s.now, cfg: s.cfg,
  });
  return { seller, user, plan, st };
}

/** Balances from the append-only ledger: pending (in the 30-day hold) and available. */
export async function balances(db, uid, now, transaction = null) {
  const rows = await db.query('commissionLedger', [['uid', '==', uid]], { limit: 1000, transaction });
  let pending = 0; let available = 0; let lifetime = 0; let paid = 0;
  const list = [];
  for (const r of rows) {
    const d = r.data;
    if (d.availableAt > now) pending += d.paise; else available += d.paise;
    if (['direct', 'leg1', 'leg2', 'target', 'pool'].includes(d.type)) lifetime += d.paise;
    if (d.type === 'payout' && d.status !== 'rejected') paid += -d.paise;
    list.push({ id: r.id, ...d });
  }
  // A payout the admin console rejected (it writes cashLedger 'Payout returned'
  // with refId = request id) goes back to available, unless already returned here.
  const returned = new Set(list.filter((x) => x.type === 'payout-return').map((x) => x.requestId));
  const cash = await db.query('cashLedger', [['uid', '==', uid]], { limit: 200, transaction }).catch(() => []);
  for (const r of cash) {
    const d = r.data || {};
    if (d.reason !== 'Payout returned' || !d.refId || returned.has(d.refId)) continue;
    const pr = list.find((x) => x.type === 'payout' && x.requestId === d.refId);
    if (!pr) continue;
    returned.add(d.refId);
    available += -pr.paise;
    list.push({ id: r.id, type: 'payout-return', paise: -pr.paise, availableAt: 0, requestId: d.refId, note: 'Payout returned' });
  }
  list.sort((a, b) => (b.at || 0) - (a.at || 0));
  return { pendingPaise: pending, availablePaise: available, lifetimePaise: lifetime, requestedPaise: paid, rows: list };
}

export async function earnSummary(ctx, uid) {
  const bal = await balances(ctx.db, uid, ctx.now);
  const team = await ctx.db.query('team', [], { parent: `users/${uid}`, limit: 100 });
  const invites = await ctx.db.query('appointments', [['toUid', '==', uid]], { limit: 20 });
  const sentInv = await ctx.db.query('appointments', [['fromUid', '==', uid]], { limit: 50 });
  return inTx(ctx, async (s) => {
    const { seller, plan, st } = await standingOf(s, uid);
    const payout = (await s.doc(P.payout(uid))) || {};
    const E = s.cfg.earn;
    // Keep the mirror docs fresh for the screens that listen.
    const p = await s.edit(P.payout(uid), {});
    p.cashBalance = Math.max(0, bal.availablePaise) / 100; p.pendingBalance = bal.pendingPaise / 100; p.lifetimeCents = bal.lifetimePaise;
    const sl = await s.edit(P.seller(uid), {});
    sl.tier = st.title; sl.wordsSoldTotal = seller.wordsLifetime || 0; sl.nextTierTarget = st.nextWords || seller.wordsLifetime || 0;
    const legs = [];
    for (const m of team) {
      const ms = (await s.doc(P.seller(m.id))) || {};
      legs.push({ uid: m.id, name: m.data.name || 'Team member', rank: ms.tier || m.data.rank, words: ms.wordsLifetime || 0, words90: words90(ms, s.now, s.cfg), since: m.data.at, level: m.data.level || 1 });
    }
    const countryOk = s.cfg.countries.earnOpen.includes(String(payout.country || 'IN').toUpperCase());
    return {
      enabled: E.enabled, countryOk,
      standing: st, plan: { active: plan.active, own: plan.own, tier: plan.tier },
      words: seller.wordsLifetime || 0, words90: words90(seller, s.now, s.cfg), friends: seller.friendsCount || 0,
      sponsor: seller.sponsorUid ? { name: seller.sponsorName || 'Your sponsor' } : null,
      ranks: E.ranks, targets: E.targets.map((t) => ({ ...t, reached: (seller.wordsLifetime || 0) >= t.words })),
      balances: { pendingINR: bal.pendingPaise / 100, availableINR: Math.max(0, bal.availablePaise) / 100, lifetimeINR: bal.lifetimePaise / 100, minPayoutINR: E.payout.minINR, payoutDay: E.payout.payoutDay },
      ledger: bal.rows.slice(0, 60).map((r) => ({ id: r.id, type: r.type, inr: r.paise / 100, at: r.at, availableAt: r.availableAt, orderId: r.orderId || '', note: r.note || '', status: r.status || '' })),
      team: legs, invites: invites.filter((i) => i.data.status === 'invited').map((i) => ({ id: i.id, rank: i.data.rank, fromName: i.data.fromName || 'A NowssB officer', at: i.data.at })),
      sentInvites: sentInv.map((i) => ({ id: i.id, rank: i.data.rank, status: i.data.status, toName: i.data.toName || '', at: i.data.at })),
      payoutAccount: { country: payout.country || '', upi: payout.upi ? payout.upi.replace(/^(.{2}).*(@.*)$/, '$1•••$2') : '', legalName: payout.legalName || '', kyc: !!payout.kycOk },
      lock: s.cfg.lock,
    };
  });
}

/* ── appointments (nobody is paid for appointing) ── */
export async function appoint(ctx, uid, data) {
  const code = String((data && data.code) || '').toUpperCase().replace(/[^A-Z0-9]/g, '');
  const rank = String((data && data.rank) || 'assistant');
  return inTx(ctx, async (s) => {
    const { st, seller } = await standingOf(s, uid);
    if (st.provisional) fail('Provisional ranks can’t appoint until the 10-word check is passed.');
    if (!st.appoints.includes(rank)) fail(`${st.title} can appoint: ${st.appoints.join(', ') || 'nobody yet'}.`);
    const link = (await s.doc(`referralCodes/${code}`)) || (await s.doc(`refLinks/${code}`));
    if (!link) fail('Ask them for their NowssB code (Reference · Link Hub).', 404, 'not-found');
    const to = link.uid;
    if (to === uid) fail('You can’t appoint yourself.');
    if (to === seller.sponsorUid || to === seller.sponsor2Uid) fail('You can’t appoint your own sponsor.');
    const toSeller = (await s.doc(P.seller(to))) || {};
    if (toSeller.sponsorUid) fail('That person already has a sponsor.');
    const team = seller.teamCount || 0;
    if (team >= st.teamMax) fail(`Your rank allows a team of ${st.teamMax}.`);
    const id = `${uid}_${to}`;
    const ex = await s.doc(`appointments/${id}`);
    if (ex && ex.status === 'invited') fail('An invite is already waiting for them.');
    const me = (await s.doc(P.user(uid))) || {};
    const them = (await s.doc(P.user(to))) || {};
    s.t.set(`appointments/${id}`, { fromUid: uid, toUid: to, rank, status: 'invited', fromName: me.displayName || me.name || '', toName: them.displayName || them.name || '', at: s.now });
    notify(s, to, 'You were invited to NowssB Earn', `${me.displayName || 'An officer'} invited you as ${s.cfg.earn.ranks.find((r) => r.id === rank).title}. Open Earn · My Team to accept.`, 'earn', id);
    return { invited: true, id };
  });
}
export async function answerAppointment(ctx, uid, data) {
  const id = String((data && data.id) || '');
  const accept = !!(data && data.accept);
  return inTx(ctx, async (s) => {
    const a = await s.doc(`appointments/${id}`);
    if (!a || a.toUid !== uid) fail('Invite not found.', 404, 'not-found');
    if (a.status !== 'invited') fail('This invite was already answered.');
    const e = await s.edit(`appointments/${id}`);
    if (!accept) { e.status = 'declined'; e.answeredAt = s.now; return { declined: true }; }
    const sl = await s.edit(P.seller(uid), {});
    if (sl.sponsorUid) fail('You already have a sponsor.');
    const sponsor = (await s.doc(P.seller(a.fromUid))) || {};
    const sp = await s.edit(P.seller(a.fromUid), {});
    sp.teamCount = (sponsor.teamCount || 0) + 1;
    sl.sponsorUid = a.fromUid; sl.sponsorName = a.fromName || ''; sl.sponsor2Uid = sponsor.sponsorUid || null;
    sl.appointed = { rank: a.rank, at: s.now, wordsAtAppoint: sl.wordsLifetime || 0, by: a.fromUid };
    e.status = 'accepted'; e.answeredAt = s.now;
    const me = (await s.doc(P.user(uid))) || {};
    s.t.set(`users/${a.fromUid}/team/${uid}`, { name: me.displayName || me.name || 'Team member', rank: a.rank, at: s.now, level: 1 });
    if (sponsor.sponsorUid) s.t.set(`users/${sponsor.sponsorUid}/team/${uid}`, { name: me.displayName || 'Team member', rank: a.rank, at: s.now, level: 2, via: a.fromUid });
    notify(s, a.fromUid, 'Your invite was accepted', `${me.displayName || 'They'} joined your team.`, 'earn');
    return { accepted: true, rank: a.rank, provisionalDays: s.cfg.earn.provisionalDays };
  });
}

/* ── payouts: manual UPI queue ── */
const UPI = /^[a-zA-Z0-9._-]{2,256}@[a-zA-Z][a-zA-Z0-9.-]{1,64}$/;
const PAN = /^[A-Z]{5}[0-9]{4}[A-Z]$/;
export async function savePayoutAccount(ctx, uid, data) {
  const country = String((data && data.country) || 'IN').toUpperCase().slice(0, 2);
  const upi = String((data && data.upi) || '').trim();
  const legalName = String((data && data.legalName) || '').trim().slice(0, 80);
  const pan = String((data && data.pan) || '').toUpperCase().trim();
  const method = ['wise', 'paypal'].includes(String(data && data.method)) ? String(data.method) : 'wise';
  const email = String((data && data.email) || '').trim().toLowerCase().slice(0, 120);
  return inTx(ctx, async (s) => {
    const E = s.cfg.earn.payout;
    if (country !== 'IN' && !/^[^@\s]+@[^@\s]+\.[a-z]{2,}$/.test(email)) fail(`Enter the email on your ${method === 'paypal' ? 'PayPal' : 'Wise'} account.`, 400, 'invalid-argument');
    if (country !== 'IN' && legalName.length < 3) fail('Enter your legal name as on that account.', 400, 'invalid-argument');
    if (country === 'IN' && !UPI.test(upi)) fail('Enter a UPI id like name@bank.', 400, 'invalid-argument');
    if (E.requireLegalName && legalName.length < 3 && country === 'IN') fail('Enter your name as on your bank / PAN.', 400, 'invalid-argument');
    if (E.requireTaxIdIN && country === 'IN' && pan && !PAN.test(pan)) fail('PAN looks like ABCDE1234F.', 400, 'invalid-argument');
    const upiHash = upi ? (await sha256Hex('upi|' + upi.toLowerCase())).slice(0, 40) : (email ? (await sha256Hex('mail|' + email)).slice(0, 40) : '');
    if (upiHash) {
      const idDoc = await s.edit(`payoutIdentities/${upiHash}`, { uids: [] });
      idDoc.uids = idDoc.uids || [];
      if (idDoc.uids.length && !idDoc.uids.includes(uid)) fail(upi ? 'This UPI id is already used by another NowssB account.' : 'This payout account is already used by another NowssB account.');
      if (!idDoc.uids.includes(uid)) idDoc.uids.push(uid);
    }
    const p = await s.edit(P.payout(uid), {});
    const rail = country === 'IN' ? (E.rails.IN || 'upi_manual') : (E.rails[country] || (method === 'paypal' ? 'paypal_manual' : (E.rails.default || 'wise_manual')));
    Object.assign(p, { country, upi: country === 'IN' ? upi : '', email: country === 'IN' ? '' : email, method: country === 'IN' ? 'upi' : method, legalName, upiHash, payoutRail: rail, updatedAt: s.now });
    if (pan) p.panLast4 = pan.slice(-4), p.panHash = (await sha256Hex('pan|' + pan)).slice(0, 40);
    p.kycOk = country !== 'IN' ? (!!email && legalName.length >= 3) : (!!upi && legalName.length >= 3 && (!E.requireTaxIdIN || !!pan || !!p.panHash));
    const open = s.cfg.countries.earnOpen.includes(country);
    return { saved: true, kyc: p.kycOk, rail, message: !open ? 'Saved. Payouts are not open in your country yet — your balance waits here.' : country === 'IN' ? 'Saved. Payouts go to this UPI id after a review.' : `Saved. Payouts go to your ${method === 'paypal' ? 'PayPal' : 'Wise'} account after a review.` };
  });
}
export async function requestPayout(ctx, uid) {
  return ctx.db.tx(async (t) => {
    const E = ctx.cfg.earn.payout;
    const pd = await t.get(P.payout(uid));
    const p = pd.data || {};
    if (!p.kycOk) throw Object.assign(new Error(String(p.country || 'IN') === 'IN' ? 'Add your UPI id, legal name and PAN first (Earn · Payouts).' : 'Add your Wise or PayPal email and legal name first (Earn · Payouts).'), { status: 400, code: 'failed-precondition' });
    if (!ctx.cfg.countries.earnOpen.includes(String(p.country || 'IN'))) throw Object.assign(new Error('Payouts are not open in your country yet.'), { status: 400, code: 'failed-precondition' });
    const bal = await balances(ctx.db, uid, ctx.now, t.transaction);
    const amt = bal.availablePaise;
    if (amt < E.minINR * 100) throw Object.assign(new Error(`Payouts start at ₹${E.minINR}. Available now: ₹${(Math.max(0, amt) / 100).toFixed(2)}.`), { status: 400, code: 'failed-precondition' });
    const open = await ctx.db.query('payoutRequests', [['uid', '==', uid], ['status', '==', 'queued']], { limit: 5, transaction: t.transaction });
    if (open.length) throw Object.assign(new Error('A payout is already in the queue.'), { status: 400, code: 'already-exists' });
    const { newId } = await import('./core.js');
    const id = newId(ctx.now, 'po');
    t.create(`payoutRequests/${id}`, { uid, paise: amt, amountBase: amt, currency: 'INR', inr: amt / 100, upi: p.upi || '', email: p.email || '', method: p.method || 'upi', rail: p.payoutRail || 'upi_manual', legalName: p.legalName || '', country: p.country || 'IN', status: 'queued', at: ctx.now, manual: E.launchModeManual });
    t.create(`commissionLedger/${newId(ctx.now, 'cl')}`, { uid, type: 'payout', paise: -amt, availableAt: ctx.now, at: ctx.now, requestId: id, status: 'queued', note: 'Payout requested' });
    t.create(`users/${uid}/notifications/${newId(ctx.now, 'n')}`, { title: 'Payout requested', body: `₹${(amt / 100).toFixed(2)} is in the queue. Payouts go out by ${p.method === 'paypal' ? 'PayPal' : p.method === 'wise' ? 'Wise' : 'UPI'} on the ${E.payoutDay}th after a review.`, kind: 'earn', read: false, at: ctx.now });
    t.set(P.payout(uid), { cashBalance: 0, lastRequestAt: ctx.now }, { merge: true });
    return { requested: true, id, amountINR: amt / 100 };
  });
}
export async function adminPayout(ctx, adminUid, data) {
  const id = String((data && data.id) || '');
  const action = String((data && data.action) || '');
  return ctx.db.tx(async (t) => {
    const r = await t.get(`payoutRequests/${id}`);
    if (!r.exists) throw Object.assign(new Error('Request not found'), { status: 404, code: 'not-found' });
    const d = r.data;
    const { newId } = await import('./core.js');
    const next = { approve: 'approved', reject: 'rejected', paid: 'paid' }[action];
    if (!next) throw Object.assign(new Error('Unknown action'), { status: 400, code: 'invalid-argument' });
    if (d.status === 'paid' || d.status === 'rejected') throw Object.assign(new Error('Already closed'), { status: 400, code: 'failed-precondition' });
    t.set(`payoutRequests/${id}`, { status: next, [`${next}At`]: ctx.now, [`${next}By`]: adminUid, reference: String(data.reference || '').slice(0, 80) }, { merge: true });
    if (next === 'rejected') t.create(`commissionLedger/${newId(ctx.now, 'cl')}`, { uid: d.uid, type: 'payout-return', paise: d.paise, availableAt: ctx.now, at: ctx.now, requestId: id, note: String(data.reason || 'Payout returned').slice(0, 120) });
    const msg = { approved: 'Your payout was approved and goes out on the payout day.', rejected: 'Your payout was returned to your balance: ' + String(data.reason || 'see Earn · Payouts.'), paid: `₹${d.inr} was sent to your ${d.method === 'paypal' ? 'PayPal' : d.method === 'wise' ? 'Wise' : 'UPI'} account.` }[next];
    t.create(`users/${d.uid}/notifications/${newId(ctx.now, 'n')}`, { title: 'Payout ' + next, body: msg, kind: 'earn', read: false, at: ctx.now });
    t.create(`adminLog/${newId(ctx.now, 'al')}`, { type: 'payout_' + next, requestId: id, uid: d.uid, by: adminUid, at: ctx.now });
    return { status: next };
  });
}

/* ── Partner Program ── */
export async function partnerSummary(ctx, uid) {
  const rows = await ctx.db.query('partnerLedger', [['uid', '==', uid]], { limit: 1000 });
  let confirmed = 0; let pending = 0;
  const byKind = {};
  for (const r of rows) {
    if (r.data.availableAt <= ctx.now) confirmed += r.data.points; else pending += r.data.points;
    byKind[r.data.track || 'word'] = (byKind[r.data.track || 'word'] || 0) + r.data.points;
  }
  return inTx(ctx, async (s) => {
    const p = await s.edit(P.partner(uid), {});
    const lvl = partnerLevel(confirmed, s.cfg);
    p.points = confirmed; p.pending = pending; p.perk = lvl ? lvl.title : '';
    p.claimed = p.claimed || [];
    return {
      confirmed, pending, level: lvl ? lvl.level : 0, title: lvl ? lvl.title : 'Starter', tracks: byKind,
      levels: s.cfg.partner.levels.map((l) => ({ ...l, reached: confirmed >= l.points, claimed: p.claimed.includes(l.level) })),
      points: s.cfg.partner.points, confirmDays: s.cfg.partner.confirmDays,
      recent: rows.sort((a, b) => b.data.at - a.data.at).slice(0, 30).map((r) => ({ points: r.data.points, kind: r.data.kind, at: r.data.at, confirmed: r.data.availableAt <= s.now })),
    };
  });
}
export async function claimPartnerLevel(ctx, uid, data) {
  const level = Number(data && data.level);
  const rows = await ctx.db.query('partnerLedger', [['uid', '==', uid]], { limit: 1000 });
  const confirmed = rows.reduce((a, r) => a + (r.data.availableAt <= ctx.now ? r.data.points : 0), 0);
  return inTx(ctx, async (s) => {
    const L = s.cfg.partner.levels.find((l) => l.level === level);
    if (!L) fail('Unknown level.', 400, 'invalid-argument');
    if (confirmed < L.points) fail(`${L.title} unlocks at ${L.points} confirmed points (you have ${confirmed}).`);
    const p = await s.edit(P.partner(uid), {});
    p.claimed = p.claimed || [];
    if (p.claimed.includes(level)) return { already: true };
    p.claimed.push(level);
    const items = [];
    if (L.coins) items.push({ type: 'coins', coins: await moveCoins(s, uid, L.coins, 'partner-' + L.id), label: `${L.coins} coins` });
    if (L.giftbox) items.push(await grantPrize(s, uid, { type: 'giftbox', box: L.giftbox }, 'partner'));
    if (L.coupon) items.push(await issueScratch(s, uid, L.coupon, 'partner-' + L.id));
    if (L.badge) items.push(await grantPrize(s, uid, { type: 'badge', id: L.badge }, 'partner'));
    if (L.cosmetic) items.push(await grantPrize(s, uid, { type: 'cosmetic', id: L.cosmetic }, 'partner'));
    if (L.pass) items.push(await grantPass(s, uid, L.pass.tier, L.pass.days, { source: 'partner-' + L.id }));
    const w = await wallet(s, uid);
    if (L.coinsBackPct) w.coinsBackBonusPct = Math.max(w.coinsBackBonusPct || 0, L.coinsBackPct);
    if (L.earlyHours) { w.earlyHours = Math.max(w.earlyHours || 0, L.earlyHours); items.push({ type: 'early', label: `New words ${L.earlyHours} h early` }); }
    if (L.fastTrack) { const sl = await s.edit(P.seller(uid), {}); sl.fastTrack = L.fastTrack; items.push({ type: 'fasttrack', label: 'Fast track to Officer' }); }
    s.effect({ kind: 'partner', level: L.level, title: L.title });
    return { items, title: L.title };
  });
}
export { DAY, grantExtra };
