# XPlain — Test Plan (TDD)

XPlain is built **test-first**. For every backlog task you write the failing test
*before* the code, watch it fail, make it pass, then refactor. The tests are not an
afterthought or a coverage-percentage chase — they are the executable definition of
each task's "Done when".

Because XPlain is also a real-time, GPU- and permission-bound macOS app, not
everything can be a unit test (you can't unit-assert "the zoom looks smooth"). So the
discipline is: **push logic out of the UI into pure, testable types, TDD those hard,
and cover the irreducibly visual/real-time behavior with a scripted manual
checklist.** Every backlog task below is mapped to one or the other — nothing is
left uncovered.

---

## The TDD loop (per task)

```
1. RED     — write the test from the task's "Done when"; run it; watch it FAIL.
2. GREEN   — write the least code that makes it pass.
3. REFACTOR— clean up with the test green.
4. GATE    — run the full gates (they run automatically; see below). All green → done.
```

Order matters: a test that has never failed proves nothing. If a task is
"manual-only" (see the matrix), its RED step is adding the unchecked item to the
release checklist in `specs/`, and its GREEN step is verifying it by eye and checking
the box in the PR.

## Tests run automatically on every code change

A **Claude Code Stop hook** (`.claude/settings.json` → `scripts/verify-gates.sh`)
runs the full gate suite after **every turn that changed source code**:

```
swiftlint --strict
swift-format lint --strict --recursive Sources Tests
xcodebuild -scheme XPlain -destination 'platform=macOS' build test
```

- Turns that only touch docs are skipped (no wasted build).
- If any gate fails, the hook returns a failure that tells the agent to **keep
  working and fix it** before finishing — you cannot "complete" a task with red gates.
- CI (`.github/workflows/ci.yml`) runs the same gates on every push as the backstop.
- Run them yourself any time: `scripts/verify-gates.sh --all`.

This is the enforcement behind the "Definition of done" below.

## Test layers & tooling

- **Unit (XCTest)** — pure logic, no window/GPU/TCC dependency. The majority of
  automated coverage. Fast, deterministic, run on every change.
- **Integration (XCTest)** — seams that need a real framework (capture, recorder,
  settings persistence). Permission/GPU-dependent ones are guarded so they **skip**
  (not fail) in headless CI.
- **Manual checklist** — real-time / visual behavior verified by eye, per release,
  from `specs/`. Each item is a concrete, observable check.

| Tool | Use |
|------|-----|
| XCTest (`xcodebuild test`) | unit + integration |
| SwiftLint `--strict` | style gate |
| swift-format `lint --strict` | format gate |
| `scripts/verify-gates.sh` | the runner wired to the Stop hook + CI |

**Testability rule (so the matrix can be mostly automated):** keep `ModeController`,
`ZoomRenderer`, the annotation model, `InputRouter`, follow-mode math, and
`SettingsStore` as **pure types** that a view merely renders. A `CaptureService`
**protocol** lets tests inject a fake so mode logic runs without real screen capture.

---

## Coverage matrix — every backlog task

`U` = unit · `I` = integration (CI-skippable if permission/GPU-bound) · `M` = manual
checklist item. Task IDs match [`backlog.md`](backlog.md).

### M0 — Project init
| Task | Type | Test asserts |
|------|------|--------------|
| M0.1–M0.7 | I/meta | The gates themselves run: `xcodebuild build test` succeeds, `swiftlint`/`swift-format` pass, `M0.5` smoke test green, CI green on push. |

### M1 — Hotkeys + overlay skeleton
| Task | Type | Test asserts |
|------|------|--------------|
| M1.1 HotkeyService | U | Each `KeyboardShortcuts.Name` maps to the correct mode-request (inject a fake emitter; assert emitted enum). |
| M1.2 ModeController | U | Driving Idle→Zoom→Draw→Idle yields the expected states; the single-active invariant holds; illegal transitions rejected. |
| M1.3 OverlayWindow | U + M | U: window is built with the target screen's frame. M: overlay actually appears on the right display. |
| M1.4 Level / Spaces | U + M | U: window built with `level > .mainMenu` and the 3 collection-behavior flags. M: appears over full-screen apps and on every Space. |
| M1.5 Esc / right-click exit | U + M | U: an Esc/right-click event routes to Idle and requests teardown. M: no window leak after repeated enter/exit. |
| M1.6 Display targeting | U | Pure `screen(forCursorAt:)` maps sample points (incl. multi-display, negative origins) to the expected `NSScreen`. |

### M2 — Permission + still capture
| Task | Type | Test asserts |
|------|------|--------------|
| M2.1 snapshot | I | With permission (local), returns a non-empty image at the display's pixel size. Fake `CaptureService` used elsewhere. |
| M2.2 Permission + prompt | U | Inject a permission checker: denied → `PermissionPrompt` state (never blank); granted → capture path. |
| M2.3 Y-flip | U | Flipping known points/rects between AppKit and CGImage spaces is exact across single- and multi-display geometries. |
| M2.4 Render snapshot | M | Overlay is visually indistinguishable from the frozen desktop. |

### M3 — Zoom mode
| Task | Type | Test asserts |
|------|------|--------------|
| M3.1 Initial present | U + M | U: transform for a given scale + cursor centers correctly. M: magnifies on activation. |
| M3.2 Pan | U + M | U: cursor delta → pan translation is 1:1. M: panning tracks the cursor. |
| M3.3 Zoom in/out | U | Level clamps to 1.25×–8×, honors step, never exceeds bounds; scroll and ↑/↓ both apply the step. |
| M3.4 Animated zoom | U + M | U: the animate flag toggles animation on/off. M: entry is smooth, not a jump. |
| M3.5 Copy / Save | I | `⌘S` writes a PNG of the visible region at expected size; `⌘C` puts an image on the pasteboard. |
| M3.6 Zoom-math tests | U | The dedicated math suite (clamp/step/pan/center) — this task *is* its tests. |

### M4 — Draw / Annotate
| Task | Type | Test asserts |
|------|------|--------------|
| M4.1 Drawable model | U | Every `Drawable` case + `Pen` constructs and round-trips (encode/decode). |
| M4.2 Freehand | U + M | U: appended points build a freehand `Drawable`. M: stroke renders live. |
| M4.3 Shapes | U | Modifier → shape mapping; geometry of line/rect/ellipse/arrow from drag start/end points. |
| M4.4 Colors/highlighter/width | U | Each key (`r g b o y p h`, `[` `]`, `⌥+scroll`) mutates the pen as specified. |
| M4.5 Text | U + M | U: text model create/edit/commit + size change. M: caret placement and typing. |
| M4.6 Whiteboard/blackboard | U | `w`/`k` swap backdrop and back **without** dropping existing annotations. |
| M4.7 Undo/redo | U | `⌘Z`/`⌘⇧Z` are exact across all `Drawable` types; `e`/Delete clears; redo after new stroke is invalidated correctly. |
| M4.8 Copy/save annotated | I | Output composites backdrop + strokes (assert a known stroke pixel is present). |
| M4.9 Standalone / over-zoom | U + M | U: both entry paths produce the right state transitions. M: visuals in each path. |
| M4.10 Input-mapping tests | U | The full spec §4 key/modifier table is asserted in `InputRouter` — this task *is* its tests. |

### M5 — LiveZoom + Record
| Task | Type | Test asserts |
|------|------|--------------|
| M5.1 Stream | I | `SCStream` delivers a sequence of frames for a display (CI-skip). |
| M5.2 MTKView magnify | M | Live view is magnified and updates continuously. |
| M5.3 Click-through | U + M | U: overlay built with `ignoresMouseEvents = true` in LiveZoom. M: clicks/typing reach the app underneath. |
| M5.4 Follow modes | U + M | U: cursor-centered vs. edge-push produces the expected view origin for sample cursor paths. M: feels right. |
| M5.5 Recorder | I | Synthetic sample buffers → a valid, playable `.mp4` of the expected duration/resolution (CI-skip if needed). |
| M5.6 Region vs full | U + I | U: region rect math. I: file scope matches selection. |
| M5.7 Audio | I | With a toggle on, the output has an audio track (CI-skip). |
| M5.8 Composite overlay | I + M | I: a recorded frame contains a known overlay pixel. M: annotations visible in playback. |
| M5.9 HUD / indicator | U + M | U: elapsed-time formatting. M: indicator state is accurate. |

### M6 — Settings, polish & distribution
| Task | Type | Test asserts |
|------|------|--------------|
| M6.1 SettingsStore | U | Encode/decode round-trip + every default value. |
| M6.2 Settings window | M | Opens and closes from the menu. |
| M6.3 Recorders + conflict | U + M | U: conflict-detection logic flags a known-reserved chord. M: rebinding takes effect with no restart. |
| M6.4 Wire panes | U + M | U: a setting change publishes to observers. M: the behavior actually changes live. |
| M6.5 Launch at login | I | `SMAppService` register/unregister toggles the login-item state. |
| M6.6 Icons | M | App + menu-bar icons render at all sizes. |
| M6.7 Signing | I/script | `codesign --verify --strict` passes on a signed build. |
| M6.8 Notarize / dmg | I/script | `spctl -a -vv` accepts the app on a clean machine. |
| M6.9 Onboarding | M | A fresh install walks a new user to a working state. |
| M6.10 Release | M | The published `.dmg` downloads and runs. |

### M7–M10 (post-MVP) — test-first when pulled in
| Milestone | Type | Test asserts |
|-----------|------|--------------|
| M7 Break Timer | U + M | U: countdown/`+`/`-`/at-zero logic. M: full-screen display + alarm. |
| M8 Demo Type | U + M | U: text→keystroke sequencing. M: types into the focused app (needs Accessibility). |
| M9 LiveDraw | U + M | U: annotation-over-live-frame model. M: draws on the running screen. |
| M10 Region loupe | U + M | U: loupe follow math. M: PiP magnifier tracks the cursor. |

---

## Definition of done

A task is done only when **all** hold:
1. Its test from the matrix was written **first** and failed before the code (RED→GREEN).
2. The **validation gates are green** — enforced automatically by the Stop hook and CI:
   `swiftlint --strict`, `swift-format lint --strict`, `xcodebuild build test`.
3. If the task has a manual row, its **checklist item is verified and checked** in the PR.
4. Its `success-criteria.md` checkbox (if any) is satisfied.

## Coverage priorities

Test hardest where a bug hurts most or hides from the eye:
1. **Coordinate transforms** (Y-flip, multi-display) — subtle and pervasive.
2. **State-machine teardown** — leaked capture streams/overlays degrade the app silently.
3. **Input mapping** — a large key/modifier surface that regresses easily.
4. **Undo/redo & settings round-trips** — data-integrity bugs.

## Gotchas

- CI runners have **no Screen Recording permission and no attached GPU** — guard the
  capture/GPU/recorder integration tests with availability checks so they **skip**,
  never fail, in headless CI. The manual checklist covers what CI cannot.
- **Don't assert wall-clock frame rates** in CI (flaky). Assert correctness — image
  size, transform values, file validity — and verify smoothness by eye.
- Keep logic **out of views** so it stays unit-testable; a view that holds real logic
  is a testing smell here.
