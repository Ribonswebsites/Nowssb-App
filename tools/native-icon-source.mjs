// Capacitor reads resources/icon.png when it creates Android and iOS assets.
// Copy the canonical PWA/webview mark there immediately before generation so
// no platform can silently use a different crop, logo disc, or default icon.

import { copyFileSync, existsSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const source = join(root, 'assets', 'icons', 'app-icon-512.png');
const destination = join(root, 'resources', 'icon.png');

if (!existsSync(source)) {
  console.error(`missing canonical app icon: ${source}`);
  process.exit(1);
}

mkdirSync(dirname(destination), { recursive: true });
copyFileSync(source, destination);
console.log(`copied canonical NowssB launcher mark to ${destination}`);
