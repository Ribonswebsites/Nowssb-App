import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";

const index = readFileSync(new URL("../index.html", import.meta.url), "utf8");
const css = readFileSync(new URL("../nowssb-nm.css", import.meta.url), "utf8");
const js = readFileSync(new URL("../app/js/part097-hero-curve.js", import.meta.url), "utf8");
const flutter = readFileSync(new URL("../flutter_app/lib/widgets/hero_curve_stage.dart", import.meta.url), "utf8");
const homeNm = readFileSync(new URL("../flutter_app/lib/screens/home_normal.dart", import.meta.url), "utf8");
const homeFash = readFileSync(new URL("../flutter_app/lib/screens/home_fashion.dart", import.meta.url), "utf8");

assert.match(index, /nwsb-curve-nm/, "Normal home must mount the 3D curve below search");
assert.match(index, /nwsb-curve-fash glass-wrap/, "Fashion curve sits in a glass pane");
assert.match(index, /Sound that finds you/, "Curve uses the Sound that finds you line");
assert.match(index, /Pronunciation & sound healing, wherever you are/, "Curve uses the pronunciation headline");
assert.doesNotMatch(index, /she stays/, "Do not put the she-stays swipe line");
assert.match(homeFash, /HeroCurveStage\(glass: true\)/, "Flutter Fashion home puts the curve under the greeting in glass");
assert.match(css, /width:\s*152px/, "Orbiting stills are 16:9 wide");
assert.match(css, /height:\s*86px/, "Orbiting stills are 16:9 short");
assert.match(css, /height:\s*72%/, "Center subject is smaller than full-bleed");
assert.match(flutter, /width: 152/, "Flutter stills are 16:9 wide");
assert.match(flutter, /height: 86/, "Flutter stills are 16:9 short");
assert.match(flutter, /heightFactor: 0\.72/, "Flutter subject is smaller");
assert.match(index, /part097-hero-curve\.js/, "Both homes must load the curve spinner");
assert.match(css, /perspective:\s*980px/, "Curve stage must be a 3D scene");
assert.match(js, /data-nwsb-curve/, "Spinner must bind every curve stage");
assert.match(flutter, /rotateY/, "Flutter curve must orbit on Y");
assert.match(homeNm, /HeroCurveStage\(compact: true\)/, "Flutter Normal home puts the curve under search");
assert.ok(existsSync(new URL("../assets/hero-curve/subject.webp", import.meta.url)));
assert.ok(existsSync(new URL("../assets/hero-curve/stillness.webp", import.meta.url)));

const searchAt = index.indexOf('class="nmh-search"');
const curveNmAt = index.indexOf('nwsb-curve-nm');
const dashAt = index.indexOf('class="nmh-supplied-dashboard"');
assert.ok(searchAt >= 0 && curveNmAt > searchAt && dashAt > curveNmAt,
  "Normal curve sits between search and the dashboard");
const greetAt = index.indexOf('class="home-greeting');
const curveFashAt = index.indexOf('nwsb-curve-fash');
const herorowAt = index.indexOf('class="hhr-blk');
assert.ok(greetAt >= 0 && curveFashAt > greetAt && herorowAt > curveFashAt,
  "Fashion curve sits below the greeting and above the hero row");

console.log("3D curve is on both homes, Flutter and WebView.");
