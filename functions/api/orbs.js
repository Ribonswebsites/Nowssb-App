/* GET /api/orbs — public read of per-slot thinking-orb choices.
   Source of truth is Firestore ui_overrides (type "orb" / slot orb.*).
   Flutter already watches that collection; this endpoint is for the website
   and for a one-shot fetch without a Firestore client.
   Admin writes go through /api/admin/orb-set (and orb-undo). */
import { cors, json, googleToken, serviceAccount } from '../_lib/server.js';
import { restStore } from '../_lib/admin_store.js';

const PROJECT = 'nowssb-34f1b';

function orbChoice(style) {
  const v = style && typeof style === 'object' ? style.orb : '';
  return typeof v === 'string' && v ? v : null;
}

export async function onRequestOptions({ request }) {
  return new Response(null, { status: 204, headers: cors(request) });
}

export async function onRequestGet({ request, env }) {
  const h = { ...cors(request), 'Cache-Control': 'public, max-age=30' };
  const url = new URL(request.url);
  const want = (url.searchParams.get('slot') || '').trim();
  const sa = serviceAccount(env || {});
  if (!sa) {
    return json({ ok: true, live: false, slots: [], note: 'FIREBASE_SERVICE_ACCOUNT not set' }, 200, h);
  }
  try {
    const db = restStore(await googleToken(sa), (env && env.FIREBASE_PROJECT_ID) || PROJECT);
    const all = await db.query({ collection: 'ui_overrides', limit: 1000 }).catch(() => []);
    const slots = all
      .filter((r) => {
        const d = r.data || {};
        const slot = String(d.slot || r.id || '');
        return d.type === 'orb' || slot.startsWith('orb.');
      })
      .map((r) => {
        const d = r.data || {};
        const style = d.style && typeof d.style === 'object' ? d.style : {};
        return { slot: String(d.slot || r.id || ''), orb: orbChoice(style), orbSize: style.orbSize ?? null, orbCircle: style.orbCircle ?? null };
      })
      .filter((r) => !want || r.slot === want);
    return json({ ok: true, live: true, slots }, 200, h);
  } catch (e) {
    return json({ ok: false, live: false, slots: [], error: 'Could not read orb config.' }, 502, h);
  }
}
