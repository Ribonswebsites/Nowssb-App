#!/usr/bin/env node
/* One-shot: copy paid fields from words/{key} (+ content/library items) into
   wordsPrivate/{key}, then strip them from the public docs.

   Admin (Chief of Staff) runs this after BF-1 rules + client lock are live.
   Safe and idempotent: phase1 copy → phase2 verify → phase3 strip.
   Already-split docs (paidStripped + wordsPrivate present) are skipped.
   Never strips public until the private copy is verified.

   Usage (from repo root):
     # Dry-run (default) — prints what would change, writes nothing:
     GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json node tools/migrate-words-private.mjs

     # Apply for real:
     GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json node tools/migrate-words-private.mjs --apply

     # Optional: only one key
     ... node tools/migrate-words-private.mjs --apply --key=aarogya

   Env:
     FIREBASE_PROJECT_ID   default nowssb-34f1b
     GOOGLE_APPLICATION_CREDENTIALS  or FIREBASE_SERVICE_ACCOUNT (JSON string)

   Free words (price <= 0) keep their meaning/audio on the public doc so the
   offline catalogue still works. Paid words (price > 0, or --all) are split.

   Note: media.nowssb.com is a public R2 bucket — this script stops putting
   those URLs in world-readable Firestore, but signed R2 URLs are still needed
   for a full media lock.
*/
import { readFileSync } from 'node:fs';
import { extractPaid, stripPaid } from '../functions/_lib/content_paid.js';

const APPLY = process.argv.includes('--apply');
const ALL = process.argv.includes('--all');
const KEY_ARG = (process.argv.find((a) => a.startsWith('--key=')) || '').slice(6).toLowerCase();
const PROJECT = process.env.FIREBASE_PROJECT_ID || 'nowssb-34f1b';

function loadSa() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  }
  const p = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!p) {
    console.error('Set GOOGLE_APPLICATION_CREDENTIALS or FIREBASE_SERVICE_ACCOUNT.');
    process.exit(2);
  }
  return JSON.parse(readFileSync(p, 'utf8'));
}

function b64url(buf) {
  return Buffer.from(buf).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function googleToken(sa) {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT', kid: sa.private_key_id }));
  const claim = b64url(JSON.stringify({
    iss: sa.client_email,
    sub: sa.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
    scope: 'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/cloud-platform',
  }));
  const crypto = await import('node:crypto');
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(header + '.' + claim);
  const sig = b64url(sign.sign(sa.private_key));
  const jwt = header + '.' + claim + '.' + sig;
  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' + encodeURIComponent(jwt),
  });
  const d = await r.json();
  if (!r.ok || !d.access_token) throw new Error('token: ' + (d.error_description || r.status));
  return d.access_token;
}

function fsValue(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(fsValue) } };
  if (typeof v === 'object') {
    if (v && typeof v.toDate === 'function') return { timestampValue: v.toDate().toISOString() };
    const fields = {};
    for (const [k, x] of Object.entries(v)) fields[k] = fsValue(x);
    return { mapValue: { fields } };
  }
  return { stringValue: String(v) };
}
function fsFields(obj) {
  const out = {};
  for (const [k, v] of Object.entries(obj)) out[k] = fsValue(v);
  return out;
}
function fsPlain(value) {
  if (!value) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('nullValue' in value) return null;
  if ('timestampValue' in value) return value.timestampValue;
  if ('arrayValue' in value) return (value.arrayValue.values || []).map(fsPlain);
  if ('mapValue' in value) {
    const o = {};
    for (const [k, v] of Object.entries(value.mapValue.fields || {})) o[k] = fsPlain(v);
    return o;
  }
  return null;
}

const root = (project) => `projects/${project}/databases/(default)/documents`;

async function listCollection(token, project, collectionId) {
  const out = [];
  let page = '';
  for (let i = 0; i < 50; i++) {
    const url = `https://firestore.googleapis.com/v1/${root(project)}/${collectionId}?pageSize=300${page ? '&pageToken=' + page : ''}`;
    const r = await fetch(url, { headers: { Authorization: 'Bearer ' + token } });
    if (!r.ok) throw new Error('list ' + collectionId + ' ' + r.status);
    const d = await r.json();
    for (const doc of d.documents || []) {
      const id = doc.name.split('/').pop();
      out.push({ id, data: fsPlain({ mapValue: { fields: doc.fields || {} } }) || {} });
    }
    if (!d.nextPageToken) break;
    page = d.nextPageToken;
  }
  return out;
}

async function getDoc(token, project, path) {
  const r = await fetch(`https://firestore.googleapis.com/v1/${root(project)}/${path}`, {
    headers: { Authorization: 'Bearer ' + token },
  });
  if (r.status === 404) return null;
  if (!r.ok) throw new Error('get ' + path + ' ' + r.status);
  const d = await r.json();
  return fsPlain({ mapValue: { fields: d.fields || {} } }) || {};
}

async function commit(token, project, writes) {
  const r = await fetch(`https://firestore.googleapis.com/v1/${root(project)}:commit`, {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' },
    body: JSON.stringify({ writes }),
  });
  const d = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error('commit ' + r.status + ' ' + JSON.stringify(d.error || d));
  return d;
}

function shouldSplit(data) {
  if (ALL) return true;
  const price = Number(data.price);
  if (!(price > 0)) return false;
  return !!extractPaid(data);
}

