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
  const html = read('index.html');
  assert.match(html, /id="authLoader"[\s\S]*?auth-loader-ring/);
  assert.doesNotMatch(html.match(/<div id="authLoader">[\s\S]*?<\/div>/)?.[0] || '', /<video/);
  assert.match(html, /id="login"[\s\S]*?login-phone-poster\.webp/);
  // bec0c918 deliberately put the full-bleed login film back on the phone.
  // It must never hold sign-in hostage: the poster paints first, the clip is
  // muted inline autoplay, and it never intercepts taps.
  const loginFilm = html.match(/<video class="lg-phone-vid"[^>]*>/)?.[0] || '';
  assert.match(loginFilm, /autoplay muted loop playsinline/);
  assert.match(loginFilm, /poster="\.\/assets\/video\/login-phone-poster\.webp"/);
  assert.match(read('nowssb-nm.css'), /\.lg-phone-vid \{[^}]*pointer-events: none/);
  assert.match(source, /const result = await signInWithEmailAndPassword/);
  assert.match(source, /const result = await createUserWithEmailAndPassword/);
  assert.match(source, /const isNativeShell =/);
  assert.match(source, /if \(isNativeShell \|\| isCapacitorIOS\)/);
  assert.match(source, /await signInWithRedirect\(auth, provider\)/);
  // e307c729: login is strictly sign-in. A missing account and a bad password
  // are reported, never silently turned into createUserWithEmailAndPassword.
  const emailLogin = source.slice(source.indexOf('window.fbEmailLogin'), source.indexOf('window.fbSignUp'));
  assert.match(emailLogin, /code === 'auth\/user-not-found'/);
  assert.match(emailLogin, /code === 'auth\/invalid-credential'/);
  assert.doesNotMatch(emailLogin, /createUserWithEmailAndPassword/);
  assert.match(source, /_ensureLoginExit\(result\.user\)/);
});

test('Flutter has a credential gate rather than leaving a user on video', () => {
  const app = read('flutter_app/lib/main.dart');
  const gate = read('flutter_app/lib/screens/auth_gate.dart');
  // 45d7711d wraps the shell in AdminAppGate; AuthGate must still be outermost.
  assert.match(app, /AuthGate\(child: (?:AdminAppGate\(child: )?NavShell\(\)\)/);
  assert.match(gate, /FirebaseAuth\.instance\.authStateChanges\(\)/);
  assert.match(gate, /GoogleSignIn/);
  assert.match(gate, /signInWithEmailAndPassword/);
  assert.match(gate, /Sign-in is taking too long/);
  // 341d4cc7 rebuilt the gate around the neon portrait (LoginStage); phone
  // sign-in is entered in the same field and still verified by SMS.
  const stage = read('flutter_app/lib/widgets/login_stage.dart');
  assert.match(gate, /body: LoginStage\(/);
  assert.match(stage, /assets\/login\/login-neon\.png/);
  assert.match(stage, /Continue with Google/);
  assert.match(gate, /verifyPhoneNumber/);
  assert.match(gate, /PhoneAuthProvider\.credential/);
  assert.match(gate, /serverClientId/);
});
