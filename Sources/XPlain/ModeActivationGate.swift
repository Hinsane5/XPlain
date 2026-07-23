/// Decides which `Mode` a hotkey's requested activation actually resolves to,
/// given whether Screen Recording permission is currently granted (M2.2). Pure
/// and injectable so it's unit-testable without touching real TCC state.
enum ModeActivationGate {
  /// `.idle` never needs permission (it's exit, not entry). Every other mode
  /// requires capture, so a denial resolves to `.permissionPrompt` instead of
  /// the requested mode — never a blank/failed capture.
  static func resolve(requested: Mode, permissionGranted: Bool) -> Mode {
    guard requested != .idle else { return .idle }
    return permissionGranted ? requested : .permissionPrompt
  }
}
