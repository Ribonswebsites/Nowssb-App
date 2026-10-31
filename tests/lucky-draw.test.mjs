import test from 'node:test';
import assert from 'node:assert/strict';
import { DEFAULT_ECONOMY, deepMerge } from '../functions/_lib/economy/config.js';
import { ACTIONS } from '../functions/api/economy/[action].js';
import { drawCfg, rollWins, firstNameInitial, dayWindow, reviewDrawReview } from '../functions/_lib/economy/draw.js';
import { rand } from '../functions/_lib/economy/rules.js';

/** Small in-memory stand-in for FsDb (get / query / tx). */
class MemDb {
  constructor() { this.m = new Map(); }
  async get(p) { return this.m.has(p) ? { exists: true, data: structuredClone(this.m.get(p)) } : { exists: false, data: null }; }
  async query(col, where = [], { limit = 100, orderBy = null } = {}) {
    let rows = [...this.m].filter(([p]) => { const s = p.split('/'); return s.length % 2 === 0 && s[s.length - 2] === col; })
      .map(([p, d]) => ({ id: p.split('/').pop(), path: p, data: structuredClone(d) }));
    for (const [f, op, v] of where) rows = rows.filter((r) => ({ '==': r.data[f] === v, '<': r.data[f] < v, '>': r.data[f] > v })[op]);
    if (orderBy) rows.sort((a, b) => (a.data[orderBy[0]] - b.data[orderBy[0]]) * (orderBy[1] === 'desc' ? -1 : 1));
    return rows.slice(0, limit);
  }
  async tx(fn) {
    const w = [];
    const t = { get: (p) => this.get(p), set: (p, o, { merge } = {}) => w.push(['set', p, o, merge]), create: (p, o) => w.push(['create', p, o]) };
    const out = await fn(t);
    for (const [k, p] of w) if (k === 'create' && this.m.has(p)) throw Object.assign(new Error('exists'), { code: 'already-exists' });
    for (const [k, p, o, merge] of w) this.m.set(p, merge ? { ...(this.m.get(p) || {}), ...structuredClone(o) } : structuredClone(o));
    return out;
  }
}
const mk = (over = {}) => {
  const db = new MemDb();
  const cfg = deepMerge(DEFAULT_ECONOMY, over);
  let now = Date.parse('2026-10-31T06:00:00Z');
  return { db, ctx: () => ({ db, cfg, now, env: {} }), tick: (ms) => { now += ms; } };
};

test('odds are 1 in 150 by default and the roll uses that threshold', () => {
  const d = drawCfg(DEFAULT_ECONOMY);
  assert.equal(d.numerator, 1); assert.equal(d.denominator, 150);
  assert.equal(rollWins(0, d), true);
  assert.equal(rollWins(1 / 150 - 1e-9, d), true);
  assert.equal(rollWins(1 / 150, d), false);
  assert.equal(rollWins(0.5, d), false);
});

test('crypto rand gives roughly 1 in 150 over many rolls', () => {
  const d = drawCfg(DEFAULT_ECONOMY);
  let wins = 0; const n = 300000;
  for (let i = 0; i < n; i++) if (rollWins(rand(), d)) wins++;
  assert.ok(wins > n / 150 * 0.85 && wins < n / 150 * 1.15, `wins ${wins}`);
});

test('status, one entry per user per day, repeat is safe, new day reopens', async () => {
  const { ctx, tick } = mk();
  const s = await ACTIONS.drawStatus(ctx(), 'u1', {});
  assert.equal(s.entered, false); assert.equal(s.result, null); assert.equal(s.odds.text, 'About 1 in 150');
  assert.ok(s.prizes.some((p) => p.kind === 'coupon') && s.prizes.some((p) => p.kind === 'gift'));
  const e1 = await ACTIONS.drawEnter(ctx(), 'u1', { drawId: s.drawId });
  assert.equal(e1.entered, true); assert.equal(typeof e1.result.won, 'boolean');
  const e2 = await ACTIONS.drawEnter(ctx(), 'u1', { drawId: s.drawId });
  assert.deepEqual(e2.result, e1.result);
  await assert.rejects(ACTIONS.drawEnter(ctx(), 'u1', { drawId: 'd19990101' }), /closed/);
  tick(86400e3);
  const s2 = await ACTIONS.drawStatus(ctx(), 'u1', {});
  assert.notEqual(s2.drawId, s.drawId); assert.equal(s2.entered, false);
});

test('a win credits a coupon or gift box, lists the winner, and the review flow works', async () => {
  const { db, ctx } = mk({ draw: { numerator: 149, denominator: 150 } }); // near-certain win for the test
  let win = null;
  for (let i = 0; i < 20 && !win; i++) { const r = await ACTIONS.drawEnter(ctx(), 'w' + i, {}, { name: 'Asha Rao' }); if (r.result.won) win = { uid: 'w' + i, r }; }
  assert.ok(win, 'someone won');
  const claimId = win.r.result.claimId;
  const coupons = await db.query('coupons'); const boxes = await db.query('boxes');
  const mine = [...coupons, ...boxes].filter((x) => x.path.startsWith(`users/${win.uid}/`));
  assert.equal(mine.length, 1, 'prize credited');
  const list = await ACTIONS.drawWinners(ctx(), 'anyone', { limit: 50 });
  const row = list.winners.find((w) => w.id === claimId);
  assert.ok(row); assert.equal(row.displayName, 'A NowssB member'); assert.equal(row.review, undefined);
  await assert.rejects(ACTIONS.drawReview(ctx(), 'someone-else', { claimId, text: 'nice' }), /Only the winner/);
  await assert.rejects(ACTIONS.drawReview(ctx(), win.uid, { claimId, text: 'x'.repeat(281) }), /280/);
  const rv = await ACTIONS.drawReview(ctx(), win.uid, { claimId, text: 'Loved the gift!', stars: 5 });
  assert.equal(rv.status, 'pending');
  assert.equal((await ACTIONS.drawWinners(ctx(), 'a', {})).winners.find((w) => w.id === claimId).review, undefined);
  await reviewDrawReview(ctx(), 'admin', { claimId, approve: true });
  assert.deepEqual((await ACTIONS.drawWinners(ctx(), 'a', {})).winners.find((w) => w.id === claimId).review, { text: 'Loved the gift!', stars: 5 });
});

test('showName consent gives "First L."; daily winner ceiling holds', async () => {
  assert.equal(firstNameInitial('Asha Kumari Rao'), 'Asha R.'); assert.equal(firstNameInitial(''), '');
  const { db, ctx } = mk({ draw: { numerator: 149, denominator: 150, maxWinnersPerDay: 2 } });
  for (let i = 0; i < 10; i++) await ACTIONS.drawEnter(ctx(), 'c' + i, { showName: true }, { name: 'Ravi Kumar' });
  const winners = await db.query('drawWinners');
  assert.equal(winners.length, 2);
  assert.ok(winners.every((w) => w.data.displayName === 'Ravi K.'));
});

test('day window follows the configured offset', () => {
  const { start, end } = dayWindow(Date.parse('2026-10-31T06:00:00Z'), { dayOffsetMinutes: 330 });
  assert.equal(new Date(start).toISOString(), '2026-10-30T18:30:00.000Z'); assert.equal(end - start, 86400e3);
});
