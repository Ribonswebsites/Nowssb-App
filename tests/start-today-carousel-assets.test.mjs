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
  join(root, "flutter_app/lib/screens/start_today_carousel.dart"),
  "utf8",
);
assert.match(dart, /assets\/coach\/aarogya-personal-coach\.png/);
assert.match(dart, /START TODAY/);
assert.match(dart, /BoxFit\.contain/);
assert.match(dart, /Let's start your healing today/);
assert.match(dart, /Start your streak today/);
assert.match(dart, /Get your score/);
assert.match(dart, /Share your score/);
assert.match(dart, /GlassEnterPill/);
assert.doesNotMatch(dart, /Personal Coach/);
assert.doesNotMatch(dart, /Customise your practice/);
assert.doesNotMatch(dart, /AAROGYA/);
assert.doesNotMatch(dart, /RoutineStyleBlackBanner/);
assert.doesNotMatch(dart, /3 cards/);

const fash = readFileSync(join(root, "flutter_app/lib/screens/fashion/sections_top.dart"), "utf8");
assert.match(fash, /GlassEnterPill/);
assert.doesNotMatch(fash, /title:\s*word/);
assert.match(fash, /Your personalized word ritual for right now\./);

const css = readFileSync(join(root, "nowssb-nm.css"), "utf8");
assert.match(css, /st-today-sec/);
assert.match(css, /st-today-label/);
assert.doesNotMatch(css, /pc-coach-sec/);
assert.match(css, /fp-card \.fp-enter/);
assert.match(css, /home-card-title/);

const js = readFileSync(join(root, "app/js/part096-start-today-carousel.js"), "utf8");
assert.match(js, /START TODAY/);
assert.doesNotMatch(js, /Personal Coach/);
assert.doesNotMatch(js, /Customise your practice/);
assert.doesNotMatch(js, /AAROGYA/);

const idx = readFileSync(join(root, "index.html"), "utf8");
assert.match(idx, /part096-start-today-carousel\.js/);
assert.doesNotMatch(idx, /part096-personal-coach-carousel\.js/);

console.log("Start Today carousel + practice hero cleanup verified.");
