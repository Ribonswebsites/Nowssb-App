import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const root = new URL('..', import.meta.url).pathname;
const read = (relative) => readFileSync(`${root}/${relative}`, 'utf8');

test('website and WebView downloads use the supplied listing and the correct latest APK', () => {
  const page = read('index.html');
  const install = read('app/js/part012.js');
  const listing = read('nowssb-listing-2.html');
  const workflow = read('.github/workflows/android-apk.yml');
  const flutterWorkflow = read('.github/workflows/flutter-apk.yml');
  const middleware = read('functions/_middleware.js');

  assert.match(page, /nowssb-listing-2\.html/);
  assert.match(install, /window\.location\.href = '\.\/nowssb-listing-2\.html'/);
  assert.match(listing, /nowssb-android\/NowssB-Android\.apk/);
  assert.match(listing, /nowssb\.com\/download\/flutter\.apk/);
  assert.match(listing, /inCapacitorWebView/);
  assert.match(listing, /window\.nwsbIsNative/);
  assert.match(listing, /Plugins && capacitor\.Plugins\.Browser/);
  assert.match(listing, /window\.location\.assign\(apk\)/);
  assert.match(listing, /window\.goBack/);
  assert.match(listing, /role="button"/);
  assert.match(listing, /listing-hero-wrap/);
  assert.match(listing, /padding:16px/);
  assert.match(listing, /border-radius:24px/);
  assert.match(listing, /height:clamp\(140px, 28vw, 220px\)/);
  assert.match(listing, /assets\/app-listing\/listing-hero-banner\.png/);
  assert.match(listing, /hero-back-btn/);
  assert.match(listing, /left:12px/);
  assert.match(listing, /right:auto/);
  assert.match(listing, /hero-back-btn/);
  assert.match(listing, /background:#fff/);
  assert.doesNotMatch(listing, /Download the app<br>/);
  assert.doesNotMatch(listing, /class="page-title"/);
  assert.doesNotMatch(listing, /header-divider/);
  assert.match(listing, /scroll-track/);
  assert.match(listing, /gallery-track/);
  assert.match(listing, /data-auto-direction="1"/);
  assert.match(listing, /data-auto-direction="-1"/);
  assert.match(listing, /requestAnimationFrame\(tick\)/);
  assert.match(listing, /assets\/app-listing\/listing-01\.webp/);
  assert.match(listing, /loading="lazy"/);
  assert.match(listing, /NowssB-Flutter-Android\.apk/);
  assert.doesNotMatch(listing, /data:image/);
  assert.doesNotMatch(listing, /artifacts\/download/);
  assert.match(workflow, /permissions:\s*\n\s+contents: write/);
  assert.match(workflow, /Publish direct NowssB APK/);
  assert.match(workflow, /PUBLIC_FILE=NowssB-Android\.apk/);
  assert.match(flutterWorkflow, /Publish direct Flutter APK and update manifest/);
  assert.match(flutterWorkflow, /PUBLIC_FILE=NowssB-Flutter-Android\.apk/);
  assert.match(middleware, /url\.pathname === '\/download\/flutter\.apk'/);
  assert.match(middleware, /Content-Disposition/);
  assert.match(middleware, /application\/vnd\.android\.package-archive/);
});


test('Fashion Plus keeps one live film behind every page and menu', () => {
  const page = read('index.html');
  const playback = read('app/js/part051.js');
  const fashion = read('app/js/part076.js');
  const css = read('nowssb-nm.css');

  assert.match(page, /part051\.js\?v=25/);
  assert.match(page, /part076\.js\?v=117/);
  assert.match(page, /nowssb-nm\.css\?v=795/);
  assert.match(playback, /v\.id === 'fpBgVideo' \|\| v\.id === 'fpPageVid'/);
  assert.match(fashion, /document\.getElementById\('fpBgVideo'\)/);
  assert.match(fashion, /v\.play\(\)/);
  assert.match(fashion, /nwsb-settings-open/);
  assert.match(fashion, /settingsOpen/);
  assert.match(css, /body\.fashplus:not\(\.fp-bg-off\) \.sub-screen\.open/);
  assert.match(css, /body\.fashplus:not\(\.fp-bg-off\) #menuDrawer\.menu-drawer/);
  assert.match(css, /prefers-reduced-motion: reduce/);
  assert.match(css, /body\.nwsb-settings-open #fpBgVideo/);
  assert.match(css, /body\.nwsb-settings-open #sub-social/);
  assert.match(css, /background: #f0f2f7 !important/);
});


test('login has no transition video and Fashion Plus restores intro artwork above the film', () => {
  const page = read('index.html');
  const auth = read('app/js/firebase.module.js');
  const middleware = read('functions/_middleware.js');
  const fashion = read('app/js/part076.js');
  const css = read('nowssb-nm.css');

  assert.match(page, /firebase\.module\.js\?v=266/);
  assert.doesNotMatch(page.match(/<div id="login"[\s\S]*?<\/div>\s*<\/div>\s*<\/div>/)?.[0] || '', /<video/);
  assert.match(page, /login-phone-poster\.webp/);
  assert.match(auth, /signInWithEmailAndPassword/);
  assert.match(auth, /auth\/invalid-credential/);
  assert.doesNotMatch(middleware, /loading\.mp4/);
  assert.doesNotMatch(middleware, /AUTH_LOADER/);
  assert.match(fashion, /restoreIntroArtwork/);
  assert.match(fashion, /fp-intro-art/);
  assert.match(css, /\.fp-intro-layer/);
  assert.match(css, /\.fp-intro-art/);
  assert.match(css, /\.sl-intro-page/);
  assert.match(css, /background: transparent !important/);
});
