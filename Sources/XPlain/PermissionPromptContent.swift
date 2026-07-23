import Foundation

/// The copy and deep link shown by the permission-prompt overlay (M2.2). Kept
/// as pure constants, separate from `OverlayWindow`, per docs/testing.md's
/// testability rule: push content out of the view so it's asserted directly
/// rather than by rendering.
enum PermissionPromptContent {
  static let message =
    "XPlain needs Screen Recording permission to capture your screen. "
    + "Open System Settings, enable it for XPlain, then relaunch."

  static let buttonTitle = "Open Screen Recording Settings"

  /// Deep-links straight to the Screen Recording pane (see docs/security.md).
  static let systemSettingsURL = URL(
    string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
  )!
}
