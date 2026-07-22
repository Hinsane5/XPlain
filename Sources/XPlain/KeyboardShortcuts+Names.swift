import KeyboardShortcuts

// Global activation shortcuts. Defaults are ⌘⌃-based on purpose: ZoomIt's ⌃1–⌃4
// collide with macOS Mission Control Space switching. All are user-configurable
// via the Settings recorder (Milestone M6).
extension KeyboardShortcuts.Name {
  static let zoom = Self("zoom", default: .init(.z, modifiers: [.command, .control]))
  static let draw = Self("draw", default: .init(.d, modifiers: [.command, .control]))
  static let liveZoom = Self("liveZoom", default: .init(.l, modifiers: [.command, .control]))
  static let record = Self("record", default: .init(.r, modifiers: [.command, .control]))
}
