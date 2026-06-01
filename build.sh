#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP="ClipStash.app"
BIN="ClipStash"

# Generate the app icon from source if it isn't present yet.
if [ ! -f AppIcon.icns ]; then
  echo "==> Generating app icon…"
  swiftc -O -o make_icon make_icon.swift
  rm -rf AppIcon.iconset
  ./make_icon AppIcon.iconset >/dev/null
  iconutil -c icns AppIcon.iconset -o AppIcon.icns
fi

echo "==> Compiling ($(uname -m))…"
rm -rf "$APP"
swiftc -O -o "$BIN" main.swift

echo "==> Assembling app bundle…"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
mv "$BIN" "$APP/Contents/MacOS/$BIN"
cp Info.plist "$APP/Contents/Info.plist"
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

echo "==> Ad-hoc code signing (required to run on Apple Silicon)…"
codesign --force --sign - "$APP"

echo "==> Built: $(pwd)/$APP"

# Pass --install to also copy into /Applications and relaunch.
if [ "${1:-}" = "--install" ]; then
  DEST="/Applications/$APP"
  echo "==> Installing to ${DEST} ..."
  osascript -e 'quit app "ClipStash"' 2>/dev/null || true
  pkill -f "$BIN" 2>/dev/null || true
  sleep 1
  rm -rf "$DEST"
  cp -R "$APP" "$DEST"
  codesign --force --sign - "$DEST"
  open "$DEST"
  echo "==> Installed and launched."
fi
