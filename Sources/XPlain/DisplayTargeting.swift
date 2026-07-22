import Cocoa

/// Pure, unit-testable display-selection logic (M1.6). Works in plain frames
/// rather than `NSScreen` so it can be tested with synthetic multi-display
/// layouts (including negative-origin secondary displays) without needing real
/// attached screens.
enum DisplayTargeting {
  /// The frame containing `point`, or `fallback` if none matches, or the first
  /// frame in `screenFrames` if there's no fallback either. Mirrors
  /// `NSScreen.frameUnderCursor()`'s real-world contract: match under the
  /// cursor, else the main display, else whatever's first.
  static func frame(at point: NSPoint, in screens: [NSRect], fallback: NSRect?) -> NSRect? {
    screens.first { $0.contains(point) } ?? fallback ?? screens.first
  }
}
