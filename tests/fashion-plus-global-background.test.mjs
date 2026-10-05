import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { assertCacheBustAtLeast } from './helpers/source-contract.mjs';

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
    'flutter_app/lib/screens/home_fashion.dart',
    'flutter_app/lib/screens/word_detail.dart',
    'flutter_app/lib/screens/personal_coach.dart',
    'flutter_app/lib/screens/sound_library.dart',
    'flutter_app/lib/screens/widgets_page.dart',
  ]) {
    assert.match(read(file), /AppBackdrop/, `${file} must use the shared backdrop`);
  }
  // Deliberate exceptions — these surfaces own their own ground:
  //  - intro gate: fixed near-black under the photo ring (30c664b6)
  //  - Normal home: the pale neumorphic page, never the Fashion film (7882aeee)
  //  - Now Playing: the black Oblivion player (16fb270a)
  assert.match(read('flutter_app/lib/widgets/intro_gate.dart'), /const ColoredBox\(color: Color\(0xFF050506\)\)/);
  assert.doesNotMatch(read('flutter_app/lib/screens/home_normal.dart'), /AppBackdrop\(/);
  assert.doesNotMatch(read('flutter_app/lib/screens/practice_player.dart'), /AppBackdrop\(/);
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
  // Floors from 6eb21a8b. bec0c918 (stale base) dropped these back to
  // 801/257/120/25/8 while keeping the new JS, so clients kept stale files.
  assertCacheBustAtLeast(html, 'nowssb-nm.css', 802);
  assertCacheBustAtLeast(html, 'part012.js', 258);
  assertCacheBustAtLeast(html, 'part076.js', 121);
  assertCacheBustAtLeast(html, 'part082.js', 26);
  assertCacheBustAtLeast(html, 'widgets.css', 9);
  assert.match(fashion, /socialSettingsOpen/);
  assert.match(fashion, /widgetsSettingsOpen/);
  assert.match(fashion, /#sub-settings\.sub-screen\.open/);
  assert.match(navigation, /nwsbFpSyncPageBackdrop/);
  assert.match(css, /body:not\(\.nm-mode\):not\(\.fashplus\) #menuDrawer\.menu-drawer/);
  assert.match(css, /background: #000 !important/);
  assert.match(css, /Widgets Settings \(#sub-settings\) on Fashion home/);
});

test('Widgets Settings and Fashion menu use Plus film or solid black', () => {
  const fashion = read('app/js/part076.js');
  const settings = read('app/js/part082.js');
  const navigation = read('app/js/part012.js');
  const css = read('nowssb-nm.css');
  const widgets = read('app/widgets.css');

  assert.match(fashion, /var socialSettingsOpen = !!document\.querySelector\('#sub-social\.sub-screen\.open'\)/);
  assert.match(fashion, /var widgetsSettingsOpen = !!document\.querySelector\('#sub-settings\.sub-screen\.open'\)/);
  assert.doesNotMatch(fashion, /settingsOpen = !!document\.querySelector\('#sub-settings/);
  assert.match(settings, /host\.style\.backgroundColor = '#000'/);
  assert.match(settings, /window\.nwsbFpSyncPageBackdrop\(\)/);
  assert.match(navigation, /function openMenu\(\)[\s\S]*nwsbFpSyncPageBackdrop/);
  assert.match(css, /body:not\(\.nm-mode\):not\(\.fashplus\) #menuDrawer\.menu-drawer/);
  assert.match(css, /body:not\(\.nm-mode\):not\(\.fashplus\) #sub-settings/);
  assert.match(widgets, /Fashion Widgets Settings backdrop/);
});
