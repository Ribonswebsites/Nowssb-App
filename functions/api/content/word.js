/* POST /api/content/word — paid fields for one word (BF-1).

   Authorization: Bearer <Firebase ID token>
   Body: { key: string }   // words/{key} id (also tried as lower-case word name)

   Returns { ok, key, paid, source } where paid is the wordsPrivate payload
   (meaning, audio/video URLs, stage media, …). Free words and entitled
   callers get the payload; everyone else gets 403.

   Looks up wordsPrivate/{key} first; if missing (migration not run yet),
   falls back to extracting paid fields from words/{key} via the service
   account so entitled users keep working during the cutover. Public clients
   must not read paid URLs from world-readable docs after the strip.
*/
import { cors, json, requireUser, serviceAccount, googleToken, fsGet, SCOPE_FIRESTORE } from '../../_lib/server.js';
import { canAccessWordPaid, extractPaid } from '../../_lib/content_paid.js';

export async function onRequestOptions({ request }) {
  return new Response(null, { status: 204, headers: cors(request) });
}

export async function onRequestPost({ request, env }) {
  const h = cors(request);
  const claims = await requireUser(request, env, h);
  if (claims instanceof Response) return claims;
  const uid = claims.sub;

  let body;
  try { body = await request.json(); } catch (_) { return json({ error: 'Send JSON.' }, 400, h); }
  const key = String((body && body.key) || '').trim().toLowerCase();
  if (!key || key.length > 120 || /[^a-z0-9_-]/.test(key)) {
    return json({ error: 'Missing or invalid word key.' }, 400, h);
  }

  const sa = serviceAccount(env);
  const project = env.FIREBASE_PROJECT_ID;
  if (!sa || !project) {
    return json({
      error: 'Content unlock is not switched on yet. Missing FIREBASE_SERVICE_ACCOUNT (or FCM_SERVICE_ACCOUNT) / FIREBASE_PROJECT_ID.',
      missing: [
        ...(!project ? ['FIREBASE_PROJECT_ID'] : []),
        ...(!sa ? ['FIREBASE_SERVICE_ACCOUNT'] : []),
      ],
    }, 501, h);
  }

  let token;
  try { token = await googleToken(sa, SCOPE_FIRESTORE); }
  catch (_) { return json({ error: 'Could not reach Firestore yet. Try again.' }, 503, h); }

  const getDoc = async (path) => {
    try { return await fsGet(token, project, path); }
    catch (_) { return null; }
  };

  const publicWord = await getDoc(`words/${encodeURIComponent(key)}`) || {};
  const price = publicWord.price != null ? publicWord.price : (body && body.price);
  const wordName = publicWord.word || (body && body.word) || key;

  const allowed = await canAccessWordPaid(getDoc, uid, {
    key, wordName, price: price == null ? 1 : price, claims,
  });
  if (!allowed) {
    return json({ error: 'This word is locked. Buy it or open a plan.', code: 'locked' }, 403, h);
  }

  let paid = await getDoc(`wordsPrivate/${encodeURIComponent(key)}`);
  let source = 'wordsPrivate';
  if (!paid || !Object.keys(paid).length) {
    paid = extractPaid(publicWord);
    source = paid ? 'words' : 'empty';
  }
  // Never echo preview-only docs as "paid".
  if (!paid) paid = {};

  return json({
    ok: true,
    key,
    paid,
    source,
    // Hint for clients: media.nowssb.com URLs are still public R2 until signed URLs land.
    mediaPublic: true,
  }, 200, h);
}
