// Cuts the canonical webview launcher icon into Android and iOS derivatives.
//
// Run this ONLY when assets/icons/app-icon-512.png changes, on a machine with
// Pillow, and commit what it writes. The build does not run it.
//
// That split is the whole point. Resizing a PNG properly needs a real image
// library, and a build runner is not guaranteed to have one — a version of
// tools/flutter-android.mjs that resized during the build died on the first
// runner it met with `ModuleNotFoundError: No module named 'PIL'` and produced
// no APK at all. Output is committed under flutter_app/android-config/mipmap/,
// beside google-services.json, and flutter-android.mjs only copies it in.
//
//   node tools/flutter-icons.mjs

import { existsSync, mkdirSync, copyFileSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

/** The same file manifest.json names, so the two installs wear one mark. */
const SRC = join(root, 'assets', 'icons', 'app-icon-512.png');
const ANDROID_OUT = join(root, 'flutter_app', 'android-config', 'mipmap');
const ADAPTIVE_OUT = join(root, 'flutter_app', 'android-config', 'adaptive');
const IOS_OUT = join(root, 'flutter_app', 'ios-config', 'AppIcon.appiconset');

/** Android's five launcher densities, in px. */
const MIPMAPS = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

/** App Store icon set: all entries are re-cut from the one canonical webview mark. */
const IOS_ICONS = [
  ['Icon-20@2x.png', 40, 'iphone', '20x20', '2x'],
  ['Icon-20@3x.png', 60, 'iphone', '20x20', '3x'],
  ['Icon-29@2x.png', 58, 'iphone', '29x29', '2x'],
  ['Icon-29@3x.png', 87, 'iphone', '29x29', '3x'],
  ['Icon-40@2x.png', 80, 'iphone', '40x40', '2x'],
  ['Icon-40@3x.png', 120, 'iphone', '40x40', '3x'],
  ['Icon-60@2x.png', 120, 'iphone', '60x60', '2x'],
  ['Icon-60@3x.png', 180, 'iphone', '60x60', '3x'],
  ['Icon-20-ipad@1x.png', 20, 'ipad', '20x20', '1x'],
  ['Icon-20-ipad@2x.png', 40, 'ipad', '20x20', '2x'],
  ['Icon-29-ipad@1x.png', 29, 'ipad', '29x29', '1x'],
  ['Icon-29-ipad@2x.png', 58, 'ipad', '29x29', '2x'],
  ['Icon-40-ipad@1x.png', 40, 'ipad', '40x40', '1x'],
  ['Icon-40-ipad@2x.png', 80, 'ipad', '40x40', '2x'],
  ['Icon-76@1x.png', 76, 'ipad', '76x76', '1x'],
  ['Icon-76@2x.png', 152, 'ipad', '76x76', '2x'],
  ['Icon-83.5@2x.png', 167, 'ipad', '83.5x83.5', '2x'],
  ['Icon-1024.png', 1024, 'ios-marketing', '1024x1024', '1x'],
];

if (!existsSync(SRC)) {
  console.error(`missing ${SRC}`);
  process.exit(1);
}

const jobs = [
  ...Object.entries(MIPMAPS).map(([dir, px]) => [join(ANDROID_OUT, dir, 'ic_launcher.png'), px]),
  ...IOS_ICONS.map(([filename, px]) => [join(IOS_OUT, filename), px]),
];
for (const [path] of jobs) mkdirSync(dirname(path), { recursive: true });
mkdirSync(join(ADAPTIVE_OUT, 'drawable-nodpi'), { recursive: true });
const plan = jobs.map(([path, px]) => `${path}\t${px}`).join('\n');

const py = `
import sys
from PIL import Image
src = Image.open(${JSON.stringify(SRC)}).convert('RGB')
for line in sys.stdin.read().strip().split('\\n'):
    path, px = line.split('\\t')
    px = int(px)
    src.resize((px, px), Image.LANCZOS).save(path, 'PNG')
    print('wrote', path, px)
`;

const out = spawnSync('python3', ['-c', py], { input: plan, encoding: 'utf8' });
if (out.status !== 0) {
  console.error(
    'could not cut the launcher icons:\n' +
      (out.stderr || '') +
      '\nthis step needs Pillow:  python3 -m pip install pillow',
  );
  process.exit(1);
}
process.stdout.write(out.stdout);

// Android 8+ launchers use an adaptive icon mask. The old Flutter setup
// replaced only legacy mipmaps, which makes Moto and Pixel launchers inset
// the image inside their safe zone. Put the SAME full-bleed source beneath a
// transparent adaptive foreground so the system mask clips it exactly as the
// Capacitor/webview icon is clipped.
copyFileSync(SRC, join(ADAPTIVE_OUT, 'drawable-nodpi', 'ic_launcher_base.png'));

const contents = {
  images: IOS_ICONS.map(([filename, , idiom, size, scale]) => ({ filename, idiom, size, scale })),
  info: { author: 'xcode', version: 1 },
};
writeFileSync(join(IOS_OUT, 'Contents.json'), `${JSON.stringify(contents, null, 2)}\n`);

console.log('\ncommit flutter_app/android-config/mipmap/, flutter_app/android-config/adaptive/, and flutter_app/ios-config/AppIcon.appiconset/');
