import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const index = readFileSync(new URL("../index.html", import.meta.url), "utf8");
const flow = readFileSync(new URL("../app/js/part093-support-flow.js", import.meta.url), "utf8");
const firebase = readFileSync(new URL("../app/js/firebase.module.js", import.meta.url), "utf8");
const admin = readFileSync(new URL("../admin.html", import.meta.url), "utf8");
const worker = readFileSync(new URL("../worker.js", import.meta.url), "utf8");

assert.match(index, /onclick="openHelpSupport\(\)"/, "Chat Support must open the Help and Support destination");
assert.match(index, /app\/widgets\/help-support\.html/, "The supplied Help and Support page must be embedded");
assert.match(index, /nwsbSupportChat/, "The dark support chat container must be present");
assert.match(flow, /\/api\/assistant\/chat/, "Support messages must use the existing secured AI route");
assert.match(flow, /body\.needsHuman \|\| state\.intent === 'feedback'/, "Reports must escalate only when the AI cannot resolve them");
assert.doesNotMatch(flow, /state\.intent === 'report'/, "Report selection alone must not bypass AI-first support");
assert.match(flow, /window\._fbCreateSupportReport/, "Escalated support cases must be persisted for the admin interface");
assert.match(firebase, /window\._fbCreateSupportReport/, "Firebase must expose authenticated support-case creation");
assert.match(firebase, /collection\(db, 'reports'\)/, "Support cases must use the protected reports collection");
assert.match(admin, /SUPPORT CASES/, "The admin dashboard must contain a Support Cases inbox");
assert.match(admin, /watchSupportCases\(\)/, "The admin dashboard must watch incoming support cases");
assert.match(worker, /\/api\/support\/escalate/, "The worker must expose a background escalation route");
assert.match(worker, /RESEND_API_KEY/, "The worker must use a server-side Resend credential");
assert.match(worker, /SUPPORT_TO_EMAIL/, "The worker must use a server-side recipient binding");
assert.doesNotMatch(worker, /nowssbonline@gmail\.com/, "The recipient must not be hardcoded into Worker source");

console.log("Support flow static contract verified.");
