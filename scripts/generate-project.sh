#!/bin/bash
# Regenerates XPlain.xcodeproj from project.yml via xcodegen, then patches the
# emitted objectVersion down to 60.
#
# xcodegen's bundled XcodeProj library always writes objectVersion = 77 (the
# newest format, tied to Xcode 16's project-file features) regardless of which
# Xcode is locally selected, and has no project.yml option to override it
# (https://github.com/yonaskolb/XcodeGen/issues/1578, #1109). Since CI pins
# Xcode 15.4 (see .github/workflows/ci.yml), a 77-format project fails to open
# there with "project is in a future Xcode project file format". objectVersion
# 60 is confirmed compatible back through Xcode 15.0.1 in that same issue, and
# we don't use any project-format feature (e.g. synced file-system groups)
# that would need a newer version.
set -euo pipefail
cd "$(dirname "$0")/.."

xcodegen generate

sed -i '' 's/objectVersion = 77;/objectVersion = 60;/' XPlain.xcodeproj/project.pbxproj
