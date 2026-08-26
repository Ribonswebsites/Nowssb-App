import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const banners = readFileSync(new URL("../app/js/part067.js", import.meta.url), "utf8");
const layout = readFileSync(new URL("../app/js/part062.js", import.meta.url), "utf8");

assert.match(banners, /\{ after: '#home-nm #nmhFashSwitch'/, "Choose Your Path must be injected below Fashion Mode on Normal Home");
assert.doesNotMatch(banners, /\{ before: '#home-nm #nmhFashSwitch'/, "Choose Your Path must not be injected above Fashion Mode");
assert.match(banners, /function placeNormalGenderPathBelowFashionMode\(\)/, "The injected path must be force-anchored after Fashion Mode");
assert.match(banners, /fashionMode\.parentNode\.insertBefore\(path, fashionMode\.nextSibling\)/, "A top-rendered path must be moved directly below Fashion Mode");
assert.match(layout, /k:'genderpath'[\s\S]*after:'fashsw'/, "Saved Normal Home layouts must keep Choose Your Path below Fashion Mode");
assert.match(layout, /var LAYOUT_V = 13/, "The placement update must migrate existing WebView layouts");

console.log("Normal Home Fashion Mode placement verified.");
