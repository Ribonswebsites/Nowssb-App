import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const root = new URL('..', import.meta.url).pathname;
const read = (relative) => readFileSync(`${root}/${relative}`, 'utf8');

test('Flutter TV frames retain the bezel and video but suppress poster artwork', () => {
  const video = read('flutter_app/lib/media/nwsb_video.dart');
  const frame = read('flutter_app/lib/widgets/tv_frame.dart');

  assert.match(video, /this\.showPoster = true/);
  assert.match(video, /final bool showPoster/);
  assert.match(video, /if \(!showPoster\) return null/);
  assert.match(frame, /NwsbVideo\([\s\S]*?showPoster: false/);
  assert.match(frame, /IgnorePointer\(child: _Bezel\(frame: frame\)\)/);
});

test('Flutter subscription text is placed at the foot of the TV video', () => {
  const sections = read('flutter_app/lib/screens/shared_sections.dart');
  const edition = sections.slice(sections.indexOf('class EditionSection'), sections.indexOf('class _PromoOffer'));

  assert.match(edition, /alignment: Alignment\.bottomLeft/);
  assert.match(edition, /EdgeInsets\.fromLTRB\(18, 0, 18, 18\)/);
  assert.doesNotMatch(edition, /alignment: Alignment\.topLeft/);
});
