import test from 'node:test';
import assert from 'node:assert/strict';
import { DEFAULT_ECONOMY, deepMerge } from '../functions/_lib/economy/config.js';
import { ACTIONS } from '../functions/api/economy/[action].js';
import { chatIdFor, usernameFrom } from '../functions/_lib/economy/connect.js';

class MemDb {
  constructor() { this.m = new Map(); }
  async get(p) { return this.m.has(p) ? { exists: true, data: structuredClone(this.m.get(p)) } : { exists: false, data: null }; }
  rows(col, parent = '') {
    return [...this.m].filter(([p]) => { const s = p.split('/'); return s.length % 2 === 0 && s[s.length - 2] === col && (!parent || s.slice(0, -2).join('/') === parent); })
      .map(([p, d]) => ({ id: p.split('/').pop(), path: p, data: structuredClone(d) }));
  }
  async query(col, where = [], { limit = 100, orderBy = null, parent = '' } = {}) {
    let rows = this.rows(col, parent).sort((a, b) => (a.id < b.id ? -1 : 1));
    for (const [f, op, v] of where) rows = rows.filter((r) => (op === '==' ? r.data[f] === v : Array.isArray(r.data[f]) && r.data[f].includes(v)));
    if (orderBy) rows.sort((a, b) => ((a.data[orderBy[0]] || 0) - (b.data[orderBy[0]] || 0)) * (orderBy[1] === 'desc' ? -1 : 1));
    return rows.slice(0, limit);
  }
  async count(col, where = [], { parent = '' } = {}) { return (await this.query(col, where, { parent, limit: 1e9 })).length; }
  async tx(fn) {
    const w = [];
    const t = { get: (p) => this.get(p), set: (p, o, { merge } = {}) => w.push(['set', p, o, merge]), create: (p, o) => w.push(['create', p, o]), delete: (p) => w.push(['del', p]) };
    const out = await fn(t);
    for (const [k, p, o, merge] of w) { if (k === 'del') this.m.delete(p); else this.m.set(p, merge ? { ...(this.m.get(p) || {}), ...structuredClone(o) } : structuredClone(o)); }
    return out;
  }
}
const mk = () => { const db = new MemDb(); const cfg = deepMerge(DEFAULT_ECONOMY, {}); let now = Date.parse('2026-10-31T06:00:00Z'); return { db, ctx: () => ({ db, cfg, now: (now += 1000), env: {} }) }; };
const A = 'userAAAA01', B = 'userBBBB02', C = 'userCCCC03';

test('empty Connect shows nothing invented', async () => {
  const { ctx } = mk();
  const h = await ACTIONS.connectHome(ctx(), A, {});
  assert.equal(h.me, null); assert.deepEqual(h.people, []); assert.deepEqual(h.posts, []);
  assert.equal(h.followerCount, 0); assert.equal(h.followingCount, 0);
  assert.deepEqual((await ACTIONS.connectInbox(ctx(), A, {})).chats, []);
});

test('profiles, follow counts and validation', async () => {
  const { ctx } = mk();
  await assert.rejects(ACTIONS.connectSaveProfile(ctx(), A, { name: ' ' }), /display name/);
  await assert.rejects(ACTIONS.connectSaveProfile(ctx(), A, { name: 'Asha', bio: 'see https://x.y' }), /Links/);
  const p = await ACTIONS.connectSaveProfile(ctx(), A, { name: 'Asha Rao', focus: 'Wellness', bio: 'Hi' }, { picture: 'https://p/a.png' });
  assert.equal(p.profile.username, usernameFrom('Asha Rao', A));
  await ACTIONS.connectSaveProfile(ctx(), B, { name: 'Ben', focus: 'nope' });
  await assert.rejects(ACTIONS.connectFollow(ctx(), A, { targetUid: C }), /not on Connect/);
  await ACTIONS.connectFollow(ctx(), A, { targetUid: B });
  const ha = await ACTIONS.connectHome(ctx(), A, {});
  assert.equal(ha.me.name, 'Asha Rao'); assert.equal(ha.me.avatar, 'https://p/a.png');
  assert.deepEqual(ha.people.map((x) => x.uid), [B]); assert.equal(ha.people[0].focus, 'Sound Healer');
  assert.deepEqual(ha.following, [B]); assert.equal(ha.followingCount, 1);
  assert.equal((await ACTIONS.connectHome(ctx(), B, {})).followerCount, 1);
  await ACTIONS.connectFollow(ctx(), A, { targetUid: B, follow: false });
  assert.equal((await ACTIONS.connectHome(ctx(), B, {})).followerCount, 0);
});

test('chat: send, thread, inbox, blocks', async () => {
  const { db, ctx } = mk();
  await assert.rejects(ACTIONS.connectSend(ctx(), A, { toUid: B, text: 'hi' }), /not on Connect/);
  await ACTIONS.connectSaveProfile(ctx(), B, { name: 'Ben' });
  await assert.rejects(ACTIONS.connectSend(ctx(), A, { toUid: B, text: 'hi' }), /profile first/);
  await ACTIONS.connectSaveProfile(ctx(), A, { name: 'Asha' });
  await assert.rejects(ACTIONS.connectSend(ctx(), A, { toUid: B, text: '  ' }), /Write/);
  await ACTIONS.connectSend(ctx(), A, { toUid: B, text: 'Hello Ben' });
  await ACTIONS.connectSend(ctx(), B, { toUid: A, text: 'Hi Asha' });
  const t = await ACTIONS.connectThread(ctx(), A, { withUid: B });
  assert.equal(t.chatId, chatIdFor(A, B));
  assert.deepEqual(t.messages.map((m) => [m.mine, m.text]), [[true, 'Hello Ben'], [false, 'Hi Asha']]);
  const inbox = await ACTIONS.connectInbox(ctx(), B, {});
  assert.equal(inbox.chats.length, 1); assert.equal(inbox.chats[0].with.name, 'Asha'); assert.equal(inbox.chats[0].lastMine, true);
  assert.ok(db.rows('notifications', `users/${B}`).length >= 1);
  await ACTIONS.blockEchoUser(ctx(), B, { targetUid: A });
  await assert.rejects(ACTIONS.connectSend(ctx(), A, { toUid: B, text: 'again' }), /can’t message/);
  assert.deepEqual((await ACTIONS.connectHome(ctx(), B, {})).people, []);
});

test('feed uses real posts and likes', async () => {
  const { db, ctx } = mk();
  await ACTIONS.connectSaveProfile(ctx(), A, { name: 'Asha', focus: 'Beginner' });
  const post = await ACTIONS.connectPost(ctx(), A, { text: 'First session today', image: 'https://evil.example/x.png' });
  const h = await ACTIONS.connectHome(ctx(), B, {});
  assert.equal(h.posts.length, 1); assert.equal(h.posts[0].authorName, 'Asha'); assert.equal(h.posts[0].image, '');
  assert.equal(h.posts[0].liked, false);
  await ACTIONS.connectLike(ctx(), B, { postId: post.id || h.posts[0].id });
  const h2 = await ACTIONS.connectHome(ctx(), B, {});
  assert.equal(h2.posts[0].likes, 1); assert.equal(h2.posts[0].liked, true);
});
