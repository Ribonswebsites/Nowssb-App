#!/usr/bin/env node
/* NowssB Firebase admin helper — no dependencies, works on the free Spark plan.

   Credentials (never printed, never committed):
     FIREBASE_SERVICE_ACCOUNT        the service-account JSON itself, or
     GOOGLE_APPLICATION_CREDENTIALS  a path to that JSON file.

   Commands:
     node tools/firebase/admin-tool.mjs list-users [--limit 200]
         Auth accounts: uid, email, name, providers, created, last sign-in.
         Read-only.
     node tools/firebase/admin-tool.mjs list-admins
         Documents in Firestore admins/{uid}. Read-only.
     node tools/firebase/admin-tool.mjs mark-admin <uid> [--claim]
         Creates admins/{uid} (what firestore.rules and the upload endpoint
         check). --claim also sets the custom claim {admin:true}, merged with
         any existing claims; the person must sign out/in to pick it up.
     node tools/firebase/admin-tool.mjs unmark-admin <uid>
         Deletes admins/{uid} and removes the admin claim. */
import { createSign } from 'node:crypto';
import { readFileSync } from 'node:fs';

function loadSa() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT ||
    (process.env.GOOGLE_APPLICATION_CREDENTIALS && readFileSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, 'utf8'));
  if (!raw) throw new Error('Set FIREBASE_SERVICE_ACCOUNT or GOOGLE_APPLICATION_CREDENTIALS.');
  const sa = JSON.parse(raw);
  if (!sa.private_key || !sa.client_email) throw new Error('That is not a service-account key.');
  return sa;
}

const b64u = (b) => Buffer.from(b).toString('base64url');
async function accessToken(sa) {
  const now = Math.floor(Date.now() / 1000);
  const head = b64u(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const body = b64u(JSON.stringify({
    iss: sa.client_email, sub: sa.client_email, aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 3600,
    scope: 'https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/identitytoolkit https://www.googleapis.com/auth/datastore',
  }));
  const s = createSign('RSA-SHA256');
  s.update(head + '.' + body);
  const jwt = head + '.' + body + '.' + s.sign(sa.private_key, 'base64url');
  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' + jwt,
  });
  const d = await r.json();
  if (!r.ok) throw new Error('token: ' + (d.error_description || d.error || r.status));
  return d.access_token;
}

async function call(tok, method, url, body) {
  const r = await fetch(url, {
    method,
    headers: { Authorization: 'Bearer ' + tok, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await r.text();
  let d = {};
  try { d = text ? JSON.parse(text) : {}; } catch { d = { raw: text }; }
  if (!r.ok && !(method === 'DELETE' && r.status === 404)) throw new Error(`${method} ${url.split('?')[0]} → ${r.status} ${d.error?.message || ''}`);
  return d;
}

const iso = (ms) => (ms ? new Date(Number(ms)).toISOString().replace('.000Z', 'Z') : '-');

async function main() {
  const [cmd, ...args] = process.argv.slice(2);
  const sa = loadSa();
  const project = sa.project_id;
  const tok = await accessToken(sa);
  const idt = `https://identitytoolkit.googleapis.com/v1/projects/${project}`;
  const fs = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;

  if (cmd === 'list-users') {
    const limit = Number(args[args.indexOf('--limit') + 1]) || 500;
    let pageToken = '';
    const out = [];
    do {
      const d = await call(tok, 'GET', `${idt}/accounts:batchGet?maxResults=${Math.min(limit, 500)}${pageToken ? '&nextPageToken=' + pageToken : ''}`);
      out.push(...(d.users || []));
      pageToken = d.nextPageToken || '';
    } while (pageToken && out.length < limit);
    out.sort((a, b) => Number(b.lastLoginAt || b.createdAt || 0) - Number(a.lastLoginAt || a.createdAt || 0));
    console.log(`${out.length} account(s), most recent sign-in first:`);
    for (const u of out) {
      const providers = (u.providerUserInfo || []).map((p) => p.providerId).join(',') || (u.phoneNumber ? 'phone' : 'anonymous');
      const claims = u.customAttributes ? ` claims=${u.customAttributes}` : '';
      console.log([u.localId, u.email || '-', JSON.stringify(u.displayName || ''), providers,
        'created ' + iso(u.createdAt), 'last ' + iso(u.lastLoginAt), u.disabled ? 'DISABLED' : ''].join(' | ') + claims);
    }
    return;
  }
  if (cmd === 'list-admins') {
    const d = await call(tok, 'GET', `${fs}/admins?pageSize=300`);
    const docs = d.documents || [];
    console.log(`${docs.length} admin doc(s):`);
    for (const x of docs) console.log(x.name.split('/').pop(), JSON.stringify(x.fields || {}));
    return;
  }
  if (cmd === 'mark-admin' || cmd === 'unmark-admin') {
    const uid = args.find((a) => !a.startsWith('--'));
    if (!uid) throw new Error('Give the uid.');
    const look = await call(tok, 'POST', `${idt}/accounts:lookup`, { localId: [uid] });
    const user = (look.users || [])[0];
    if (!user) throw new Error('No Auth account with uid ' + uid);
    const claims = user.customAttributes ? JSON.parse(user.customAttributes) : {};
    if (cmd === 'mark-admin') {
      await call(tok, 'PATCH', `${fs}/admins/${encodeURIComponent(uid)}`, {
        fields: {
          email: { stringValue: user.email || '' },
          addedAt: { timestampValue: new Date().toISOString() },
          addedBy: { stringValue: 'tools/firebase/admin-tool.mjs' },
        },
      });
      console.log(`admins/${uid} written (${user.email || 'no email'}).`);
      if (args.includes('--claim')) {
        await call(tok, 'POST', `${idt}/accounts:update`, { localId: uid, customAttributes: JSON.stringify({ ...claims, admin: true }) });
        console.log('custom claim admin:true set — sign out and in again to pick it up.');
      }
    } else {
      await call(tok, 'DELETE', `${fs}/admins/${encodeURIComponent(uid)}`);
      if (claims.admin) {
        delete claims.admin;
        await call(tok, 'POST', `${idt}/accounts:update`, { localId: uid, customAttributes: JSON.stringify(claims) });
      }
      console.log(`admin removed for ${uid}.`);
    }
    return;
  }
  console.log('Commands: list-users | list-admins | mark-admin <uid> [--claim] | unmark-admin <uid>');
}

main().catch((e) => { console.error('Error:', e.message); process.exit(1); });
