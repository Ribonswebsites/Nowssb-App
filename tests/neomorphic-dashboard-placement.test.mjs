import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const index = readFileSync(new URL("../index.html", import.meta.url), "utf8");
const registry = readFileSync(new URL("../app/js/part062.js", import.meta.url), "utf8");
const flutter = readFileSync(new URL("../flutter_app/lib/screens/home_normal.dart", import.meta.url), "utf8");

const searchAt = index.indexOf('class="nmh-search"');
const dashboardAt = index.indexOf('class="nmh-supplied-dashboard"');
assert.ok(searchAt >= 0 && dashboardAt > searchAt, "WebView dashboard must follow Normal Home search");
assert.match(index, /<iframe src="app\/widgets\/neomorphic_dashboard\.html"/, "WebView must embed the supplied dashboard file");
assert.match(registry, /k:'dashboard'[\s\S]*sel:\['\.nmh-supplied-dashboard'\][\s\S]*after:'search'/, "Dashboard must remain anchored below search");
assert.ok(flutter.indexOf("'search'") < flutter.indexOf("'dashboard'"), "Flutter dashboard must follow search in Normal Home order");
assert.match(flutter, /NmSuppliedDashboard\(onStart: \(\) => _go\(1\)\)/, "Flutter must render the dashboard after search");

console.log("Supplied dashboard is anchored below Normal Home search in WebView and Flutter.");
