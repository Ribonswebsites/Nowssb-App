// Configures a freshly generated Flutter iOS target for the same NowssB
// product identity, launcher art, Firebase configuration, and Google callback
// used by the Android and Capacitor WebView builds. flutter_app/ios is
// regenerated in CI, so every native modification is applied here.

import { cpSync, copyFileSync, existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const ios = join(root, 'flutter_app', 'ios');
const runner = join(ios, 'Runner');
const project = join(ios, 'Runner.xcodeproj', 'project.pbxproj');
const info = join(runner, 'Info.plist');
const iconSource = join(root, 'flutter_app', 'ios-config', 'AppIcon.appiconset');
const iconDestination = join(runner, 'Assets.xcassets', 'AppIcon.appiconset');
const firebaseConfig = join(root, 'flutter_app', 'ios-config', 'GoogleService-Info.plist');
const appId = 'com.nowssb.app';

for (const path of [runner, project, info, iconSource, firebaseConfig]) {
  if (!existsSync(path)) {
    console.error(`missing ${path}; run flutter create --platforms=ios first`);
    process.exit(1);
  }
}

// The AppIcon catalog is cut from assets/icons/app-icon-512.png, the exact
// site/PWA/WebView image. It has no extra container or alternative artwork.
cpSync(iconSource, iconDestination, { recursive: true, force: true });
copyFileSync(firebaseConfig, join(runner, 'GoogleService-Info.plist'));

const firebaseText = readFileSync(firebaseConfig, 'utf8');
const reversedClientId = (
  firebaseText.match(/<key>REVERSED_CLIENT_ID<\/key>\s*<string>([^<]+)<\/string>/) || []
)[1];
if (!reversedClientId) {
  console.error('GoogleService-Info.plist has no REVERSED_CLIENT_ID');
  process.exit(1);
}

let infoText = readFileSync(info, 'utf8');
if (!infoText.includes(reversedClientId)) {
  const callbackType = `\n\t\t<dict>\n\t\t\t<key>CFBundleTypeRole</key>\n\t\t\t<string>Editor</string>\n\t\t\t<key>CFBundleURLSchemes</key>\n\t\t\t<array><string>${reversedClientId}</string></array>\n\t\t</dict>`;
  if (infoText.includes('<key>CFBundleURLTypes</key>')) {
    infoText = infoText.replace(
      /(<key>CFBundleURLTypes<\/key>\s*<array>)/,
      `$1${callbackType}`,
    );
  } else {
    const types = `\n\t<key>CFBundleURLTypes</key>\n\t<array>${callbackType}\n\t</array>\n`;
    infoText = infoText.replace('\n</dict>\n</plist>', `${types}</dict>\n</plist>`);
  }
}
if (!infoText.includes('<key>CFBundleDisplayName</key>')) {
  infoText = infoText.replace('<dict>', '<dict>\n\t<key>CFBundleDisplayName</key>\n\t<string>NowssB</string>');
}
writeFileSync(info, infoText);

// Flutter's generated project does not know about this configuration file.
// Add it to the Runner resource phase so Firebase can discover it at runtime.
const fileRef = 'F10A55B0C0DE000000000001';
const buildRef = 'F10A55B0C0DE000000000002';
let pbx = readFileSync(project, 'utf8');
if (!pbx.includes('GoogleService-Info.plist')) {
  pbx = pbx.replace(
    '/* Begin PBXBuildFile section */',
    `/* Begin PBXBuildFile section */\n\t\t${buildRef} /* GoogleService-Info.plist in Resources */ = {isa = PBXBuildFile; fileRef = ${fileRef} /* GoogleService-Info.plist */; };`,
  );
  pbx = pbx.replace(
    '/* Begin PBXFileReference section */',
    `/* Begin PBXFileReference section */\n\t\t${fileRef} /* GoogleService-Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = GoogleService-Info.plist; sourceTree = "<group>"; };`,
  );
  const runnerGroup = /(\/\* Runner \*\/ = \{[\s\S]*?children = \(\n)/;
  const resources = /(\/\* Resources \*\/ = \{[\s\S]*?files = \(\n)/;
  if (!runnerGroup.test(pbx) || !resources.test(pbx)) {
    throw new Error('could not locate the Runner source group or resource phase');
  }
  pbx = pbx.replace(runnerGroup, `$1\t\t\t\t${fileRef} /* GoogleService-Info.plist */,\n`);
  pbx = pbx.replace(resources, `$1\t\t\t\t${buildRef} /* GoogleService-Info.plist in Resources */,\n`);
}
pbx = pbx.replace(/PRODUCT_BUNDLE_IDENTIFIER = [^;]+;/g, `PRODUCT_BUNDLE_IDENTIFIER = ${appId};`);
writeFileSync(project, pbx);

console.log('configured Flutter iOS: canonical icon, NowssB, Firebase, and Google callback');
