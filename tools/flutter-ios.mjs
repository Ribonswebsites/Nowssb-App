// Installs platform-owned iOS resources after `flutter create --platforms=ios`.
// The image set is generated from assets/icons/app-icon-512.png, which is the
// exact launcher artwork used by the Capacitor/webview app and its PWA.

import { cpSync, copyFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const ios = join(root, 'flutter_app', 'ios');
const source = join(root, 'flutter_app', 'ios-config', 'AppIcon.appiconset');
const destination = join(ios, 'Runner', 'Assets.xcassets', 'AppIcon.appiconset');
const firebasePlist = join(root, 'flutter_app', 'ios-config', 'GoogleService-Info.plist');

if (!existsSync(ios)) {
  console.error(`missing ${ios} — run \`flutter create --platforms=ios,android\` first`);
  process.exit(1);
}
if (!existsSync(source)) {
  console.error(`missing ${source} — run \`node tools/flutter-icons.mjs\` first`);
  process.exit(1);
}

cpSync(source, destination, { recursive: true, force: true });
console.log('installed AppIcon.appiconset from the canonical webview mark');

// This file is supplied by Firebase after the iOS app is registered. It is
// intentionally ignored by Git. Copying it here makes it available for Xcode
// target membership; Xcode must include it in the Runner target before a
// signed release is archived.
if (existsSync(firebasePlist)) {
  copyFileSync(firebasePlist, join(ios, 'Runner', 'GoogleService-Info.plist'));
  console.log('copied GoogleService-Info.plist for the iOS Firebase build');
} else {
  console.warn('GoogleService-Info.plist is absent; email and Google sign-in will remain unavailable on iOS until Firebase registers com.nowssb.app.');
}
