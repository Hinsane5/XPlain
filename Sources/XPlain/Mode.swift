/// A screen mode XPlain can be in. `idle` is the resting state; the others are
/// activated by a global hotkey (see `HotkeyService`) and enforced one-at-a-time
/// by the mode controller (Milestone M1.2).
enum Mode: Equatable, CaseIterable {
  case idle
  case zoom
  case draw
  case liveZoom
  case record

  /// Shown instead of a requested mode when Screen Recording permission is
  /// denied (M2.2), per docs/core.md's invariant: a capture-permission failure
  /// must route here, never leave the user looking at a blank overlay. See
  /// `ModeActivationGate`.
  case permissionPrompt
}
