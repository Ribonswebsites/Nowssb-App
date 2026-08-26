import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const index = readFileSync(new URL("../index.html", import.meta.url), "utf8");
const registry = readFileSync(new URL("../app/js/part062.js", import.meta.url), "utf8");
const flutter = readFileSync(new URL("../flutter_app/lib/screens/home_normal.dart", import.meta.url), "utf8");
const flutterDashboard = readFileSync(new URL("../flutter_app/lib/screens/normal/neomorphic_dashboard.dart", import.meta.url), "utf8");
const styles = readFileSync(new URL("../nowssb-nm.css", import.meta.url), "utf8");
const dashboard = readFileSync(new URL("../app/widgets/neomorphic_dashboard.html", import.meta.url), "utf8");

const searchAt = index.indexOf('class="nmh-search"');
const dashboardAt = index.indexOf('class="nmh-supplied-dashboard"');
assert.ok(searchAt >= 0 && dashboardAt > searchAt, "WebView dashboard must follow Normal Home search");
assert.match(index, /<iframe src="app\/widgets\/neomorphic_dashboard\.html"/, "WebView must use the supplied dashboard file directly");
assert.doesNotMatch(styles, /\.nmh-supplied-dashboard\s*\{[^}]*height:/s, "Host must not reserve a fixed empty height");
assert.doesNotMatch(styles, /\.nmh-supplied-dashboard\s*\{[^}]*box-shadow:/s, "Host must not add another dashboard wrapper shadow");
assert.doesNotMatch(dashboard, /class="phone"/, "Dashboard must not retain the large outer phone wrapper");
assert.match(dashboard, /type: 'nowssb-dashboard-action'/, "Dashboard actions must notify the parent application");
assert.match(dashboard, /nowssb-dashboard-data/, "Dashboard values must be supplied by the parent app");
assert.match(dashboard, /dashboardMetricToday/, "Dashboard must expose a live sessions-today metric");
assert.match(index, /nowssb-dashboard-action/, "Normal Home must handle dashboard action messages");
assert.match(index, /startDashboardPractice/, "Dashboard actions must start the playable practice session");
assert.match(index, /part094-dashboard-live\.js/, "Normal Home must load the live dashboard controller");
assert.match(registry, /k:'dashboard'[\s\S]*sel:\['\.nmh-supplied-dashboard'\][\s\S]*after:'search'/, "Dashboard must remain anchored below search");
assert.ok(flutter.indexOf("'search'") < flutter.indexOf("'dashboard'"), "Flutter dashboard must follow search in Normal Home order");
assert.match(flutter, /NmSuppliedDashboard\(onStart: _openDashboardSession, onProgress: _openDashboardProgress\)/, "Flutter must wire the dashboard to its real player and progress screen");
assert.match(flutterDashboard, /PracticeProgress\.instance/, "Flutter dashboard must use persistent user session data");
assert.match(flutterDashboard, /Plays aloud/, "Flutter dashboard must identify the audible session behavior");

console.log("Supplied dashboard is anchored below Normal Home search in WebView and Flutter.");
