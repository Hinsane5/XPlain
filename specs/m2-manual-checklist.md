# M2 — Manual / permission-gated verification checklist

Unlike M1's checklist (purely visual), M2's pending items need a **resource this
dev machine doesn't have**: real Screen Recording permission (see
`docs/security.md`). The code + guarded tests are done and gates are green — the
guarded tests correctly **skip** (not fail) without permission, per
`docs/testing.md`'s CI-skip convention. Run these once permission is granted to
confirm the real behavior.

## M2.1 — `CaptureService.snapshot(of:)`  *(code + guarded test: ✅ done)*

1. Grant Screen Recording to the built app: System Settings ▸ Privacy & Security
   ▸ Screen Recording ▸ add/enable the built `XPlain.app`, then relaunch it.
2. Re-run `xcodebuild -scheme XPlain -destination 'platform=macOS' test` — the two
   `CaptureServiceTests` should now **run and pass** instead of skipping:
   - [ ] `testSnapshotReturnsNonEmptyImageAtDisplayPixelSize` passes (non-empty
         image, dimensions > 0).
   - [ ] `testSnapshotThrowsForUnknownDisplay` passes (`noMatchingDisplay` for a
         bogus display ID).

## M2.2 — Permission prompt  *(add once built)*
- [ ] With permission **denied**, activating a mode shows the `PermissionPrompt`
      state — never a blank/frozen overlay.
- [ ] The prompt's deep-link button opens the correct System Settings pane.
- [ ] After granting permission and relaunching, the normal capture path works.
