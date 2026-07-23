# M4 — Manual verification checklist (Draw / Annotate mode)

Visual checks for Draw mode (spec §4). The model, shape geometry, pen mutation,
board toggle, and undo/redo are unit-tested; these cover the on-screen result.
Enter Draw mode with ⌘⌃D (freezes the screen as a backdrop).

## M4.2 — Freehand  ✅ verified live 2026-07-23
- [x] ⌘⌃D freezes the screen; left-drag paints a freehand stroke that renders
      live; Esc / right-click exits.

## M4.3 — Shape modifiers  ✅ verified live 2026-07-23
- [x] Shift = straight line, ⌘ = rectangle, ⌥ = ellipse, Shift+⌘ = arrow, each
      as a rubber-band preview committed on mouse-up.

## M4.4 — Colors / highlighter / width  ✅ verified live 2026-07-23
- [x] r/g/b/o/y/p change color; h toggles highlighter; [ / ] and ⌥+scroll change width.

## M4.5 — Text  *(pending)*
- [ ] t → click → type → Enter/Esc commits; ⌥+scroll resizes before commit.

## M4.6 — Whiteboard / blackboard  *(pending)*
- [ ] w = white backdrop, k = black; press again to restore; annotations survive.

## M4.7 — Undo / redo  *(pending)*
- [ ] ⌘Z undo, ⌘⇧Z redo; e / Delete clears all.

## M4.8 — Copy / save annotated  *(pending)*
- [ ] ⌘C / ⌘S include the annotations, not just the backdrop.

## M4.9 — Standalone vs over-zoom  *(pending)*
- [ ] ⌘⌃D from Idle draws on the frozen screen; from Zoom draws on the magnified image.
