/* NowssB Connect: real profiles, follows, a feed and one-to-one chats.

   Everything goes through the server (service account), so the phone never
   needs list access to other people's data and nothing is invented:
     connectProfiles/{uid}                    a person's Connect profile (opt-in, made in Connect setup)
     follows/{uid}/following|followers/{x}    shared with Word Print (social.setFollow)
     echoPosts / echoLikes                    shared with the Echo Wall (moderated, rate limited)
     connectChats/{a_b}                       { participants:[a,b], lastText, lastFrom, lastAt }
     connectChats/{a_b}/messages/{id}         { from, text, at }
   Empty lists stay empty: no sample people, posts or replies. */
import { fail, inTx, notify } from './core.js';
import { createEchoPost, setFollow, toggleEchoLike } from './social.js';

const clip = (t, n) => String(t || '').replace(/\s+/g, ' ').trim().slice(0, n);
const UID = /^[A-Za-z0-9_-]{6,128}$/;
const IMAGE_OK = /^https:\/\/media\.nowssb\.com\/[\w./%-]{1,300}$/;
export const FOCUS = ['Sound Healer', 'Daily Practitioner', 'Wellness', 'Beginner', 'Practitioner', 'Frequency Sage'];

export const chatIdFor = (a, b) => [a, b].sort().join('_');
const okUid = (u) => (UID.test(String(u || '')) ? String(u) : fail('Pick a person first.', 400, 'invalid-argument'));

export function usernameFrom(name, uid) {
  const base = String(name || '').toLowerCase().normalize('NFKD').replace(/[^a-z0-9]+/g, '.').replace(/^\.+|\.+$/g, '').slice(0, 18) || 'member';
  return `${base}.${String(uid).slice(0, 4).toLowerCase()}`;
}

function personOut(id, p) {
  return { uid: id, name: p.name || 'NowssB member', username: p.username || '', focus: p.focus || '', bio: p.bio || '', avatar: p.photoURL || '', banner: p.banner || '' };
}

export async function connectSaveProfile(ctx, uid, data = {}, claims = {}) {
  const name = clip(data.name, 40);
  if (name.length < 1) fail('Add a display name.', 400, 'invalid-argument');
  const focus = FOCUS.includes(data.focus) ? data.focus : FOCUS[0];
  const bio = clip(data.bio, 150);
  if (/(https?:\/\/|www\.)/i.test(bio)) fail('Links are not allowed in a bio.');
  const banner = IMAGE_OK.test(String(data.banner || '')) ? String(data.banner) : '';
  const theme = data.theme === 'glass' ? 'glass' : 'neu';
  return inTx(ctx, async (s) => {
    const p = await s.edit(`connectProfiles/${uid}`, { createdAt: s.now });
    Object.assign(p, { uid, name, username: p.username || usernameFrom(name, uid), focus, bio, banner, theme, photoURL: String((claims && claims.picture) || p.photoURL || '').slice(0, 500), updatedAt: s.now });
    return { profile: personOut(uid, p), theme };
  });
}

async function blockedSet(db, uid) {
  const mine = await db.query('blocks', [], { parent: `users/${uid}`, limit: 300 }).catch(() => []);
  return new Set(mine.map((r) => r.id));
}

export async function connectHome(ctx, uid) {
  const db = ctx.db;
  const [meDoc, profiles, following, followerCount, posts, likes, blocked] = await Promise.all([
    db.get(`connectProfiles/${uid}`),
    db.query('connectProfiles', [], { limit: 60, orderBy: ['updatedAt', 'desc'] }),
    db.query('following', [], { parent: `follows/${uid}`, limit: 500 }),
    db.count('followers', [], { parent: `follows/${uid}` }).catch(() => 0),
    db.query('echoPosts', [['status', '==', 'live']], { limit: 40 }),
    db.query('echoLikes', [['uid', '==', uid], ['on', '==', true]], { limit: 300 }).catch(() => []),
    blockedSet(db, uid),
  ]);
  const byUid = new Map(profiles.map((r) => [r.id, r.data]));
  const liked = new Set(likes.map((r) => r.data.postId));
  const followingIds = following.map((r) => r.id).filter((id) => !blocked.has(id));
  return {
    me: meDoc.exists ? { ...personOut(uid, meDoc.data), theme: meDoc.data.theme || 'neu' } : null,
    people: profiles.filter((r) => r.id !== uid && !blocked.has(r.id)).map((r) => personOut(r.id, r.data)),
    following: followingIds,
    followingCount: followingIds.length,
    followerCount: Number(followerCount) || 0,
    posts: posts
      .filter((r) => !blocked.has(r.data.authorUid))
      .map((r) => {
        const a = byUid.get(r.data.authorUid) || {};
        return { id: r.id, authorUid: r.data.authorUid, authorName: a.name || r.data.authorName || 'NowssB member', authorAvatar: a.photoURL || '', authorFocus: a.focus || '', text: r.data.text || '', image: IMAGE_OK.test(String(r.data.imageRef || '')) ? r.data.imageRef : '', likes: r.data.likeCount || 0, comments: r.data.commentCount || 0, liked: liked.has(r.id), at: r.data.at || 0 };
      }),
  };
}

