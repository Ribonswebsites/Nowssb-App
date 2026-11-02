/* NowssB Connect: the daily word board.

   One board per day, centred on that day's word of the day. People share a
   short thought on how the word felt (up to 280 characters), an optional
   feeling chip and an optional image. Posts are anonymous: no profiles,
   follows, usernames or chats. Others tap a single gentle "felt this".

   Paths (server-only; clients have no write access):
     wordBoard/{day}                      { day, word, meaning, posts }
     wordBoard/{day}/posts/{id}           { authorUid, text, feeling, imageRef, felt, reports, status, at }
     wordBoard/{day}/felt/{postId}_{uid}  { on }
     wordBoard/{day}/reports/{postId}_{uid} { reason }
     users/{uid}/boardHidden/{postId}     posts this person hid for themselves
   Today's board takes posts; earlier boards are read-only. */
import { fail, inTx } from './core.js';
import { dayKey } from './rules.js';

export const MAX_TEXT = 280;
export const POSTS_PER_DAY = 3;
export const HIDE_AT_REPORTS = 3;
export const FEELINGS = ['calm', 'light', 'heavy', 'open', 'warm', 'tender', 'clear', 'restless'];
const DAY_RE = /^\d{8}$/;
const ID_RE = /^[A-Za-z0-9_-]{4,64}$/;

const clip = (t, n) => String(t || '').replace(/\s+/g, ' ').trim().slice(0, n);

/* A small, deliberately plain profanity list (English and common Hinglish).
   Matched on whole words after folding look-alike characters. */
const BAD = ['fuck', 'fucking', 'fucker', 'shit', 'bitch', 'bastard', 'asshole', 'cunt', 'dick', 'pussy', 'slut', 'whore', 'motherfucker', 'chutiya', 'madarchod', 'behenchod', 'bhenchod', 'gandu', 'randi', 'bhosdike', 'harami', 'kamina'];
const fold = (t) => String(t).toLowerCase().replace(/[@4]/g, 'a').replace(/3/g, 'e').replace(/[1!|]/g, 'i').replace(/0/g, 'o').replace(/[$5]/g, 's').replace(/7/g, 't');
export function hasProfanity(text) {
  const words = fold(text).split(/[^a-z]+/).filter(Boolean);
  const joined = words.join('');
  return words.some((w) => BAD.includes(w) || BAD.some((b) => b.length >= 5 && w.includes(b))) || BAD.some((b) => b.length >= 6 && joined.includes(b));
}

/** Only the poster's own compressed upload: connect/{uid}/{ms}.jpg */
export const imageOk = (uid, ref) => new RegExp(`^connect/${uid.replace(/[^A-Za-z0-9_-]/g, '')}/\\d{10,16}\\.jpg$`).test(String(ref || ''));

const okDay = (d, today) => (d == null || d === '' ? today : DAY_RE.test(String(d)) ? String(d) : fail('Pick a day.', 400, 'invalid-argument'));
const okId = (id) => (ID_RE.test(String(id || '')) ? String(id) : fail('Pick a post.', 400, 'invalid-argument'));

function postOut(r, uid, feltSet) {
  const d = r.data;
  return { id: r.id, text: d.text || '', feeling: d.feeling || '', image: d.imageRef || '', felt: d.felt || 0, feltByMe: feltSet.has(r.id), mine: d.authorUid === uid, at: d.at || 0 };
}

export async function boardDay(ctx, uid, data = {}) {
  const db = ctx.db;
  const today = dayKey(ctx.now, ctx.cfg);
  const day = okDay(data.day, today);
  const [board, rows, felt, hidden, cap, recent] = await Promise.all([
    db.get(`wordBoard/${day}`),
    db.query('posts', [['status', '==', 'live']], { parent: `wordBoard/${day}`, limit: 200 }),
    db.query('felt', [['uid', '==', uid], ['on', '==', true]], { parent: `wordBoard/${day}`, limit: 500 }).catch(() => []),
    db.query('boardHidden', [], { parent: `users/${uid}`, limit: 500 }).catch(() => []),
    day === today ? db.get(`users/${uid}/earnCaps/${today}`) : Promise.resolve({ exists: false }),
    db.query('wordBoard', [], { limit: 60 }).catch(() => []),
  ]);
  const feltSet = new Set(felt.map((r) => r.data.postId));
  const hid = new Set(hidden.map((r) => r.id));
  const used = (cap.exists && cap.data && cap.data.counts && cap.data.counts.board_posts) || 0;
  const b = board.exists ? board.data : {};
  return {
    day, today, readOnly: day !== today,
    word: b.word || '', meaning: b.meaning || '',
    posts: rows.filter((r) => !hid.has(r.id)).map((r) => postOut(r, uid, feltSet)).sort((a, c) => c.at - a.at),
    postsLeft: day === today ? Math.max(0, POSTS_PER_DAY - used) : 0,
    days: recent.map((r) => r.id).filter((d) => DAY_RE.test(d) && d < today).sort().reverse().slice(0, 7),
    feelings: FEELINGS,
  };
}

