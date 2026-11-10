#!/bin/bash
set -euo pipefail

DMG="$1"
WORK_DIR="$(mktemp -d "$RUNNER_TEMP/verify-macos-dmg.XXXXXX")"
MOUNT_POINT="$WORK_DIR/mount"
APP_PID=""
MOUNTED=false

cleanup() {
  if [ -n "$APP_PID" ]; then
    kill "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
  if [ "$MOUNTED" = true ]; then
    hdiutil detach "$MOUNT_POINT"
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir "$MOUNT_POINT"
hdiutil verify "$DMG"
hdiutil attach "$DMG" -readonly -nobrowse -mountpoint "$MOUNT_POINT"
MOUNTED=true

test "$(readlink "$MOUNT_POINT/Applications")" = /Applications
ditto "$MOUNT_POINT/MCCompanion.app" "$WORK_DIR/MCCompanion.app"
APP="$WORK_DIR/MCCompanion.app"
codesign --verify --deep --strict --verbose=2 "$APP"

if [ "$DISTRIBUTION_BUILD" = true ]; then
  xcrun stapler validate "$DMG"
  xcrun stapler validate "$APP"
  spctl --assess --type execute --verbose=2 "$APP"
fi

"$APP/Contents/MacOS/MCCompanion" > "$WORK_DIR/app.log" 2>&1 &
APP_PID=$!
sleep 10
if ! kill -0 "$APP_PID" 2>/dev/null; then
  echo "::error::The app from the DMG exited during startup."
  cat "$WORK_DIR/app.log"
  wait "$APP_PID" || true
  APP_PID=""
  exit 1
fi
