# XPlain — Security & Privacy

XPlain can see the entire screen and record it. That makes **privacy the central
concern**: the app requests some of the most sensitive permissions macOS offers, so
it must be transparent, local-only, and trustworthy. There are no accounts, servers,
or secrets — the threat model is about **respecting the user's screen**, not
defending a backend.

## Posture in one line

Everything XPlain captures stays **on the device**. No network egress of screen
contents, ever. No telemetry by default.

## Assets & threats

| Asset | Threat | Mitigation |
|-------|--------|------------|
| Live screen pixels (may contain passwords, private messages) | Exfiltration or logging | **No network stack** touches captured pixels; nothing is written to disk except files the user explicitly saves/records. |
| Screen Recording TCC grant | Silent abuse / scope creep | Request only when a capture mode is first used; explain why; deep-link the user to the exact System Settings pane. |
| Global hotkey registration | Keylogging suspicion | Use Carbon `RegisterEventHotKey` (via KeyboardShortcuts) which **does not read key contents** and needs **no Accessibility permission**; in-mode keys are handled only while our own overlay is key window. |
| Saved recordings / screenshots | Leaking sensitive frames | Saved only to user-chosen folders (`~/Movies/XPlain`, `~/Pictures/XPlain`); never auto-uploaded. |
| The distributed `.app` | Tampering / malware impersonation | Developer ID signing + notarization + hardened runtime, so Gatekeeper verifies integrity. |

## Permissions (macOS TCC)

- **Screen Recording — required.** Needed for any capture. Preflight with
  `CGPreflightScreenCaptureAccess()`; request with `CGRequestScreenCaptureAccess()`
  or let ScreenCaptureKit prompt. macOS caches the grant per signed binary; after
  re-signing or moving the `.app`, the grant can reset and the app must relaunch —
  document this in onboarding.
- **Accessibility — not required for the MVP.** Global hotkeys and in-mode keys work
  without it. It becomes necessary only for backlog features that synthesize input
  (e.g. **Demo Type**). Request it lazily, only if/when such a feature is used.
- **Microphone — optional**, only if the user enables mic capture in Record. Request
  at that moment, not at launch.

## Checklist (verify before shipping any feature that touches these)

- **Least privilege** — request each permission lazily, at the moment the feature
  needs it, with an in-app explanation first.
- **Local only** — no library or code path sends captured pixels off-device; audit
  dependencies for hidden network calls.
- **Usage strings** — set clear `NSCameraUsageDescription` (mic),
  and Screen Recording rationale copy that says exactly what and why.
- **Hardened Runtime** — enabled, with only the entitlements actually needed
  (screen capture; device-audio-input only if mic is offered). No
  `com.apple.security.cs.allow-unsigned-executable-memory` unless a dependency truly
  requires it.
- **Notarization** — every release `.dmg` is signed with Developer ID, notarized via
  `notarytool`, and stapled; verify with `spctl -a -vv` on a clean machine.
- **No secrets in the repo** — there are none by design; there is no `.env`, no API
  key, no server. If that ever changes, add `.env.example` and load from env.
- **Dependencies** — keep the (small) SwiftPM dependency set pinned and reviewed;
  prefer Apple frameworks over third-party for anything touching capture.
- **Telemetry** — none by default. If ever added, it must be **opt-in**, documented,
  and must never include screen contents.

## Out of scope (tracked, not forgotten)

- Sandbox/Mac App Store hardening — XPlain ships **outside** the App Store precisely
  because the sandbox blocks system-wide capture and global hotkeys. Revisit only if
  a reduced App Store edition is ever pursued.
- Enterprise MDM deployment and managed-permission provisioning.
- Signing-key management/rotation beyond a single Developer ID certificate.
