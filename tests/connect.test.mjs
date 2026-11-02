import test from 'node:test';
import assert from 'node:assert/strict';
import { DEFAULT_ECONOMY, deepMerge } from '../functions/_lib/economy/config.js';
import { ACTIONS } from '../functions/api/economy/[action].js';
import { hasProfanity, imageOk, POSTS_PER_DAY } from '../functions/_lib/economy/connect.js';

class MemDb {
  constructor() { this.m = new Map(); }
  async get(p) { return this.m.has(p) ? { exists: true, data: structuredClone(this.m.get(p)) } : { exists: false, data: null }; }
  rows(col, parent = '') {
    return [...this.m].filter(([p]) => { const s = p.split('/'); return s.length % 2 === 0 && s[s.length - 2] === col && (!parent || s.slice(0, -2).join('/') === parent); })
      .map(([p, d]) => ({ id: p.split('/').pop(), path: p, data: structuredClone(d) }));
  }
  async query(col, where = [], { limit = 100, parent = '' } = {}) {
    let rows = this.rows(col, parent);
    for (const [f, op, v] of where) rows = rows.filter((r) => op === '==' && r.data[f] === v);
    return rows.slice(0, limit);
  }
  async tx(fn) {
    const w = [];
    const t = { get: (p) => this.get(p), set: (p, o, { merge } = {}) => w.push(['set', p, o, merge]), create: (p, o) => w.push(['create', p, o]), delete: (p) => w.push(['del', p]) };
    const out = await fn(t);
    for (const [k, p, o, merge] of w) { if (k === 'del') this.m.delete(p); else this.m.set(p, merge ? { ...(this.m.get(p) || {}), ...structuredClone(o) } : structuredClone(o)); }
    return out;
  }
}
const mk = (start = '2026-11-02T06:00:00Z') => { const db = new MemDb(); const cfg = deepMerge(DEFAULT_ECONOMY, {}); const clock = { now: Date.parse(start) }; return { db, clock, ctx: () => ({ db, cfg, now: (clock.now += 1000), env: {} }) }; };
const A = 'userAAAA01', B = 'userBBBB02', C = 'userCCCC03', D = 'userDDDD04';

test('old Instagram-style Connect actions are gone', () => {
  for (const a of ['connectSaveProfile', 'connectHome', 'connectFollow', 'connectPost', 'connectLike', 'connectInbox', 'connectThread', 'connectSend']) assert.equal(ACTIONS[a], undefined, a);
  for (const a of ['boardDay', 'boardPost', 'boardFelt', 'boardReport']) assert.equal(typeof ACTIONS[a], 'function', a);
});

test('empty board invents nothing', async () => {
  const { ctx } = mk();
  const b = await ACTIONS.boardDay(ctx(), A, {});
  assert.deepEqual(b.posts, []); assert.equal(b.readOnly, false); assert.equal(b.postsLeft, POSTS_PER_DAY); assert.deepEqual(b.days, []);
});

test('anonymous posts, newest first, no author identity leaks', async () => {
  const { ctx } = mk();
  await ACTIONS.boardPost(ctx(), A, { text: 'Felt like rain on a hot day', feeling: 'calm', word: 'TEJAS', meaning: 'radiance' });
  await ACTIONS.boardPost(ctx(), B, { text: 'Heavy, then lighter', feeling: 'nope' });
  const b = await ACTIONS.boardDay(ctx(), C, {});
  assert.equal(b.word, 'TEJAS'); assert.equal(b.posts.length, 2);
  assert.equal(b.posts[0].text, 'Heavy, then lighter'); assert.equal(b.posts[0].feeling, '');
  assert.equal(b.posts[1].feeling, 'calm');
  assert.ok(!JSON.stringify(b).includes(A)); assert.ok(!JSON.stringify(b).includes(B));
  assert.equal((await ACTIONS.boardDay(ctx(), A, {})).posts[1].mine, true);
});

