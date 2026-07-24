#!/usr/bin/env bash
# Builds a distributable .dmg of XPlain (M6.8).
#
# Produces build/XPlain.dmg containing XPlain.app plus an /Applications symlink
# (drag-to-install). By default it packages a Release build signed with whatever
# identity the project resolves (the free Personal Team locally). For a real
# distributable build, sign + notarize with a Developer ID first (see
# scripts/notarize.sh) — an un-notarized .dmg opens on the build machine but
# warns on Gatekeeper elsewhere (right-click ▸ Open to bypass).
set -euo pipefail

cd "$(dirname "$0")/.."

SCHEME="XPlain"
CONFIG="${CONFIG:-Release}"
OUT_DIR="build"
STAGE_DIR="$OUT_DIR/dmg-stage"
DMG_PATH="$OUT_DIR/XPlain.dmg"
VOL_NAME="XPlain"

echo "▶ Building $SCHEME ($CONFIG)…"
xcodebuild -scheme "$SCHEME" -configuration "$CONFIG" \
  -destination 'platform=macOS' -derivedDataPath "$OUT_DIR/DerivedData" \
  build >/dev/null

APP_PATH="$OUT_DIR/DerivedData/Build/Products/$CONFIG/$SCHEME.app"
[ -d "$APP_PATH" ] || { echo "✗ App not found at $APP_PATH"; exit 1; }

echo "▶ Staging ${APP_PATH}…"
rm -rf "$STAGE_DIR" "$DMG_PATH"
mkdir -p "$STAGE_DIR"
cp -R "$APP_PATH" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

echo "▶ Creating ${DMG_PATH}…"
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGE_DIR" \
  -ov -format UDZO "$DMG_PATH" >/dev/null
rm -rf "$STAGE_DIR"

echo "✓ Built $DMG_PATH"
codesign --verify --deep --strict "$APP_PATH" 2>/dev/null \
  && echo "✓ App passes codesign --verify" \
  || echo "⚠ App failed codesign --verify"
echo "  (Un-notarized — run scripts/notarize.sh with a Developer ID to distribute.)"
