import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { dartClass } from './helpers/source-contract.mjs';

const root = new URL('..', import.meta.url).pathname;
const read = (relative) => readFileSync(`${root}/${relative}`, 'utf8');

test('Flutter TV frames retain the bezel and video but suppress poster artwork', () => {
  const video = read('flutter_app/lib/media/nwsb_video.dart');
  const frame = read('flutter_app/lib/widgets/tv_frame.dart');

  assert.match(video, /this\.showPoster = true/);
  assert.match(video, /final bool showPoster/);
  assert.match(video, /if \(!showPoster\) return null/);
  // TvFrame suppresses the poster by default and passes it through, so only a
  // caller that opts in (healing-path soft-fail) ever shows artwork.
  assert.match(frame, /this\.showPoster = false/);
  assert.match(frame, /NwsbVideo\([\s\S]*?showPoster: showPoster/);
  assert.match(frame, /IgnorePointer\(child: _Bezel\(frame: frame\)\)/);
});

test('Flutter subscription text is placed at the foot of the TV video', () => {
  const sections = read('flutter_app/lib/screens/shared_sections.dart');
  // _PromoOffer no longer exists; slice the class itself.
  const edition = dartClass(sections, 'EditionSection');

  // The overlay is a spaceBetween column: banner, tiers, then the
  // subscription copy pinned to the foot of the TV.
  assert.match(edition, /overlay: Padding\(\s*padding: const EdgeInsets\.fromLTRB\(16, 18, 16, 18\)/);
  assert.match(edition, /mainAxisAlignment: MainAxisAlignment\.spaceBetween/);
  const tiers = edition.indexOf('_SubscriptionTierStack(');
  const copy = edition.indexOf("'Get your subscription today'");
  assert.ok(tiers > 0 && copy > tiers, 'subscription copy sits below the tiers, at the foot of the TV');
  assert.doesNotMatch(edition, /alignment: Alignment\.topLeft/);
});
