import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

const root = new URL('..', import.meta.url);
const read = (path) => readFileSync(new URL(path, root), 'utf8');

test('Flutter resolves every primary-page backdrop from the selected Fashion Plus media', () => {
  const settings = read('flutter_app/lib/data/settings.dart');
  const backdrop = read('flutter_app/lib/widgets/app_backdrop.dart');

  assert.match(settings, /static const _kVideo = 'nwsb_fashplus_video'/);
  assert.match(settings, /static const _kImage = 'nwsb_fashplus_image'/);
  assert.match(settings, /String get fashionVideoAsset => fashionVideos\[_fashionVideo\]/);
  assert.match(settings, /String\? get fashionImageAsset/);
  assert.match(settings, /int get backgroundTransition => _backgroundTransition/);
  assert.match(settings, /void fadeBackgroundForNavigation\(\)/);
  assert.match(backdrop, /if \(settings\.fashionPlus\)/);
  assert.match(backdrop, /asset: settings\.fashionVideoAsset/);
  assert.match(backdrop, /final image = settings\.fashionImageAsset/);
  assert.match(backdrop, /const ColoredBox\(color: NwsbColors\.deep\)/);
  assert.match(backdrop, /AnimatedSwitcher\(/);
  assert.match(backdrop, /Duration\(milliseconds: 360\)/);

  for (const file of [
    'flutter_app/lib/widgets/page_shell.dart',
    'flutter_app/lib/widgets/intro_gate.dart',
    'flutter_app/lib/screens/home_fashion.dart',
    'flutter_app/lib/screens/home_normal.dart',
    'flutter_app/lib/screens/word_detail.dart',
    'flutter_app/lib/screens/practice_player.dart',
    'flutter_app/lib/screens/personal_coach.dart',
  ]) {
    assert.match(read(file), /AppBackdrop/, `${file} must use the shared backdrop`);
  }
});

test('WebView refreshes selected Fashion Plus video and image backgrounds for every opened page', () => {
  const navigation = read('app/js/part012.js');
  const fashion = read('app/js/part076.js');
  const mode = read('app/js/part066.js');
  const css = read('nowssb-nm.css');
  const html = read('index.html');

  assert.match(fashion, /window\.fpBgVid = function \(\) \{ return FILMS\[bgChoice\(\)\]\.vid; \}/);
  assert.match(fashion, /function syncOpenPageBackdrop\(\)/);
  assert.match(mode, /window\.nwsbFpBackgrounds\(isOn\)/);
  assert.match(fashion, /function bgPartOn\(\) \{ return isOn\(\); \}/);
  assert.match(fashion, /addEventListener\('loadeddata'/);
  assert.match(fashion, /function observePageOpenState\(\)/);
  assert.match(fashion, /new MutationObserver/);
  assert.match(fashion, /target\.classList\.contains\('sub-screen'\)/);
  assert.match(fashion, /window\.nwsbFpFadeBackground = function \(\)/);
  assert.match(fashion, /document\.body\.classList\.toggle\('nwsb-sub-open', hasOpenPage\)/);
  assert.match(navigation, /window\.nwsbFpSyncPageBackdrop\(\)/);
  assert.match(navigation, /document\.body\.classList\.add\('nwsb-menu-open'\)/);
  assert.match(navigation, /document\.body\.classList\.remove\('nwsb-menu-open'\)/);
  assert.match(navigation, /window\.nwsbFpFadeBackground\(\)/);
  assert.match(navigation, /requestAnimationFrame\(function \(\) \{ _playScreenVideos\(sub\.id\); \}\)/);
  assert.match(navigation, /v\.muted = true/);
  assert.match(css, /\.fp-sub-open #fpBgVideo/);
  assert.match(css, /body\.fashplus:not\(\.fp-bg-off\) \.sub-screen\.open/);
  assert.match(css, /fash-plyr-wrap > #todayPracticeCard\.fp-card/);
  assert.match(css, /height: clamp\(230px, 50vw, 360px\)/);
  assert.match(css, /todayPracticeCard\.fp-card > \.fp-media/);
  assert.match(css, /sub-screen\.open > \.sub-screen-bg video/);
  assert.match(css, /display: none !important/);
  assert.match(css, /\.nwsb-sub-open #appBg/);
  assert.match(css, /\.nwsb-menu-open #fpBgVideo/);
  assert.match(css, /\.nwsb-menu-open #appBg/);
  assert.match(css, /nwsb-bg-fade-out/);
  assert.match(css, /body\.nwsb-custom-fashion-bg:not\(\.fashplus\) #appBg/);
  assert.match(html, /nowssb-nm\.css\?v=792/);
  assert.match(html, /part012\.js\?v=257/);
  assert.match(html, /part076\.js\?v=114/);
});
