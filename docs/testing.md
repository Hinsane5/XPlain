# XPlain — Test Plan

XPlain is a real-time, graphics-heavy macOS app whose most important behaviors
(magnification smoothness, overlay placement, permission flows) are inherently
manual to judge. So the strategy is: **unit-test the pure logic hard, integration-
test the seams where practical, and keep a disciplined manual checklist for the
visual/real-time behavior** that can't be meaningfully automated.

## What to test, by layer

### Unit (XCTest) — the bulk of automated coverage
Pure, deterministic logic with no window/GPU/permission dependency:
- **Zoom math** — scale clamping to the configured range, step application,
  cursor-centered pan transforms, coordinate Y-flip (AppKit ↔ CGImage).
- **Annotation model** — building each `Drawable`, the undo/redo stacks (push,
  undo, redo, clear), hit-testing if added.
- **Input mapping** — `InputRouter` turning a given key/modifier/scroll event into
  the correct action (color select, shape mode, pen-width delta, zoom step) per
  `docs/spec.md` §4.
- **Settings** — `SettingsStore` encode/decode round-trips and defaults.
- **Display targeting** — choosing the correct `NSScreen` from a cursor location.

### Integration — the seams
- **CaptureService** — with permission granted in the test environment, assert a
  snapshot returns a non-empty image of the expected pixel dimensions; assert the
  permission-denied path routes to the PermissionPrompt state (inject a stubbed
  permission checker so this runs without real TCC state).
- **ModeController transitions** — drive the state machine through
  Idle→Zoom→Draw→Idle and assert exactly one overlay exists and that Idle fully
  releases capture + windows (no leaked streams).
- **Recorder** — feed synthetic sample buffers and assert a valid, playable `.mp4`
  is produced with the expected duration/resolution.

### Manual checklist — real-time & visual behavior
Kept in `specs/` per release; each item is a spec §N behavior verified by eye:
- Zoom activates < ~150 ms, no tearing, pan tracks 1:1, exit restores desktop.
- Overlays appear over **full-screen apps** and on **secondary monitors**.
- LiveZoom stays interactive (clicks/typing pass through) at ≥ 30 fps.
- Every Draw key/modifier from §4 produces the documented result.
- Record output plays back correctly with annotations composited in.
- Denied Screen Recording permission shows the prompt, not a blank screen; granting
  + relaunch then works.

## Tooling

- Test runner: **XCTest**, via `xcodebuild -scheme XPlain test`.
- Lint: **SwiftLint** (`--strict`).
- Format: **swift-format lint**.
- No UI-automation framework in the MVP — the real-time paths are covered by the
  manual checklist rather than brittle `XCUITest` snapshots.

## Definition of done

A change is done when:
- The **validation gates in `AGENTS.md` pass**: `swiftlint --strict`,
  `swift-format lint`, and `xcodebuild ... build test`.
- **New logic has a unit test that fails without the change** (Zoom math, model,
  input mapping, settings — anything in the "Unit" layer above).
- If the change touches a **real-time or visual** behavior, the relevant manual
  checklist item is re-verified and noted in the PR.

## Coverage priorities

Test where a bug would hurt most or is hardest to catch by eye:
1. **Coordinate transforms** (Y-flip, multi-display) — off-by-a-flip bugs are
   subtle and pervasive.
2. **State-machine teardown** — leaked capture streams or overlays degrade the
   whole app silently.
3. **Input mapping** — a large surface of key/modifier combinations that's easy to
   regress.

## Gotchas

- CI runners have **no Screen Recording permission and no GPU display** — gate the
  capture/GPU integration tests behind an availability check or a stubbed
  `CaptureService`, and let them **skip** (not fail) in headless CI. The manual
  checklist covers what CI cannot.
- Real-time timing assertions are flaky in CI; assert **correctness** (image size,
  transform values, file validity), not wall-clock frame rate.
