// Cuts the Android launcher icon to its five densities.
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

import { existsSync, mkdirSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

/** The same file manifest.json names, so the two installs wear one mark. */
const SRC = join(root, 'assets', 'icons', 'app-icon-512.png');
const OUT = join(root, 'flutter_app', 'android-config', 'mipmap');

/** Android's five launcher densities, in px. */
const MIPMAPS = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

if (!existsSync(SRC)) {
  console.error(`missing ${SRC}`);
  process.exit(1);
}

const plan = Object.entries(MIPMAPS)
  .map(([dir, px]) => {
    mkdirSync(join(OUT, dir), { recursive: true });
    return `${join(OUT, dir, 'ic_launcher.png')}\t${px}`;
  })
  .join('\n');

const py = `
import sys
from PIL import Image
src = Image.open(${JSON.stringify(SRC)}).convert('RGBA')
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
console.log('\ncommit flutter_app/android-config/mipmap/');
