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

import { readdirSync, mkdirSync, copyFileSync, statSync, lstatSync, existsSync,
         readFileSync, writeFileSync, symlinkSync, unlinkSync, readlinkSync } from 'node:fs';
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
  // NOTE: do NOT list 'videos' here. Copying assets/videos/ (~664MB library)
  // into flutter_app/assets/videos ballooned the APK to ~1GB. Fashion /
  // home only need a handful of those clips; ensureVideosAllowlist() below
  // installs them as symlinks into the root library (same bytes, one copy).
  'frames',       // the device bezels — see lib/widgets/tv_frame.dart
  'coach',        // Personal Coach hero artwork
  'icons',        // the logo disc, the search mark
  'store',        // the intro-page artwork, and the collection covers
  'fashion',      // the Fashion Plus intro and its icon
  'routine',      // My Routine / Get Started editorial cards
  'player',       // the player's own artwork
  'signature',    // the Signature's marks
  'certificates',
  'banners',      // the collection banners
  'hero-curve',   // Lesmana-style 3D home gallery
];

/* Local asset paths referenced by Flutter (assets/videos/...). Practice
   player themes use https://nowssb.com/… and are NOT bundled. Posters that
   only live under flutter_app/assets/videos/ are left alone. */
const VIDEOS_ALLOWLIST = [
  '09a50041065bdeab_grok_video_2026-07-30-14-54-07_ddjmrr.mp4',
  '28eb0c85b5fd748e_grok_video_2026-07-24-15-42-55_lknomr.mp4',
  '415dd447da33973b_grok_video_2026-07-30-14-35-05_q3tyzk.mp4',
  '7e4d709136dc254a_grok_video_2026-07-18-15-53-02_ubjx5b.mp4',
  'beaf11ea10561d43_grok_video_2026-07-30-15-35-40_xwm1ei.mp4',
  '1e9a0c8d452a809f_grok_video_2026-05-06-15-27-23_zhylbe.mp4',
];

const KEEP = /\.(mp4|webp|png|jpe?g|svg)$/i;

let copied = 0, skipped = 0, bytes = 0;

function copyDir(rel) {
  const from = join(root, 'assets', rel);
  const to = join(root, 'flutter_app', 'assets', rel);
  if (!existsSync(from)) return;
  // Prefer committed symlinks (single source of truth). Never materialize a
  // second full tree on top of them — that is what ballooned the APK.
  if (existsSync(to) && lstatSync(to).isSymbolicLink()) {
    skipped++;
    console.log(`skip ${rel}: already a symlink → ${readlinkSafe(to)}`);
    return;
  }
  mkdirSync(to, { recursive: true });

  for (const name of readdirSync(from)) {
    const src = join(from, name);
    const s = statSync(src);
    if (s.isDirectory()) { copyDir(join(rel, name)); continue; }
    if (!KEEP.test(name)) continue;

    const dst = join(to, name);
    if (existsSync(dst) && lstatSync(dst).isSymbolicLink()) {
      skipped++; bytes += s.size; continue;
    }
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

function readlinkSafe(p) {
  try { return lstatSync(p).isSymbolicLink() ? readlinkSync(p) : p; }
  catch { return p; }
}

/** Install only the Fashion/home clips as symlinks into assets/videos/. */
function ensureVideosAllowlist() {
  const fromDir = join(root, 'assets', 'videos');
  const toDir = join(root, 'flutter_app', 'assets', 'videos');
  if (!existsSync(fromDir)) return;
  // If someone left a directory symlink to the FULL library, replace it —
  // that would ship ~664MB into the APK.
  try {
    if (lstatSync(toDir).isSymbolicLink()) unlinkSync(toDir);
  } catch { /* missing is fine */ }
  mkdirSync(toDir, { recursive: true });
  for (const name of VIDEOS_ALLOWLIST) {
    const src = join(fromDir, name);
    const dst = join(toDir, name);
    if (!existsSync(src)) {
      console.warn(`videos allowlist missing in assets/videos: ${name}`);
      continue;
    }
    const target = `../../../assets/videos/${name}`;
    let have = false;
    try { lstatSync(dst); have = true; } catch { have = false; }
    if (have) {
      if (lstatSync(dst).isSymbolicLink() && readlinkSync(dst) === target) {
        skipped++; bytes += statSync(src).size; continue;
      }
      // Replace a prior real copy with a symlink (same bytes, one tree).
      unlinkSync(dst);
    }
    symlinkSync(target, dst);
    copied++; bytes += statSync(src).size;
  }
}

for (const f of FOLDERS) copyDir(f);
ensureVideosAllowlist();

console.log(
  `flutter_app/assets/  ${copied} copied, ${skipped} already current, ` +
  `${(bytes / 1024 / 1024).toFixed(1)} MB total`
);

/* ── The URL → bundled-file map ────────────────────────────────────────
   lib/media/nwsb_image.dart reads this. A section names a picture by the
   URL index.html uses; this says whether that picture is on disk yet.

   Written from the manifest and filtered to what has ACTUALLY been
   downloaded, so a URL in the map is a promise the bundle can keep. Until
   `node tools/asset-manifest.mjs --download` runs, the map is nearly empty
   and every section falls back — which is the designed state, not a
   failure. */
const manifestPath = join(root, 'assets', 'media-manifest.json');
const mapOut = join(root, 'flutter_app', 'lib', 'media', 'media_map.dart');

let entries = [];
if (existsSync(manifestPath)) {
  const m = JSON.parse(readFileSync(manifestPath, 'utf8'));
  entries = m.assets || m.entries || m;
  if (!Array.isArray(entries)) entries = [];
}

const have = entries.filter(
  (e) => e && e.url && e.local &&
         existsSync(join(root, 'assets', 'media', e.local)),
);

// Copy the downloaded media in too — it is only useful to the app if it is
// in the bundle beside everything else.
if (have.length) {
  mkdirSync(join(root, 'flutter_app', 'assets', 'media'), { recursive: true });
  for (const e of have) {
    const src = join(root, 'assets', 'media', e.local);
    const dst = join(root, 'flutter_app', 'assets', 'media', e.local);
    mkdirSync(dirname(dst), { recursive: true });
    if (!existsSync(dst) || statSync(dst).size !== statSync(src).size) {
      copyFileSync(src, dst);
    }
  }
}

writeFileSync(
  mapOut,
  '// GENERATED by tools/flutter-assets.mjs — do not edit by hand.\n' +
  '//\n' +
  '// The address a section names, and the file in the bundle that answers\n' +
  '// it. Only URLs that have actually been downloaded appear here; the rest\n' +
  '// fall back, which is what lib/media/nwsb_image.dart is for.\n' +
  '//\n' +
  '//   node tools/asset-manifest.mjs --download   fetches them\n' +
  '//   node tools/flutter-assets.mjs              rebuilds this\n' +
  'library;\n\n' +
  'const Map<String, String> kNowssbMedia = {\n' +
  have.map((e) => `  ${JSON.stringify(e.url)}: 'assets/media/${e.local}',`)
      .join('\n') +
  (have.length ? '\n' : '') +
  '};\n',
);
console.log(`lib/media/media_map.dart  ${have.length} of ${entries.length} downloaded`);

execFileSync(process.execPath, [join(root, 'tools', 'export-content.mjs')], {
  stdio: 'inherit',
});
