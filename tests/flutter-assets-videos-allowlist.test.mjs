import assert from 'node:assert/strict';
import { readFileSync, lstatSync, readlinkSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const script = readFileSync(join(root, 'tools/flutter-assets.mjs'), 'utf8');

test('flutter-assets does not bulk-copy assets/videos into the Flutter bundle', () => {
  assert.doesNotMatch(script, /['"]videos['"],\s*\/\/ Fashion/);
  assert.match(script, /VIDEOS_ALLOWLIST/);
  assert.match(script, /ensureVideosAllowlist/);
  // Must never list the full library folder as a FOLDERS entry (comments OK).
  const foldersBlock = script.slice(script.indexOf('const FOLDERS'), script.indexOf('];', script.indexOf('const FOLDERS')) + 2);
  const entries = [...foldersBlock.matchAll(/^[ \t]*['"]([^'"]+)['"]/gm)].map(m => m[1]);
  assert.ok(!entries.includes('videos'), `FOLDERS entries unexpectedly include videos: ${entries}`);
  assert.ok(entries.includes('video'));
});

test('Flutter local practice clips are symlinks into root assets/videos (no second copy)', () => {
  const needed = [
    '09a50041065bdeab_grok_video_2026-07-30-14-54-07_ddjmrr.mp4',
    '28eb0c85b5fd748e_grok_video_2026-07-24-15-42-55_lknomr.mp4',
    '415dd447da33973b_grok_video_2026-07-30-14-35-05_q3tyzk.mp4',
    '7e4d709136dc254a_grok_video_2026-07-18-15-53-02_ubjx5b.mp4',
    'beaf11ea10561d43_grok_video_2026-07-30-15-35-40_xwm1ei.mp4',
  ];
  for (const name of needed) {
    const p = join(root, 'flutter_app/assets/videos', name);
    assert.ok(existsSync(p), `missing ${name}`);
    assert.ok(lstatSync(p).isSymbolicLink(), `${name} should be a symlink`);
    assert.equal(readlinkSync(p), `../../../assets/videos/${name}`);
    assert.ok(existsSync(join(root, 'assets/videos', name)), `root missing ${name}`);
  }
  // Unused full-film clone must not be reintroduced.
  assert.equal(
    existsSync(join(root, 'flutter_app/assets/videos/3a1f74f98d7a0d18_grok_video_2026-07-30-14-57-37_tbzpox.mp4')),
    false,
  );
});
