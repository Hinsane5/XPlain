import Foundation

/// XPlain's small persisted settings, backed by `UserDefaults`. First use is the
/// LiveZoom follow mode (M5.4); more of spec §7's toggles land here later.
enum Preferences {
  private static let liveZoomFollowModeKey = "liveZoomFollowMode"
  private static let recordingScopeKey = "recordingScope"
  private static let capturesSystemAudioKey = "capturesSystemAudio"

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

  /// What Record captures (M5.6), defaulting to the full display (M5.5's
  /// behavior). `selectedRegion` prompts a drag-rectangle at start.
  static var recordingScope: RecordingScope {
    get {
      (UserDefaults.standard.string(forKey: recordingScopeKey))
        .flatMap(RecordingScope.init(rawValue:)) ?? .fullDisplay
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: recordingScopeKey)
    }
  }

  /// Whether Record captures system audio (M5.7), off by default. Covered by
  /// Screen Recording permission, so no extra prompt.
  static var capturesSystemAudio: Bool {
    get { UserDefaults.standard.bool(forKey: capturesSystemAudioKey) }
    set { UserDefaults.standard.set(newValue, forKey: capturesSystemAudioKey) }
  }
}

/// Whether Record captures the whole display or a drag-selected region (M5.6).
enum RecordingScope: String, CaseIterable {
  case fullDisplay
  case selectedRegion

  /// Human-readable label for the status-menu items.
  var title: String {
    switch self {
    case .fullDisplay: return "Full display"
    case .selectedRegion: return "Selected region"
    }
  }
}
