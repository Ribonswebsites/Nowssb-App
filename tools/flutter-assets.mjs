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
const from = join(root, 'assets', 'video');
const to = join(root, 'flutter_app', 'assets', 'video');

if (!existsSync(from)) {
  console.error(`missing ${from} — nothing to bundle`);
  process.exit(1);
}

mkdirSync(to, { recursive: true });

let copied = 0, skipped = 0, bytes = 0;
for (const name of readdirSync(from)) {
  // The clips and the posters, and nothing else. A poster is as required as
  // its clip: at most four videos decode at once, so most of what is on
  // screen at any moment IS the poster.
  if (!/\.(mp4|webp)$/i.test(name)) continue;

  const src = join(from, name);
  const dst = join(to, name);
  const s = statSync(src);

  // Same size and not older: already there. Makes a re-run cheap, which
  // matters when the folder is 136 MB.
  if (existsSync(dst)) {
    const d = statSync(dst);
    if (d.size === s.size && d.mtimeMs >= s.mtimeMs) {
      skipped++;
      bytes += s.size;
      continue;
    }
  }

  copyFileSync(src, dst);
  copied++;
  bytes += s.size;
}

console.log(
  `flutter_app/assets/video/  ${copied} copied, ${skipped} already current, ` +
  `${(bytes / 1024 / 1024).toFixed(1)} MB total`
);

execFileSync(process.execPath, [join(root, 'tools', 'export-content.mjs')], {
  stdio: 'inherit',
});