export async function boardPost(ctx, uid, data = {}) {
  const text = clip(data.text, MAX_TEXT + 1);
  if (text.length > MAX_TEXT) fail(`Keep it to ${MAX_TEXT} characters.`, 400, 'invalid-argument');
  const image = String(data.image || '');
  if (image && !imageOk(uid, image)) fail('That image did not upload. Try again.', 400, 'invalid-argument');
  if (text.length < 2 && !image) fail('Share a thought first.', 400, 'invalid-argument');
  if (/(https?:\/\/|www\.)/i.test(text)) fail('Links are not allowed here.', 400, 'invalid-argument');
  if (hasProfanity(text)) fail('Please keep the board gentle. Try other words.', 400, 'invalid-argument');
  const feeling = FEELINGS.includes(data.feeling) ? data.feeling : '';
  return inTx(ctx, async (s) => {
    const cap = await s.edit(`users/${uid}/earnCaps/${s.day}`, { day: s.day, counts: {} });
    cap.counts = cap.counts || {};
    if ((cap.counts.board_posts || 0) >= POSTS_PER_DAY) fail(`That is ${POSTS_PER_DAY} thoughts for today. Come back tomorrow.`, 429, 'resource-exhausted');
    cap.counts.board_posts = (cap.counts.board_posts || 0) + 1;
    const board = await s.edit(`wordBoard/${s.day}`, { day: s.day, posts: 0, createdAt: s.now });
    if (!board.word) { board.word = clip(data.word, 40); board.meaning = clip(data.meaning, 200); }
    board.posts = (board.posts || 0) + 1;
    const id = s.append(`wordBoard/${s.day}/posts`, { authorUid: uid, text, feeling, imageRef: image, felt: 0, reports: 0, status: 'live' }, 'wb');
    return { post: { id, text, feeling, image, felt: 0, feltByMe: false, mine: true, at: s.now }, postsLeft: POSTS_PER_DAY - cap.counts.board_posts };
  });
}

export async function boardFelt(ctx, uid, data = {}) {
  const postId = okId(data.postId);
  return inTx(ctx, async (s) => {
    const day = okDay(data.day, s.day);
    if (day !== s.day) fail('Earlier boards are read-only.', 400, 'failed-precondition');
    const post = await s.doc(`wordBoard/${day}/posts/${postId}`);
    if (!post || post.status !== 'live') fail('That thought is gone.', 404, 'not-found');
    const mark = await s.edit(`wordBoard/${day}/felt/${postId}_${uid}`, { postId, uid, on: false });
    const on = data.on == null ? !mark.on : data.on === true;
    if (on !== !!mark.on) {
      mark.on = on;
      const p = await s.edit(`wordBoard/${day}/posts/${postId}`);
      p.felt = Math.max(0, (p.felt || 0) + (on ? 1 : -1));
      return { postId, feltByMe: on, felt: p.felt };
    }
    return { postId, feltByMe: on, felt: post.felt || 0 };
  });
}

/** Report hides the post for the reporter at once; enough reports hide it for everyone. */
export async function boardReport(ctx, uid, data = {}) {
  const postId = okId(data.postId);
  const reason = clip(data.reason, 120);
  return inTx(ctx, async (s) => {
    const day = okDay(data.day, s.day);
    const post = await s.doc(`wordBoard/${day}/posts/${postId}`);
    if (!post) fail('That thought is gone.', 404, 'not-found');
    await s.edit(`users/${uid}/boardHidden/${postId}`, { day, at: s.now });
    if (data.hideOnly === true) return { postId, hidden: true };
    const rep = await s.doc(`wordBoard/${day}/reports/${postId}_${uid}`);
    if (!rep) {
      s.create(`wordBoard/${day}/reports/${postId}_${uid}`, { postId, uid, reason, at: s.now });
      const p = await s.edit(`wordBoard/${day}/posts/${postId}`);
      p.reports = (p.reports || 0) + 1;
      if (p.reports >= HIDE_AT_REPORTS) p.status = 'hidden';
    }
    return { postId, hidden: true, reported: true };
  });
}
