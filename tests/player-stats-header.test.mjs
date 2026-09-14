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
  assert.match(js, /lgp-stats/);
  assert.match(js, /lgpOpenQueueSheet/);
  assert.match(js, /lgp-stage-lv/);
  assert.match(js, /lgp-nextup/);
  assert.match(js, /lgp-np-name/);
  assert.match(css, /letter-spacing:\.22em/);
  assert.match(css, /\.lgp-nextup/);
});

test('Flutter player matches the web stats / profile / next-up surgery', () => {
  const player = read('flutter_app/lib/screens/practice_player.dart');
  const progress = read('flutter_app/lib/data/practice_progress.dart');

  assert.match(player, /_StatsRow/);
  assert.match(player, /_ProfileHeader/);
  assert.match(player, /_NextUpCard/);
  // Tagline may live in marquee lines; YTM scroll is the contract now.
  assert.match(player, /NestedScrollView/);
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
  assert.match(html, /nowssb-player\.css\?v=237/);
  assert.match(html, /nowssb-player\.js\?v=330/);
  assert.doesNotMatch(html, /nowssb-player\.css\?v=236/);
  assert.doesNotMatch(html, /nowssb-player\.js\?v=329/);
  assert.match(sw, /nowsbansiu-v969/);
  assert.doesNotMatch(sw, /nowsbansiu-v968/);
});

test('Profile and level sit inside the video; play is the sphere image in the glass tube', () => {
  const js = read('nowssb-player.js');
  const css = read('nowssb-player.css');
  assert.match(js, /lgp-visual/);
  assert.match(js, /lgpPickLevel/);
  assert.match(js, /lgp-stage-lv/);
  assert.match(js, /lgp-tube/);
  assert.match(js, /lgp-acts/);
  assert.match(css, /\.lgp-tube/);
  assert.match(css, /border-radius:50% !important/);
});

test('Level opens a 1–12 glass list; stats sit in the tab; video is a glass box', () => {
  const js = read('nowssb-player.js');
  const css = read('nowssb-player.css');
  assert.match(js, /lgpPickLevel/);
  assert.match(js, /nwsb_player_level/);
  assert.match(js, /lgp-stats-tab/);
  assert.match(js, /lgp-stage-lv/);
  assert.doesNotMatch(js, /lgp-visual-tab/);
  assert.doesNotMatch(js, /src="\.\/assets\/video\/word-acts\.mp4"/);
  assert.match(js, /lgp-wa-vid/);
  assert.match(css, /\.lgp-stats-tab/);
  assert.doesNotMatch(css, /\.lgp-visual-tab/);
});

test('Flutter Now Playing uses YTM continuous NestedScrollView collapse + store glass box', () => {
  const player = read('flutter_app/lib/screens/practice_player.dart');
  assert.match(player, /NestedScrollView/);
  assert.match(player, /_YtmCollapsingHero/);
  assert.match(player, /_QueueStickyHeadDelegate/);
  assert.match(player, /_StoreGlassVideoBox/);
  assert.match(player, /nowssb-bag-headphones\.webp/);
  assert.match(player, /Icons\.cast_rounded/);
  assert.doesNotMatch(player, /DraggableScrollableSheet/);
});

test('Web Up Next queue is continuous scroll-driven with cast\/play mini bar + store glass', () => {
  const js = read('nowssb-player.js');
  const css = read('nowssb-player.css');
  assert.match(js, /setProgress/);
  assert.match(js, /--lgp-q-t/);
  assert.match(js, /lgp-queue-playmini/);
  assert.match(js, /lgp-queue-cast/);
  assert.match(js, /lgp-store-glass-box/);
  assert.match(js, /nowssb-bag-headphones\.webp/);
  assert.match(css, /--lgp-q-t/);
  assert.match(css, /lgp-queue-collapse-art/);
  assert.match(css, /lgp-store-glass-inner/);
});
