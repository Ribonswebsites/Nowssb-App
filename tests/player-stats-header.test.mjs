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

test('Website and WebView cache-bust pins the rebuilt player, not the old files', () => {
  const html = read('index.html');
  const sw = read('sw.js');
  assert.match(html, /nowssb-player\.css\?v=221/);
  assert.match(html, /nowssb-player\.js\?v=314/);
  assert.doesNotMatch(html, /nowssb-player\.css\?v=220/);
  assert.doesNotMatch(html, /nowssb-player\.js\?v=313/);
  assert.match(sw, /nowsbansiu-v957/);
  assert.doesNotMatch(sw, /nowsbansiu-v956/);
});

test('Profile is a big Image-2 header outside the video, play is a white circle', () => {
  const js = read('nowssb-player.js');
  const css = read('nowssb-player.css');
  assert.match(js, /lgp-profile-hero/);
  assert.match(js, /lgp-acts/);
  assert.match(js, /lgp-playrow/);
  assert.match(js, /lgp-play-svg/);
  assert.doesNotMatch(js, /lgp-rail-l/);
  assert.doesNotMatch(js, /lgp-tube-round/);
  assert.match(css, /\.lgp-playrow/);
  assert.match(css, /border-radius:50% !important/);
});

test('Level opens a 1–12 glass list; stats sit in the tab; video is a glass box', () => {
  const js = read('nowssb-player.js');
  const css = read('nowssb-player.css');
  assert.match(js, /lgpPickLevel/);
  assert.match(js, /lgp-levels/);
  assert.match(js, /nwsb_player_level/);
  assert.match(js, /lgp-stats-tab/);
  assert.doesNotMatch(js, /lgp-visual-tab/);
  assert.doesNotMatch(js, /src="\.\/assets\/video\/word-acts\.mp4"/);
  assert.match(js, /class="lgp-wa-vid"/);
  assert.match(css, /\.lgp-stats-tab/);
  assert.doesNotMatch(css, /\.lgp-visual-tab/);
  assert.match(css, /\.lgp-levels/);
  assert.match(css, /max-height:36vh/);
});
