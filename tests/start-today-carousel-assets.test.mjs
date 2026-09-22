import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");

/* Flutter still keeps the practice-art bytes. Website / WebView no longer
   mount a Start Today rail — that rail is what scrolled the page. */
const art = "aarogya-personal-coach.png";
for (const base of ["assets/coach", "flutter_app/assets/coach"]) {
  const p = join(root, base, art);
  assert.ok(existsSync(p), `missing ${base}/${art}`);
  assert.equal(readFileSync(p).length, 1933133, `${base}/${art} must be original bytes (no recompress)`);
}

const fash = readFileSync(join(root, "flutter_app/lib/screens/fashion/sections_top.dart"), "utf8");
assert.match(fash, /GlassEnterPill/);
assert.doesNotMatch(fash, /title:\s*word/);
assert.match(fash, /Your personalized word ritual for right now\./);

const css = readFileSync(join(root, "nowssb-nm.css"), "utf8");
assert.match(css, /\.st-today-sec[\s\S]{0,180}display:\s*none\s*!important/);
assert.doesNotMatch(css, /st-today-label/);
assert.doesNotMatch(css, /pc-coach-sec/);
assert.match(css, /fp-card \.fp-enter/);
assert.match(css, /home-card-title/);

const js = readFileSync(join(root, "app/js/part096-start-today-carousel.js"), "utf8");
assert.doesNotMatch(js, /START TODAY/);
assert.doesNotMatch(js, /scrollIntoView/);
assert.doesNotMatch(js, /st-today-card/);
assert.doesNotMatch(js, /Let's start your healing today/);
assert.match(js, /\.st-today-sec/);
assert.match(js, /removeChild/);
assert.match(js, /todayPracticeTitle/);
assert.match(js, /removeProperty\('display'\)/);

const idx = readFileSync(join(root, "index.html"), "utf8");
assert.match(idx, /part096-start-today-carousel\.js\?v=3/);
assert.doesNotMatch(idx, /part096-personal-coach-carousel\.js/);
assert.match(idx, /nwsb_sw_reset_v8/);
assert.match(idx, /nowssb-nm\.css\?v=805/);
assert.match(idx, /part062\.js\?v=51/);

const layout = readFileSync(join(root, "app/js/part062.js"), "utf8");
const nmReg = layout.slice(layout.indexOf("nm: {"), layout.indexOf("fash: {"));
const fashReg = layout.slice(layout.indexOf("fash: {"));
assert.doesNotMatch(layout, /k:'coachCards'/);
assert.doesNotMatch(layout, /label:'Start Today'/);
assert.match(layout, /LAYOUT_V = 9/);
assert.match(nmReg, /k:'healing'[\s\S]{0,220}always:1/);
assert.doesNotMatch(nmReg, /k:'healing'[\s\S]{0,220}defOff:1/);
assert.match(nmReg, /k:'genderpath'[\s\S]{0,80}sel:\['\.nwsb-genderpath'\]/);
assert.doesNotMatch(nmReg, /k:'genderpath'[\s\S]{0,220}after:'healing'/);
assert.match(fashReg, /k:'healing'[\s\S]{0,220}defOff:1/);
assert.doesNotMatch(fashReg, /k:'healing'[\s\S]{0,220}always:1/);
assert.match(fashReg, /k:'genderpath'[\s\S]{0,80}sel:\['\.nwsb-genderpath'\]/);
assert.doesNotMatch(fashReg, /k:'genderpath'[\s\S]{0,220}after:'healing'/);
assert.match(layout, /if \(\(raw\.v \|\| 0\) < 9\)/);

const flutterNm = readFileSync(join(root, "flutter_app/lib/screens/home_normal.dart"), "utf8");
const flutterFash = readFileSync(join(root, "flutter_app/lib/screens/home_fashion.dart"), "utf8");
assert.ok(
  flutterNm.indexOf("'connectban'") < flutterNm.indexOf("'healing'"),
  "Flutter Normal Personalised Healing sits after Connect Banner",
);
assert.ok(
  flutterNm.indexOf("'healing'") < flutterNm.indexOf("'genderpath'"),
  "Flutter Normal Choose Your Path sits under Personalised Healing",
);
assert.ok(
  flutterFash.indexOf("'connectban'") < flutterFash.indexOf("'healing'"),
  "Flutter Fashion Personalised Healing sits after Connect Banner",
);

console.log("Start Today removed from website/WebView; Personalised Healing pinned like Flutter.");
