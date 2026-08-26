import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const index = readFileSync(new URL("../index.html", import.meta.url), "utf8");
const registry = readFileSync(new URL("../app/js/part062.js", import.meta.url), "utf8");
const flutter = readFileSync(new URL("../flutter_app/lib/screens/home_normal.dart", import.meta.url), "utf8");
const flutterDashboard = readFileSync(new URL("../flutter_app/lib/screens/normal/neomorphic_dashboard.dart", import.meta.url), "utf8");
const styles = readFileSync(new URL("../nowssb-nm.css", import.meta.url), "utf8");

const searchAt = index.indexOf('class="nmh-search"');
const dashboardAt = index.indexOf('class="nmh-supplied-dashboard"');
assert.ok(searchAt >= 0 && dashboardAt > searchAt, "WebView dashboard must follow Normal Home search");
assert.doesNotMatch(index, /<iframe src="app\/widgets\/neomorphic_dashboard\.html"/, "Dashboard must not use an extra iframe wrapper");
assert.match(index, /<h2>Morning<br>Resonance<\/h2>/, "WebView dashboard must use the requested Morning Resonance title");
assert.match(index, /Start practice/, "WebView dashboard must use the requested practice CTA");
assert.match(index, /meditation<br>sessions/, "WebView dashboard must use the requested progress labels");
assert.doesNotMatch(styles, /\.nmh-supplied-dashboard\s*\{[^}]*height:\s*1036px/s, "Dashboard must not reserve a fixed empty height");
assert.match(registry, /k:'dashboard'[\s\S]*sel:\['\.nmh-supplied-dashboard'\][\s\S]*after:'search'/, "Dashboard must remain anchored below search");
assert.ok(flutter.indexOf("'search'") < flutter.indexOf("'dashboard'"), "Flutter dashboard must follow search in Normal Home order");
assert.match(flutter, /NmSuppliedDashboard\(onStart: \(\) => _go\(1\)\)/, "Flutter must render the dashboard after search");
assert.match(flutterDashboard, /Morning\\nResonance/, "Flutter dashboard must use the requested Morning Resonance title");
assert.match(flutterDashboard, /Build your routine/, "Flutter dashboard must use the requested Up next text");

console.log("Supplied dashboard is anchored below Normal Home search in WebView and Flutter.");
