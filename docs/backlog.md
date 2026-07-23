# XPlain — Backlog (Task Tracker)

The granular, numbered task list for building XPlain. Each task is small and
specific enough to hand to a coding agent **as-is** — say *"do M0.3"* and the agent
gets one bounded job with a clear finish line, instead of a vague "do Phase 0".

## How to use this

- **IDs:** `M<milestone>.<task>` — e.g. `M0.3`. Milestones (`M0`, `M1`, …) map 1:1 to
  the phases in [`plan.md`](plan.md). Tasks run **in order within a milestone**; check
  `Depends on` before starting.
- **Workflow per task (TDD):** read the linked spec/architecture section → write a
  one-screen spec in `specs/` (e.g. `m0.3-swiftlint.md`) → **write the failing test
  first** (its test is in [`testing.md`](testing.md)'s coverage matrix) → make it pass
  → refactor → the gates run automatically ([`AGENTS.md`](../AGENTS.md)) → tick the box.
  Every task maps to a test or a manual-checklist item; don't tick a box without it.
- **Status:** `[ ]` todo · `[~]` in progress · `[x]` done. Update the box in the same
  commit that finishes the task.
- **A task is done only when its `Done when` is objectively true** — a passing test, a
  visible behavior, a file that exists. No "looks about right".

References: behavior → [`spec.md`](spec.md) · components/APIs → [`core.md`](core.md) ·
acceptance → [`success-criteria.md`](success-criteria.md).

---

<a id="m0"></a>
## M0 — Project init & toolchain  ·  *(Phase 0)*

Goal: an empty-but-real menu-bar app whose validation gates actually run.

- [x] **M0.1 — Create the Xcode project**
  - **Do:** New macOS App target named `XPlain`, interface **AppKit** (or SwiftUI
    lifecycle + AppKit menu-bar), language Swift, **Deployment Target macOS 14.0**.
  - **Files:** `XPlain.xcodeproj`, `Sources/…`, `XPlain/Info.plist`.
  - **Done when:** the project opens in Xcode and `xcodebuild -scheme XPlain build`
    succeeds.
  - **Depends on:** —

- [x] **M0.2 — Make it a menu-bar agent (no Dock icon)**
  - **Do:** Set `LSUIElement = YES` in `Info.plist`; add an `NSStatusItem` with a
    placeholder menu (`Quit`).
  - **Done when:** launching shows a menu-bar icon, **no** Dock icon, and Quit exits.
  - **Depends on:** M0.1

- [x] **M0.3 — Wire SwiftLint**
  - **Do:** Add a `.swiftlint.yml` and make `swiftlint --strict` runnable locally
    (Homebrew install documented in README).
  - **Done when:** `swiftlint --strict` runs and passes on the current source.
  - **Depends on:** M0.1

- [x] **M0.4 — Wire swift-format**
  - **Do:** Add a `.swift-format` config; make `swift-format lint --recursive Sources`
    runnable.
  - **Done when:** `swift-format lint --recursive Sources` passes.
  - **Depends on:** M0.1

- [x] **M0.5 — Add the XCTest target + a smoke test**
  - **Do:** Create a unit-test target `XPlainTests` with one trivial passing test.
  - **Done when:** `xcodebuild -scheme XPlain test` runs the test and it passes.
  - **Depends on:** M0.1

- [x] **M0.6 — Add the KeyboardShortcuts dependency**
  - **Do:** Add SwiftPM package `https://github.com/sindresorhus/KeyboardShortcuts`
    and `import KeyboardShortcuts` somewhere that compiles.
  - **Done when:** the package resolves and the app still builds.
  - **Depends on:** M0.1

- [x] **M0.7 — Commit the CI workflow**
  - **Do:** Move `.github/workflows/ci.yml` into the commit (it already runs the three
    gates on `macos-14`); confirm the `Xcode_15.x` path and scheme name match.
  - **Done when:** CI runs on push and all three gates pass green.
  - **Depends on:** M0.3, M0.4, M0.5

**M0 exit:** `swiftlint --strict`, `swift-format lint`, and `xcodebuild build test`
all pass locally **and** green in CI.

---

<a id="m1"></a>
## M1 — Hotkeys + overlay skeleton  ·  *(Phase 1)*

Goal: pressing a hotkey opens/closes a blank full-screen overlay on the right display.
No capture yet.

- [x] **M1.1 — `HotkeyService` with default shortcuts**
  - **Do:** Define `KeyboardShortcuts.Name`s for Zoom/Draw/LiveZoom/Record with
    defaults `⌘⌃Z / ⌘⌃D / ⌘⌃L / ⌘⌃R`; emit a mode-request on each.
  - **Done when:** each shortcut logs its distinct mode-request; no `⌃1`–`⌃4` used.
  - **Depends on:** M0.6

- [x] **M1.2 — `ModeController` state machine**
  - **Do:** `enum Mode { idle, zoom, draw, liveZoom, record }`; transitions enforce
    **exactly one** active mode. (See core.md "State machine".)
  - **Done when:** unit test drives Idle→Zoom→Draw→Idle and asserts the single-active
    invariant.
  - **Depends on:** M1.1

- [x] **M1.3 — `OverlayWindow` on the display under the cursor**
  - **Do:** Borderless `NSWindow` sized to the `NSScreen` containing
    `NSEvent.mouseLocation`; opaque test color.
  - **Done when:** a hotkey shows a full-screen colored overlay on the correct display.
  - **Depends on:** M1.2

- [x] **M1.4 — Correct window level + Spaces behavior**
  - **Do:** `level` above `.mainMenu`; `collectionBehavior = [.canJoinAllSpaces,
    .fullScreenAuxiliary, .stationary]`.
  - **Done when:** the overlay appears over full-screen apps and on every Space.
  - **Depends on:** M1.3

- [x] **M1.5 — Esc / right-click exits to Idle**
  - **Do:** Overlay becomes key window; Esc and right-click both route to
    `ModeController` → Idle and tear the window down.
  - **Done when:** both inputs reliably dismiss the overlay; no window leak.
  - **Depends on:** M1.3

- [x] **M1.6 — Multi-display targeting test**
  - **Do:** Extract display-selection into a pure function.
  - **Done when:** unit test maps sample cursor points to the expected `NSScreen`.
  - **Depends on:** M1.3

---

<a id="m2"></a>
## M2 — Screen-recording permission + still capture  ·  *(Phase 2)*

Goal: overlays show a pixel-accurate frozen snapshot; missing permission is handled.

- [x] **M2.1 — `CaptureService.snapshot(of:)`**
  - **Do:** Wrap `SCScreenshotManager` to return a `CGImage` of a given display.
  - **Done when:** returns a non-empty image at the display's pixel dimensions.
  - **Depends on:** M1.3

- [x] **M2.2 — Permission preflight + `PermissionPrompt` state**
  - **Do:** `CGPreflightScreenCaptureAccess()` / `CGRequestScreenCaptureAccess()`; on
    denial, show a prompt overlay that deep-links to System Settings (see security.md).
  - **Done when:** granted → snapshot works; denied → prompt shown, never a blank screen.
  - **Depends on:** M2.1

- [x] **M2.3 — Centralize the coordinate Y-flip**
  - **Do:** Convert AppKit (bottom-left) ↔ CGImage (top-left) **once**, in
    `CaptureService`. (See core.md "Coordinate discipline".)
  - **Done when:** unit test verifies flip for a few points/rects on multiple displays.
  - **Depends on:** M2.1

- [x] **M2.4 — Render the snapshot into the overlay**  *(verified live 2026-07-23 once stable code signing made the Screen Recording grant persist — see `specs/m2-manual-checklist.md`)*
  - **Do:** Replace M1.3's test color with the captured `CGImage` at 1×.
  - **Done when:** the overlay is visually indistinguishable from the frozen desktop.
  - **Depends on:** M2.1, M1.4

---

<a id="m3"></a>
## M3 — Zoom mode  ·  *(Phase 3)*  ·  spec §3

Goal: the core feature — freeze, magnify, pan.

- [x] **M3.1 — `ZoomRenderer`: initial magnified present** — scale (default 2×) centered
  on the cursor. **Done when:** activation shows the snapshot magnified around the
  cursor. **Depends on:** M2.4
- [x] **M3.2 — Pan on mouse move** — 1:1 cursor tracking. **Done when:** panning matches
  cursor movement exactly. **Depends on:** M3.1
- [x] **M3.3 — Zoom in/out** — scroll wheel + ↑/↓, clamped to **1.25×–8×**, configurable
  step. **Done when:** level changes within range and never exceeds bounds (unit-tested).
  **Depends on:** M3.1
- [x] **M3.4 — Animated zoom-in** — smooth transition, not a hard jump. **Done when:**
  entry animates and can be disabled by a flag. **Depends on:** M3.1
- [x] **M3.5 — Copy / Save** — `⌘C` copies visible region to clipboard; `⌘S` writes PNG to
  `~/Pictures/XPlain`. **Done when:** both produce correct output for the visible region.
  **Depends on:** M3.1
- [x] **M3.6 — Zoom-math unit tests** — clamping, step, pan transform, cursor-centering.
  **Done when:** tests cover the range/step/transform edge cases. **Depends on:** M3.3

---

<a id="m4"></a>
## M4 — Draw / Annotate mode  ·  *(Phase 4)*  ·  spec §4

Goal: full annotation toolset, over a zoom or standalone.

- [x] **M4.1 — `Drawable` model + `Pen`** — value types per core.md "Data model".
  **Done when:** each case constructs and round-trips in a test. **Depends on:** M2.4
- [x] **M4.2 — Freehand drawing** — left-drag paints with the current pen. **Done when:**
  a dragged stroke renders live. **Depends on:** M4.1
- [x] **M4.3 — Shape modifiers** — Shift = line, ⌘ = rect, ⌥ = ellipse, Shift+⌘ = arrow
  (drawn as a rubber-band preview, committed on mouse-up). **Done when:** each modifier
  yields the correct shape. **Depends on:** M4.2
- [x] **M4.4 — Colors, highlighter, width** — keys `r/g/b/o/y/p`, `h` highlighter toggle,
  `⌥+scroll` / `[` `]` width. **Done when:** every key changes the pen as specified.
  **Depends on:** M4.2
- [x] **M4.5 — Text tool** — `t` → click → type → Enter/Esc commits; `⌥+scroll` resizes
  pre-commit. **Done when:** text places, edits, and commits correctly. **Depends on:** M4.2
- [x] **M4.6 — Whiteboard / blackboard** — `w` / `k` swap the backdrop; press again to
  restore. **Done when:** backdrop toggles without losing annotations. **Depends on:** M4.2
- [x] **M4.7 — Undo / redo** — `⌘Z` / `⌘⇧Z`; `e` or Delete clears all. **Done when:**
  undo/redo is exact across every `Drawable` type (unit-tested). **Depends on:** M4.1
- [x] **M4.8 — Copy / Save annotated output** — `⌘C` / `⌘S` composite backdrop + strokes.
  **Done when:** output PNG/clipboard includes annotations. **Depends on:** M4.2, M3.5
- [x] **M4.9 — Standalone draw + draw-over-zoom** — `⌘⌃D` from Idle freezes the live
  screen; from Zoom it draws on the magnified image. **Done when:** both entry paths work
  and exit cleanly. **Depends on:** M4.2, M3.1
- [x] **M4.10 — Model + input-mapping unit tests** — `InputRouter` key/modifier → action
  coverage. **Done when:** the mapping table from spec §4 is fully asserted. **Depends
  on:** M4.3, M4.4

---

<a id="m5"></a>
## M5 — LiveZoom + Record  ·  *(Phase 5)*  ·  spec §5–§6

Goal: live magnification and screen recording. Highest technical risk — see core.md risks.

- [x] **M5.1 — `CaptureService.stream(of:)`** — async `SCStream` frame feed. **Done when:**
  a live frame sequence is delivered for a display. **Depends on:** M2.1
  *(verified live via M5.2 — the magnified view updates continuously)*
- [x] **M5.2 — live magnification** — render the stream magnified. **Done when:**
  live screen shows magnified and updates continuously. **Depends on:** M5.1
  *(layer-backed `LiveZoomView`, not `MTKView` — updates continuously; Metal is a
  future perf optimization if needed, per core.md risks)*
- [x] **M5.3 — Click-through overlay** — `ignoresMouseEvents = true` for LiveZoom so input
  hits the app underneath. **Done when:** you can click/type through the magnifier.
  **Depends on:** M5.2
  *(click-through removes Esc / right-click as exits, so the activation hotkey now
  toggles — `ModeController.toggle` — and ⌘⌃L again exits LiveZoom)*
- [~] **M5.4 — Cursor-follow modes** — cursor-centered vs. edge-push (configurable).
  **Done when:** both follow modes track the cursor as specified. **Depends on:** M5.2
  *(pure follow math in `LiveZoomFollow` unit-tested; persisted in `Preferences`;
  status-menu "LiveZoom Follow" submenu switches modes. Live verification pending.)*
- [ ] **M5.5 — `Recorder` (H.264 mp4)** — `AVAssetWriter` fed by `SCStream` buffers → mp4 in
  `~/Movies/XPlain`. **Done when:** start→stop yields a playable file at native
  resolution. **Depends on:** M5.1
- [ ] **M5.6 — Region vs. full-screen recording** — optional drag-rectangle at start.
  **Done when:** both scopes record correctly. **Depends on:** M5.5
- [ ] **M5.7 — Optional audio** — system + mic toggles (off by default; mic permission
  requested lazily). **Done when:** enabling either captures audio in the file.
  **Depends on:** M5.5
- [ ] **M5.8 — Composite overlay into recording** — Zoom/Draw annotations appear in the
  output. **Done when:** a recorded session shows the annotations. **Depends on:** M5.5, M4.2
- [ ] **M5.9 — Recording HUD / indicator** — menu-bar state + elapsed time. **Done when:**
  recording state and time are visible and accurate. **Depends on:** M5.5

---

<a id="m6"></a>
## M6 — Settings, polish & distribution  ·  *(Phase 6)*  ·  spec §7

Goal: configurable, signed, notarized, releasable.

- [ ] **M6.1 — `SettingsStore`** — typed `UserDefaults` wrapper with defaults. **Done
  when:** encode/decode round-trips are unit-tested. **Depends on:** M0.1
- [ ] **M6.2 — Settings window shell** — SwiftUI preferences window from the menu. **Done
  when:** the window opens and closes. **Depends on:** M6.1
- [ ] **M6.3 — Hotkey recorders + conflict warnings** — `KeyboardShortcuts.Recorder` per
  mode; warn on known-conflict chords. **Done when:** rebinding a mode takes effect with
  no restart. **Depends on:** M6.2, M1.1
- [ ] **M6.4 — Wire the settings panes** — zoom (level/step/animate), pen
  (color/width/opacity/font), recording (folder/scope/audio/quality), general
  (display target). **Done when:** each setting changes the corresponding behavior live.
  **Depends on:** M6.2, M3.3, M4.4, M5.6
- [ ] **M6.5 — Launch at login** — `SMAppService` toggle in General. **Done when:** the
  toggle registers/unregisters the login item. **Depends on:** M6.2
- [ ] **M6.6 — Icons** — app icon + menu-bar template icon. **Done when:** both render at
  all required sizes. **Depends on:** M0.2
- [ ] **M6.7 — Signing + hardened runtime + entitlements** — Developer ID, minimal
  entitlements (screen capture; device-audio only if mic offered). **Done when:** a signed
  build passes `codesign --verify`. **Depends on:** M0.1
- [ ] **M6.8 — Notarize + staple + `.dmg`** — `notarytool` submit, `stapler`, dmg build
  script. **Done when:** `spctl -a -vv` accepts the app on a clean machine. **Depends
  on:** M6.7
- [ ] **M6.9 — First-run onboarding** — guided Screen-Recording permission + hotkey cheat
  sheet. **Done when:** a fresh install walks a new user to a working state. **Depends
  on:** M2.2
- [ ] **M6.10 — GitHub Release** — tag `v0.1.0`, attach the notarized `.dmg`, write notes.
  **Done when:** the release is downloadable and runs. **Depends on:** M6.8

**M6 exit = v0.1 ships.** All boxes in [`success-criteria.md`](success-criteria.md)
"MVP acceptance" are checked.

---

## Post-MVP milestones (planned, not yet scheduled)

Pull one into the numbered flow when you decide to build it; write `specs/` first.

- **M7 — Break Timer** (`⌘⌃T`): full-screen countdown; `+`/`-` adjust; alarm at zero;
  optional background image; elapsed/remaining display. (First-class ZoomIt mode,
  deferred from the MVP.)
- **M8 — Demo Type**: type a text file into the focused app to simulate live typing.
  Needs **Accessibility** permission (see security.md) — request lazily.
- **M9 — LiveDraw**: annotate directly on the live (non-frozen) screen.
- **M10 — Region loupe / picture-in-picture**: a following magnifier instead of a
  full-screen takeover.

## Icebox (ideas — not committed, no ID yet)

- Draw: shape snapping (15° / square / circle), blur & spotlight tool, numbered
  callouts, persistent boards.
- Recording: pause/resume, click & keystroke visualization, GIF export, per-window
  capture.
- Platform/DX: Sparkle auto-updates, Homebrew Cask, hotkey-conflict detection,
  localization scaffolding.

## Explicitly not planned

Windows/Linux ports · cloud sync · accounts · any telemetry/analytics without
explicit opt-in.
