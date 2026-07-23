import Foundation

/// XPlain's small persisted settings, backed by `UserDefaults`. First use is the
/// LiveZoom follow mode (M5.4); more of spec §7's toggles land here later.
enum Preferences {
  private static let liveZoomFollowModeKey = "liveZoomFollowMode"

  /// The LiveZoom cursor-follow mode (M5.4), defaulting to cursor-centered — the
  /// same behavior as static Zoom, and what M5.2/M5.3 shipped with.
  static var liveZoomFollowMode: LiveZoomFollow.Mode {
    get {
      (UserDefaults.standard.string(forKey: liveZoomFollowModeKey))
        .flatMap(LiveZoomFollow.Mode.init(rawValue:)) ?? .cursorCentered
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: liveZoomFollowModeKey)
    }
  }
}
