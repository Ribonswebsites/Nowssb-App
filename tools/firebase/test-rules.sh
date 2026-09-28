#!/usr/bin/env bash
# Run tools/firebase/rules.test.mjs against firestore.rules in the local
# Firestore emulator (needs Java 11+). Dependencies go to a temp folder, not
# the repo.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
work="${RULES_TEST_DIR:-/tmp/nowssb-rules-test}"
mkdir -p "$work"
cd "$work"
[[ -f package.json ]] || npm init -y >/dev/null
[[ -d node_modules/@firebase/rules-unit-testing ]] || npm i -s firebase-tools@14 @firebase/rules-unit-testing@4 firebase@11 >/dev/null
cp "$root/firestore.rules" "$root/tools/firebase/rules.test.mjs" .
cat > firebase.json <<'JSON'
{ "firestore": { "rules": "firestore.rules" }, "emulators": { "firestore": { "port": 8089 }, "ui": { "enabled": false } } }
JSON
npx firebase emulators:exec --only firestore --project nowssb-34f1b "node rules.test.mjs"
