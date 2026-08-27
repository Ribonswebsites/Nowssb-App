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
    assert.match(shell, new RegExp(`\\('${tab}'`));
  }
  assert.match(shell, /_fashion \? const HomeFashion\(\) : const HomeNormal\(\)/);
  assert.match(normal, /Settings\.instance\.setFashionHome\(true\)/);
  assert.match(fashion, /Settings\.instance\.setFashionHome\(false\)/);
  assert.match(shell, /const PracticeScreen\(\)/);
  assert.match(shell, /const LibraryScreen\(\)/);
  assert.match(shell, /const StoreScreen\(\)/);
  assert.match(shell, /const ProfileScreen\(\)/);
});

test('Flutter pages do not advertise unavailable tab actions and Sound Library opens the real Player', () => {
  const sound = read('flutter_app/lib/screens/sound_library.dart');
  const profile = read('flutter_app/lib/screens/profile.dart');
  const settings = read('flutter_app/lib/screens/widgets_page.dart');

  assert.match(sound, /PracticePlayerScreen\(/);
  assert.match(sound, /Start library player/);
  assert.doesNotMatch(sound, /Playback is not built yet/);
  assert.doesNotMatch(profile, /Not built yet/);
  assert.doesNotMatch(settings, /Not built yet/);
});
