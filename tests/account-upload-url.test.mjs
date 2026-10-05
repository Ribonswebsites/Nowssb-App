// Offline tests for POST /api/account/upload-url (user avatar → R2).
// Run: node --test tests/account-upload-url.test.mjs
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

import {
  ALLOWED_IMAGE_TYPES,
  MAX_BYTES,
  buildAvatarKey,
  isUserAvatarKey,
  resolveImageExt,
  onRequestPost,
  onRequest,
} from '../functions/api/account/upload-url.js';
import { presignPut, publicObjectUrl } from '../functions/_lib/r2_presign.js';

const root = new URL('..', import.meta.url).pathname;
const read = (relative) => readFileSync(`${root}/${relative}`, 'utf8');

test('source: account upload-url is auth-gated and user-owned', () => {
  const source = read('functions/api/account/upload-url.js');
  assert.match(source, /requireUser/);
  assert.match(source, /'users\/' \+ safeUid \+ '\/avatar\//);
  assert.match(source, /image\/jpeg/);
  assert.match(source, /image\/png/);
  assert.match(source, /image\/webp/);
  assert.match(source, /MAX_BYTES/);
  assert.match(source, /uploadUrl/);
  assert.match(source, /publicUrl/);
  assert.match(source, /expiresIn/);
  assert.doesNotMatch(source, /isAdmin/);
  // Must never accept a client-chosen arbitrary key.
  assert.doesNotMatch(source, /body\.key/);
  assert.doesNotMatch(source, /body\.path/);
});

test('source: profile.dart wires avatar upload + prefs + Firestore photoURL', () => {
  const profile = read('flutter_app/lib/screens/profile.dart');
  assert.match(profile, /\/api\/account\/upload-url/);
  assert.match(profile, /nwsb_local_photo/);
  assert.match(profile, /photoURL/);
  assert.match(profile, /publicProfiles/);
  assert.match(profile, /ScaffoldMessenger/);
  assert.match(profile, /uploadUrl/);
  assert.match(profile, /mounted/);
});

test('resolveImageExt accepts only jpeg/png/webp', () => {
  assert.equal(resolveImageExt('image/jpeg', 'jpg'), 'jpg');
  assert.equal(resolveImageExt('image/jpeg', 'jpeg'), 'jpg');
  assert.equal(resolveImageExt('image/png', 'png'), 'png');
  assert.equal(resolveImageExt('image/webp', 'webp'), 'webp');
  assert.equal(resolveImageExt('image/gif', 'gif'), null);
  assert.equal(resolveImageExt('application/octet-stream', 'jpg'), null);
  assert.equal(resolveImageExt('image/jpeg', 'png'), null); // type/ext mismatch
  assert.equal(Object.keys(ALLOWED_IMAGE_TYPES).sort().join(','), 'image/jpeg,image/png,image/webp');
  assert.equal(MAX_BYTES, 5 * 1024 * 1024);
});

test('buildAvatarKey is always under users/{uid}/avatar/', () => {
  const key = buildAvatarKey('uid_ABC-123', 'jpg', { uuid: '11111111-2222-3333-4444-555555555555' });
  assert.equal(key, 'users/uid_ABC-123/avatar/11111111-2222-3333-4444-555555555555.jpg');
  assert.equal(isUserAvatarKey(key, 'uid_ABC-123'), true);
  assert.equal(isUserAvatarKey(key, 'other'), false);
  assert.equal(isUserAvatarKey('users/uid_ABC-123/evil/x.jpg', 'uid_ABC-123'), false);
  assert.equal(isUserAvatarKey('ui/slot/x.jpg', 'uid_ABC-123'), false);
  assert.equal(isUserAvatarKey('users/uid_ABC-123/avatar/../x.jpg', 'uid_ABC-123'), false);
  // Path traversal / injection attempts are stripped from uid.
  const scrubbed = buildAvatarKey('../admin', 'png', { uuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' });
  assert.equal(scrubbed, 'users/admin/avatar/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.png');
  assert.ok(scrubbed.startsWith('users/admin/avatar/'));
});

test('presignPut URL contains the avatar key and signature params', async () => {
  const key = 'users/u1/avatar/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.webp';
  const url = await presignPut({
    accountId: 'acct',
    bucket: 'bucket',
    accessKeyId: 'AKIAEXAMPLE',
    secret: 'secretsecretsecretsecret',
    key,
    expires: 900,
    now: new Date('2026-10-05T08:00:00.000Z'),
    signedHeaders: { 'content-type': 'image/webp', 'content-length': '12' },
  });
  assert.match(url, /^https:\/\/acct\.r2\.cloudflarestorage\.com\/bucket\/users\/u1\/avatar\//);
  assert.match(url, /X-Amz-Algorithm=AWS4-HMAC-SHA256/);
  assert.match(url, /X-Amz-Signature=[0-9a-f]{64}/);
  assert.match(url, /X-Amz-SignedHeaders=content-length%3Bcontent-type%3Bhost/);
  assert.equal(
    publicObjectUrl('https://media.nowssb.com/', key),
    'https://media.nowssb.com/users/u1/avatar/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.webp',
  );
});

test('POST without Authorization is rejected (401)', async () => {
  const res = await onRequestPost({
    request: new Request('https://nowssb.com/api/account/upload-url', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ contentType: 'image/jpeg', ext: 'jpg', contentLength: 10 }),
    }),
    env: { FIREBASE_PROJECT_ID: 'nowssb-34f1b' },
  });
  assert.equal(res.status, 401);
  const body = await res.json();
  assert.match(String(body.error || ''), /Sign in/i);
});

test('non-POST is rejected (405)', async () => {
  const res = await onRequest({
    request: new Request('https://nowssb.com/api/account/upload-url', { method: 'GET' }),
    env: {},
  });
  assert.equal(res.status, 405);
});
