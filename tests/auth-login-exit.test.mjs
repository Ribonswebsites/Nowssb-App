import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const root = new URL('..', import.meta.url).pathname;
const read = (relative) => readFileSync(`${root}/${relative}`, 'utf8');

test('WebView sign-in has an idempotent exit from the loader video', () => {
  const source = read('app/js/firebase.module.js');
  assert.match(source, /function _ensureLoginExit\(user\)/);
  assert.match(source, /function _authTransitionActive\(\)/);
  assert.match(source, /document\.querySelector\('\.screen\.active'\)/);
  assert.match(source, /if \(_authTransitionActive\(\)\) _doNavigate\(fallbackDest\)/);
  assert.match(source, /function _hideAuthLoader\(\)[\s\S]*?loader\.classList\.remove\('visible'\)/);
  assert.match(source, /const result = await signInWithEmailAndPassword/);
  assert.match(source, /const result = await createUserWithEmailAndPassword/);
  assert.match(source, /_ensureLoginExit\(result\.user\)/);
});

test('Flutter has a credential gate rather than leaving a user on video', () => {
  const app = read('flutter_app/lib/main.dart');
  const gate = read('flutter_app/lib/screens/auth_gate.dart');
  assert.match(app, /AuthGate\(child: NavShell\(\)\)/);
  assert.match(gate, /FirebaseAuth\.instance\.authStateChanges\(\)/);
  assert.match(gate, /GoogleSignIn/);
  assert.match(gate, /signInWithEmailAndPassword/);
  assert.match(gate, /Sign-in is taking too long/);
  assert.doesNotMatch(gate, /VideoPlayer/);
});
