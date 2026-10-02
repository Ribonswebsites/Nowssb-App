/* The purchase pipeline. Runs only after Google Play has confirmed a real
   payment (/api/play/product, /api/play/verify, RTDN). One transaction per
   order id (idempotent): items to the buyer, buyer coins/scratch, the link
   holder's commission through the money lock, both paid legs, word credit,
   rank and targets, Partner points, leaderboards. A refund or chargeback
   runs reverseSale: every row gets an opposite row, nothing is edited. */
import { DAY, dayIndex, moneyLock, partnerPointsFor, standing, targetsCrossed, drawWeighted, resolvePrize } from './rules.js';
import { P, cleanId, fail, grantExtra, grantPrize, inTx, issueScratch, moveCoins, newId, notify, wallet } from './core.js';
import { standingOf, words90 } from './earn.js';
import { holderOf } from './reference.js';
import { afterPurchaseRarity } from './coupons.js';
import { createGiftCard, voidGiftForOrder } from './gifts.js';

const WORDISH = ['word', 'meaning', 'stage', 'signature'];
export function kindOfBagItem(it) {
  const id = String(it.id || '');
  const k = String(it.kind || '').toLowerCase();
  if (k.includes('meaning')) return 'meaning';
  if (id.startsWith('signature:') || k.startsWith('signature')) return 'signature';
  if (k.includes('bundle')) return 'bundle';
  if (k.includes('stage')) return 'stage';
  if (k.includes('ebook')) return 'ebook';
  return 'word';
}

async function blockReason(s, buyer, owner, cfg) {
  if (!owner) return 'no-link';
  if (owner === buyer) return 'self';
  const bw = (await s.doc(P.wallet(buyer))) || {};
  const ow = (await s.doc(P.wallet(owner))) || {};
  if ((bw.devices || []).some((d) => (ow.devices || []).includes(d))) return 'same-device';
  const bp = (await s.doc(P.payout(buyer))) || {};
  const op = (await s.doc(P.payout(owner))) || {};
  if (bp.upiHash && bp.upiHash === op.upiHash) return 'same-payout';
  const oref = (await s.doc(P.referral(owner))) || {};
  if (oref.lastBoughtVia && oref.lastBoughtVia.uid === buyer && s.now - oref.lastBoughtVia.at < cfg.reference.circleDays * DAY) return 'circle';
  if (cfg.earn.blockTeamPurchases) {
    const bs = (await s.doc(P.seller(buyer))) || {};
    const os = (await s.doc(P.seller(owner))) || {};
    if (os.sponsorUid === buyer || bs.sponsorUid === owner || os.sponsor2Uid === buyer || bs.sponsor2Uid === owner) return 'team';
  }
  return null;
}

/**
 * order: { orderId, buyerUid, productId, kind, items[], words, payINR (ex-tax charged),
 *          taxINR, realFeeINR, planKey, isRenewal, renewalMonths, checkout, purchaseTimeMs }
 */
