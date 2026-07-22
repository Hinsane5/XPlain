import KeyboardShortcuts

/// Registers XPlain's global activation shortcuts and reports which `Mode` each
/// one requests. Registration goes through KeyboardShortcuts (Carbon
/// `RegisterEventHotKey` under the hood), so it needs no Accessibility permission.
final class HotkeyService {
  /// Each activation shortcut paired with the mode it requests.
  static let bindings: [(name: KeyboardShortcuts.Name, mode: Mode)] = [
    (.zoom, .zoom),
    (.draw, .draw),
    (.liveZoom, .liveZoom),
    (.record, .record),
  ]

  private let emit: (Mode) -> Void

  /// - Parameter emit: called with the requested mode whenever a shortcut fires.
  init(emit: @escaping (Mode) -> Void) {
    self.emit = emit
  }

  /// Registers the global handlers. Call once, after launch.
  func start() {
    for binding in Self.bindings {
      let mode = binding.mode
      KeyboardShortcuts.onKeyDown(for: binding.name) { [emit] in
        emit(mode)
      }
    }
  }

  /// The mode a shortcut requests, or `nil` if it isn't an activation shortcut.
  func mode(for name: KeyboardShortcuts.Name) -> Mode? {
    Self.bindings.first { $0.name == name }?.mode
  }

  /// Simulates a shortcut firing without a real key event — used by tests (and
  /// available for previews) to exercise the mapping deterministically.
  func trigger(_ name: KeyboardShortcuts.Name) {
    guard let mode = mode(for: name) else { return }
    emit(mode)
  }
}
