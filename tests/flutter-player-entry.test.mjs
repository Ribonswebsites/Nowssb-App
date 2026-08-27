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
