import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { test } from 'node:test';

const root = new URL('..', import.meta.url).pathname;
const read = (relative) => readFileSync(`${root}/${relative}`, 'utf8');
const hash = (relative) => createHash('sha256').update(readFileSync(`${root}/${relative}`)).digest('hex');

test('Flutter copies the exact working WebView adaptive launcher resources', (t) => {
  const generator = read('tools/flutter-android.mjs');
  assert.match(generator, /adaptive-res/);
  assert.match(generator, /for \(const folder of \[/);
  assert.match(generator, /'drawable-v24'/);
  assert.match(generator, /'mipmap-anydpi-v26'/);
  assert.match(generator, /'mipmap-xxxhdpi'/);
  assert.doesNotMatch(generator, /cpSync\(ICON_SRC, res/);
  // android/ is the gitignored Capacitor project (`npm run android:add` +
  // `npm run android:assets`). Compare byte-for-byte when it has been
  // generated; on a plain checkout there is nothing to compare against.
  if (!existsSync(`${root}/android/app/src/main/res`)) {
    t.diagnostic('android/ not generated (gitignored Capacitor output); skipped byte comparison');
    return;
  }
  for (const relative of [
    'mipmap-xxxhdpi/ic_launcher.png',
    'mipmap-xxxhdpi/ic_launcher_foreground.png',
    'mipmap-anydpi-v26/ic_launcher.xml',
  ]) {
    assert.equal(
      hash(`android/app/src/main/res/${relative}`),
      hash(`flutter_app/android-config/adaptive-res/${relative}`),
      `${relative} must match the working WebView resource exactly`,
    );
  }
});

test('iOS targets preserve NowssB identity and authenticated sign-in configuration', () => {
  const webviewInfo = read('ios/App/App/Info.plist');
  const webviewProject = read('ios/App/App.xcodeproj/project.pbxproj');
  const flutterScript = read('tools/flutter-ios.mjs');
  const webAuth = read('app/js/firebase.module.js');
  assert.match(webviewInfo, /<string>NowssB<\/string>/);
  assert.match(webviewInfo, /com\.googleusercontent\.apps\.1024709686012-0v0fcd2h694hep2j9ni2dqejean6e00c/);
  assert.match(webviewProject, /GoogleService-Info\.plist in Resources/);
  assert.match(flutterScript, /GoogleService-Info\.plist/);
  assert.match(flutterScript, /const appId = 'com\.nowssb\.app'/);
  assert.match(flutterScript, /replace\(\/PRODUCT_BUNDLE_IDENTIFIER = \[\^;\]\+;\/g/);
  assert.match(webAuth, /isCapacitorIOS/);
  assert.match(webAuth, /const isNativeShell =/);
  assert.match(webAuth, /if \(isNativeShell \|\| isCapacitorIOS\)[\s\S]*?signInWithRedirect/);
});
