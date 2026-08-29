import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const root = new URL('..', import.meta.url).pathname;
const read = (relative) => readFileSync(`${root}/${relative}`, 'utf8');

test('Web player replaced the fashion banner with a real stats row', () => {
  const js = read('nowssb-player.js');
  const css = read('nowssb-player.css');

  assert.match(js, /lgp-stats/);
  assert.match(js, /Days Streak/);
  assert.match(js, /lgpSessionStats/);
  assert.doesNotMatch(js, /class="lgp-banner-tab"/);
  assert.doesNotMatch(js, /class="lgp-visual-tag"/);
  assert.doesNotMatch(js, /class="lgp-barwrap"/);
  assert.match(js, /LISTEN · SPEAK · HEAL/);
  assert.match(js, /lgp-profile/);
  assert.match(js, /lgp-nextup/);
  assert.match(js, /lgp-eq-title/);
  assert.match(css, /letter-spacing:\.22em/);
  assert.match(css, /\.lgp-nextup/);
});

test('Flutter player matches the web stats / profile / next-up surgery', () => {
  const player = read('flutter_app/lib/screens/practice_player.dart');
  const progress = read('flutter_app/lib/data/practice_progress.dart');

  assert.match(player, /_StatsRow/);
  assert.match(player, /_ProfileHeader/);
  assert.match(player, /_NextUpCard/);
  assert.match(player, /LISTEN · SPEAK · HEAL/);
  assert.doesNotMatch(player, /The new fashion trend of meditation/);
  assert.doesNotMatch(player, /Afternoon/);
  assert.doesNotMatch(player, /_ProgressPanel/);
  assert.match(progress, /durationSec/);
  assert.match(progress, /totalMinutes/);
  assert.match(progress, /int get level/);
});
