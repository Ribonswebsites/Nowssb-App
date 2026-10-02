/* Admin-only economy actions (the admin panel calls these). */
import { DAY } from './rules.js';
import { fail, inTx, notify } from './core.js';
import { reverseSale } from './sales.js';
import { adminPayout } from './earn.js';

export async function isAdmin(db, uid, claims) {
  if (claims && claims.admin === true) return true;
  const a = await db.get(`admins/${uid}`);
  return a.exists;
}

/** Monthly top-seller pool: pct of the month's Net, split by words among the top N. */
export async function adminMonthlyPool(ctx, adminUid, data) {
  const month = String((data && data.month) || '').replace(/[^0-9]/g, '').slice(0, 6);
  if (month.length !== 6) fail('month = YYYYMM', 400, 'invalid-argument');
  return inTx(ctx, async (s) => {
    const E = s.cfg.earn;
    const lb = await s.doc(`leaderboards/sellers_${month}`);
    if (!lb || !lb.entries) fail('No sales that month.');
    if (lb.poolPaidAt) fail('The pool for that month was paid.', 400, 'already-exists');
    const rows = Object.entries(lb.entries).map(([uid, e]) => ({ uid, ...e }));
    const totalNet = rows.reduce((a, r) => a + (r.net || 0), 0);
    const pool = Math.floor(totalNet * E.monthlyPoolPct) ; // paise: net INR * pct% * 100 = net * pct
    const top = rows.filter((r) => r.words > 0).sort((a, b) => b.words - a.words).slice(0, E.monthlyPoolTop);
    const words = top.reduce((a, r) => a + r.words, 0);
    const out = [];
    for (const r of top) {
      const paise = Math.floor((pool * r.words) / (words || 1));
      if (paise <= 0) continue;
      s.append('commissionLedger', { uid: r.uid, type: 'pool', paise, availableAt: s.now + s.cfg.lock.holdDays * DAY, status: 'pending', note: `Top seller pool ${month}`, month });
      notify(s, r.uid, 'Top seller pool', `₹${(paise / 100).toFixed(2)} from the ${month.slice(0, 4)}-${month.slice(4)} pool (pending 30 days).`, 'earn');
      out.push({ uid: r.uid, inr: paise / 100 });
    }
    const e = await s.edit(`leaderboards/sellers_${month}`);
    e.poolPaidAt = s.now; e.poolPaidBy = adminUid; e.poolINR = pool / 100;
    s.append('adminLog', { type: 'monthly_pool', month, by: adminUid, poolINR: pool / 100 });
    return { poolINR: pool / 100, paid: out };
  });
}
export async function adminReverse(ctx, adminUid, data) {
  const orderId = String((data && data.orderId) || '');
  if (!orderId) fail('orderId', 400, 'invalid-argument');
  return reverseSale(ctx, orderId, 'admin:' + String((data && data.reason) || 'refund').slice(0, 60));
}
export { adminPayout };
