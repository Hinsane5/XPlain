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

Optional spot check, not blocking: with permission denied, activate any mode
and click the prompt's button — confirms it opens System Settings' Screen
Recording pane in practice, on top of the unit-tested URL string.
- [ ] Deep-link button opens the correct pane (optional; unit-tested URL
      already covers the logic).
