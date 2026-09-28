#!/usr/bin/env bash
# Make one Firebase account a NowssB admin (Firestore admins/{uid}; add
# --claim to also set the custom claim). Free Spark plan is fine.
#   FIREBASE_SERVICE_ACCOUNT='…json…' tools/firebase/mark-admin.sh <uid> [--claim]
#   (or GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json)
# Find the uid first with:  node tools/firebase/admin-tool.mjs list-users
set -euo pipefail
cd "$(dirname "$0")/../.."
exec node tools/firebase/admin-tool.mjs mark-admin "$@"
