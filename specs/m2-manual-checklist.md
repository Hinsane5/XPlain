# M2 — Manual / permission-gated verification checklist

Unlike M1's checklist (purely visual), M2's pending items need a **resource this
dev machine doesn't have**: real Screen Recording permission (see
`docs/security.md`). The code + guarded tests are done and gates are green — the
guarded tests correctly **skip** (not fail) without permission, per
`docs/testing.md`'s CI-skip convention. Run these once permission is granted to
confirm the real behavior.

## M2.1 — `CaptureService.snapshot(of:)`  ✅ verified 2026-07-23

Permission was granted to the specific hosting app binary (unit tests run
*hosted* inside `XPlain.app` — see `TEST_HOST` build setting — not to the
terminal/shell invoking `xcodebuild`). Once granted to that exact path:
- [x] `testSnapshotReturnsNonEmptyImageAtDisplayPixelSize` passes for real
      (0.237s — an actual capture round-trip, not skipped).
- [x] `testSnapshotThrowsForUnknownDisplay` passes for real.

## M2.2 — Permission prompt  *(code + unit tests: ✅ done — no manual row in
docs/testing.md's matrix, ticked `[x]`)*

- [x] Confirmed live 2026-07-23: with permission denied, ⌘⌃Z showed the
      prompt's message + button (never a blank screen), and the button opened
      System Settings directly to the Screen Recording pane, exactly as
      designed. See M2.4 below for how this got exercised.

## M2.4 — Render the snapshot into the overlay  ✅ verified live 2026-07-23

**Resolved.** The blocker below was ad-hoc code signing not persisting the
Screen Recording grant across rebuilds. Fixed by signing local builds with a
stable Apple Development identity (Personal Team `37784HMFS9` — see
`project.yml` and the "Sign local builds with a stable Apple Development
identity" commit). With that in place:
- [x] ⌘⌃Z captures the real display and renders it into the overlay (permission
      now persists across rebuilds — granted once, no re-prompt).
- [x] A **red-dot cursor** marks the active overlay (M2.4's frozen 1× snapshot
      is otherwise pixel-identical to the live desktop — the visible 2× zoom is
      M3). ZoomIt-style "you're in" cue.
- [x] Confirmed no blue self-capture ghost and a single cursor (the
      capture-before-show + `showsCursor = false` fixes — see the "Fix overlay
      self-capture, double cursor, and two-click dismiss" commit).

`CaptureService.snapshot` takes an explicit `pixelSize` (fixes a real bug caught
before it shipped — requesting a display's *point* size instead of its native
pixel size would have captured at half resolution on this Retina display).
`Display` carries `backingScaleFactor` so the true native pixel size is
requested.

---

**Historical: what was blocked before the signing fix (kept as a record):**

1. Screen Recording permission was granted to the exact `TEST_HOST` binary
   (`~/Library/Developer/Xcode/DerivedData/XPlain-.../Build/Products/Debug/
   XPlain.app` — unit tests run *hosted* inside the app, not the invoking
   shell). This is an **ad-hoc signature** (`codesign -dvvv` shows
   `flags=0x2(adhoc)`, `TeamIdentifier=not set`) — every rebuild changes the
   binary's hash, and this machine's TCC does not reliably retain the grant
   across rebuilds, even though the same file *path* is reused. Re-granting
   after each rebuild is the workaround (already documented in AGENTS.md's
   Screen Recording gotcha, just triggered more aggressively than expected —
   by any rebuild, not only re-signing/moving).
2. Launched the actual built app directly (not via `xcodebuild test`) to
   verify M2.4's real "Done when" independent of the test-hosting nuance.
   Result: **confirmed M2.2's permission-prompt fallback works correctly
   live** (see above) — but couldn't get past it to see the real capture,
   because:
3. Toggling the permission off/on in System Settings didn't help.
4. A full **logout and back in** — the standard fix for Screen Recording
   grants not propagating to the WindowServer session — also didn't help.
5. Immediately after, `xcodebuild test` itself started **crashing** (not
   failing — a hard `Abort trap: 6` in `IDELaunchServicesLauncher
   _waitForChildExit`, Xcode's own GUI-test-host launcher) in the shell
   session driving this work. `swiftlint`/`swift-format` (no GUI launch
   needed) and a plain `xcodebuild build` still work fine — this points to
   the shell's launchd session (`launchctl managername` reports
   `Background`) being orphaned from the *new* WindowServer session created
   by the logout, unable to bridge into it to launch/track a GUI test host.
6. **Confirmed the theory**: the user ran the identical `xcodebuild test`
   command in a genuinely fresh Terminal.app window and got a clean run —
   44 tests, 3 skipped (still permission-gated, same ad-hoc-signing issue),
   0 failures, `** TEST SUCCEEDED **`. So the crash really was specific to
   that one stale automation shell, not the machine, Xcode, or the code.
   The permission-gated skip is the only piece still open, and is purely
   the ad-hoc-signing issue in point 1.

**To actually close this out:** on a machine/session without the above two
issues (or once this one's session state is fresh again), or ideally once
the app has a **stable code-signing identity** (a free Apple ID-backed
development certificate would very likely fix the rebuild-resets-permission
issue for good — worth doing before M2 is revisited further, and required
anyway by M6.7):
- [ ] Grant Screen Recording once with a stable signing identity; confirm it
      survives a rebuild.
- [ ] `CaptureServiceTests`' three tests run (not skip) and pass.
- [ ] ⌘⌃Z shows the real desktop, pixel-for-pixel — not the M1.3 color fill,
      and not visibly blurry (the retina pixelSize fix, confirmed by eye).