async function main() {
  console.log(APPLY ? 'APPLY mode — copy → verify → strip.' : 'DRY-RUN (pass --apply to write).');
  console.log('project:', PROJECT);
  const sa = loadSa();
  const token = await googleToken(sa);

  const words = await listCollection(token, PROJECT, 'words');
  console.log('words docs:', words.length);

  const toSplit = [];
  for (const { id, data } of words) {
    if (KEY_ARG && id !== KEY_ARG) continue;
    if (!shouldSplit(data)) continue;
    const paid = extractPaid(data);
    if (!paid) continue;
    // Idempotent: already stripped and private exists → skip.
    const existingPriv = await getDoc(token, PROJECT, `wordsPrivate/${id}`);
    const already = data.paidStripped === true && existingPriv && extractPaid({ ...data, ...existingPriv });
    if (data.paidStripped === true && existingPriv && Object.keys(existingPriv).length) {
      console.log(`  ${id}: already split — skip`);
      continue;
    }
    toSplit.push({ id, data, paid, existingPriv });
    console.log(`  ${id}: will move ${Object.keys(paid).join(',')} → wordsPrivate/${id}`);
  }

  // content/library items
  const library = await getDoc(token, PROJECT, 'content/library');
  const libraryPlan = [];
  let libraryItems = null;
  if (library && Array.isArray(library.items)) {
    libraryItems = library.items.map((it) => {
      if (!it || typeof it !== 'object') return it;
      const k = String(it.key || it.word || '').toLowerCase().replace(/\s+/g, '-');
      if (KEY_ARG && k !== KEY_ARG) return it;
      if (!shouldSplit(it)) return it;
      const paid = extractPaid(it);
      if (!paid) return it;
      libraryPlan.push({ k, paid, it });
      console.log(`  content/library item ${k}: will copy paid → wordsPrivate/${k}`);
      return it; // strip later, after verify
    });
    console.log('content/library paid items to split:', libraryPlan.length);
  } else {
    console.log('content/library: missing or no items');
  }

  console.log('words to split:', toSplit.length);
  if (!APPLY) {
    console.log('Dry-run complete. Re-run with --apply to write.');
    return;
  }

  // ── Phase 1: COPY paid → wordsPrivate (do not touch public yet) ──
  const copyWrites = [];
  for (const { id, paid } of toSplit) {
    copyWrites.push({
      update: {
        name: `${root(PROJECT)}/wordsPrivate/${id}`,
        fields: fsFields({ ...paid, key: id, migratedAt: new Date().toISOString() }),
      },
    });
  }
  for (const { k, paid } of libraryPlan) {
    if (!k) continue;
    copyWrites.push({
      update: {
        name: `${root(PROJECT)}/wordsPrivate/${k}`,
        fields: fsFields({ ...paid, key: k, migratedAt: new Date().toISOString(), from: 'content/library' }),
      },
    });
  }
  for (let i = 0; i < copyWrites.length; i += 400) {
    await commit(token, PROJECT, copyWrites.slice(i, i + 400));
    console.log('phase1 copy committed', Math.min(i + 400, copyWrites.length), '/', copyWrites.length);
  }

  // ── Phase 2: VERIFY every private doc ──
  const verified = [];
  for (const { id, paid } of toSplit) {
    const priv = await getDoc(token, PROJECT, `wordsPrivate/${id}`);
    if (!priv || !Object.keys(priv).length) {
      throw new Error(`VERIFY FAIL: wordsPrivate/${id} missing after copy — public not stripped.`);
    }
    for (const k of Object.keys(paid)) {
      if (priv[k] === undefined || priv[k] === null || priv[k] === '') {
        // arrays/objects may be empty-ish; still require key present when paid had it
        if (typeof paid[k] === 'string' && paid[k] && !priv[k]) {
          throw new Error(`VERIFY FAIL: wordsPrivate/${id} missing field ${k}`);
        }
      }
    }
    verified.push(id);
  }
  for (const { k, paid } of libraryPlan) {
    if (!k) continue;
    const priv = await getDoc(token, PROJECT, `wordsPrivate/${k}`);
    if (!priv || !Object.keys(priv).length) {
      throw new Error(`VERIFY FAIL: wordsPrivate/${k} (from library) missing after copy.`);
    }
  }
  console.log('phase2 verified:', verified.length, 'wordsPrivate docs');

  // ── Phase 3: STRIP public words + library ──
  const stripWrites = [];
  for (const { id, data } of toSplit) {
    const preview = stripPaid(data);
    stripWrites.push({
      update: {
        name: `${root(PROJECT)}/words/${id}`,
        fields: fsFields({ ...preview, paidStripped: true }),
      },
    });
  }
  if (library && libraryItems && libraryPlan.length) {
    const strippedItems = library.items.map((it) => {
      if (!it || typeof it !== 'object') return it;
      const k = String(it.key || it.word || '').toLowerCase().replace(/\s+/g, '-');
      if (KEY_ARG && k !== KEY_ARG) return it;
      if (!shouldSplit(it)) return it;
      if (!extractPaid(it)) return it;
      return stripPaid(it);
    });
    stripWrites.push({
      update: {
        name: `${root(PROJECT)}/content/library`,
        fields: fsFields({ ...library, items: strippedItems }),
      },
    });
  }
  for (let i = 0; i < stripWrites.length; i += 400) {
    await commit(token, PROJECT, stripWrites.slice(i, i + 400));
    console.log('phase3 strip committed', Math.min(i + 400, stripWrites.length), '/', stripWrites.length);
  }
  console.log('Done. Copied, verified, then stripped', verified.length, 'words.');
}


main().catch((e) => {
  console.error(e);
  process.exit(1);
});
