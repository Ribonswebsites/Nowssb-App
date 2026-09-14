import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const root = new URL('..', import.meta.url).pathname;
const read = (relative) => readFileSync(`${root}/${relative}`, 'utf8');

test('Flutter VideoPool raises concurrent live/open limits for simultaneous loops', () => {
  const pool = read('flutter_app/lib/media/video_pool.dart');
  assert.match(pool, /static const int maxLive = 24/);
  assert.match(pool, /static const int maxLiveGlassHome = 28/);
  assert.match(pool, /static const int openAtOnce = 12/);
  assert.match(pool, /soft fail/i);
  assert.match(pool, /mixWithOthers:\s*true/);
});

test('NwsbVideo keeps per-widget lease and does not singleton-pause siblings', () => {
  const video = read('flutter_app/lib/media/nwsb_video.dart');
  assert.match(video, /VideoPool\.instance\.lease/);
  assert.match(video, /l\.play\(\)/);
  assert.doesNotMatch(video, /currentlyPlaying/);
  assert.doesNotMatch(video, /pauseOthers|pauseSibling/i);
});

test('Website decorative video controller plays all on-screen clips together', () => {
  const js = read('app/js/part051.js');
  assert.match(js, /var MAX_PLAYING = 24/);
  assert.match(js, /onScreen\.has\(v\) \|\| isFeature\(v\)/);
  assert.match(js, /preload = 'auto'/);
  assert.match(js, /setAttribute\('autoplay'/);
  // Must not keep the old "only nearest 8 play" as the primary rule without inView.
  assert.match(js, /Fully off-screen clips pause/);
});

test('GentleMarqueeText exists; section wraps do NOT inject top black banners', () => {
  const parts = read('flutter_app/lib/widgets/home_parts.dart');
  assert.match(parts, /class GentleMarqueeText/);
  assert.match(parts, /class SectionMotionBanner/);
  // SecBanner title is static; only the subtitle marquees.
  assert.match(parts, /Text\(\s*title,/);
  assert.match(parts, /GentleMarqueeText\(\s*sub,/);
  const glass = read('flutter_app/lib/widgets/glass_wrap.dart');
  assert.doesNotMatch(glass, /SectionMotionBanner/);
  assert.doesNotMatch(glass, /GentleMarqueeText/);
  const neu = read('flutter_app/lib/widgets/neu_wrap.dart');
  assert.doesNotMatch(neu, /SectionMotionBanner/);
  assert.doesNotMatch(neu, /GentleMarqueeText/);
  const css = read('app/app.css');
  assert.match(css, /nwsb-section-motion-banner/);
  assert.match(css, /nwsb-sub-marquee/);
  const inject = read('app/js/part049.js');
  // Must not auto-inject banners into every section wrap.
  assert.doesNotMatch(inject, /querySelectorAll\('#home \.glass-wrap/);
  assert.match(inject, /Intentionally NOT injected/);
});

test('Home lists key sections and bound cacheExtent to avoid video remount churn', () => {
  const normal = read('flutter_app/lib/screens/home_normal.dart');
  const fashion = read('flutter_app/lib/screens/home_fashion.dart');
  assert.match(normal, /cacheExtent: 480/);
  assert.match(normal, /ValueKey\('nm-\$k'\)/);
  assert.match(fashion, /cacheExtent: 480/);
  assert.match(fashion, /ValueKey\('fash-\$k'\)/);
});
