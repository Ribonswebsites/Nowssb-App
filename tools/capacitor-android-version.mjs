// Stamps the generated Capacitor Android project with the same increasing
// GitHub Actions run number embedded in www/app-build.json. Android refuses
// to install an APK over an existing package unless its versionCode is higher,
// so this is the part that makes the WebView update prompt real.
import { readFileSync, writeFileSync } from 'node:fs';

const build = Number.parseInt(process.env.NWSB_BUILD_NUMBER || '', 10);
if (!Number.isInteger(build) || build < 1 || build > 2100000000) {
  throw new Error('NWSB_BUILD_NUMBER must be a positive Android versionCode');
}

const path = 'android/app/build.gradle';
const source = readFileSync(path, 'utf8');
const stamped = source
  .replace(/versionCode\s+\d+/, `versionCode ${build}`)
  .replace(/versionName\s+"[^"]*"/, `versionName "9.5.${build}"`);
if (stamped === source || !stamped.includes(`versionCode ${build}`)) {
  throw new Error(`${path} did not contain Android version fields to stamp`);
}
writeFileSync(path, stamped);
console.log(`Capacitor Android version stamped: 9.5.${build} (${build})`);
