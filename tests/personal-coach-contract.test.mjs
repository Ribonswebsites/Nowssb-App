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

test('WebView coach calls the active secure Worker and has no canned response', () => {
  const source = read('app/js/personal-coach-live.js');
  const renderer = read('app/js/part095-direct-neomorphic-sections.js');
  assert.match(source, /nowssb-api\.ribonpatil2\.workers\.dev\/api\/assistant\/chat/);
  assert.match(source, /getIdToken/);
  assert.match(source, /mode: 'coach'/);
  assert.match(source, /saveMessages/);
  assert.match(source, /Plan my day/);
  assert.match(renderer, /NowssbPersonalCoach\.mount/);
  assert.doesNotMatch(source, /start with one focused practice now/);
});

test('Flutter coach is native, authenticated, persistent, and asset-backed', () => {
  const screen = read('flutter_app/lib/screens/personal_coach.dart');
  const pubspec = read('flutter_app/pubspec.yaml');
  assert.match(screen, /GoogleSignIn/);
  assert.match(screen, /FirebaseAuth/);
  assert.match(screen, /getIdToken/);
  assert.match(screen, /FirebaseFirestore/);
  assert.match(screen, /PracticeProgress/);
  assert.match(screen, /nowssb-api\.ribonpatil2\.workers\.dev\/api\/assistant\/chat/);
  assert.match(screen, /assets\/coach\/personal_coach_hero\.jpg/);
  assert.match(pubspec, /- assets\/coach\//);
  assert.ok(existsSync(`${root}/flutter_app/assets/coach/personal_coach_hero.jpg`));
});

test('Firestore rules keep coach history owner-only', () => {
  const rules = read('firestore.rules');
  assert.match(rules, /match \/users\/{uid}\/coachConversations\/{conversationId}/);
  assert.match(rules, /match \/messages\/{messageId}/);
  assert.match(rules, /request\.auth\.uid == uid/);
});
