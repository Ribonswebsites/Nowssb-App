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

  assert.match(player, /NwsbVideo\(asset: theme\.video, poster: theme\.image/);
  assert.match(player, /NwsbVideo\(asset: video/);
  assert.doesNotMatch(player, /assets\/video\/word-acts\.mp4/);
  assert.match(player, /assets\/frames\/word-acts-tab\.webp/);
  assert.match(player, /_TransportTube/);
  assert.match(player, /_WordActionStrip/);
  assert.match(player, /_PlayerInfoSheet/);
  assert.match(player, /SoundLibraryScreen/);
  assert.match(player, /StoreScreen/);
  assert.match(video, /p\.startsWith\('http:\/\/'\)/);
});
