// Configures the generated Android project, after `flutter create`.
//
// flutter_app/android/ is generated and not committed, so everything this app
// needs beyond the defaults has to be applied on the way into a build. Four
// things, each of which the build fails without:
//
//   1. THE APPLICATION ID.  google-services.json is issued for a package name,
//      and the one in the Firebase console is `com.nowssb.app`. flutter create
//      derives `com.nowssb.nowssb` from --org and --project-name, and the
//      google-services plugin refuses a mismatch outright. Only applicationId
//      is changed; the namespace stays as generated, because the manifest
//      resolves `.MainActivity` against the namespace and moving it would mean
//      moving the Kotlin file too, for nothing.
//
//   2. CORE LIBRARY DESUGARING.  flutter_local_notifications uses java.time,
//      which does not exist below API 26, so it requires desugaring and the
//      build says so by name.
//
//   3. minSdk 23.  firebase_auth's floor. The Flutter default is lower.
//
//   4. THE GOOGLE SERVICES PLUGIN, plus the json beside it. The FlutterFire
//      packages do not apply this for you — without it the json is inert and
//      Firebase.initializeApp() fails at runtime with no default options.
//
// Run it AFTER `flutter create` and BEFORE `flutter build`. It is idempotent:
// running twice is a no-op, so a local android/ that is already configured is
// left alone.
//
//   node tools/flutter-android.mjs

import { readFileSync, writeFileSync, existsSync, copyFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const android = join(root, 'flutter_app', 'android');

/** The package name Firebase issued the config for. Read from the file rather
 *  than written here twice — if the console ever issues a new one, this
 *  follows it. */
const configJson = join(root, 'flutter_app', 'android-config', 'google-services.json');
if (!existsSync(configJson)) {
  console.error(`missing ${configJson}`);
  process.exit(1);
}
const APP_ID = JSON.parse(readFileSync(configJson, 'utf8'))
  .client[0].client_info.android_client_info.package_name;

if (!existsSync(android)) {
  console.error(`missing ${android} — run \`flutter create --platforms=android\` first`);
  process.exit(1);
}

// Pinned deliberately. A build that quietly changes its toolchain between runs
// is a build that fails on a day nobody touched it.
const GOOGLE_SERVICES = '4.4.2';
const DESUGAR_LIBS = '2.1.4';

const appGradle = join(android, 'app', 'build.gradle.kts');
const settings = join(android, 'settings.gradle.kts');

for (const f of [appGradle, settings]) {
  if (!existsSync(f)) {
    console.error(`missing ${f} — this script expects the Kotlin DSL that ` +
      `flutter create writes; if Flutter has gone back to Groovy, update it`);
    process.exit(1);
  }
}

const done = [];
const already = [];

// ── settings.gradle.kts: declare the plugin ────────────────────────────
let s = readFileSync(settings, 'utf8');
if (s.includes('com.google.gms.google-services')) {
  already.push('google-services declared');
} else {
  const anchor = 'id("com.android.application")';
  const at = s.indexOf(anchor);
  if (at < 0) throw new Error('settings.gradle.kts: no com.android.application plugin line');
  const eol = s.indexOf('\n', at);
  s = s.slice(0, eol + 1) +
    `    id("com.google.gms.google-services") version "${GOOGLE_SERVICES}" apply false\n` +
    s.slice(eol + 1);
  writeFileSync(settings, s);
  done.push('declared google-services');
}

// ── app/build.gradle.kts ───────────────────────────────────────────────
let a = readFileSync(appGradle, 'utf8');

// 4. apply the plugin
if (a.includes('id("com.google.gms.google-services")')) {
  already.push('google-services applied');
} else {
  a = a.replace(
    'id("dev.flutter.flutter-gradle-plugin")',
    'id("dev.flutter.flutter-gradle-plugin")\n    id("com.google.gms.google-services")',
  );
  done.push('applied google-services');
}

// 1. the application id Firebase issued the config for
if (a.includes(`applicationId = "${APP_ID}"`)) {
  already.push(`applicationId ${APP_ID}`);
} else {
  const before = a;
  a = a.replace(/applicationId = "[^"]*"/, `applicationId = "${APP_ID}"`);
  if (a === before) throw new Error('app/build.gradle.kts: no applicationId line');
  done.push(`applicationId → ${APP_ID}`);
}

// 3. firebase_auth's floor
if (/minSdk = 23\b/.test(a)) {
  already.push('minSdk 23');
} else {
  const before = a;
  a = a.replace(/minSdk = flutter\.minSdkVersion/, 'minSdk = 23');
  if (a === before && !/minSdk = \d+/.test(a)) {
    throw new Error('app/build.gradle.kts: no minSdk line');
  }
  done.push('minSdk → 23');
}

// 2. desugaring: the flag, and the library that backs it
if (a.includes('isCoreLibraryDesugaringEnabled')) {
  already.push('desugaring enabled');
} else {
  const before = a;
  a = a.replace(
    /(compileOptions \{\n)/,
    `$1        isCoreLibraryDesugaringEnabled = true\n`,
  );
  if (a === before) throw new Error('app/build.gradle.kts: no compileOptions block');
  done.push('enabled core library desugaring');
}

if (a.includes('coreLibraryDesugaring(')) {
  already.push('desugar_jdk_libs present');
} else {
  a += `\n// Required by flutter_local_notifications, which uses java.time — a class\n` +
       `// that does not exist below API 26 and has to be desugared in.\n` +
       `dependencies {\n` +
       `    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:${DESUGAR_LIBS}")\n` +
       `}\n`;
  done.push('added desugar_jdk_libs');
}

writeFileSync(appGradle, a);

// ── the config itself ──────────────────────────────────────────────────
// Not a secret: google-services.json ships inside every copy of the APK and
// identifies the project rather than authorising anything. The keystore and
// the service-account json are the secrets, and .gitignore refuses both.
const dest = join(android, 'app', 'google-services.json');
copyFileSync(configJson, dest);
done.push('copied google-services.json');

console.log('flutter_app/android/ configured for ' + APP_ID);
for (const d of done) console.log(`  + ${d}`);
for (const d of already) console.log(`  · ${d} (already)`);
