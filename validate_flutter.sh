#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/flutter_app"
export PATH="/home/ubuntu/flutter/bin:/home/ubuntu/flutter/bin/cache/dart-sdk/bin:$PATH"

run_step() {
  local name="$1"; shift
  local attempt=1
  while [ "$attempt" -le 3 ]; do
    echo "==> $name (attempt $attempt/3)"
    if "$@"; then
      echo "PASS: $name"
      return 0
    fi
    echo "RETRY: $name failed"
    attempt=$((attempt + 1))
    sleep 3
  done
  echo "FAIL: $name after 3 attempts"
  return 1
}

cd "$ROOT"
run_step "Install web dependencies" npm ci || exit 1
run_step "Bundle Flutter assets" node tools/flutter-assets.mjs || exit 1
cd "$APP"
if [ ! -d android ] || [ ! -d ios ]; then
  run_step "Create Flutter platform projects" flutter create --platforms=ios,android --org com.nowssb --project-name nowssb . || exit 1
fi
cd "$ROOT"
run_step "Configure Android" node tools/flutter-android.mjs || exit 1
run_step "Configure iOS" node tools/flutter-ios.mjs || exit 1
cd "$APP"
run_step "Resolve Flutter dependencies" flutter pub get || exit 1
run_step "Analyze Flutter sources" flutter analyze --no-fatal-infos || exit 1
run_step "Run Flutter tests" flutter test || exit 1
printf '%s\n' 'ALL VALIDATION CHECKS PASSED'
