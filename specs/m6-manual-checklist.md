# M6 — Manual verification checklist (Settings, polish & distribution)

UI / integration checks for the Settings window (spec §7) and the
signing/notarization/release steps. The pure pieces (`SettingsStore`
round-trips, conflict detection) are unit-tested; the window, live rebinding,
login item, and Gatekeeper acceptance are verified here.

## M6.1 — SettingsStore  ✅ (unit-tested)
- [x] Round-trips + unset defaults covered in `SettingsStoreTests` (no manual step).

## M6.2 — Settings window shell  ✅ verified live 2026-07-24
- [x] Menu ▸ "Settings…" (⌘,) opens the "XPlain Settings" window with 5 tabs.
- [x] Tabs switch; window closes and reopens cleanly.

## M6.3 — Hotkey recorders + conflict warnings  ✅ verified live 2026-07-24
- [x] The Hotkeys tab shows a recorder per mode; rebinding takes effect with no
      restart (the new chord triggers the mode, the old one doesn't).
- [x] A known-conflict chord (⌃1) shows the orange conflict warning.

## M6.4 — Wire the settings panes  ✅ verified live 2026-07-24
- [x] Zoom level/step/animate change zoom behavior live (verified 5× + no-animate).
- [x] Pen color/width/opacity/text-size change Draw defaults live (verified green pen).
- [x] Recording folder/quality (+ scope/audio mirroring the menu) apply live
      (verified custom output folder).
- [x] General active-display target selects the display a mode uses.
- [ ] Multi-display "Main display" targeting (needs a second monitor to verify).

## M6.5 — Launch at login  ✅ verified live 2026-07-24
- [x] The General toggle adds/removes XPlain in System Settings ▸ Login Items.
- [x] The toggle reflects the real login-item state when Settings reopens.

## M6.6 — Icons  ✅ verified live 2026-07-24
- [x] Menu-bar shows the template magnifier glyph (auto-tinted), not "X".
- [x] App icon (blue magnifier) renders in Finder.
- [x] Recording HUD still swaps glyph → red-dot clock → glyph.

## M6.7 — Signing + hardened runtime  ✅ verified 2026-07-24
- [x] Debug + Release builds pass `codesign --verify --strict --deep` with the
      hardened-runtime flag and the `audio-input` entitlement.

## M6.8 — Notarize + staple + .dmg  *(dmg done; notarization blocked)*
- [x] `scripts/build-dmg.sh` builds build/XPlain.dmg (mounts, app + /Applications,
      passes codesign --verify).
- [ ] BLOCKED: Developer ID signing + notarize + staple + `spctl -a -vv` acceptance
      need a paid Apple Developer membership (user opted out). `scripts/notarize.sh`
      is ready for if that ever changes.

## M6.9 — First-run onboarding  ✅ verified live 2026-07-25
- [x] First launch shows the "Welcome to XPlain" window (permission status +
      hotkey cheat sheet); "Get Started" dismisses it.
- [x] `hasCompletedOnboarding` persists so it doesn't reappear on relaunch.

## M6.10 — GitHub Release  *(pending)*
- [ ] The release is downloadable and runs.
