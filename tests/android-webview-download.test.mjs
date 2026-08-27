import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const root = new URL('..', import.meta.url).pathname;
const read = (relative) => readFileSync(`${root}/${relative}`, 'utf8');

test('Android download sends visitors to the direct WebView APK, not a PWA prompt or ZIP', () => {
  const page = read('index.html');
  const install = read('app/js/part012.js');
  const workflow = read('.github/workflows/android-apk.yml');

  assert.match(page, /id="dlAndroidInstallNote"/);
  assert.match(install, /function isAndroid\(\)/);
  assert.match(install, /if \(isAndroid\(\)\) \{[\s\S]*?webview-latest\/NowssB-WebView\.apk/);
  assert.match(install, /Direct WebView APK/);
  assert.doesNotMatch(install, /artifacts\/download/);
  assert.match(workflow, /permissions:\s*\n\s+contents: write/);
  assert.match(workflow, /Publish direct WebView APK/);
  assert.match(workflow, /PUBLIC_FILE=NowssB-WebView\.apk/);
  assert.match(workflow, /gh release upload .*\$PUBLIC_FILE/);
});
