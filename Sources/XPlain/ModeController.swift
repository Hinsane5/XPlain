/// Owns XPlain's single active `Mode` and the legal transitions between modes.
/// Exactly one mode is ever active (see docs/core.md "State machine"): switching
/// modes replaces the current one, it never stacks. M1.3+ hooks overlay-window
/// creation and teardown onto `onChange`.
final class ModeController {
  /// The mode you may move to *from* a given mode. Mirrors the core.md diagram:
  /// enter any activatable mode from idle; Zoom↔Draw; and Esc-to-idle from any
  /// active mode. Anything else must exit to idle first.
  private static let legalTransitions: [Mode: Set<Mode>] = [
    .idle: [.zoom, .draw, .liveZoom, .record, .permissionPrompt],
    .zoom: [.draw, .idle],
    .draw: [.zoom, .idle],
    .liveZoom: [.idle],
    .record: [.idle],
    .permissionPrompt: [.idle],
  ]

  private(set) var current: Mode = .idle

  /// Called after every accepted transition with `(from, next)`. M1.3 uses this
  /// to build and tear down overlay windows.
  var onChange: ((_ from: Mode, _ next: Mode) -> Void)?

  /// Whether a non-idle mode is active.
  var isActive: Bool { current != .idle }

  /// Requests a transition into `mode`. Returns `true` if it was accepted, or
  /// `false` for a no-op (already in `mode`) or an illegal transition.
  @discardableResult
  func request(_ mode: Mode) -> Bool {
    guard mode != current else { return false }
    guard Self.legalTransitions[current]?.contains(mode) == true else { return false }

    let from = current
    current = mode
    onChange?(from, mode)
    return true
  }

  /// Exits the active mode back to idle. No-op if already idle.
  @discardableResult
  func exit() -> Bool {
    request(.idle)
  }

  /// Toggles `mode`: exits to idle if it's already current, otherwise requests
  /// it. The global activation hotkeys route through this so pressing a mode's
  /// shortcut again leaves that mode — the only exit path for click-through
  /// LiveZoom (M5.3), which passes Esc / right-click through to the app beneath.
  @discardableResult
  func toggle(_ mode: Mode) -> Bool {
    current == mode ? exit() : request(mode)
  }
}
