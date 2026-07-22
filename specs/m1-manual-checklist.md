# M1 — Manual verification checklist

Real-time / visual checks that can't be unit-tested (see `docs/testing.md`). Run
these on a real Mac after building; the unit-testable parts already pass in the
gates. Check a box when verified and note your macOS version + display setup.

**Build & run**

```
open XPlain.xcodeproj      # then Product ▸ Run  (⌘R)
```

Watch the Xcode/Console output for `XPlain: <from> → <to>` transition logs.

---

## M1.3 — Overlay appears on the correct display  ✅ verified 2026-07-23

- [x] Press **⌘⌃Z** (Zoom): a translucent blue overlay covers the **whole**
      display the **cursor** is currently on.
- [ ] Move the cursor to a second display, press ⌘⌃Z again: the overlay appears
      on **that** display. *(Not tested — single-display setup. Revisit if/when
      testing on a multi-monitor Mac.)*
- [x] The console logs `idle → zoom` on entry. *(Cross-checked live via `log
      stream --predicate 'process == "XPlain"'` during the check.)*

## M1.4 — Level + Spaces  ✅ verified 2026-07-23
- [x] Overlay appears **above** full-screen apps and on **every** Space.
- [x] With another app in full-screen mode, press ⌘⌃Z: the overlay still shows on
      top of it (not hidden behind).
- [x] Switch Spaces (Control+←/→) while the overlay is up: it follows you to the
      new Space instead of staying behind on the old one.

## M1.5 — Esc / right-click exit  ✅ verified 2026-07-23
- [x] **Esc** and **right-click** both dismiss the overlay (`… → idle` logged).
- [x] Enter/exit rapidly 10× — no leftover/stuck windows (check with
      `⌘⌃Z` then Esc, repeated; Activity Monitor / no visible residue). 16
      transitions logged, all cleanly paired (`idle → zoom` immediately followed
      by `zoom → idle`), no stuck overlay observed.
