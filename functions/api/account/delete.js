/* POST /api/account/delete — in-app account deletion (Google Play policy).

     Authorization: Bearer <Firebase ID token of the account to delete>

   With FIREBASE_SERVICE_ACCOUNT set: deletes the person's Firestore data
   (users/{uid} and every sub-collection under it, publicProfiles/{uid},
   follows/{uid}, accountDeletionRequests/{uid}) and then the Firebase Auth
   account itself (identitytoolkit accounts:delete). Purchase receipts and
   ledgers that the law or Google Play require us to keep (payments, sales,
   playReceipts) are not personal profile data and stay, keyed by uid only.
   Without the key → 501, and the app files accountDeletionRequests/{uid}
   for an admin to finish, then signs the person out. */
import { cors, json, requireUser, serviceAccount, googleToken, fsBase } from '../../_lib/server.js';

const SCOPE = 'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/identitytoolkit https://www.googleapis.com/auth/cloud-platform';

export async function onRequestOptions({ request }) {
  return new Response(null, { status: 204, headers: cors(request) });
}

async function listDocs(tok, docPath) {
  // Every document directly under each sub-collection of docPath (one level).
  const base = 'https://firestore.googleapis.com/v1/';
  const out = [];
  const ids = await fetch(`${base}${docPath}:listCollectionIds`, {
    method: 'POST', headers: { Authorization: 'Bearer ' + tok, 'Content-Type': 'application/json' }, body: JSON.stringify({ pageSize: 100 }),
  }).then((r) => (r.ok ? r.json() : {})).catch(() => ({}));
  for (const col of ids.collectionIds || []) {
    let page = '';
    for (let i = 0; i < 20; i++) {
      const r = await fetch(`${base}${docPath}/${col}?pageSize=300&mask.fieldPaths=__name__${page ? '&pageToken=' + page : ''}`, { headers: { Authorization: 'Bearer ' + tok } });
      if (!r.ok) break;
      const d = await r.json();
      for (const doc of d.documents || []) out.push(doc.name);
      if (!d.nextPageToken) break;
      page = d.nextPageToken;
    }
  }
  return out;
}

async function commitDeletes(tok, project, names) {
  for (let i = 0; i < names.length; i += 400) {
    const r = await fetch(`https://firestore.googleapis.com/v1/${fsBase(project)}:commit`, {
      method: 'POST', headers: { Authorization: 'Bearer ' + tok, 'Content-Type': 'application/json' },
      body: JSON.stringify({ writes: names.slice(i, i + 400).map((n) => ({ delete: n })) }),
    });
    if (!r.ok) throw new Error('firestore delete ' + r.status);
  }
}

export async function onRequestPost({ request, env }) {
  const h = cors(request);
  const sa = serviceAccount(env);
  if (!sa) {
    return json({ error: 'Account deletion is queued for the team (server key not set).', missing: ['FIREBASE_SERVICE_ACCOUNT'], code: 'not-configured' }, 501, h);
  }
  const claims = await requireUser(request, env, h);
  if (claims instanceof Response) return claims;
  const uid = claims.sub;
  const project = env.FIREBASE_PROJECT_ID || sa.project_id;
  try {
    const tok = await googleToken(sa, SCOPE);
    const userDoc = `projects/${project}/databases/(default)/documents/users/${uid}`;
    const names = [
      ...(await listDocs(tok, userDoc)),
      `${userDoc}`,
      `projects/${project}/databases/(default)/documents/publicProfiles/${uid}`,
      `projects/${project}/databases/(default)/documents/accountDeletionRequests/${uid}`,
      ...(await listDocs(tok, `projects/${project}/databases/(default)/documents/follows/${uid}`)),
    ];
    await commitDeletes(tok, project, names);
    const r = await fetch(`https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts:delete`, {
      method: 'POST', headers: { Authorization: 'Bearer ' + tok, 'Content-Type': 'application/json' }, body: JSON.stringify({ localId: uid }),
    });
    if (!r.ok) {
      const d = await r.json().catch(() => ({}));
      return json({ error: 'Your data was deleted, but the sign-in could not be removed yet. The team will finish it.', detail: (d.error && d.error.message) || String(r.status) }, 502, h);
    }
    return json({ ok: true, deleted: names.length }, 200, h);
  } catch (e) {
    return json({ error: 'Could not delete the account right now. It is safe to try again.' }, 502, h);
  }
}
