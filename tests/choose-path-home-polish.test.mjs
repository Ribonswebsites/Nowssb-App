import assert from "node:assert/strict";
import { existsSync, readFileSync, statSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");

const part067 = readFileSync(join(root, "app/js/part067.js"), "utf8");
assert.match(part067, /before:\s*'#homeFooterNm'/);
assert.match(part067, /before:\s*'#homeFooter'/);
assert.match(part067, /nwsb-genderpath/);
assert.match(part067, /wrapKey:\s*'genderpath'/);
assert.match(part067, /noBan:\s*1/);
assert.match(part067, /healing-path-bg\.mp4\?v=2/);
assert.match(part067, /\.vb-path-fill:not\(\.nwsb-genderpath\)/);
assert.match(part067, /spec\.head && !spec\.noBan/);
assert.doesNotMatch(part067, /after:\s*'#home-nm \.nmh-healing-wrap'/);
assert.doesNotMatch(part067, /after:\s*'#home \.fash-healing-wrap'/);

const css = readFileSync(join(root, "nowssb-nm.css"), "utf8");
assert.match(css, /#home \.fash-healing-wrap[\s\S]{0,80}display:\s*none\s*!important/);
assert.match(css, /#home-nm \.nsub-blk \.nwsb-sub-overlay/);
assert.match(css, /#home-nm \.nsub-blk \.nmh-banner-cta/);
assert.match(css, /\.vb-path-fill \.vbf-screen > video[\s\S]{0,220}object-fit:\s*cover\s*!important/);
assert.match(css, /#home \.nwsb-genderpath > \.nsub-ban/);

const sub = readFileSync(join(root, "app/js/subscription-tiers.js"), "utf8");
assert.match(sub, /block\.closest\('#home-nm'\)/);

const idx = readFileSync(join(root, "index.html"), "utf8");
assert.match(idx, /part067\.js\?v=41/);
assert.match(idx, /subscription-tiers\.js\?v=4/);

for (const base of ["assets/video", "flutter_app/assets/video"]) {
  const mp4 = join(root, base, "healing-path-bg.mp4");
  const poster = join(root, base, "healing-path-bg-poster.webp");
  assert.ok(existsSync(mp4), `missing ${base}/healing-path-bg.mp4`);
  assert.ok(existsSync(poster), `missing ${base}/healing-path-bg-poster.webp`);
  const bytes = statSync(mp4).size;
  assert.ok(bytes > 3_000_000 && bytes < 6_000_000, `${base}/healing-path-bg.mp4 size ${bytes} is not the pink/blue path film`);
}

const fash = readFileSync(join(root, "flutter_app/lib/screens/fashion/sections_top.dart"), "utf8");
assert.match(fash, /class FashStreak /);
assert.match(fash, /FashStreakBody\(/);
assert.doesNotMatch(fash, /build\(BuildContext context\) => const SizedBox\.shrink\(\);/);
assert.match(fash, /Alignment\(-0\.66,\s*-0\.08\)/);
assert.match(fash, /DAY\\nSTREAK/);
assert.match(fash, /KEEP\\nGOING/);
assert.match(fash, /DeviceFrame\.tabletLandscape/);
assert.doesNotMatch(fash, /secondCard:\s*FashStreakBody/);

const footer = readFileSync(join(root, "flutter_app/lib/screens/shared_sections.dart"), "utf8");
assert.match(footer, /Positioned\.fill/);
assert.match(footer, /BoxFit\.cover/);
assert.doesNotMatch(footer, /#homeFooterNm \.footer-bg-img/);
assert.doesNotMatch(footer, /if \(fashion\)/);

const flutterFash = readFileSync(join(root, "flutter_app/lib/screens/home_fashion.dart"), "utf8");
assert.match(flutterFash, /HealingSection/);
assert.ok(
  flutterFash.indexOf("'connectban'") < flutterFash.indexOf("'healing'"),
  "Flutter Fashion keeps Personalised Healing after Connect Banner",
);

console.log("Choose Your Path above footer; Fashion healing off on web; streak cubes + footer fill on Flutter.");