export async function applySale(ctx, order) {
  const orderId = cleanId(order.orderId);
  return inTx(ctx, async (s) => {
    const cfg = s.cfg;
    const salePath = `sales/${orderId}`;
    if (await s.doc(salePath)) return { already: true, orderId };
    const buyer = order.buyerUid;
    const coinsMoved = [];
    const granted = [];
    const sale = { orderId, buyerUid: buyer, productId: order.productId, kind: order.kind, items: (order.items || []).slice(0, 30), words: order.words || 0, payINR: order.payINR, taxINR: order.taxINR || 0, realFeeINR: order.realFeeINR ?? null, isRenewal: !!order.isRenewal, status: 'cleared', at: s.now, rows: [], points: 0, coins: coinsMoved, test: !!order.test };
    const addCoins = async (uid, n, reason) => { const got = await moveCoins(s, uid, n, reason, { ref: orderId }); if (got) coinsMoved.push({ uid, coins: got }); return got; };

    /* 1 · the buyer gets what they paid for */
    const ck = order.checkout || null;
    if (ck && ck.id) {
      const c = await s.edit(`checkouts/${ck.id}`);
      if (c.status === 'released' && c.coins > 0) await moveCoins(s, buyer, -c.coins, 'reverse:checkout-late', { ref: orderId });
      c.status = 'paid'; c.orderId = orderId; c.paidAt = s.now;
      if (c.couponId) { const cp = await s.edit(`users/${buyer}/coupons/${c.couponId}`); cp.status = 'used'; cp.usedOn = orderId; }
    }
    for (const it of order.items || []) {
      if (it.grant) { granted.push(await grantPrize(s, buyer, it.grant, 'buy:' + order.productId)); continue; }
      if (it.giftCard) { const g = await createGiftCard(s, buyer, it.giftCard, it.meta || {}, orderId); sale.giftCode = g.code; granted.push({ type: 'giftcard', label: g.title, code: g.code }); continue; }
      if (it.paidCard) {
        const card = it.paidCard;
        const d = drawWeighted(card.odds);
        const prize = resolvePrize(d.item.prize);
        const floorCoins = Math.round((card.priceINR * cfg.coinsPerRupee * cfg.coupons.paidValueFloorPct) / 100);
        const sc = await issueScratch(s, buyer, card.id, 'paid', { prize, paid: { cardId: card.id, orderId, priceINR: card.priceINR, floorCoins } });
        sale.scratchId = sc.id;
        const w = await wallet(s, buyer);
        if (w.paidCardMonth !== s.month) { w.paidCardMonth = s.month; w.paidCardSpentINR = 0; }
        w.paidCardSpentINR += card.priceINR;
        granted.push(sc);
        continue;
      }
      if (it.id && it.kind !== 'subscription') {
        s.t.set(`users/${buyer}/owned/${cleanId(it.id)}`, { id: it.id, kind: it.kind, title: it.title || '', orderId, at: s.now, status: 'active' });
        granted.push({ type: 'owned', id: it.id, label: it.title || it.id });
      }
    }

    /* 2 · buyer rewards (coins back, first purchase, bundle bonus, renewal bonus, free card) */
    const B = cfg.rewards.buying;
    const bw = await wallet(s, buyer);
    const isProductReward = !['scratch', 'giftcard'].includes(order.kind);
    if (isProductReward && order.payINR > 0) {
      const pct = B.coinsBackPct + (bw.coinsBackBonusPct || 0) + (order.kind === 'bundle' ? B.bundleBonusPct : 0);
      await addCoins(buyer, Math.round((order.payINR * cfg.coinsPerRupee * pct) / 100), 'coins-back');
      if (!bw.firstPurchaseAt) {
        bw.firstPurchaseAt = s.now;
        await addCoins(buyer, B.firstPurchase.coins, 'first-purchase');
        granted.push(await issueScratch(s, buyer, B.firstPurchase.coupon, 'first-purchase'));
      }
      if (order.isRenewal && B.renewalBonus[order.renewalMonths]) await addCoins(buyer, B.renewalBonus[order.renewalMonths], 'renewal-' + order.renewalMonths);
      if (B.freeScratchAfterPurchase && !order.isRenewal) granted.push(await issueScratch(s, buyer, afterPurchaseRarity(cfg, order.payINR, order.kind === 'subscription'), 'after-purchase'));
    }
    bw.purchases = (bw.purchases || 0) + 1;
    bw.stats.purchases = (bw.stats.purchases || 0) + 1;

    /* 3 · attribution */
    const ref = await s.edit(P.referral(buyer), {});
    const holder = holderOf(ref, cfg, s.now);
    const owner = holder ? holder.ownerUid : null;
    const blocked = await blockReason(s, buyer, owner, cfg);
    sale.ownerUid = owner || null;
    sale.refBlocked = owner ? blocked : null;
    if (holder && !ref.lockedTo && blocked !== 'self') ref.lockedTo = { ...holder, lockedAt: s.now };
    if (holder && WORDISH.includes(order.kind) && ck && ck.friendPct) ref.friendWordBuys = (ref.friendWordBuys || 0) + 1;
    if (owner) ref.lastBoughtVia = { uid: owner, at: s.now };

    if (owner && !blocked) {
      /* 4 · the seller: words, rank, commission through the money lock */
      const before = await standingOf(s, owner);
      const sl = await s.edit(P.seller(owner), {});
      const wBefore = sl.wordsLifetime || 0;
      const credit = order.isRenewal ? 0 : order.words || 0;
      sl.wordsLifetime = Math.round((wBefore + credit) * 100) / 100;
      const di = String(dayIndex(s.now, cfg));
      sl.window = sl.window || {};
      sl.window[di] = (sl.window[di] || 0) + credit;
      for (const k of Object.keys(sl.window)) if (Number(di) - Number(k) > cfg.earn.keepWindowDays + 2) delete sl.window[k];
      if (!sl.firstSaleAt) sl.firstSaleAt = s.now;
      const friendPath = `users/${owner}/friends/${buyer}`;
      const fr = await s.doc(friendPath);
      const bu = (await s.doc(P.user(buyer))) || {};
      if (!fr) { sl.friendsCount = (sl.friendsCount || 0) + 1; s.t.set(friendPath, { name: (bu.displayName || 'Friend').split(' ')[0], firstAt: s.now, purchases: 1, last: s.now }); }
      else s.t.set(friendPath, { purchases: (fr.purchases || 0) + 1, last: s.now }, { merge: true });
      {
        const rr = await s.edit(`referrals/${buyer}`, { referrerUid: owner, at: s.now });
        rr.referrerUid = owner; rr.purchases = (rr.purchases || 0) + 1; rr.lastPurchaseAt = s.now;
        if (order.kind === 'subscription') rr.subscribed = true;
        if (sl.sponsorUid && !rr.level2Uid) rr.level2Uid = sl.sponsorUid;
      }
      if (holder.code) {
        const le = await s.edit(`refLinks/${holder.code}`, { code: holder.code, uid: owner });
        le.sales = (le.sales || 0) + 1;
        if (!fr) le.buyers = (le.buyers || 0) + 1;
      }
      const st = standing({ wordsLifetime: sl.wordsLifetime, words90: words90(sl, s.now, cfg), appointed: sl.appointed || null, fastTrack: sl.fastTrack || null, plan: before.plan, rankSince: sl.rankSince || 0, firstSaleAt: sl.firstSaleAt, now: s.now, cfg });
      if (st.rankIndex > before.st.rankIndex || !sl.rankSince) { sl.rankSince = s.now; if (st.rankIndex > before.st.rankIndex) notify(s, owner, `You are now ${st.title}`, `Your direct rate is ${st.ratePct}% of Net.`, 'earn'); }
      sl.tier = st.title; sl.wordsSoldTotal = sl.wordsLifetime; sl.nextTierTarget = st.nextWords || sl.wordsLifetime;
      const oPay = (await s.doc(P.payout(owner))) || {};
      const countryOk = cfg.countries.earnOpen.includes(String(oPay.country || 'IN').toUpperCase());
      let l1 = null; let l2 = null;
      if (sl.sponsorUid) l1 = await standingOf(s, sl.sponsorUid);
      if (sl.sponsor2Uid) l2 = await standingOf(s, sl.sponsor2Uid);
      const cashOk = cfg.earn.enabled && countryOk && st.canEarn;
      const lock = moneyLock({
        exTaxINR: order.payINR, realFeeINR: order.realFeeINR ?? null, words: credit,
        ownPct: cashOk ? st.ratePct + (order.isRenewal ? 0 : st.fastStartPct) : 0,
        leg1Pct: cashOk && l1 && l1.st.canEarn ? l1.st.leg[0] : 0,
        leg2Pct: cashOk && l2 && l2.st.canEarn ? l2.st.leg[1] : 0,
        renewal: !!order.isRenewal, cfg,
      });
      sale.lock = lock;
      const availableAt = s.now + cfg.lock.holdDays * DAY;
      const row = (uid, type, inr, note) => {
        if (!(inr > 0)) return;
        const id = s.append('commissionLedger', { uid, type, orderId, paise: Math.round(inr * 100), availableAt, status: 'pending', net: lock.net, note });
        sale.rows.push({ id, uid, type, paise: Math.round(inr * 100), availableAt });
        // Admin console view (People · cash, Earn · network). The money itself is commissionLedger.
        s.append('cashLedger', { uid, delta: Math.round(inr * 100), reason: `Commission (${type})`, refId: orderId, held: true, availableAt, mirror: true });
        if (type === 'direct') s.append('referralLedger', { referrerUid: uid, uid: buyer, reason: 'Sale', kind: order.kind, cents: Math.round(inr * 100), orderId });
      };
      row(owner, 'direct', lock.own, `${st.ratePct}%${st.fastStartPct && !order.isRenewal ? ` + ${st.fastStartPct}% fast start` : ''} of ₹${lock.net} Net${order.isRenewal ? ' (renewal)' : ''}`);
      if (l1) row(sl.sponsorUid, 'leg1', lock.leg1, 'Team sale · level 1');
      if (l2) row(sl.sponsor2Uid, 'leg2', lock.leg2, 'Team sale · level 2');
      await addCoins(owner, st.coinsPerSale, 'sale-coins');
      // Targets crossed by this sale.
      sl.targetsHit = sl.targetsHit || [];
      for (const t of targetsCrossed(wBefore, sl.wordsLifetime, cfg)) {
        if (sl.targetsHit.includes(t.words)) continue;
        sl.targetsHit.push(t.words);
        if (cashOk && t.cashINR) row(owner, 'target', t.cashINR, `Target ${t.words} words`);
        if (t.coins) await addCoins(owner, t.coins, 'target-' + t.words);
        if (t.coupon) await issueScratch(s, owner, t.coupon, 'target-' + t.words);
        for (const x of t.extras || []) await grantExtra(s, owner, x, 'target-' + t.words);
        notify(s, owner, `Target reached: ${t.words} words`, cashOk ? `₹${t.cashINR} bonus (pending 30 days), ${t.coins} coins and a ${t.coupon} card.` : `${t.coins} coins and a ${t.coupon} card. Cash bonuses need an own paid plan.`, 'earn');
      }
      // Partner Program points (confirmed after the refund window).
      let pts = 0;
      if (order.kind === 'subscription') pts = order.isRenewal ? 0 : partnerPointsFor('subscription', order.planKey, cfg);
      else for (const it of order.items || []) pts += partnerPointsFor(it.giftCard ? 'giftcard' : it.kind, null, cfg);
      if (pts > 0) {
        const pid = s.append('partnerLedger', { uid: owner, points: pts, kind: order.kind, track: order.kind === 'subscription' ? 'plan' : 'word', orderId, availableAt: s.now + cfg.partner.confirmDays * DAY });
        sale.points = pts; sale.pointsRow = pid;
        const pd = await s.edit(P.partner(owner), {});
        pd.pending = (pd.pending || 0) + pts;
      }
      // Monthly leaderboards.
      const lb = await s.edit(`leaderboards/sellers_${s.month}`, { month: s.month, entries: {} });
      lb.entries = lb.entries || {};
      const oUser = (await s.doc(P.user(owner))) || {};
      const e = lb.entries[owner] || { words: 0, net: 0, name: (oUser.displayName || 'Seller').split(' ')[0] };
      e.words += credit; e.net = Math.round((e.net + lock.net) * 100) / 100;
      lb.entries[owner] = e;
      // Mirror for the existing referral card.
      const oref = await s.edit(P.referral(owner), {});
      oref.paidReferralCount = sl.friendsCount || 0; oref.unitsSold = sl.wordsLifetime;
      notify(s, owner, 'A sale cleared through your link', `${credit ? credit + ' word' + (credit === 1 ? '' : 's') + ' · ' : ''}${lock.own > 0 ? '₹' + lock.own.toFixed(2) + ' pending 30 days' : 'commission needs an own paid plan'}${pts ? ' · ' + pts + ' Partner points' : ''}.`, 'earn', orderId);
    }

    s.create(salePath, sale);
    s.append('adminLog', { type: 'sale', orderId, buyerUid: buyer, ownerUid: owner || null, payINR: order.payINR, blocked: sale.refBlocked || null });
    s.effect({ kind: 'purchase', granted });
    return { orderId, granted, ownerCredited: !!(owner && !blocked) };
  });
}

