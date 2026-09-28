#!/usr/bin/env bash
# Deploy ONLY firestore.rules to nowssb-34f1b. No functions, no storage —
# the project stays on the free Spark plan.
#   GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json tools/firebase/deploy-rules.sh
# FIREBASE_SERVICE_ACCOUNT (the JSON itself) also works: it is written to a
# private temp file for the duration of the deploy and removed afterwards.
# Test first:  tools/firebase/test-rules.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
cleanup=""
if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" && -n "${FIREBASE_SERVICE_ACCOUNT:-}" ]]; then
  umask 077
  tmp="$(mktemp)"
  printf '%s' "$FIREBASE_SERVICE_ACCOUNT" > "$tmp"
  export GOOGLE_APPLICATION_CREDENTIALS="$tmp"
  cleanup="$tmp"
fi
trap '[[ -n "$cleanup" ]] && rm -f "$cleanup"' EXIT
: "${GOOGLE_APPLICATION_CREDENTIALS:?Set GOOGLE_APPLICATION_CREDENTIALS or FIREBASE_SERVICE_ACCOUNT}"
npx --yes firebase-tools@14 deploy --only firestore:rules --project nowssb-34f1b --non-interactive
