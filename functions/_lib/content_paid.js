/* Paid fields for NowssB words — shared by /api/content/word and the
   migration script. Public catalogue keeps title/cover/price/preview;
   these go in wordsPrivate/{id} once stripped from words/{id}.

   media.nowssb.com is still a public R2 bucket: locking Firestore stops
   leaking the URLs through rules, but signed R2 URLs are still needed for
   a full media lock. */

/** Top-level keys that never belong on a world-readable paid word doc. */
export const PAID_TOP_KEYS = [
  'meaning', 'meanings', 'audio', 'audioMale', 'audioFemale',
  'video', 'videoUrl', 'videoPoster',
];

/** Build the private payload from a full word map (words/{id} or library item). */
export function extractPaid(raw) {
  if (!raw || typeof raw !== 'object') return null;
  const out = {};
  for (const k of PAID_TOP_KEYS) {
    if (raw[k] !== undefined && raw[k] !== null && raw[k] !== '') out[k] = raw[k];
  }
  if (Array.isArray(raw.meanings) && raw.meanings.length) out.meanings = [...raw.meanings];
  if (Array.isArray(raw.parts)) {
    const partsAudio = raw.parts.map((p) => (p && typeof p === 'object' ? String(p.audio || '') : ''));
    if (partsAudio.some(Boolean)) out.partsAudio = partsAudio;
  }
  if (Array.isArray(raw.stages)) {
    const stagesMedia = raw.stages.map((s) => {
      if (!s || typeof s !== 'object') return { audio: '', video: '' };
      return { audio: String(s.audio || ''), video: String(s.video || '') };
    });
    if (stagesMedia.some((s) => s.audio || s.video)) out.stagesMedia = stagesMedia;
  }
  return Object.keys(out).length ? out : null;
}

/** Public preview: same word map with paid fields cleared. */
export function stripPaid(raw) {
  if (!raw || typeof raw !== 'object') return raw;
  const out = { ...raw };
  for (const k of PAID_TOP_KEYS) delete out[k];
  if (Array.isArray(out.parts)) {
    out.parts = out.parts.map((p) => {
      if (!p || typeof p !== 'object') return p;
      const n = { ...p };
      delete n.audio;
      return n;
    });
  }
  if (Array.isArray(out.stages)) {
    out.stages = out.stages.map((s) => {
      if (!s || typeof s !== 'object') return s;
      const n = { ...s };
      delete n.audio;
      delete n.video;
      return n;
    });
  }
  return out;
}

/** Merge a wordsPrivate payload onto a public word map. */
export function mergePaid(publicWord, paid) {
  if (!paid || typeof paid !== 'object') return publicWord || {};
  const out = { ...(publicWord || {}) };
  for (const k of PAID_TOP_KEYS) {
    if (paid[k] !== undefined && paid[k] !== null && paid[k] !== '') out[k] = paid[k];
  }
  if (Array.isArray(paid.meanings)) out.meanings = paid.meanings;
  if (Array.isArray(out.parts) && Array.isArray(paid.partsAudio)) {
    out.parts = out.parts.map((p, i) => {
      if (!p || typeof p !== 'object') return p;
      const audio = paid.partsAudio[i] || '';
      return audio ? { ...p, audio } : { ...p };
    });
  }
  if (Array.isArray(out.stages) && Array.isArray(paid.stagesMedia)) {
    out.stages = out.stages.map((s, i) => {
      if (!s || typeof s !== 'object') return s;
      const m = paid.stagesMedia[i] || {};
      return { ...s, audio: m.audio || '', video: m.video || '' };
    });
  } else if (Array.isArray(paid.stages)) {
    out.stages = paid.stages;
  }
  return out;
}

/** Owned doc id under users/{uid}/owned — same as Flutter ownedDocId / cleanId. */
export function ownedDocId(itemId) {
  return String(itemId || '').replace(/[^A-Za-z0-9_.@-]/g, '_').replace(/^\.+/, '_').slice(0, 300) || '_';
}

const TIER_RANK = { resonance: 1, frequency: 2, frequencyX: 3 };

/** Normalize FsDb.get / fsGet results to a plain data object or null. */
export function asData(doc) {
  if (!doc) return null;
  if (typeof doc === 'object' && 'exists' in doc) {
    if (doc.exists === false) return null;
    return doc.data || null;
  }
  return doc;
}

/**
 * Whether this uid may read paid fields for word [key].
 * Mirrors entitlements.dart: free price, admin, owned word/signature/meaning,
 * or any active plan (isPro + known tier).
 *
 * getDoc(path) → plain data | {exists,data} | null
 */
export async function canAccessWordPaid(getDoc, uid, { key, wordName, price = 1, claims } = {}) {
  if (!uid) return false;
  if (claims && claims.admin === true) return true;

  const free = !(Number(price) > 0);
  if (free) return true;

  const admin = asData(await getDoc(`admins/${uid}`));
  if (admin) return true;

  const user = asData(await getDoc(`users/${uid}`));
  if (user && user.isPro === true && TIER_RANK[String(user.tier || '')]) return true;

  const id = String(key || '').toLowerCase();
  const name = String(wordName || key || '').toLowerCase();
  const candidates = [
    ownedDocId(`word:${name}`),
    ownedDocId(`word:${id}`),
    ownedDocId(`signature:${name}`),
    ownedDocId(`signature:${id}`),
    ownedDocId(`meaning:${name}`),
    ownedDocId(`meaning:${id}`),
  ];
  for (const docId of [...new Set(candidates)]) {
    const o = asData(await getDoc(`users/${uid}/owned/${docId}`));
    if (o && String(o.status || 'active') === 'active') return true;
  }
  return false;
}
