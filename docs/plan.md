# XPlain — Build Plan

Build strategy: **ship a thin vertical slice first** (menu-bar app that magnifies
the screen on a hotkey), then layer one mode at a time. Each phase is shippable and
verifiable on its own. Do not start a phase until the previous one's gates pass.

The validation gates live in `AGENTS.md`. Milestones below reference `docs/spec.md`
for behavior and `docs/testing.md` for how to verify.

**Each phase = one milestone (`M0`…`M6`).** This doc is the *strategy* (what/why/order);
the *granular, agent-ready tasks* live in [`backlog.md`](backlog.md) as `M0.1`, `M0.2`, …
When vibe-coding, don't ask an agent to "do Phase 0" — hand it a single task like
"do **M0.3**". Each phase header below links to its task list.

---

## Phase 0 — Project init & toolchain  ·  **M0** ([tasks](backlog.md#m0))

- **Scope:** create the Xcode project for a macOS 14+ menu-bar agent app named
  `XPlain` (`LSUIElement = YES`). Add the Swift Package dependency
  `KeyboardShortcuts`. Wire up **SwiftLint**, **swift-format**, and an **XCTest**
  target. Add `.github/workflows/ci.yml` running the gates on a `macos-14` runner.
- **Done when:** `swiftlint --strict`, `swift-format lint`, and
  `xcodebuild ... build test` all run locally (even with zero real tests), and CI
  runs them on push. The app launches, shows a menu-bar icon, and quits cleanly.

## Phase 1 — Hotkeys + overlay skeleton  ·  **M1** ([tasks](backlog.md#m1))

- **Scope:** register the five global shortcuts via `HotkeyService`. Stand up
  `ModeController` and an `OverlayWindow` that covers the display under the cursor
  with the correct level and `collectionBehavior`. Pressing a hotkey shows a plain
  full-screen overlay; **Esc**/right-click dismisses it. No capture yet.
- **Done when:** each hotkey opens/closes an overlay on the correct display,
  including over full-screen apps and on secondary monitors; only one overlay exists
  at a time.

## Phase 2 — Screen Recording permission + still capture  ·  **M2** ([tasks](backlog.md#m2))

- **Scope:** implement `CaptureService.snapshot(of:)` via `SCScreenshotManager`.
  Preflight Screen Recording permission; on denial, show the **PermissionPrompt**
  sub-state with a deep link to System Settings. Centralize the coordinate Y-flip.
- **Done when:** with permission granted, an overlay shows a pixel-accurate frozen
  snapshot of the target display; with permission denied, the user sees a clear
  prompt instead of a blank screen.

## Phase 3 — Zoom mode (the core slice)  ·  **M3** ([tasks](backlog.md#m3))

- **Scope:** `ZoomRenderer` — present the snapshot at the initial scale centered on
  the cursor; pan on mouse move; zoom on scroll/↑↓ within the configured range;
  animated zoom-in. Implements §3 of the spec.
- **Done when:** `⌘⌃Z` magnifies within ~150 ms, panning tracks the cursor 1:1,
  zoom in/out is smooth, and exit restores the desktop untouched.

## Phase 4 — Draw / Annotate mode  ·  **M4** ([tasks](backlog.md#m4))

- **Scope:** `AnnotationCanvas` + the `Drawable` model + undo/redo. Freehand,
  shapes (Shift/⌘/⌥/Shift+⌘), color keys, highlighter, pen width, text tool,
  whiteboard/blackboard, `⌘C` copy, `⌘S` save. Works both on top of Zoom and
  standalone. Implements §4 of the spec. Route input through `InputRouter`.
- **Done when:** every documented key/modifier produces its result; strokes render
  without perceptible lag; undo/redo is exact; save/copy produce correct PNGs.

## Phase 5 — LiveZoom + Record  ·  **M5** ([tasks](backlog.md#m5))

- **Scope:** `CaptureService.stream(of:)` async `SCStream` feed. `MTKView`-backed
  live magnification with a click-through overlay (LiveZoom, §5). `Recorder` writing
  H.264 `.mp4` via `AVAssetWriter`, full-screen or region, optional audio, overlay
  composited in (Record, §6).
- **Done when:** LiveZoom keeps the screen interactive at ≥ 30 fps under
  magnification; Record produces a playable `.mp4` at native resolution saved to the
  configured folder.

## Phase 6 — Settings, polish & distribution  ·  **M6** ([tasks](backlog.md#m6))

- **Scope:** SwiftUI Settings window (hotkey recorders with conflict warnings, zoom,
  pen, recording, general, live permission status — §7). Launch-at-login. App icon +
  menu-bar icon. Developer ID signing, hardened runtime, notarization, and a `.dmg`
  build script + GitHub Release. See `docs/security.md`.
- **Done when:** all settings persist and take effect; a notarized `.dmg` installs
  and runs on a clean Mac with no Gatekeeper warning; first-run permission flow is
  smooth.

---

## Out of scope (for now)

- **Break Timer**, **Demo Type**, **LiveDraw on the live screen**, snap-to-grid,
  and preset shape libraries — tracked in `docs/backlog.md`.
- Windows/Linux ports; cloud sync; accounts; any telemetry.

## Dependencies & sequencing notes

- Phase 2 (permission + capture) gates everything visual — nothing renders real
  pixels until it lands.
- The Metal path in Phase 5 is the biggest technical risk; prototype LiveZoom
  latency early and keep a Core Image fallback in mind (see `docs/core.md` risks).
- Notarization (Phase 6) needs a paid Apple Developer account and a Developer ID
  certificate; set that up before the phase, not during it.
