#!/usr/bin/env bash
# Runs the economy engine against the local Firestore emulator (Java 11+).
# No real project, no keys: FsDb talks to the emulator with the owner token.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
work="${RULES_TEST_DIR:-/tmp/nowssb-rules-test}"
mkdir -p "$work" && cd "$work"
[[ -f package.json ]] || npm init -y >/dev/null
[[ -d node_modules/firebase-tools ]] || npm i -s firebase-tools@14 >/dev/null
cat > firebase.json <<'JSON'
{ "firestore": { "rules": "firestore.rules" }, "emulators": { "firestore": { "port": 8089 }, "ui": { "enabled": false } } }
JSON
cp "$root/firestore.rules" .
npx firebase emulators:exec --only firestore --project nowssb-34f1b "export FIRESTORE_EMULATOR_HOST=127.0.0.1:8089; node '$root/tools/economy/economy-engine.test.mjs' && node '$root/tools/economy/play-ack.test.mjs' && node '$root/tools/economy/batch1-server.test.mjs' && node '$root/tools/economy/batch1-rules.test.mjs'"
