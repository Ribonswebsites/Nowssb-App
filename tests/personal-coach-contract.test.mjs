import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { test } from 'node:test';

const root = new URL('..', import.meta.url).pathname;
const read = (relative) => readFileSync(`${root}/${relative}`, 'utf8');

test('coach API is authenticated, persisted, and provider-backed', () => {
  const source = read('functions/api/coach.js');
  assert.match(source, /Authorization/);
  assert.match(source, /verifyIdToken/);
  assert.match(source, /COACH_LLM_API_URL/);
  assert.match(source, /COACH_LLM_API_KEY/);
  assert.match(source, /users\/\$\{uidPath\}\/coachConversations/);
  assert.match(source, /export async function onRequest/);
  assert.match(source, /request\.method === 'GET'/);
  assert.match(source, /request\.method === 'POST'/);
});

test('web coach calls the real API and has no canned response', () => {
  const source = read('app/js/part095-direct-neomorphic-sections.js');
  assert.match(source, /fetch\('\/api\/coach'/);
  assert.match(source, /getIdToken/);
  assert.match(source, /loadHistory/);
  assert.match(source, /conversationId/);
  assert.match(source, /start_practice/);
  assert.doesNotMatch(source, /start with one focused practice now/);
});

test('Flutter coach is native, authenticated, persistent-by-server, and asset-backed', () => {
  const screen = read('flutter_app/lib/screens/personal_coach.dart');
  const api = read('flutter_app/lib/data/coach_api.dart');
  const pubspec = read('flutter_app/pubspec.yaml');
  assert.match(screen, /CoachApi/);
  assert.match(screen, /assets\/coach\/coach-orb\.png/);
  assert.match(screen, /completedTodayFor/);
  assert.match(api, /getIdToken/);
  assert.match(api, /\/api\/coach/);
  assert.match(api, /loadHistory/);
  assert.match(api, /conversationId/);
  assert.match(pubspec, /- assets\/coach\//);
  assert.ok(existsSync(`${root}/assets/coach/coach-orb.png`));
  assert.ok(existsSync(`${root}/flutter_app/assets/coach/coach-orb.png`));
});

test('Firestore rules keep coach history owner-only', () => {
  const rules = read('firestore.rules');
  assert.match(rules, /match \/users\/{uid}\/coachConversations\/{conversationId}/);
  assert.match(rules, /match \/messages\/{messageId}/);
  assert.match(rules, /request\.auth\.uid == uid/);
});
