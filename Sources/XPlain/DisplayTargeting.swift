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

  /// Same selection logic as `frame(at:in:fallback:)`, but carrying the extra
  /// identity `CaptureService.snapshot` needs (M2.4): which `CGDirectDisplayID`
  /// to capture, and the `backingScaleFactor` to compute its native pixel size.
  static func display(at point: NSPoint, in list: [Display], fallback: Display?) -> Display? {
    list.first { $0.frame.contains(point) } ?? fallback ?? list.first
  }
}

/// A display's frame plus the identity needed to capture it (M2.4).
struct Display: Equatable {
  let frame: NSRect
  let displayID: CGDirectDisplayID
  let backingScaleFactor: CGFloat

  /// The display's true native pixel size — `frame` is in points.
  var pixelSize: CGSize {
    CGSize(width: frame.width * backingScaleFactor, height: frame.height * backingScaleFactor)
  }
}
