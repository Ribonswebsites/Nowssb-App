// Flutter derives Android versionCode from pubspec.yaml's +build suffix. This
// runner-only stamp is intentionally applied before `flutter create` and
// `flutter build`, so the APK behind a new release manifest really upgrades
// an older Flutter installation instead of failing as "app not installed".
import { readFileSync, writeFileSync } from 'node:fs';

const build = Number.parseInt(process.env.NWSB_BUILD_NUMBER || '', 10);
if (!Number.isInteger(build) || build < 1 || build > 2100000000) {
  throw new Error('NWSB_BUILD_NUMBER must be a positive Android versionCode');
}

const path = 'flutter_app/pubspec.yaml';
const source = readFileSync(path, 'utf8');
const stamped = source.replace(/^version:\s*[^\r\n]+/m, `version: 9.5.0+${build}`);
if (stamped === source || !stamped.includes(`version: 9.5.0+${build}`)) {
  throw new Error(`${path} did not contain a Flutter version field to stamp`);
}
writeFileSync(path, stamped);
console.log(`Flutter Android version stamped: 9.5.0+${build}`);
