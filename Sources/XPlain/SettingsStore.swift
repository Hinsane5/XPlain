import Foundation

/// XPlain's typed settings, persisted in `UserDefaults` (spec §7). A thin, typed
/// wrapper: each property reads/writes one key and falls back to a documented
/// default when unset. The backing `UserDefaults` is injectable so round-trips
/// are unit-tested against an ephemeral suite (M6.1); `shared` is the app-wide
/// instance over `.standard`. A reference type so `shared.x = y` writes through.
final class SettingsStore {
  /// The app-wide store.
  static let shared = SettingsStore()

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  // MARK: LiveZoom / Record (M5.4–M5.7b)

  /// The LiveZoom cursor-follow mode (M5.4), defaulting to cursor-centered.
  var liveZoomFollowMode: LiveZoomFollow.Mode {
    get { enumValue(.liveZoomFollowMode, default: .cursorCentered) }
    set { setEnum(.liveZoomFollowMode, newValue) }
  }

  /// What Record captures (M5.6): the full display or a drag-selected region.
  var recordingScope: RecordingScope {
    get { enumValue(.recordingScope, default: .fullDisplay) }
    set { setEnum(.recordingScope, newValue) }
  }

  /// Whether Record captures system audio (M5.7), off by default.
  var capturesSystemAudio: Bool {
    get { bool(.capturesSystemAudio, default: false) }
    set { defaults.set(newValue, forKey: Key.capturesSystemAudio.rawValue) }
  }

  /// Whether Record captures the microphone (M5.7b), off by default.
  var capturesMicrophone: Bool {
    get { bool(.capturesMicrophone, default: false) }
    set { defaults.set(newValue, forKey: Key.capturesMicrophone.rawValue) }
  }

  /// Where recordings are written (spec §6), default `~/Movies/XPlain`.
  var recordingFolder: URL {
    get {
      defaults.string(forKey: Key.recordingFolder.rawValue)
        .map { URL(fileURLWithPath: $0) } ?? Recorder.defaultSaveDirectory
    }
    set { defaults.set(newValue.path, forKey: Key.recordingFolder.rawValue) }
  }

  // MARK: Zoom (spec §7)

  /// The zoom level applied on activation, default `ZoomRenderer.defaultScale`.
  var initialZoomLevel: CGFloat {
    get { cgFloat(.initialZoomLevel, default: ZoomRenderer.defaultScale) }
    set { defaults.set(Double(newValue), forKey: Key.initialZoomLevel.rawValue) }
  }

  /// The per-notch zoom step, default `ZoomRenderer.defaultStep`.
  var zoomStep: CGFloat {
    get { cgFloat(.zoomStep, default: ZoomRenderer.defaultStep) }
    set { defaults.set(Double(newValue), forKey: Key.zoomStep.rawValue) }
  }

  /// Whether the zoom-in animates on entry (spec §3/§7), default on.
  var animateZoomIn: Bool {
    get { bool(.animateZoomIn, default: true) }
    set { defaults.set(newValue, forKey: Key.animateZoomIn.rawValue) }
  }

  // MARK: Pen (spec §7)

  /// The default pen color for a fresh session, default red.
  var defaultPenColor: PenColor {
    get { enumValue(.defaultPenColor, default: .red) }
    set { setEnum(.defaultPenColor, newValue) }
  }

  /// The default pen stroke width, default 3.
  var defaultPenWidth: CGFloat {
    get { cgFloat(.defaultPenWidth, default: 3) }
    set { defaults.set(Double(newValue), forKey: Key.defaultPenWidth.rawValue) }
  }

  /// The default text-tool font size, default `AnnotationCanvas.defaultTextSize`.
  var textFontSize: CGFloat {
    get { cgFloat(.textFontSize, default: AnnotationCanvas.defaultTextSize) }
    set { defaults.set(Double(newValue), forKey: Key.textFontSize.rawValue) }
  }

  /// The highlighter's stroke opacity (spec §7), default 0.4.
  var highlighterOpacity: CGFloat {
    get { cgFloat(.highlighterOpacity, default: 0.4) }
    set { defaults.set(Double(newValue), forKey: Key.highlighterOpacity.rawValue) }
  }

  /// The recording video quality (spec §7), default high.
  var recordingQuality: RecordingQuality {
    get { enumValue(.recordingQuality, default: .high) }
    set { setEnum(.recordingQuality, newValue) }
  }

  // MARK: General (spec §7)

  /// Which display a mode targets, default the one under the cursor.
  var activeDisplayTarget: ActiveDisplayTarget {
    get { enumValue(.activeDisplayTarget, default: .underCursor) }
    set { setEnum(.activeDisplayTarget, newValue) }
  }

  // MARK: Backing helpers

  /// The `UserDefaults` keys, exposed so the SwiftUI panes' `@AppStorage`
  /// bindings (M6.4) write the exact same keys this store reads.
  enum Key: String {
    case liveZoomFollowMode
    case recordingScope
    case capturesSystemAudio
    case capturesMicrophone
    case recordingFolder
    case recordingQuality
    case initialZoomLevel
    case zoomStep
    case animateZoomIn
    case defaultPenColor
    case defaultPenWidth
    case textFontSize
    case highlighterOpacity
    case activeDisplayTarget
  }

  private func enumValue<T: RawRepresentable>(_ key: Key, default def: T) -> T
  where T.RawValue == String {
    defaults.string(forKey: key.rawValue).flatMap(T.init(rawValue:)) ?? def
  }

  private func setEnum<T: RawRepresentable>(_ key: Key, _ value: T) where T.RawValue == String {
    defaults.set(value.rawValue, forKey: key.rawValue)
  }

  /// Reads a `Bool`, returning `default` when the key is absent (so a default of
  /// `true` isn't clobbered by `bool(forKey:)`'s implicit `false`).
  private func bool(_ key: Key, default def: Bool) -> Bool {
    defaults.object(forKey: key.rawValue) == nil ? def : defaults.bool(forKey: key.rawValue)
  }

  /// Reads a `CGFloat`, returning `default` when the key is absent (so a nonzero
  /// default isn't clobbered by `double(forKey:)`'s implicit `0`).
  private func cgFloat(_ key: Key, default def: CGFloat) -> CGFloat {
    defaults.object(forKey: key.rawValue) == nil
      ? def : CGFloat(defaults.double(forKey: key.rawValue))
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

/// Which display a mode targets (spec §7 General), the one under the cursor or
/// the main display.
enum ActiveDisplayTarget: String, CaseIterable {
  case underCursor
  case mainDisplay

  /// Human-readable label for the settings UI.
  var title: String {
    switch self {
    case .underCursor: return "Display under cursor"
    case .mainDisplay: return "Main display"
    }
  }
}

/// Recording video quality (spec §7), mapped to a bits-per-pixel target that
/// scales the H.264 average bitrate with the captured resolution.
enum RecordingQuality: String, CaseIterable {
  case high
  case medium
  case low

  /// Human-readable label for the settings UI.
  var title: String {
    switch self {
    case .high: return "High"
    case .medium: return "Medium"
    case .low: return "Low"
    }
  }

  /// Target bits per pixel per frame — multiplied by pixel count and frame rate
  /// to get the average bitrate.
  var bitsPerPixel: Double {
    switch self {
    case .high: return 0.20
    case .medium: return 0.11
    case .low: return 0.06
    }
  }
}
