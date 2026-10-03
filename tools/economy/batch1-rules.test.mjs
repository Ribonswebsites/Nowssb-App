// Firestore rules checks for the batch-1 rule changes (emulator only):
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node tools/economy/batch1-rules.test.mjs
// users/{uid}/mastery: owner may read, nobody may write.
// leagues/{id} and leagues/{id}/entries/{uid}: admins only (no uid/XP list).
const host = process.env.FIRESTORE_EMULATOR_HOST;
if (!host) { console.log('FIRESTORE_EMULATOR_HOST not set; skipped'); process.exit(0); }
const project = 'nowssb-34f1b';
const base = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const token = (uid) => `${b64({ alg: 'none', typ: 'JWT' })}.${b64({ sub: uid, user_id: uid, aud: project, iss: `https://securetoken.google.com/${project}`, iat: 1, exp: 9999999999, firebase: { sign_in_provider: 'password' } })}.`;
const req = (path, auth, init = {}) => fetch(`${base}/${path}`, { ...init, headers: { 'content-type': 'application/json', authorization: `Bearer ${auth}`, ...(init.headers || {}) } });
const put = (path, fields, auth = 'owner') => req(path, auth, { method: 'PATCH', body: JSON.stringify({ fields }) });

let pass = 0, fail = 0;
const t = async (name, fn) => { try { await fn(); pass++; console.log('ok  ', name); } catch (e) { fail++; console.log('FAIL', name, e.message); } };
const status = async (p, want) => { const r = await p; if (r.status !== want) throw new Error(`expected ${want} got ${r.status}`); };

await put('users/alice/mastery/om', { word: { stringValue: 'om' }, lastPracticeDay: { stringValue: '20261001' } });
await put('leagues/2026-40_bronze/entries/alice', { uid: { stringValue: 'alice' }, xp: { integerValue: '50' } });
await put('leagues/2026-40_bronze', { members: { mapValue: {} } });

await t('owner reads own mastery', () => status(req('users/alice/mastery/om', token('alice')), 200));
await t('another user cannot read mastery', () => status(req('users/alice/mastery/om', token('bob')), 403));
await t('owner cannot write mastery', () => status(put('users/alice/mastery/om', { level: { integerValue: '99' } }, token('alice')), 403));
await t('user cannot read league entries', () => status(req('leagues/2026-40_bronze/entries/alice', token('alice')), 403));
await t('user cannot read league board', () => status(req('leagues/2026-40_bronze', token('bob')), 403));

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
