import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const root = new URL('..', import.meta.url).pathname;
const read = (relative) => readFileSync(`${root}/${relative}`, 'utf8');

test('Flutter Practice tab exposes the real Player session', () => {
  const practice = read('flutter_app/lib/screens/practice.dart');
  const player = read('flutter_app/lib/screens/practice_player.dart');

  assert.match(practice, /import 'practice_player\.dart';/);
  assert.match(practice, /PracticePlayerScreen\(/);
  assert.match(practice, /Start Player/);
  assert.match(practice, /final sessionWords = now\.isEmpty \? rest : now;/);
  assert.match(player, /FlutterTts/);
  assert.match(player, /recordCompletedWord/);
});

test('Flutter Player uses the same liquid-glass media structure as the WebView Player', () => {
  const player = read('flutter_app/lib/screens/practice_player.dart');
  const video = read('flutter_app/lib/media/nwsb_video.dart');

  // Page film behind the player, and the artwork box plays its clip over
  // the still (poster) so the box is never empty while the clip opens.
  assert.match(player, /NwsbVideo\(\s*asset: pageBackgroundVideo,/);
  assert.match(player, /NwsbVideo\(\s*asset: video,\s*poster: art,/);
  assert.doesNotMatch(player, /assets\/video\/word-acts\.mp4/);
  assert.match(player, /assets\/frames\/word-acts-tab\.webp/);
  assert.match(player, /_TransportTube/);
  assert.match(player, /_WordActionStrip/);
  assert.match(player, /_PlayerInfoSheet/);
  assert.match(player, /SoundLibraryScreen/);
  // BF-8: Store switches the shell to the Store tab instead of pushing a
  // second StoreScreen over the player. (compact / star controls went with
  // the 16fb270a and 5e93c211 player redesigns.)
  assert.match(player, /onStore: \(\) => NavScope\.goTo\(context, 3\)/);
  assert.doesNotMatch(player, /builder: \(_\) => const StoreScreen\(\)/);
  assert.match(player, /lgp-play\.png/);
  assert.match(player, /gwttc6\.png/);
  assert.match(video, /p\.startsWith\('http:\/\/'\)/);
});
