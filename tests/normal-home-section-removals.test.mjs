import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const index = readFileSync(new URL("../index.html", import.meta.url), "utf8");
const layout = readFileSync(new URL("../app/js/part062.js", import.meta.url), "utf8");
const normalRegistry = layout.slice(layout.indexOf("nm: {"), layout.indexOf("fash: {"));
const normalStart = index.indexOf('id="home-nm"');
const normalEnd = index.indexOf('id="home"', normalStart + 1);
assert.ok(normalStart >= 0 && normalEnd > normalStart, "Normal Home boundaries must be present");
const normalHome = index.slice(normalStart, normalEnd);

assert.doesNotMatch(normalHome, /nmh-cust-panel/, "Normal Home Customize section must be removed");
assert.doesNotMatch(normalHome, /class="nmh-connect-sec nwsb-inframe/, "Normal Home tall NowssB Connect section must be removed");
assert.doesNotMatch(normalHome, /nedi-blk/, "Normal Home NowssB Edition section must be removed");
assert.doesNotMatch(normalRegistry, /nmh-cust-panel/, "Normal Home Customize layout entry must be removed");
assert.doesNotMatch(normalRegistry, /nmh-connect-sec/, "Normal Home Connect layout entry must be removed");
assert.doesNotMatch(normalRegistry, /nedi-blk/, "Normal Home Edition layout entry must be removed");

console.log("Requested Normal Home section removals verified.");
