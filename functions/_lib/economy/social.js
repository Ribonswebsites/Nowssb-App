/* Echo Wall + Word Print (the community parts of Rewards). Posts and
   comments are written by the server so counts, rate limits and
   moderation hold. */
import { P, fail, inTx, moveCoins, today, wallet } from './core.js';

const clip = (t, n) => String(t || '').replace(/\s+/g, ' ').trim().slice(0, n);
const LINKY = /(https?:\/\/|www\.|\.com\b|\.in\b|t\.me|wa\.me)/i;

async function nameOf(s, uid) {
  const u = (await s.doc(P.user(uid))) || {};
  return clip(u.displayName || u.name || 'Listener', 40);
}

export async function createEchoPost(ctx, uid, data) {
  const text = clip(data && data.text, 500);
  if (text.length < 2 && !(data && data.imageRef)) fail('Write something first.', 400, 'invalid-argument');
  if (LINKY.test(text)) fail('Links are not allowed on the Echo Wall.');
  return inTx(ctx, async (s) => {
    const d = await today(s, uid);
    if ((d.counts.echo_posts || 0) >= 10) fail('Ten posts a day at most.', 429, 'resource-exhausted');
    d.counts.echo_posts = (d.counts.echo_posts || 0) + 1;
    const id = s.append('echoPosts', { authorUid: uid, authorName: await nameOf(s, uid), text, imageRef: clip(data && data.imageRef, 300), status: 'live', likeCount: 0, commentCount: 0 }, 'ep');
    const w = await wallet(s, uid);
    w.done = w.done || {};
    let coins = 0;
    if (!w.done.echo_first_post) { w.done.echo_first_post = s.now; coins = await moveCoins(s, uid, s.cfg.rewards.actions.echo_first_post.coins, 'act:echo_first_post', { free: true }); }
    return { id, coins };
  });
}
export async function commentOnPost(ctx, uid, data) {
  const postId = String((data && data.postId) || '');
  const text = clip(data && data.text, 300);
  if (!text) fail('Write a comment.', 400, 'invalid-argument');
  if (LINKY.test(text)) fail('Links are not allowed.');
  return inTx(ctx, async (s) => {
    const p = await s.doc(`echoPosts/${postId}`);
    if (!p || p.status !== 'live') fail('Post not found.', 404, 'not-found');
    const blocked = await s.doc(`users/${p.authorUid}/blocks/${uid}`);
    if (blocked) fail('You can’t comment on this post.');
    const d = await today(s, uid);
    if ((d.counts.echo_comments || 0) >= 50) fail('That is enough comments for today.', 429, 'resource-exhausted');
    d.counts.echo_comments = (d.counts.echo_comments || 0) + 1;
    const e = await s.edit(`echoPosts/${postId}`);
    e.commentCount = (e.commentCount || 0) + 1;
    const id = s.append('echoComments', { postId, authorUid: uid, authorName: await nameOf(s, uid), text, status: 'live' }, 'ec');
    return { id };
  });
}
export async function toggleEchoLike(ctx, uid, data) {
  const postId = String((data && data.postId) || '');
  return inTx(ctx, async (s) => {
    const p = await s.doc(`echoPosts/${postId}`);
    if (!p || p.status !== 'live') fail('Post not found.', 404, 'not-found');
    const lp = `echoLikes/${postId}_${uid}`;
    const had = await s.doc(lp);
    const e = await s.edit(`echoPosts/${postId}`);
    if (had && had.on) { s.t.set(lp, { uid, postId, on: false, at: s.now }); e.likeCount = Math.max(0, (e.likeCount || 0) - 1); return { liked: false, likes: e.likeCount }; }
    s.t.set(lp, { uid, postId, on: true, at: s.now, ever: true });
    e.likeCount = (e.likeCount || 0) + 1;
    // Like milestones pay the author once each (never for liking yourself).
    if (!had && p.authorUid !== uid) {
      e.paid = e.paid || [];
      for (const m of s.cfg.rewards.community.likeMilestones) {
        if (e.likeCount >= m.likes && !e.paid.includes(m.likes)) { e.paid.push(m.likes); await moveCoins(s, p.authorUid, m.coins, 'echo-likes-' + m.likes, { free: true, ref: postId }); }
      }
    }
    return { liked: true, likes: e.likeCount };
  });
}
export async function reportEcho(ctx, uid, data) {
  return inTx(ctx, async (s) => {
    const targetType = data && data.targetType === 'comment' ? 'comment' : 'post';
    const targetId = String((data && data.targetId) || '');
    if (!targetId) fail('Nothing to report.', 400, 'invalid-argument');
    s.t.set(`echoReports/${targetType}_${targetId}_${uid}`, { reporterUid: uid, targetType, targetId, reason: clip(data && data.reason, 200), status: 'open', at: s.now });
    return { reported: true };
  });
}
export async function reviewEchoReport(ctx, adminUid, data) {
  return inTx(ctx, async (s) => {
    const id = String((data && data.reportId) || '');
    const r = await s.doc(`echoReports/${id}`);
    if (!r) fail('Report not found.', 404, 'not-found');
    const e = await s.edit(`echoReports/${id}`);
    e.status = data.remove ? 'removed' : 'kept'; e.reviewedBy = adminUid; e.reviewedAt = s.now;
    if (data.remove) s.t.set(`${r.targetType === 'comment' ? 'echoComments' : 'echoPosts'}/${r.targetId}`, { status: 'removed', removedBy: adminUid }, { merge: true });
    return { status: e.status };
  });
}
export async function blockEchoUser(ctx, uid, data) {
  const target = String((data && data.targetUid) || '');
  if (!target || target === uid) fail('Pick someone else.', 400, 'invalid-argument');
  return inTx(ctx, async (s) => { s.t.set(`users/${uid}/blocks/${target}`, { at: s.now }); return { blocked: true }; });
}
export async function setFollow(ctx, uid, data) {
  const target = String((data && data.targetUid) || '');
  if (!target || target === uid) fail('Pick someone else.', 400, 'invalid-argument');
  return inTx(ctx, async (s) => {
    if (data.follow === false) { s.t.delete(`follows/${uid}/following/${target}`); s.t.delete(`follows/${target}/followers/${uid}`); return { following: false }; }
    s.t.set(`follows/${uid}/following/${target}`, { at: s.now });
    s.t.set(`follows/${target}/followers/${uid}`, { at: s.now });
    return { following: true };
  });
}
export async function updateWordPrint(ctx, uid, data) {
  const handle = String((data && data.handle) || '').toLowerCase().replace(/[^a-z0-9_.]/g, '').slice(0, 24);
  const handles = handle ? await ctx.db.query('profiles', [['handle', '==', handle]], { limit: 2 }) : [];
  return inTx(ctx, async (s) => {
    if (handle && handles.some((h) => h.id !== uid)) fail('That handle is taken.');
    const w = await wallet(s, uid);
    const badges = Array.isArray(data && data.featuredBadges) ? data.featuredBadges.map(String).filter((b) => w.badges.includes(b) || w.cosmetics.includes(b)).slice(0, 6) : [];
    const seller = (await s.doc(P.seller(uid))) || {};
    const pr = await s.edit(`profiles/${uid}`, {});
    if (handle) pr.handle = handle;
    pr.bio = clip(data && data.bio, 160); pr.featuredBadges = badges; pr.name = await nameOf(s, uid);
    pr.stats = { streak: w.streak || 0, longestStreak: w.bestStreak || 0, wordsOwned: w.purchases || 0, wordsSold: seller.wordsLifetime || 0, badges: w.badges.length };
    pr.updatedAt = s.now;
    return { saved: true };
  });
}
