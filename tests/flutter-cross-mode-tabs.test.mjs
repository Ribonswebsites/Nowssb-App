import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

const root = new URL('..', import.meta.url);
const read = (path) => readFileSync(new URL(path, root), 'utf8');

test('Flutter provides all five primary tabs in both Normal and Fashion home modes', () => {
  const shell = read('flutter_app/lib/shell/nav_shell.dart');
  const normal = read('flutter_app/lib/screens/home_normal.dart');
  const fashion = read('flutter_app/lib/screens/home_fashion.dart');

  for (const tab of ['Connect', 'Practice', 'Library', 'Store', 'Profile']) {
    assert.match(shell, new RegExp(`'label': '${tab}'`));
  }
  assert.match(shell, /_fashion \? const HomeFashion\(\) : const HomeNormal\(\)/);
  assert.match(normal, /Settings\.instance\.setFashionHome\(true\)/);
  // Fashion -> Normal is the shared mode pill above the nav (dbc21a12).
  assert.match(shell, /Settings\.instance\.setFashionHome\(!_fashion\)/);
  assert.match(shell, /const PracticeScreen\(\)/);
  // Library tab is the media-rich Sound Library, not the old letter list.
  assert.match(shell, /_tabAlive\(2, const SoundLibraryScreen\(embedded: true\)\)/);
  assert.match(shell, /const StoreScreen\(\)/);
  assert.match(shell, /const ProfileScreen\(\)/);
  assert.match(normal, /MainOptionsSection\(onGo: _go, onAction: _openMainOption\)/);
  assert.match(fashion, /MainOptionsSection\(onGo: _go, onAction: _openMainOption\)/);
  assert.match(normal, /case 'Sound Library':[\s\S]*SoundLibraryScreen/);
  assert.match(fashion, /case 'My Progress':[\s\S]*PracticeProgressScreen/);
});

test('Flutter pages do not advertise unavailable tab actions and Sound Library opens the real Player', () => {
  const sound = read('flutter_app/lib/screens/sound_library.dart');
  const profile = read('flutter_app/lib/screens/profile.dart');
  const settings = read('flutter_app/lib/screens/widgets_page.dart');

  assert.match(sound, /PracticePlayerScreen\(/);
  // f3cff76f dropped the "Start library player" label when Sound Library was
  // matched to the WebView; rows still open the real player.
  assert.match(sound, /builder: \(_\) => PracticePlayerScreen\(words: \[w\]/);
  assert.doesNotMatch(sound, /Playback is not built yet/);
  assert.doesNotMatch(profile, /Not built yet/);
  assert.doesNotMatch(settings, /Not built yet/);
});
