// Fills flutter_app/assets/ before a Flutter build.
//
// The clips live in one place in this repository — assets/video/ — because
// the website and the app show the same films and a second copy is a second
// copy to keep in step. So flutter_app/assets/video/ is NOT committed; it is
// filled from assets/video/ on the way into a build, the same way www/ is
// filled by tools/build-native.mjs.
//
//   node tools/flutter-assets.mjs
//
// Run this BEFORE `flutter pub get`. A directory named in pubspec.yaml's
// assets: block that does not exist fails pub get outright, so this is not
// optional and it is not an optimisation — it is a build step.
//
// It also writes the shipped content, by calling tools/export-content.mjs,
// so one command puts everything the bundle needs in place.

import { readdirSync, mkdirSync, copyFileSync, statSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
/* The folders that go into the bundle. Not only the clips: the app's own
   artwork lives here too and is what makes it look like NowssB rather than
   like a Material demo — the device bezels the televisions are drawn from,
   the intro-page paintings, the logo disc, the collection banners. All of
   it is already in this repository; none of it needed downloading. */
const FOLDERS = [
  'video',        // the clips and their posters
  'frames',       // the device bezels — see lib/widgets/tv_frame.dart
  'icons',        // the logo disc, the search mark
  'media/image',  // restored repository images; videos remain R2-only
  'store',        // the intro-page artwork, and the collection covers
  'fashion',      // the Fashion Plus intro and its icon
  'player',       // the player's own artwork
  'signature',    // the Signature's marks
  'certificates',
  'banners',      // the collection banners
];

const KEEP = /\.(mp4|webp|png|jpe?g|svg)$/i;

let copied = 0, skipped = 0, bytes = 0;

function copyDir(rel) {
  const from = join(root, 'assets', rel);
  const to = join(root, 'flutter_app', 'assets', rel);
  mkdirSync(to, { recursive: true });
  if (!existsSync(from)) return;

  for (const name of readdirSync(from)) {
    const src = join(from, name);
    const s = statSync(src);
    if (s.isDirectory()) { copyDir(join(rel, name)); continue; }
    if (!KEEP.test(name)) continue;

    const dst = join(to, name);
    // Same size and not older: already there. Makes a re-run cheap, which
    // matters when this is 200 MB.
    if (existsSync(dst)) {
      const d = statSync(dst);
      if (d.size === s.size && d.mtimeMs >= s.mtimeMs) {
        skipped++; bytes += s.size; continue;
      }
    }
    copyFileSync(src, dst);
    copied++; bytes += s.size;
  }
}

for (const f of FOLDERS) copyDir(f);

console.log(
  `flutter_app/assets/  ${copied} copied, ${skipped} already current, ` +
  `${(bytes / 1024 / 1024).toFixed(1)} MB total`
);

execFileSync(process.execPath, [join(root, 'tools', 'export-content.mjs')], {
  stdio: 'inherit',
});
