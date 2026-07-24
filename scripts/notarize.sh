#!/usr/bin/env bash
# Notarizes and staples XPlain.dmg (M6.8) — REQUIRES a paid Apple Developer
# Program membership (Developer ID Application cert + notarytool credentials).
#
# The project is currently signed with a free Personal Team, which CANNOT be
# notarized, so this script is a ready-to-run template for if/when a Developer
# ID is available. It intentionally does nothing until the env vars are set.
#
# Prerequisites (paid membership):
#   1. A "Developer ID Application: <name> (<TEAMID>)" cert in the login keychain.
#   2. notarytool credentials — either an App Store Connect API key, or an
#      app-specific password stored as a keychain profile:
#        xcrun notarytool store-credentials XPLAIN_NOTARY \
#          --apple-id "you@example.com" --team-id "TEAMID" --password "app-specific-pw"
#
# Usage:
#   DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)" \
#   NOTARY_PROFILE=XPLAIN_NOTARY \
#   scripts/notarize.sh
set -euo pipefail
cd "$(dirname "$0")/.."

: "${DEVELOPER_ID:?Set DEVELOPER_ID to your 'Developer ID Application: … (TEAMID)' identity}"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE to your notarytool keychain profile name}"

APP_PATH="${APP_PATH:-build/DerivedData/Build/Products/Release/XPlain.app}"
DMG_PATH="${DMG_PATH:-build/XPlain.dmg}"

echo "▶ Re-signing $APP_PATH with Developer ID (hardened runtime + entitlements)…"
codesign --force --deep --options runtime \
  --entitlements XPlain/XPlain.entitlements \
  --sign "$DEVELOPER_ID" "$APP_PATH"
codesign --verify --strict --deep --verbose=2 "$APP_PATH"

echo "▶ Rebuilding the .dmg around the signed app…"
CONFIG=Release scripts/build-dmg.sh

echo "▶ Submitting to Apple notary service (waits for the result)…"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo "▶ Stapling the ticket…"
xcrun stapler staple "$DMG_PATH"

echo "▶ Gatekeeper assessment (expect: accepted)…"
spctl -a -vv --type open --context context:primary-signature "$DMG_PATH" || true

echo "✓ Notarized + stapled $DMG_PATH"
