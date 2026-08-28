// Takes every remote media URL out of the source and points it at the copy
// on disk.
//
//   node tools/asset-manifest.mjs --download    # fetch all 520 files first
//   node tools/localise-media.mjs               # then rewrite the source
//   node tools/localise-media.mjs --dry-run     # or just see what it would do
//
// WHY IT IS TWO STEPS. The download needs the network; the rewrite needs the
// files. Keeping them apart means the rewrite is a pure, reviewable text
// change you can read in a diff and revert with git — and it refuses to
// rewrite a URL whose file is not actually there, so a half-finished
// download cannot leave the app pointing at nothing.
//
// WHAT IT REWRITES. Every https://res.r2.com/… (and any other remote
// media the manifest found) becomes ./assets/media/<kind>/<name>, which is
// the path tools/asset-manifest.mjs already chose and already downloaded to.
// The name is derived from the URL, so the same URL always lands on the same
// file no matter how many times either tool runs.
//
// WHAT IT LEAVES ALONE.
//   · admin.html — the studio is not shipped in the app and its pictures are
//     uploaded from it. Rewriting those would point the studio at files it is
//     supposed to be creating.
//   · Anything the manifest has no local copy for. Reported, not guessed at.

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const MANIFEST = join(ROOT, 'assets', 'media-manifest.json');
const DRY = process.argv.includes('--dry-run');

if (!existsSync(MANIFEST)) {
  console.error('no assets/media-manifest.json — run `node tools/asset-manifest.mjs` first');
  process.exit(1);
}

const manifest = JSON.parse(readFileSync(MANIFEST, 'utf8'));
const entries = manifest.assets || manifest.entries || manifest;
if (!Array.isArray(entries)) {
  console.error('unexpected manifest shape — expected an array of {url, local}');
  process.exit(1);
}

// url -> ./assets/media/<local>, but only where the file is actually present.
const map = new Map();
let missing = 0;
for (const e of entries) {
  if (!e || !e.url || !e.local) continue;
  if (!existsSync(join(ROOT, 'assets', 'media', e.local))) { missing++; continue; }
  map.set(e.url, './assets/media/' + e.local);
}

console.log(`${map.size} of ${entries.length} downloaded and ready to rewrite`);
if (missing) {
  console.log(`${missing} not on disk yet — run \`node tools/asset-manifest.mjs --download\``);
}
if (!map.size) process.exit(missing ? 1 : 0);

/* Longest URL first. R2 serves the same asset under several
   transforms, and some of those URLs are prefixes of others — rewriting the
   short one first would corrupt the long one into a local path with a
   transform tail still hanging off it. */
const urls = [...map.keys()].sort((a, b) => b.length - a.length);

const FILES = [
  'index.html',
  'nowssb-nm.js', 'nowssb-player.js', 'nowssb-social.js',
  'nowssb-nm.css', 'nowssb-player.css', 'nowssb-social.css',
  ...manifestFiles(),
];

function manifestFiles() {
  const seen = new Set();
  for (const e of entries) for (const r of e.refs || []) seen.add(r);
  // The studio stays remote — see the note at the top.
  return [...seen].filter(f => f !== 'admin.html' && f !== 'admin-dev.html');
}

let changedFiles = 0, changedRefs = 0;
for (const rel of [...new Set(FILES)]) {
  const abs = join(ROOT, rel);
  if (!existsSync(abs)) continue;
  const before = readFileSync(abs, 'utf8');
  let after = before;
  for (const u of urls) {
    if (!after.includes(u)) continue;
    const n = after.split(u).length - 1;
    after = after.split(u).join(map.get(u));
    changedRefs += n;
  }
  if (after !== before) {
    changedFiles++;
    if (!DRY) writeFileSync(abs, after);
    console.log(`  ${DRY ? 'would rewrite' : 'rewrote'}  ${rel}`);
  }
}

console.log(
  `${DRY ? 'would change' : 'changed'} ${changedRefs} references across ${changedFiles} files`,
);
if (DRY) console.log('(dry run — nothing written)');
