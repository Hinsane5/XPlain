#!/bin/bash
# verify-gates.sh — XPlain's validation gates, run automatically on every code change.
#
# Wired as a Claude Code Stop hook (.claude/settings.json): after any turn that
# changed source code, this runs SwiftLint + swift-format + `xcodebuild build test`.
# If a gate fails it exits 2, which tells Claude Code to keep working and fix it
# before finishing. Turns that only touch docs are skipped so the heavy build
# doesn't run for nothing.
#
# Run it by hand any time (forces a full run regardless of what changed):
#     scripts/verify-gates.sh --all
set -uo pipefail
cd "$(dirname "$0")/.."

FORCE=0
case "${1:-}" in --all|--force) FORCE=1 ;; esac

# Loop guard: if Claude is already continuing *because of* this Stop hook, don't
# block again (prevents an infinite stop→fix→stop loop). Hooks get JSON on stdin.
if [ "$FORCE" -eq 0 ] && [ ! -t 0 ]; then
  stdin_json="$(cat 2>/dev/null || true)"
  case "$stdin_json" in
    *'"stop_hook_active"'*true*) exit 0 ;;
  esac
fi

# Toolchain guard: if the gates can't run here, warn but never block development.
for tool in swiftlint swift-format xcodebuild; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "⚠ verify-gates: '$tool' not found on PATH; skipping gates." >&2
    exit 0
  }
done

# Only run when SOURCE (not just docs) changed vs HEAD — staged, unstaged, untracked.
code_regex='\.swift$|\.xcodeproj|project\.yml$|Info\.plist$|\.swiftlint\.yml$|\.swift-format$|Package\.resolved$'
if [ "$FORCE" -eq 0 ]; then
  changed="$({ git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } | sort -u)"
  echo "$changed" | grep -qE "$code_regex" || exit 0
fi

fail() {
  echo "❌ verify-gates: $1 FAILED — fix it before finishing (see docs/testing.md)." >&2
  exit 2
}

echo "▶ verify-gates: source changed — running SwiftLint + swift-format + build test…" >&2

swiftlint --strict >/dev/null 2>&1 || fail "swiftlint --strict"
swift-format lint --strict --recursive Sources Tests >/dev/null 2>&1 || fail "swift-format lint"

if ! xcodebuild -scheme XPlain -destination 'platform=macOS' build test -quiet >/tmp/xplain-verify.log 2>&1; then
  tail -25 /tmp/xplain-verify.log >&2
  fail "xcodebuild build test"
fi

echo "✅ verify-gates: all gates green." >&2
exit 0
