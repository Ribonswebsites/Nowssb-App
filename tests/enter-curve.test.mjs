import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";

const index = readFileSync(new URL("../index.html", import.meta.url), "utf8");
const css = readFileSync(new URL("../nowssb-nm.css", import.meta.url), "utf8");
const js = readFileSync(new URL("../app/js/part097-hero-curve.js", import.meta.url), "utf8");
const reg = readFileSync(new URL("../app/js/part062.js", import.meta.url), "utf8");
const flutter = readFileSync(new URL("../flutter_app/lib/widgets/enter_curve_stage.dart", import.meta.url), "utf8");
const homeFash = readFileSync(new URL("../flutter_app/lib/screens/home_fashion.dart", import.meta.url), "utf8");
const promo = readFileSync(new URL("../flutter_app/lib/screens/fashion/sections_bottom.dart", import.meta.url), "utf8");

assert.match(index, /nwsb-enter-curve/, "Enter curve sits on Fashion home");
assert.match(index, /banner-player\.webp/, "Player banner is in the ring");
assert.match(index, /banner-library\.webp/, "Library banner is in the ring");
assert.match(index, /banner-store\.webp/, "Store banner is in the ring");
assert.match(index, /banner-reader\.webp/, "Reader banner is in the ring");
assert.match(index, /pointer\.webp/, "Pointing figure is the bottom-right of the stage");
assert.match(index, /nwsb-enter-embed/, "Promo tablet uses the enter ring");
assert.doesNotMatch(index, /fpv-video/, "Promo tablet has no background film");
assert.match(css, /nwsb-enter-pill/, "Enter is a glass pill");
assert.match(js, /openSub\('practice'\)/, "Player Enter opens practice");
assert.match(js, /openSub\('sound-library'\)/, "Library Enter opens the sound library");
assert.match(reg, /k:'enterCurve'/, "Registry places the enter curve");
assert.match(homeFash, /enterCurve/, "Flutter Fashion home has the enter curve");
assert.match(homeFash, /EnterCurveStage\(glass: true/, "Flutter enter curve is glass");
assert.match(promo, /showVideo: false/, "Flutter promo tablet has no film");
assert.match(promo, /EnterCurveStage\(/, "Flutter promo tablet uses the enter ring");
assert.match(flutter, /cleopatra\.webp/, "Second enter card uses the Egyptian centre");
assert.match(flutter, /heightFactor: compact \? 0.88 : 0.50/, "Centre figure is smaller like the hero");
assert.match(flutter, /PageView/, "Enter curve is a swipeable pair of cards");
assert.match(index, /cleopatra\.webp/, "Website ships the Egyptian centre");
assert.match(index, /nwsb-enter-pager/, "Website enter curve is swipeable");
assert.match(index, /home-tile-banner/, "Second four-button card uses the banners");
assert.match(index, /home-tile-title">Connect/, "Sound Library on the first four-button card is Connect");
assert.match(homeFash, /FashTiles\(onTile: _go, onOpen: _openEnter\)/, "Second tile card opens destinations");
assert.match(flutter, /clamp\(-72.0, 72.0\)/, "Parallax is viewport-relative so the section stays on screen");
assert.doesNotMatch(flutter, /_pos!\.pixels/, "Parallax is not raw list pixels");
assert.match(flutter, /_WhiteChip/, "Icon sits in a white circle");
assert.match(flutter, /_WhiteEnter/, "Enter sits in a white pill");
assert.doesNotMatch(flutter, /nwsb-enter-rule|_EnterRail/, "No extra vertical rule — the still already has one");
assert.match(flutter, /height: 560/, "Enter curve pager is tall");
assert.match(flutter, /EnterCurveAssets.extras/, "Ring is filled like the hero");
assert.match(js, /ICONS.filter/, "Website rail uses the one icon for that banner");
assert.doesNotMatch(js, /nwsb-enter-icons/, "Website no longer dumps every icon on each card");
assert.match(css, /height: 420px/, "Website enter stage matches the hero tile ring");
assert.ok(existsSync(new URL("../assets/hero-curve/pointer.webp", import.meta.url)));
assert.ok(existsSync(new URL("../assets/hero-curve/banner-player.webp", import.meta.url)));

const fpsAt = index.indexOf('id="fpSection"');
const enterAt = index.indexOf('nwsb-enter-curve');
const rxAt = index.indexOf('id="rxCardWrap"');
assert.ok(fpsAt >= 0 && enterAt > fpsAt && rxAt > enterAt,
  "Enter curve sits between Fashion Plus and AI Prescription");

console.log("Enter curve is above prescription, tablet has no film.");
