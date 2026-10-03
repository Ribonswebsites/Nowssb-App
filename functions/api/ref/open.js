/* POST /api/ref/open { code } — counts a link open (no sign-in; one count
   per IP per day per the rate limit). Returns the item the link is for. */
import { cors, json, serviceAccount, sha256Hex } from '../../_lib/server.js';
import { FsDb } from '../../_lib/economy/fsdb.js';
import { loadEconomy } from '../../_lib/economy/config.js';
import { countOpenOnce } from '../../_lib/economy/reference.js';

export async function onRequestOptions({ request }) {
  return new Response(null, { status: 204, headers: cors(request) });
}
export async function onRequestPost({ request, env }) {
  const h = cors(request);
  if (!serviceAccount(env) && !env.FIRESTORE_EMULATOR_HOST) return json({ ok: false, switchingOn: true, missing: ['FIREBASE_SERVICE_ACCOUNT'] }, 501, h);
  let b = {};
  try { b = await request.json(); } catch (e) { b = {}; }
  try {
    const db = await FsDb.fromEnv(env);
    const cfg = await loadEconomy(db);
    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    const r = await countOpenOnce(db, cfg, b.code, await sha256Hex('ip|' + ip));
    return json(r, 200, h);
  } catch (e) {
    return json({ ok: false }, 200, h);
  }
}
