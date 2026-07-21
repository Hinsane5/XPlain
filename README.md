# XPlain

**Zoom into your screen, draw on it, and record it — with a keystroke.**
XPlain is a native macOS menu-bar tool for presenters, teachers, and streamers.
It's a [ZoomIt](https://learn.microsoft.com/en-us/sysinternals/downloads/zoomit)
for the Mac.

> **Status:** early development (pre-v0.1). Nothing is built yet — this repo
> currently holds the spec and plan. See [docs/plan.md](docs/plan.md) for the
> roadmap.

## What it does

Press a global hotkey to enter a mode; press **Esc** to leave.

| Mode | Hotkey* | What it does |
|------|---------|--------------|
| **Zoom** | `⌘⌃Z` | Freeze and magnify the screen; pan with the mouse, scroll to zoom. |
| **Draw** | `⌘⌃D` | Annotate with pens, shapes, arrows, highlighter, and text. |
| **LiveZoom** | `⌘⌃L` | Magnify while the screen stays live and clickable. |
| **Record** | `⌘⌃R` | Record the screen (with your annotations) to an `.mp4`. |

*All hotkeys are configurable. Break Timer and more are on the [backlog](docs/backlog.md).*

## Tech stack

- **Swift + AppKit**, macOS 14 (Sonoma)+ — a menu-bar agent, no Dock icon.
- **ScreenCaptureKit** for capture, **Metal / Core Graphics** for rendering.
- **[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)** for
  global hotkeys, **AVFoundation** for recording.
- Distributed as a **notarized `.dmg`** (not sandboxed, not on the App Store — that's
  what lets it capture the whole screen). See [docs/security.md](docs/security.md).

## Quickstart (development)

```bash
# Requires Xcode 15+ on macOS 14+.
git clone <this-repo> && cd XPlain
open XPlain.xcodeproj     # then Product ▸ Run
```

On first launch, grant **Screen Recording** permission in
System Settings ▸ Privacy & Security, then relaunch.

## Documentation

- [AGENTS.md](AGENTS.md) — instructions for AI coding agents working in this repo.
- [docs/spec.md](docs/spec.md) — full functional spec: every mode, hotkey, behavior.
- [docs/core.md](docs/core.md) — architecture, components, and the state machine.
- [docs/plan.md](docs/plan.md) — phased build roadmap (strategy).
- [docs/backlog.md](docs/backlog.md) — granular numbered task tracker (`M0.1`, `M1.1`, …).
- [docs/testing.md](docs/testing.md) — test strategy and definition of done.
- [docs/success-criteria.md](docs/success-criteria.md) — acceptance criteria.
- [docs/security.md](docs/security.md) — permissions, privacy, notarization.

## Development

Follow **Explore → Plan → Code → Verify**. For non-trivial changes, write a short
spec in [`specs/`](specs/) first. Run the validation gates before declaring a change
done:

```bash
swiftlint --strict
swift-format lint --recursive Sources
xcodebuild -scheme XPlain -destination 'platform=macOS' build test
```

## Privacy

Everything XPlain captures stays **on your device**. No accounts, no servers, no
telemetry. See [docs/security.md](docs/security.md).

## License

[MIT](LICENSE) © 2026 Howard Goh.

---

*XPlain is an independent project and is not affiliated with or endorsed by
Microsoft or Sysinternals. "ZoomIt" is referenced only to describe the kind of tool
this is.*
