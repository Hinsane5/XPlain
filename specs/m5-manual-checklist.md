# M5 — Manual verification checklist (LiveZoom + Record)

Real-time / hardware checks for LiveZoom (spec §5) and Record (spec §6). The pure
math (follow modes, region rect, elapsed formatting) is unit-tested; the
capture/GPU/recorder paths need real Screen Recording permission and a live
screen, so they're verified here. CI skips the capture-bound integration tests.

## M5.1 — Live SCStream frame feed  ✅ verified live 2026-07-23
- [x] Verified via M5.2 (the live magnified view updates continuously).

## M5.2 — Live magnification  ✅ verified live 2026-07-23
- [x] ⌘⌃L shows a magnified view of the live screen that updates continuously
      (menu-bar clock ticks) and follows the cursor. No self-capture feedback.

## M5.3 — Click-through  ✅ verified live 2026-07-23
- [x] Clicks/typing pass through the LiveZoom overlay to the app underneath.
- [x] ⌘⌃L again cleanly exits LiveZoom (the hotkey is the exit, since Esc /
      right-click now pass through too).

## M5.4 — Cursor-follow modes  *(pending)*
- [ ] Cursor-centered vs. edge-push both track the cursor as specified.

## M5.5 — Recorder  *(pending)*
- [ ] ⌘⌃R start→stop writes a playable .mp4 to ~/Movies/XPlain at native resolution.

## M5.6 — Region vs full-screen  *(pending)*
- [ ] Full-display and a selected region both record correctly.

## M5.7 — Optional audio  *(pending)*
- [ ] Enabling system/mic audio puts an audio track in the file.

## M5.8 — Composite overlay  *(pending)*
- [ ] Zoom/Draw annotations appear in the recording.

## M5.9 — Recording HUD  *(pending)*
- [ ] Menu-bar state + elapsed time are visible and accurate while recording.
