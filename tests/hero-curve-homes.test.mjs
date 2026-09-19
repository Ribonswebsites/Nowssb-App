import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";

const index = readFileSync(new URL("../index.html", import.meta.url), "utf8");
const css = readFileSync(new URL("../nowssb-nm.css", import.meta.url), "utf8");
const js = readFileSync(new URL("../app/js/part097-hero-curve.js", import.meta.url), "utf8");
const flutter = readFileSync(new URL("../flutter_app/lib/widgets/hero_curve_stage.dart", import.meta.url), "utf8");
const homeNm = readFileSync(new URL("../flutter_app/lib/screens/home_normal.dart", import.meta.url), "utf8");
const homeFash = readFileSync(new URL("../flutter_app/lib/screens/home_fashion.dart", import.meta.url), "utf8");

assert.match(index, /nwsb-curve-nm/, "Normal home must mount the 3D curve below search");
assert.match(index, /nwsb-curve-fash/, "Fashion home must mount the 3D curve at the hero");
assert.match(index, /part097-hero-curve\.js/, "Both homes must load the curve spinner");
assert.match(css, /perspective:\s*980px/, "Curve stage must be a 3D scene");
assert.match(js, /data-nwsb-curve/, "Spinner must bind every curve stage");
assert.match(flutter, /rotateY/, "Flutter curve must orbit on Y");
assert.match(homeNm, /HeroCurveStage\(compact: true\)/, "Flutter Normal home puts the curve under search");
assert.match(homeFash, /const HeroCurveStage\(\)/, "Flutter Fashion home puts the curve on the hero");
assert.ok(existsSync(new URL("../assets/hero-curve/subject.webp", import.meta.url)));
assert.ok(existsSync(new URL("../assets/hero-curve/stillness.webp", import.meta.url)));

const searchAt = index.indexOf('class="nmh-search"');
const curveNmAt = index.indexOf('nwsb-curve-nm');
const dashAt = index.indexOf('class="nmh-supplied-dashboard"');
assert.ok(searchAt >= 0 && curveNmAt > searchAt && dashAt > curveNmAt,
  "Normal curve sits between search and the dashboard");
const homeAt = index.indexOf('id="home">');
const curveFashAt = index.indexOf('nwsb-curve-fash');
const heroAt = index.indexOf('HERO HEADER', homeAt);
assert.ok(curveFashAt > homeAt && curveFashAt < heroAt,
  "Fashion curve sits at the top of the hero header");

console.log("3D curve is on both homes, Flutter and WebView.");
