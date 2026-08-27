import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { test } from 'node:test';

const root = new URL('..', import.meta.url).pathname;
const read = (relative) => readFileSync(`${root}/${relative}`, 'utf8');
const hash = (relative) => createHash('sha256').update(readFileSync(`${root}/${relative}`)).digest('hex');

test('Flutter copies the exact working WebView adaptive launcher resources', () => {
  const generator = read('tools/flutter-android.mjs');
  assert.match(generator, /adaptive-res/);
  assert.match(generator, /cpSync\(ICON_SRC, res/);
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
  assert.match(webAuth, /if \(isCapacitorIOS\)[\s\S]*?signInWithRedirect/);
});
