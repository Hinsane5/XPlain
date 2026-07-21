# XPlain — Backlog

Everything beyond the MVP, roughly prioritized. The MVP scope (Zoom, Draw,
LiveZoom, Record) lives in `docs/plan.md`; this is the "later" list. Pull an item
up into a plan phase when you decide to build it — write a `specs/` doc first.

Status legend: 🔜 next up · 💡 idea · 🧊 icebox.

## High-value features

- 🔜 **Break Timer** (`⌘⌃T`) — full-screen countdown for breaks, with `+`/`-` to
  adjust, an alarm sound at zero, optional background image, and elapsed/remaining
  display. This is a first-class ZoomIt mode intentionally deferred out of the MVP.
- 🔜 **Demo Type** — type a predefined text file into the focused app to simulate
  live typing during demos. (Needs Accessibility permission — see `docs/security.md`.)
- 💡 **LiveDraw** — draw directly on the *live* (non-frozen) screen, so annotations
  float over a running demo.
- 💡 **Region zoom / picture-in-picture** — a fixed magnifier loupe that follows the
  cursor instead of taking over the whole display.

## Draw enhancements

- 💡 **Shape snapping** — snap lines to 15° increments, squares/circles when holding
  an extra modifier.
- 💡 **Blur / spotlight tool** — obscure or dim everything except a highlighted area.
- 💡 **Sticky arrows & numbered callouts** — auto-incrementing step markers.
- 🧊 **Persistent boards** — save/restore a whiteboard session across launches.

## Recording enhancements

- 💡 **Pause/resume** during recording.
- 💡 **Cursor click highlights** — visualize clicks and keystrokes in the recording.
- 💡 **GIF export** for short clips.
- 🧊 **Per-window capture** — record a single window rather than a display/region.

## Platform & distribution

- 💡 **Sparkle auto-updates** — in-app update checks for the notarized build.
- 💡 **Homebrew Cask** — `brew install --cask xplain`.
- 🧊 **Apple Silicon + Intel universal binary** verification matrix.

## Quality & DX

- 💡 **First-run onboarding** — a short guided flow that requests Screen Recording
  permission and shows the default hotkeys.
- 💡 **Hotkey conflict detection** — warn when a chosen shortcut collides with a
  known system or common-app binding.
- 🧊 **Localization** scaffolding.

## Explicitly not planned

- Windows/Linux ports (XPlain is macOS-native by design).
- Cloud sync, user accounts, or any analytics/telemetry.
