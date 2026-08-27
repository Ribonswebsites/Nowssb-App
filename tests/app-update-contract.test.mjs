import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const root = new URL('..', import.meta.url).pathname;
const read = (relative) => readFileSync(`${root}/${relative}`, 'utf8');

test('every successful Android build publishes a stable APK before its update manifest', () => {
  const webview = read('.github/workflows/android-apk.yml');
  const flutter = read('.github/workflows/flutter-apk.yml');
  const build = read('tools/build-native.mjs');

  assert.match(webview, /NWSB_BUILD_NUMBER: \$\{\{ github\.run_number \}\}/);
  assert.match(webview, /tools\/capacitor-android-version\.mjs/);
  assert.match(webview, /NowssB-Android\.apk/);
  assert.match(webview, /NowssB-WebView-update\.json/);
  assert.match(webview, /gh release upload "\$TAG" "\$PUBLIC_FILE"[\s\S]*gh release upload "\$TAG" "\$UPDATE_FILE"/);
  assert.match(flutter, /NWSB_BUILD_NUMBER=\$\{\{ github\.run_number \}\}/);
  assert.match(flutter, /tools\/flutter-version\.mjs/);
  assert.match(flutter, /NowssB-Flutter-Android\.apk/);
  assert.match(flutter, /NowssB-Flutter-update\.json/);
  assert.match(flutter, /permissions:\s*\n\s*contents: write/);
  assert.match(build, /app-build\.json/);
  assert.match(build, /NWSB_BUILD_NUMBER/);
  assert.match(read('tools/capacitor-android-version.mjs'), /versionCode/);
  assert.match(read('tools/flutter-version.mjs'), /version: 9\.5\.0\+\$\{build\}/);
});

test('installed WebView checks a no-cache manifest and opens the official update destination', () => {
  const index = read('index.html');
  const update = read('app/js/part078.js');

  assert.match(index, /app\/js\/part078\.js\?v=2/);
  assert.match(update, /NowssB-WebView-update\.json/);
  assert.match(update, /app-build\.json/);
  assert.match(update, /next > local/);
  assert.match(update, /nwsb_update_later_webview/);
  assert.match(update, /Capacitor\.Plugins.*Browser/);
  assert.match(update, /websiteUrl \|\| remote\.apkUrl/);
});

test('installed Flutter checks its real release manifest after splash and on foreground return', () => {
  const update = read('flutter_app/lib/app_update.dart');
  const app = read('flutter_app/lib/main.dart');
  const pubspec = read('flutter_app/pubspec.yaml');

  assert.match(update, /NowssB-Flutter-update\.json/);
  assert.match(update, /int\.fromEnvironment\('NWSB_BUILD_NUMBER'/);
  assert.match(update, /build <= currentBuild/);
  assert.match(app, /NwsbAppUpdate\.findNewer/);
  assert.match(app, /LaunchMode\.externalApplication/);
  assert.match(app, /launchUrl\(update\.apkUrl/);
  assert.match(app, /AppLifecycleState\.resumed[\s\S]*_checkForUpdate/);
  assert.match(pubspec, /url_launcher: \^6\.3\.2/);
});
