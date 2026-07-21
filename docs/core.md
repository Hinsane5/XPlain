# XPlain — Core Architecture

How XPlain is built. `docs/spec.md` defines *what* it does; this doc defines the
components, the state machine, and the key technical decisions behind them.

## Shape of the system

XPlain is a single **menu-bar agent process**. A central `ModeController` owns a
small **state machine** (Idle ↔ Zoom ↔ Draw ↔ LiveZoom ↔ Record). Global hotkeys
request mode transitions; the controller tears down the old mode and stands up the
new one, each backed by a full-screen borderless **overlay window**. Screen pixels
come from **ScreenCaptureKit**; annotations are a separate vector layer rendered on
top. Nothing is persisted except user settings.

## Stack & key decisions

| Concern | Choice | Why |
|---------|--------|-----|
| Language | Swift 5.9+ | First-class access to AppKit / ScreenCaptureKit / Metal. |
| Min OS | macOS 14 (Sonoma) | `SCScreenshotManager.captureImage` gives simple, fast still capture; modern SCK. |
| UI shell | AppKit menu-bar agent (`LSUIElement`) | No Dock icon; always-resident background tool. |
| Overlays | Borderless `NSWindow` per active display | Full control of level, click-through, and Spaces behavior. |
| Screen capture | ScreenCaptureKit | The only sanctioned modern capture API; `SCStream` for live, `SCScreenshotManager` for stills. |
| Global hotkeys | KeyboardShortcuts (SwiftPM) | Carbon `RegisterEventHotKey` under the hood — **no Accessibility permission needed** — plus a ready-made recorder UI for Settings. |
| Static rendering | Core Animation / Core Graphics | Simple, sufficient for a frozen zoom + vector overlay. |
| Live rendering | Metal (`MTKView`) | LiveZoom and Record need high, steady frame rates. |
| Recording | AVFoundation `AVAssetWriter` + `SCStream` | Works from macOS 14; avoids hard-requiring `SCRecordingOutput` (macOS 15+). |
| Settings storage | `UserDefaults` | Small key/value config; no database warranted. |

## Components

- **`AppDelegate` / menu-bar controller** — owns the `NSStatusItem`, the menu, and
  app lifecycle. Boots the hotkey registrations and the `ModeController`.
- **`HotkeyService`** — registers each mode's global shortcut via KeyboardShortcuts;
  emits mode-request events. The single entry point for all global key handling.
- **`ModeController`** — the state machine. Guarantees one active mode, owns
  transitions, and is the only object that creates/destroys overlay windows.
- **`OverlayWindow` / `OverlayWindowController`** — a borderless `NSWindow` sized to
  the target display, with the right `level`, `collectionBehavior`, and
  `ignoresMouseEvents` for the current mode. Hosts the render view.
- **`CaptureService`** — wraps ScreenCaptureKit. Provides `snapshot(of: display)`
  for Zoom/Draw backdrops and a `stream(of: display)` async frame feed for
  LiveZoom/Record. Owns permission preflight.
- **`ZoomRenderer`** — applies scale + pan (`CGAffineTransform`) to the captured
  image; handles the animated zoom-in and cursor-follow math.
- **`AnnotationCanvas`** — the drawing layer. Holds the `[Drawable]` model and an
  undo/redo stack; renders shapes over whatever backdrop is active.
- **`InputRouter`** — while a mode is active the overlay window is key; this maps
  `keyDown` / `scrollWheel` / `mouse*` / `flagsChanged` events to mode actions
  (colors, shapes, zoom step, pen width) per `docs/spec.md`.
- **`Recorder`** — consumes `SCStream` sample buffers, composites the overlay, and
  writes H.264 to disk via `AVAssetWriter`.
- **`SettingsStore` + Settings UI** — typed wrapper over `UserDefaults`; SwiftUI
  preferences window including the KeyboardShortcuts recorders.

## State machine

```
        ┌─────────────────────────── Esc / right-click ───────────────────────────┐
        ▼                                                                          │
     ┌──────┐   ⌘⌃Z   ┌──────┐   ⌘⌃D / left-drag   ┌──────┐                        │
     │ Idle │ ──────► │ Zoom │ ──────────────────► │ Draw │ ── save/copy ─┐        │
     └──────┘         └──────┘ ◄────────────────── └──────┘               │        │
        │  ⌘⌃D (standalone draw)   ▲                                      │        │
        ├──────────────────────────┘                                      ▼        │
        │  ⌘⌃L         ┌──────────┐                                    (to Idle) ──┘
        ├────────────► │ LiveZoom │
        │  ⌘⌃R         └──────────┘
        └────────────► ┌────────┐
                       │ Record │  (may overlay Zoom/Draw output)
                       └────────┘
```

Invariants:
- At most one overlay window group exists at a time.
- Every transition into Idle fully releases capture streams and overlay windows.
- A capture-permission failure routes to a **PermissionPrompt** sub-state, never a
  blank overlay.

## Data flow — a typical Zoom → Draw → Save

1. User presses `⌘⌃Z`. `HotkeyService` emits `.enterZoom`.
2. `ModeController` asks `CaptureService.snapshot(of:)` for the display under the
   cursor (preflighting Screen Recording permission).
3. It creates an `OverlayWindow` on that display and hands the `CGImage` to
   `ZoomRenderer`, which presents it at the initial scale centered on the cursor.
4. Mouse move → `InputRouter` → `ZoomRenderer` pan; scroll → zoom step.
5. User left-drags → `ModeController` enters **Draw**; `InputRouter` forwards points
   to `AnnotationCanvas`, which appends a `Drawable` and redraws the overlay.
6. `⌘S` → `AnnotationCanvas` + `ZoomRenderer` composite to a `CGImage` → written to
   `~/Pictures/XPlain`.
7. `Esc` → `ModeController` tears down the overlay and stream → back to Idle.

## Data model (summary)

There is no database. The only durable data is **settings** in `UserDefaults`.
In-memory, the annotation model is a value type:

```
enum Drawable {
  case freehand(points: [CGPoint], pen: Pen)
  case line(from: CGPoint, to: CGPoint, pen: Pen)
  case rect(CGRect, pen: Pen)
  case ellipse(CGRect, pen: Pen)
  case arrow(from: CGPoint, to: CGPoint, pen: Pen)
  case text(String, at: CGPoint, font: Font, color: Color)
}
struct Pen { var color: Color; var width: CGFloat; var isHighlighter: Bool }
```

Undo/redo is two stacks of `[Drawable]` snapshots (or command deltas).

## Cross-cutting conventions

- **All screen capture goes through `CaptureService`** — never call ScreenCaptureKit
  directly from a view or the controller.
- **All global key handling goes through `HotkeyService`**; all in-mode key handling
  through `InputRouter`. Views do not register shortcuts themselves.
- **Coordinate discipline**: convert once, at the capture boundary. AppKit is
  bottom-left origin; `CGImage`/SCK are top-left. Centralize the Y-flip in
  `CaptureService` so the rest of the code works in one space.
- **Overlay windows** are created only by `ModeController`, always with
  `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`
  and a `level` above `.mainMenu`.
- **No blocking dialogs** while a mode is active.

## Open questions / risks

- **LiveZoom latency** on Intel/older GPUs — Metal path must be profiled early; a
  Core Image fallback may be needed. (Prototype in Phase 3.)
- **Recording overlay compositing** — decide whether to composite in the `SCStream`
  pipeline or capture the overlay window into the same stream. (Resolve in Phase 5.)
- **Permission reset on re-sign** — document the relaunch requirement clearly; there
  is no way around the TCC behavior.
