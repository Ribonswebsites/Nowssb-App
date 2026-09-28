// Writes NowssB-Flutter-update.json, the manifest the in-app updater reads
// (flutter_app/lib/app_update.dart). Run by .github/workflows/flutter-apk.yml
// after the release APKs are built, and uploaded to the release LAST, so a
// phone never sees a manifest that points at a file not uploaded yet.
//
//   node tools/flutter-update-manifest.mjs --build 912 --repo owner/name \
//     --tag nowssb-flutter-android --out NowssB-Flutter-update.json \
//     --universal NowssB-Flutter-Android.apk=path/to/app-release.apk \
//     --apk arm64-v8a=NowssB-Flutter-912-arm64-v8a.apk=path/to/app-arm64-v8a-release.apk \
//     --apk armeabi-v7a=NowssB-Flutter-912-armeabi-v7a.apk=path/to/app-armeabi-v7a-release.apk
//
// FORCING AN UPDATE. flutter_app/update-policy.json:
//   "minBuild": 0         nobody is forced (the default).
//   "minBuild": 905       builds below 905 are blocked until they update.
//   "minBuild": "latest"  every older build is blocked — this build is the
//                         minimum. It stays that way for every later build
//                         until the file is changed back, so use it for one
//                         push and then set a number.
//   "notes": "…"          optional text carried in the manifest.
//
// Fields `build`, `websiteUrl` and `apkUrl` are what the first updater
// read; they stay so those installs still see the update.
import { createHash } from 'node:crypto';
import { createReadStream, readFileSync, statSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const opt = (name) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : undefined;
};
const many = (name) => args.flatMap((a, i) => (a === `--${name}` ? [args[i + 1]] : []));

const build = Number.parseInt(opt('build') ?? '', 10);
const repo = opt('repo');
const tag = opt('tag');
const out = opt('out');
if (!Number.isInteger(build) || build < 1 || !repo || !tag || !out) {
  console.error('usage: --build N --repo owner/name --tag TAG --out FILE --universal NAME=PATH [--apk ABI=NAME=PATH ...]');
  process.exit(1);
}

const sha256 = (path) => new Promise((resolve, reject) => {
  const hash = createHash('sha256');
  createReadStream(path).on('data', (d) => hash.update(d)).on('error', reject)
    .on('end', () => resolve(hash.digest('hex')));
});
const url = (name) => `https://github.com/${repo}/releases/download/${tag}/${name}`;
const describe = async (name, path) => {
  if (!existsSync(path)) throw new Error(`missing ${path}`);
  return { url: url(name), size: statSync(path).size, sha256: await sha256(path) };
};

const policyPath = join(root, 'flutter_app', 'update-policy.json');
const policy = existsSync(policyPath) ? JSON.parse(readFileSync(policyPath, 'utf8')) : {};
let minBuild = 0;
if (policy.minBuild === 'latest') minBuild = build;
else if (Number.isInteger(policy.minBuild) && policy.minBuild > 0) minBuild = Math.min(policy.minBuild, build);

const [uName, uPath] = (opt('universal') ?? '').split('=');
if (!uName || !uPath) throw new Error('--universal NAME=PATH is required');
const universal = await describe(uName, uPath);

const apks = {};
for (const spec of many('apk')) {
  const [abi, name, path] = spec.split('=');
  if (!abi || !name || !path) throw new Error(`bad --apk ${spec}`);
  apks[abi] = await describe(name, path);
}

const manifest = {
  channel: 'flutter-android',
  build,
  minBuild,
  websiteUrl: 'https://ribonswebsites.github.io/Nowssb-App/',
  apkUrl: universal.url,
  apkSize: universal.size,
  apkSha256: universal.sha256,
  apks,
  notes: typeof policy.notes === 'string' ? policy.notes : '',
};
writeFileSync(out, JSON.stringify(manifest, null, 2) + '\n');
const mb = (n) => `${(n / 1048576).toFixed(1)} MB`;
console.log(`update manifest: build ${build}, minBuild ${minBuild}`);
console.log(`  universal   ${mb(universal.size)}  ${uName}`);
for (const [abi, a] of Object.entries(apks)) console.log(`  ${abi.padEnd(11)} ${mb(a.size)}  ${a.url.split('/').pop()}`);
