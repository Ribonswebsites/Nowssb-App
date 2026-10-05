#!/usr/bin/env bash
# Run tools/firebase/rules.test.mjs against the repo's firestore.rules in the
# local Firestore emulator.
#
# Requirements: Node 20+, Java 21+ (Firestore emulator, firebase-tools 14).
# Dependencies (@firebase/rules-unit-testing, firebase, firebase-tools) live in
# tools/firebase/package.json so the root web/Capacitor install stays lean.
# The emulator jar is downloaded to ~/.cache/firebase/emulators on first run.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"
if [[ ! -d node_modules/@firebase/rules-unit-testing ]]; then
  if [[ -f package-lock.json ]]; then npm ci --no-audit --no-fund; else npm install --no-audit --no-fund; fi
fi
npm test