/** Refund / chargeback / revoke: every row gets its opposite. */
export async function reverseSale(ctx, orderIdRaw, reason = 'refund') {
  const orderId = cleanId(orderIdRaw);
  return inTx(ctx, async (s) => {
    const sale = await s.doc(`sales/${orderId}`);
    if (!sale) return { missing: true };
    if (sale.status === 'reversed') return { already: true };
    const e = await s.edit(`sales/${orderId}`);
    e.status = 'reversed'; e.reversedAt = s.now; e.reverseReason = reason;
    for (const r of sale.rows || []) {
      s.append('commissionLedger', { uid: r.uid, type: 'reversal', orderId, paise: -r.paise, availableAt: r.availableAt, status: 'reversed', note: `Reversed (${reason})` });
    }
    for (const c of sale.coins || []) await moveCoins(s, c.uid, -c.coins, 'reverse', { ref: orderId });
    if (sale.ownerUid && !sale.refBlocked) {
      const sl = await s.edit(P.seller(sale.ownerUid), {});
      const credit = sale.isRenewal ? 0 : sale.words || 0;
      sl.wordsLifetime = Math.max(0, (sl.wordsLifetime || 0) - credit);
      sl.wordsSoldTotal = sl.wordsLifetime;
      const di = String(dayIndex(sale.at, s.cfg));
      if (sl.window && sl.window[di]) sl.window[di] = Math.max(0, sl.window[di] - credit);
      if (sale.points) s.append('partnerLedger', { uid: sale.ownerUid, points: -sale.points, kind: 'reversal', orderId, availableAt: s.now });
      notify(s, sale.ownerUid, 'A sale was refunded', 'The commission, coins and word credit for that order were reversed.', 'earn', orderId);
    }
    for (const it of sale.items || []) if (it.id && !it.grant && !it.giftCard && !it.paidCard) s.t.set(`users/${sale.buyerUid}/owned/${cleanId(it.id)}`, { status: 'revoked', revokedAt: s.now }, { merge: true });
    if (sale.giftCode) await voidGiftForOrder(s, orderId, sale.giftCode);
    if (sale.scratchId) {
      const sc = await s.doc(`users/${sale.buyerUid}/scratchCards/${sale.scratchId}`);
      if (sc && sc.status === 'sealed') s.t.set(`users/${sale.buyerUid}/scratchCards/${sale.scratchId}`, { status: 'void' }, { merge: true });
    }
    s.append('adminLog', { type: 'sale_reversed', orderId, reason });
    return { reversed: true };
  });
}
export { fail, newId };
