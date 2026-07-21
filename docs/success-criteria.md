# XPlain — Success Criteria

What "done" and "great" mean. `docs/testing.md` says *how* to verify; this doc says
*what bar to clear*. Grouped as **MVP acceptance** (must pass to ship v1), **quality
bar** (what makes it feel great), and **guardrails** (things that must never happen).

## MVP acceptance criteria (v1 ships when all are true)

**Zoom**
- [ ] `⌘⌃Z` magnifies the display under the cursor in **≤ 150 ms**.
- [ ] Panning follows the cursor **1:1**; zoom range **1.25×–8×** via scroll and ↑/↓.
- [ ] Exiting (Esc / right-click) restores the desktop with **no visual residue**.

**Draw**
- [ ] Freehand plus all four shape modifiers (Shift / ⌘ / ⌥ / Shift+⌘) work as
      specified.
- [ ] All six color keys, highlighter, pen-width, text, and whiteboard/blackboard
      work as specified.
- [ ] Undo/redo is **exact**; `⌘C` and `⌘S` produce correct clipboard/PNG output.

**LiveZoom**
- [ ] The screen underneath stays **interactive** (clicks and typing pass through).
- [ ] Live magnified view sustains **≥ 30 fps** on Apple Silicon.

**Record**
- [ ] Start→stop yields a **playable H.264 `.mp4`** at the display's native
      resolution, saved to the configured folder, with overlays composited in.

**System behavior**
- [ ] Overlays render correctly over **full-screen apps** and on **secondary
      displays**.
- [ ] Only **one mode** is ever active; every mode exits cleanly to Idle.
- [ ] Missing Screen Recording permission shows a **clear prompt**, never a blank
      or frozen screen.

**Distribution**
- [ ] A **Developer ID-notarized `.dmg`** installs and launches on a clean Mac with
      **no Gatekeeper warning**.
- [ ] The app runs as a **menu-bar agent** (no Dock icon) and can **launch at login**.

**Engineering**
- [ ] All `AGENTS.md` validation gates pass in CI on `macos-14`.
- [ ] Unit tests cover zoom math, the annotation model, input mapping, and settings.

## Quality bar (what makes XPlain feel great)

- Mode entry/exit feels **instantaneous** — no perceptible flash, resize, or lag.
- The animated zoom-in is **smooth**, not a hard jump.
- Drawing has **no perceptible latency** between the cursor and the ink.
- Hotkeys are **discoverable** (menu shows them) and **configurable** without a
  restart.
- First-run permission flow is **guided**, not a dead end.
- Feels like a **native Mac citizen**: respects Spaces, multi-monitor, and system
  appearance.

## Guardrails (must never happen)

- The app must **never** capture, store, or transmit screen contents anywhere off
  the device — no network calls with user pixels, ever (see `docs/security.md`).
- No **modal dialog** can trap the user while a mode is active; **Esc always exits**.
- A mode must **never leave the screen frozen** or an overlay stuck after exit.
- No **telemetry or analytics** without explicit, opt-in consent (default: none).
- Capture streams and overlay windows must **never leak** across mode transitions.

## How we'll know (measurement)

- **Automated**: the validation gates + unit/integration suites in `docs/testing.md`.
- **Manual**: the per-release checklist in `specs/`, run on at least one Apple
  Silicon Mac with a multi-monitor setup, covering each acceptance box above.
- **Dogfood**: give a real 5-minute presentation using only XPlain before tagging a
  release — the truest test that the tool disappears into the task.
