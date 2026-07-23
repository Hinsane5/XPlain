# M3 — Manual verification checklist (Zoom mode)

Real-time / visual checks for Zoom mode (spec §3). The zoom math is unit-tested
(`ZoomRendererTests`); these cover what only the eye can judge. Requires Screen
Recording permission (now persists via stable signing — see M2 checklist).

## M3.1 — Initial magnified present  ✅ verified live 2026-07-23
- [x] ⌘⌃Z magnifies the screen to **2×**, centered on the cursor.
- [x] The red-dot cursor shows **immediately** on activation (no click needed).
- [ ] The point under the cursor stays put (zoom is anchored on the pointer, not
      a corner or the wrong spot) — confirm by eye.

## M3.2 — Pan on mouse move  *(pending)*
- [ ] Moving the mouse pans the magnified view 1:1 (content tracks the cursor).

## M3.3 — Zoom in/out  *(pending)*
- [ ] Scroll wheel and ↑/↓ change the zoom level, clamped to 1.25×–8×.

## M3.4 — Animated zoom-in  *(pending)*
- [ ] Entry animates smoothly (not a hard jump); can be disabled by a flag.

## M3.5 — Copy / Save  *(pending)*
- [ ] ⌘C copies the visible region; ⌘S writes a PNG to ~/Pictures/XPlain.
