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

## M5.4 — Cursor-follow modes  *(code + unit tests done; live check pending)*
- [ ] Status menu ▸ "LiveZoom Follow" shows both modes, checkmark on the active one.
- [ ] Cursor-centered: magnified view re-centers on the pointer continuously.
- [ ] Edge-push: view holds still while the cursor roams the center, scrolls only
      when the cursor nears an edge.

## M5.5 — Recorder  ✅ verified live 2026-07-23
- [x] ⌘⌃R start→stop writes a playable .mp4 to ~/Movies/XPlain at native resolution.
      Probed: playable, H.264 (avc1), 1920×1080, ~32.7 fps, 3.65 s.

## M5.6 — Region vs full-screen  ✅ verified live 2026-07-23
- [x] Status menu ▸ "Recording Scope" toggles full display vs. selected region.
- [x] Selected region shows a dim drag-select overlay; Esc / tiny click cancels.
- [x] Full-display records at native resolution; region records cropped to the
      drag rectangle. Probed: full 1920×1080/5.12s, region 146×90/4.96s.
- [x] Duration is wall-clock accurate even for a static region (stop() ends the
      writer session at the real stop time — SCStream only emits frames on change).

## M5.7 — Optional audio  ✅ verified live 2026-07-24
- [x] Menu ▸ "Record System Audio" toggles + persists; checkmark sticks.
- [x] Enabling system audio puts an AAC 48kHz stereo track in the file.
      Verified live: video 1920×1080/5.15s + audio aac/5.08s.
- [x] Menu ▸ "Record Microphone" toggles + persists; first record prompts for
      mic permission (macOS 15+).
- [x] Enabling microphone puts a mic AAC track in the file. Verified live with
      both on: 3 tracks (video + system aac + mic aac).
- [ ] Known limitation: both-on = two separate audio tracks (players play one);
      single-track mixing is iceboxed.

## M5.8 — Composite overlay  ✅ verified live 2026-07-24
- [x] Recording is a background activity (⌘⌃R), independent of the mode machine.
- [x] Zooming/drawing while recording composites those overlays into the file.
      Verified: extracted a frame from a recording showing a red pen stroke baked
      into the live screen. (Draw's backdrop is frozen — live+draw is M9.)

## M5.9 — Recording HUD  *(pending)*
- [ ] Menu-bar state + elapsed time are visible and accurate while recording.
