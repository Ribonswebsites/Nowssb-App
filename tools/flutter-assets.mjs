// Fills flutter_app/assets/ before a Flutter build.
//
// The 25 August native build did not copy the entire repository media catalog
// into the APK. It bundled the curated home/player film set and the small app
// artwork, while the generated media/image library stayed remote. Keeping this
// mirror selective is what keeps the native package near 200 MB instead of
// approaching 1 GB.
//
//   node tools/flutter-assets.mjs
//
// Run this before `flutter pub get`.

import {
  readdirSync,
  mkdirSync,
  copyFileSync,
  statSync,
  existsSync,
  rmSync,
} from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

// This is the compact media set used by the 25 August build. Posters are kept
// with the clips that have them; remote/generated media is intentionally not
// copied into the APK.
const VIDEO_KEEP = new Set([
  'connect-banner.mp4',
  'coupon-a-poster.webp',
  'coupon-a.mp4',
  'coupon-b.mp4',
  'fashion-hero-ebooks.mp4',
  'fashion-hero-meaning-store.mp4',
  'fashion-hero-subscription.mp4',
  'fashion-hero-word-store.mp4',
  'fashion-plus-bg-1.mp4',
  'fashion-plus-bg-2.mp4',
  'fashion-plus-bg-3.mp4',
  'fashion-plus-bg-4.mp4',
  'fashion-plus-bg-5.mp4',
  'fashion-plus-bg-6.mp4',
  'fashion-plus-bg.mp4',
  'fp-word-science.mp4',
  'healing-path-bg-poster.webp',
  'healing-path-bg.mp4',
  'hero-bg.mp4',
  'loading.mp4',
  'login-phone-poster.webp',
  'login-phone.mp4',
  'orb-loop.mp4',
  'player-liquid-splash.mp4',
  'rx-banner.mp4',
  'signature-a.mp4',
  'signature-b.mp4',
  'signature-banner-poster.webp',
  'signature-banner.mp4',
  'signature-c.mp4',
  'signature-d.mp4',
  'signature-e.mp4',
  'signature-store-poster.webp',
  'signature-store.mp4',
  'sound-library-banner-poster.webp',
  'sound-library-banner.mp4',
  'start-animation-poster.webp',
  'start-animation.mp4',
  'store-banner-fash.mp4',
  'store-banner.mp4',
  'store-section-poster.webp',
  'store-section.mp4',
  'store-verify-banner-poster.webp',
  'store-verify-banner.mp4',
  'subscription-a.mp4',
  'subscription-promo-poster.webp',
  'subscription-promo.mp4',
  'time-afternoon.mp4',
  'time-evening.mp4',
  'time-morning.mp4',
  'time-night.mp4',
  'tv-screen-poster.webp',
  'tv-screen.mp4',
  'word-acts.mp4',
]);

// These folders are small, named app artwork. The large generated
// assets/media/image catalog is deliberately absent from this list.
const FOLDERS = [
  'video',
  'frames',
  'icons',
  'store',
  'fashion',
  'player',
  'signature',
  'certificates',
];
const KEEP = /\.(mp4|webp|png|jpe?g|svg)$/i;

let copied = 0;
let bytes = 0;

function copyDir(rel) {
  const from = join(root, 'assets', rel);
  const to = join(root, 'flutter_app', 'assets', rel);
  rmSync(to, { recursive: true, force: true });
  mkdirSync(to, { recursive: true });
  if (!existsSync(from)) return;

  for (const name of readdirSync(from)) {
    const src = join(from, name);
    const s = statSync(src);
    if (s.isDirectory()) continue;
    if (!KEEP.test(name)) continue;
    if (rel === 'video' && !VIDEO_KEEP.has(name)) continue;
    copyFileSync(src, join(to, name));
    copied++;
    bytes += s.size;
  }
}

for (const folder of FOLDERS) copyDir(folder);
for (const stale of ['media/image', 'banners']) {
  rmSync(join(root, 'flutter_app', 'assets', stale), {
    recursive: true,
    force: true,
  });
}
console.log(
  `flutter_app/assets/  ${copied} files, ` +
    `${(bytes / 1024 / 1024).toFixed(1)} MB selected`,
);

execFileSync(process.execPath, [join(root, 'tools', 'export-content.mjs')], {
  stdio: 'inherit',
});
