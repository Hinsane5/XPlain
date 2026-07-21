# XPlain

XPlain is a native macOS menu-bar tool that lets you **zoom into your screen, draw
on it, and record it** with global hotkeys — a ZoomIt for the Mac, built for
presenters, teachers, and streamers.

> This file is the always-loaded index for AI coding agents. Keep it short. The
> detail lives in `docs/` — read the relevant doc before working in that area.

## Tech stack

- Language: **Swift 5.9+**, targeting **macOS 14 (Sonoma) or newer**.
- UI: **AppKit** menu-bar agent (`LSUIElement`), borderless overlay `NSWindow`s.
- Screen capture: **ScreenCaptureKit** (`SCScreenshotManager`, `SCStream`).
- Global hotkeys: **[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)** (SwiftPM).
- Rendering: **Core Animation / Core Graphics** for static zoom + draw; **Metal (`MTKView`)** for LiveZoom / high-FPS paths.
- Recording: **AVFoundation** (`AVAssetWriter`) fed by `SCStream` sample buffers.
- Build: **Xcode 15+** project; dependencies via Swift Package Manager.
- Distribution: **Developer ID-signed + notarized** `.dmg` (not sandboxed, not Mac App Store).

## Setup

```
# Requires Xcode 15+ and macOS 14+.
open XPlain.xcodeproj          # then Product ▸ Run
xcodebuild -resolvePackageDependencies -scheme XPlain
```

`XPlain.xcodeproj` is generated from `project.yml` via
[XcodeGen](https://github.com/yonaskolb/XcodeGen) — there's no other CLI path to
create/edit an Xcode project outside the Xcode GUI. **After changing
`project.yml`, run `./scripts/generate-project.sh`** (not `xcodegen generate`
directly) — it also patches the emitted `objectVersion` down to one CI's pinned
Xcode 15.4 can read; see the script's comment for why.

First run requires granting **Screen Recording** permission in
System Settings ▸ Privacy & Security, then relaunching the app. See `docs/security.md`.

## Common commands

```
build      xcodebuild -scheme XPlain -destination 'platform=macOS' build
test       xcodebuild -scheme XPlain -destination 'platform=macOS' test
lint       swiftlint --strict
format     swift-format lint --recursive Sources
```

## Validation gates (run before declaring a task done)

Run these and ensure they pass before considering any change complete. If a gate
fails, fix it and re-run — do not report completion with failing gates.

```
swiftlint --strict
swift-format lint --recursive Sources
xcodebuild -scheme XPlain -destination 'platform=macOS' build test
```

Until the toolchain is initialized (see `docs/plan.md` Phase 0), these do not run
yet. Standing them up is the first milestone.

## Project docs

Read the relevant doc before working in that area:

- `docs/spec.md` — **functional spec**: every mode, hotkey, and on-screen behavior.
- `docs/core.md` — **architecture**: components, state machine, data flow, key decisions.
- `docs/plan.md` — **phased build plan** (strategy): what to build, in what order, done-when.
- `docs/backlog.md` — **granular task tracker**: numbered tasks `M0.1`, `M1.1`, … Hand an
  agent one task ID at a time; each has a concrete "Done when". Start here to build.
- `docs/testing.md` — test strategy and the definition of "done".
- `docs/success-criteria.md` — acceptance criteria and what "great" looks like.
- `docs/security.md` — TCC permissions, privacy posture, signing & notarization.

## Workflow

Follow **Explore → Plan → Code → Verify**. For any non-trivial change, write a
short spec into `specs/` first, build against `docs/plan.md`, then run the
validation gates above before declaring done.

## Gotchas

- **Screen Recording permission (TCC) is mandatory** for any capture. macOS caches
  the grant per app binary; after re-signing or moving the `.app`, the grant may
  reset and the app must be relaunched.
- **Coordinate systems differ**: AppKit is bottom-left origin; ScreenCaptureKit /
  `CGImage` are top-left. Flip Y when mapping the cursor onto the captured image.
- **Overlay windows** must set `level` above the menu bar and a `collectionBehavior`
  of `.canJoinAllSpaces | .fullScreenAuxiliary | .stationary` to appear over
  full-screen apps and on every Space.
- **Default hotkeys avoid `⌃1`–`⌃4`** (they collide with Mission Control Spaces).
  Defaults are `⌘⌃`-based and user-configurable.
- The app is a **menu-bar agent** (`LSUIElement = YES`, no Dock icon).
