import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const layout = readFileSync(new URL("../app/js/part062.js", import.meta.url), "utf8");
const dashboard = readFileSync(new URL("../app/js/part090.js", import.meta.url), "utf8");
const essentials = readFileSync(new URL("../app/js/part091.js", import.meta.url), "utf8");
const fashionPlus = readFileSync(new URL("../app/js/part076.js", import.meta.url), "utf8");

assert.match(layout, /var LAYOUT_V = 12/, "Fashion Home restoration must have a dedicated layout migration");
assert.match(layout, /restoreAugustFashion/, "Existing Fashion Home layouts must be restored to the August 15 baseline");
assert.match(layout, /data-vbwrap="vb3"/, "August 15 Fashion Home must retain its original Choose Your Path section");
assert.doesNotMatch(dashboard, /mount\('fashion'/, "The post-August dashboard must not be injected into Fashion Home");
assert.doesNotMatch(essentials, /mount\('fashion'/, "The post-August essentials panel must not be injected into Fashion Home");
assert.match(fashionPlus, /name: 'Violet Silk'/, "August 15 Fashion Home must restore its original Fashion Plus background option");
assert.match(fashionPlus, /name === 'Violet Silk'/, "August 15 Fashion Home must restore Violet Silk as the default background");

console.log("August 15 Fashion Home WebView baseline verified.");