export async function connectFollow(ctx, uid, data = {}) {
  const target = okUid(data.targetUid);
  const prof = await ctx.db.get(`connectProfiles/${target}`);
  if (!prof.exists) fail('That person is not on Connect.', 404, 'not-found');
  const out = await setFollow(ctx, uid, { targetUid: target, follow: data.follow !== false });
  if (out.following) {
    const me = await ctx.db.get(`connectProfiles/${uid}`);
    await inTx(ctx, async (s) => { notify(s, target, 'New follower', `${(me.data && me.data.name) || 'Someone'} followed you on NowssB Connect.`, 'connect', uid); });
  }
  return out;
}

export async function connectPost(ctx, uid, data = {}) {
  const image = IMAGE_OK.test(String(data.image || '')) ? String(data.image) : '';
  return createEchoPost(ctx, uid, { text: data.text, imageRef: image });
}

export const connectLike = (ctx, uid, data = {}) => toggleEchoLike(ctx, uid, { postId: String(data.postId || '') });

export async function connectInbox(ctx, uid) {
  const rows = await ctx.db.query('connectChats', [['participants', 'array-contains', uid]], { limit: 100 });
  const others = [...new Set(rows.map((r) => (r.data.participants || []).find((p) => p !== uid)).filter(Boolean))];
  const profs = await Promise.all(others.map((o) => ctx.db.get(`connectProfiles/${o}`)));
  const byUid = new Map(others.map((o, i) => [o, profs[i].exists ? profs[i].data : null]));
  return {
    chats: rows
      .map((r) => {
        const other = (r.data.participants || []).find((p) => p !== uid);
        return { id: r.id, with: personOut(other, byUid.get(other) || {}), lastText: r.data.lastText || '', lastMine: r.data.lastFrom === uid, lastAt: r.data.lastAt || 0 };
      })
      .sort((a, b) => b.lastAt - a.lastAt),
  };
}

export async function connectThread(ctx, uid, data = {}) {
  const other = okUid(data.withUid);
  const id = chatIdFor(uid, other);
  const chat = await ctx.db.get(`connectChats/${id}`);
  if (!chat.exists) return { chatId: id, messages: [] };
  if (!(chat.data.participants || []).includes(uid)) fail('Not your chat.', 403, 'permission-denied');
  const rows = await ctx.db.query('messages', [], { parent: `connectChats/${id}`, limit: 200, orderBy: ['at', 'desc'] });
  return { chatId: id, messages: rows.reverse().map((r) => ({ id: r.id, mine: r.data.from === uid, text: r.data.text || '', at: r.data.at || 0 })) };
}

export async function connectSend(ctx, uid, data = {}) {
  const other = okUid(data.toUid);
  if (other === uid) fail('Pick someone else.', 400, 'invalid-argument');
  const text = clip(data.text, 1000);
  if (!text) fail('Write a message first.', 400, 'invalid-argument');
  const id = chatIdFor(uid, other);
  return inTx(ctx, async (s) => {
    const [them, me, blockedByThem, blockedByMe] = await Promise.all([
      s.doc(`connectProfiles/${other}`), s.doc(`connectProfiles/${uid}`), s.doc(`users/${other}/blocks/${uid}`), s.doc(`users/${uid}/blocks/${other}`),
    ]);
    if (!them) fail('That person is not on Connect.', 404, 'not-found');
    if (!me) fail('Set up your Connect profile first.', 400, 'failed-precondition');
    if (blockedByThem || blockedByMe) fail('You can’t message this person.', 403, 'permission-denied');
    const day = await s.edit(`users/${uid}/earnCaps/${s.day}`, { day: s.day, counts: {} });
    day.counts = day.counts || {};
    if ((day.counts.connect_msgs || 0) >= 300) fail('That is enough messages for today.', 429, 'resource-exhausted');
    day.counts.connect_msgs = (day.counts.connect_msgs || 0) + 1;
    const c = await s.edit(`connectChats/${id}`, { participants: [uid, other].sort(), createdAt: s.now });
    Object.assign(c, { lastText: text.slice(0, 120), lastFrom: uid, lastAt: s.now });
    const msgId = s.append(`connectChats/${id}/messages`, { from: uid, text }, 'm');
    notify(s, other, me.name || 'New message', text.slice(0, 120), 'connect', uid);
    return { chatId: id, message: { id: msgId, mine: true, text, at: s.now } };
  });
}
