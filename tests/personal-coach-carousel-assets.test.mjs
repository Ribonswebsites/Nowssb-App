import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const art = "aarogya-personal-coach.png";
for (const base of ["assets/coach", "flutter_app/assets/coach"]) {
  const p = join(root, base, art);
  assert.ok(existsSync(p), `missing ${base}/${art}`);
  assert.equal(readFileSync(p).length, 1933133, `${base}/${art} must be original bytes (no recompress)`);
}
const dart = readFileSync(
  join(root, "flutter_app/lib/screens/personal_coach_carousel.dart"),
  "utf8",
);
assert.match(dart, /assets\/coach\/aarogya-personal-coach\.png/);
assert.match(dart, /RoutineStyleBlackBanner/);
assert.match(dart, /Personal Coach/);
const fash = readFileSync(join(root, "flutter_app/lib/screens/fashion/sections_top.dart"), "utf8");
assert.match(fash, /GlassEnterPill/);
assert.doesNotMatch(fash, /title:\s*word/);
assert.match(fash, /Your personalized word ritual for right now\./);
const css = readFileSync(join(root, "nowssb-nm.css"), "utf8");
assert.match(css, /pc-coach-sec/);
assert.match(css, /fp-card \.fp-enter/);
assert.match(css, /home-card-title/);
console.log("Personal Coach carousel + practice hero cleanup verified.");