test('validation: length, links, profanity, image ownership', async () => {
  const { ctx } = mk();
  await assert.rejects(ACTIONS.boardPost(ctx(), A, { text: 'x'.repeat(281) }), /280/);
  await assert.rejects(ACTIONS.boardPost(ctx(), A, { text: ' ' }), /thought/);
  await assert.rejects(ACTIONS.boardPost(ctx(), A, { text: 'see www.spam.com' }), /Links/);
  await assert.rejects(ACTIONS.boardPost(ctx(), A, { text: 'this is sh1t' }), /gentle/);
  await assert.rejects(ACTIONS.boardPost(ctx(), A, { text: 'ok', image: `connect/${B}/1730000000000.jpg` }), /image/);
  const p = await ACTIONS.boardPost(ctx(), A, { image: `connect/${A}/1730000000000.jpg` });
  assert.equal(p.post.image, `connect/${A}/1730000000000.jpg`);
  assert.equal(hasProfanity('Shall we pass the class'), false);
  assert.equal(imageOk(A, 'https://evil/x.jpg'), false);
});

test('three posts a day, then a new day resets and yesterday is read-only', async () => {
  const { ctx, clock } = mk();
  for (let i = 0; i < 3; i++) await ACTIONS.boardPost(ctx(), A, { text: `thought ${i}` });
  await assert.rejects(ACTIONS.boardPost(ctx(), A, { text: 'one more' }), /3 thoughts/);
  const y = (await ACTIONS.boardDay(ctx(), A, {})).today;
  clock.now += 24 * 3600e3;
  const t = await ACTIONS.boardDay(ctx(), A, {});
  assert.notEqual(t.today, y); assert.deepEqual(t.posts, []); assert.equal(t.postsLeft, 3); assert.deepEqual(t.days, [y]);
  const old = await ACTIONS.boardDay(ctx(), A, { day: y });
  assert.equal(old.readOnly, true); assert.equal(old.posts.length, 3); assert.equal(old.postsLeft, 0);
  await assert.rejects(ACTIONS.boardFelt(ctx(), B, { day: y, postId: old.posts[0].id }), /read-only/);
  await ACTIONS.boardPost(ctx(), A, { text: 'new day' });
});

test('felt this toggles once per person and counts', async () => {
  const { ctx } = mk();
  const { post } = await ACTIONS.boardPost(ctx(), A, { text: 'soft' });
  assert.equal((await ACTIONS.boardFelt(ctx(), B, { postId: post.id })).felt, 1);
  assert.equal((await ACTIONS.boardFelt(ctx(), C, { postId: post.id, on: true })).felt, 2);
  assert.equal((await ACTIONS.boardFelt(ctx(), C, { postId: post.id, on: true })).felt, 2);
  const b = await ACTIONS.boardDay(ctx(), B, {});
  assert.equal(b.posts[0].felt, 2); assert.equal(b.posts[0].feltByMe, true);
  assert.equal((await ACTIONS.boardFelt(ctx(), B, { postId: post.id })).felt, 1);
});

test('hide is personal; three reports hide for everyone', async () => {
  const { ctx } = mk();
  const { post } = await ACTIONS.boardPost(ctx(), A, { text: 'something odd' });
  await ACTIONS.boardReport(ctx(), B, { postId: post.id, hideOnly: true });
  assert.equal((await ACTIONS.boardDay(ctx(), B, {})).posts.length, 0);
  assert.equal((await ACTIONS.boardDay(ctx(), C, {})).posts.length, 1);
  await ACTIONS.boardReport(ctx(), C, { postId: post.id, reason: 'spam' });
  await ACTIONS.boardReport(ctx(), C, { postId: post.id, reason: 'spam' });
  await ACTIONS.boardReport(ctx(), D, { postId: post.id });
  assert.equal((await ACTIONS.boardDay(ctx(), A, {})).posts.length, 1);
  await ACTIONS.boardReport(ctx(), B, { postId: post.id });
  assert.equal((await ACTIONS.boardDay(ctx(), A, {})).posts.length, 0);
});
