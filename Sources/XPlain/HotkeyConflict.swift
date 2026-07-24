import AppKit

/// Flags a chosen global shortcut that collides with a well-known macOS system
/// shortcut, so the Settings hotkey recorder (M6.3) can warn about it. Pure over
/// a `(carbonKeyCode, modifiers)` pair so it's unit-tested without the recorder
/// UI. Not exhaustive — it covers the collisions most likely to silently swallow
/// XPlain's keys, chiefly the ⌃1–⌃4 Spaces chords docs/CLAUDE.md warns about.
enum HotkeyConflict {
  private struct SystemShortcut {
    let keyCode: Int
    let modifiers: NSEvent.ModifierFlags
    let name: String
  }

  // Carbon/virtual key codes (identical to NSEvent.keyCode).
  private static let known: [SystemShortcut] = [
    SystemShortcut(keyCode: 18, modifiers: [.control], name: "Mission Control — Desktop 1"),
    SystemShortcut(keyCode: 19, modifiers: [.control], name: "Mission Control — Desktop 2"),
    SystemShortcut(keyCode: 20, modifiers: [.control], name: "Mission Control — Desktop 3"),
    SystemShortcut(keyCode: 21, modifiers: [.control], name: "Mission Control — Desktop 4"),
    SystemShortcut(keyCode: 123, modifiers: [.control], name: "Move left a Space"),
    SystemShortcut(keyCode: 124, modifiers: [.control], name: "Move right a Space"),
    SystemShortcut(keyCode: 126, modifiers: [.control], name: "Mission Control"),
    SystemShortcut(keyCode: 125, modifiers: [.control], name: "Application windows"),
    SystemShortcut(keyCode: 49, modifiers: [.command], name: "Spotlight"),
  ]

  /// The name of the system shortcut this chord collides with, or `nil` if it's
  /// clear. Only the four device-independent modifier bits are compared, so
  /// stray caps-lock/function bits don't mask a real conflict.
  static func name(carbonKeyCode: Int, modifiers: NSEvent.ModifierFlags) -> String? {
    let relevant: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
    let mods = modifiers.intersection(relevant)
    return known.first { $0.keyCode == carbonKeyCode && $0.modifiers == mods }?.name
  }
}
