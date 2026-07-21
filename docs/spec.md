# XPlain — Functional Spec

This is the source of truth for **what XPlain does**. It defines every mode, its
hotkeys, and its on-screen behavior. `docs/core.md` covers *how* it is built.

XPlain is modeled on [Microsoft ZoomIt](https://learn.microsoft.com/en-us/sysinternals/downloads/zoomit),
adapted to macOS conventions. Where ZoomIt's defaults collide with macOS system
shortcuts, XPlain diverges and the divergence is noted.

---

## 1. App model

- XPlain is a **menu-bar agent** — no Dock icon, no main window. It lives in the
  status bar and listens for global hotkeys at all times.
- The menu-bar icon opens a menu: enter each mode, open **Settings**, **About**,
  **Check permissions**, **Quit**.
- Only **one mode** is active at a time. Entering a mode from another mode
  transitions cleanly (e.g. Zoom → Draw).
- **Esc** or **right-click** exits any active mode back to Idle.

## 2. Modes overview

| Mode | Default hotkey | Summary |
|------|----------------|---------|
| **Zoom** | `⌘⌃Z` | Freeze the screen and zoom into a static image; pan with the mouse. |
| **Draw** | `⌘⌃D` | Annotate — freehand, shapes, arrows, highlighter, text. Works standalone or on top of Zoom. |
| **LiveZoom** | `⌘⌃L` | Zoom while the screen underneath stays **live and interactive**. |
| **Record** | `⌘⌃R` | Record the screen (or a region) to an `.mp4` file. |
| **Break Timer** | `⌘⌃T` | Full-screen countdown for breaks. *(Post-MVP — see `docs/backlog.md`.)* |

All hotkeys are **user-configurable** in Settings via a shortcut recorder. The
defaults deliberately avoid `⌃1`–`⌃4` (Mission Control Space switching) and other
reserved system chords.

---

## 3. Zoom mode (`⌘⌃Z`)

**Purpose:** magnify part of the screen for an audience.

- On activation, XPlain captures the display under the cursor as a still image and
  presents it full-screen at an initial zoom (default **2×**).
- The zoom is centered on the cursor. **Moving the mouse pans** the view.
- **Scroll wheel** or **↑ / ↓** changes the zoom level (range **1.25×–8×**, step
  configurable, default 0.25× per notch).
- The underlying screen is **frozen** — this is a snapshot, not live.
- **Enter Draw** at any time by pressing `⌘⌃D` or simply starting to drag with the
  left mouse button; annotations render on top of the zoomed image.
- **⌘C** copies the currently visible region to the clipboard; **⌘S** saves it to a
  PNG (default `~/Pictures/XPlain`).
- **Esc** / **right-click** exits to Idle.

**Done-when (behavioral):** pressing the hotkey magnifies the live screen within
~150 ms with no visible tearing; panning tracks the cursor 1:1; exit restores the
desktop untouched.

---

## 4. Draw / Annotate mode (`⌘⌃D`)

**Purpose:** draw on the screen to explain.

Draw can be entered two ways:
1. **From Zoom** — annotate the magnified image.
2. **Standalone** — the current screen is captured as a frozen backdrop and you
   draw directly on it at 1×.

### Drawing

- **Left-drag** draws freehand with the current pen.
- Hold a modifier while dragging to draw a shape (Mac-native mapping):

  | Hold while dragging | Shape |
  |---------------------|-------|
  | *(none)* | Freehand line |
  | **Shift** | Straight line |
  | **⌘** | Rectangle |
  | **⌥** | Ellipse |
  | **Shift + ⌘** | Arrow |

### Pen

- **Colors** (single keypress): `r` red · `g` green · `b` blue · `o` orange ·
  `y` yellow · `p` pink. Default red.
- **Highlighter**: `h` toggles a semi-transparent wide pen.
- **Width**: `⌥ + scroll` or `[` / `]` adjusts pen thickness.

### Text

- `t` enters **text mode**: click to place a caret, type, **Enter** or **Esc**
  commits. Font/size configurable in Settings; `⌥ + scroll` resizes before commit.

### Board & canvas

- `w` blanks to a **whiteboard** (white background); `k` to a **blackboard**.
  Press again or the color key to return to the screen backdrop.
- **⌘Z** undoes the last stroke; **⌘⇧Z** redoes. `e` or **Delete** clears all
  annotations.

### Output

- **⌘C** copies the annotated screen to the clipboard.
- **⌘S** saves a PNG to `~/Pictures/XPlain`.
- **Esc** / **right-click** exits to Idle (annotations are discarded unless saved).

**Done-when (behavioral):** every listed key and modifier produces the documented
result; strokes render with no perceptible lag; undo/redo is exact; exiting leaves
no residue on the desktop.

---

## 5. LiveZoom mode (`⌘⌃L`)

**Purpose:** magnify while the screen underneath stays fully interactive — you can
keep clicking, typing, and demoing at the zoomed scale.

- On activation, XPlain shows a **continuously updating** magnified view of the
  live screen (not a frozen snapshot).
- The magnified region **follows the cursor** (or a configurable follow mode:
  cursor-centered vs. edge-push).
- **Scroll** / **↑ ↓** changes zoom level; the same range as Zoom.
- Input **passes through** to the app underneath — LiveZoom does not intercept
  clicks (the overlay is click-through).
- **Esc** / the hotkey again exits to Idle.

**Done-when (behavioral):** the live screen updates smoothly under magnification
(target ≥ 30 fps) while remaining clickable/typeable; toggling on/off is instant.

---

## 6. Record mode (`⌘⌃R`)

**Purpose:** capture a screen recording to a file.

- `⌘⌃R` **starts** recording; pressing it again **stops** and saves.
- A small HUD (or menu-bar indicator) shows recording state and elapsed time.
- Scope options in Settings: **full display**, or a **selected region** chosen with
  a drag rectangle at start.
- Output: **H.264 `.mp4`** to `~/Movies/XPlain` (folder configurable). System audio
  and microphone capture are **optional** toggles (off by default).
- Recording composites any active Zoom/Draw overlay, so annotations appear in the
  file.

**Done-when (behavioral):** start→stop produces a playable `.mp4` at the display's
native resolution and a stable frame rate, saved to the configured folder.

---

## 7. Settings

A SwiftUI preferences window (opened from the menu). Persisted in `UserDefaults`.

- **Hotkeys** — a recorder for each mode's global shortcut, with conflict warnings.
- **Zoom** — initial level, min/max, step, whether the zoom-in animates.
- **Pen** — default color, default width, highlighter opacity, text font & size.
- **Recording** — output folder, region vs. full screen, audio toggles, quality.
- **General** — launch at login, menu-bar icon style, active-display selection
  (display under cursor vs. main display).
- **Permissions** — live status of Screen Recording (and, if ever needed,
  Accessibility) with a button that deep-links to the correct System Settings pane.

## 8. Cross-mode behaviors

- **Active display**: the mode targets the display containing the cursor at
  activation. Multi-monitor is supported; the overlay covers only that display.
- **Full-screen apps & Spaces**: overlays appear above full-screen apps and on the
  current Space.
- **Failure to capture** (permission missing): instead of a blank screen, XPlain
  shows a small prompt explaining the missing permission and how to grant it.
- **Never blocks the system**: no modal dialogs while a mode is active; exit is
  always one Esc away.

## 9. Explicit non-goals (see `docs/backlog.md` for the "later" list)

- No Break Timer, Demo Type, or LiveDraw-on-live-screen in the MVP.
- No cross-platform (Windows/Linux) build.
- No cloud sync, accounts, or telemetry.
