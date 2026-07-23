import CoreGraphics

/// Pure crop math for region recording (M5.6). Turns a drag-selected rectangle —
/// in the overlay's AppKit space (points, bottom-left origin, relative to the
/// display) — into the ScreenCaptureKit `sourceRect` (points, top-left origin)
/// and the output pixel size for the writer. Kept view-free so the geometry is
/// unit-tested in isolation; `AppDelegate` supplies the live selection and
/// `Recorder` applies the results.
enum RecordingRegion {
  /// The smallest usable region edge, in points — a smaller drag is treated as a
  /// stray click and recording falls back to full-screen.
  static let minEdge: CGFloat = 16

  /// The SCK `sourceRect` (points, top-left origin) for a bottom-left selection
  /// within a display of the given point height. Only the Y origin flips; width,
  /// height, and X are unchanged (same transform as `CaptureService.flipY`).
  static func sourceRect(selection: CGRect, displayHeightPoints: CGFloat) -> CGRect {
    CaptureService.flipY(selection, displayHeight: displayHeightPoints)
  }

  /// The output pixel size for a selection: points × `scale` (native pixels),
  /// each dimension rounded down to an even integer — H.264 requires even
  /// dimensions, and rounding down never exceeds the captured region.
  static func pixelSize(selection: CGRect, scale: CGFloat) -> CGSize {
    CGSize(
      width: evenFloor(selection.width * scale),
      height: evenFloor(selection.height * scale)
    )
  }

  /// Clamps a selection to `[0, displaySize]` so the region never exceeds the
  /// display (a drag can run past the edges).
  static func clamped(_ rect: CGRect, to displaySize: CGSize) -> CGRect {
    let minX = max(rect.minX, 0)
    let minY = max(rect.minY, 0)
    let maxX = min(rect.maxX, displaySize.width)
    let maxY = min(rect.maxY, displaySize.height)
    return CGRect(x: minX, y: minY, width: max(0, maxX - minX), height: max(0, maxY - minY))
  }

  /// Whether a selection is big enough to record (both edges ≥ `minEdge`).
  static func isUsable(_ rect: CGRect) -> Bool {
    rect.width >= minEdge && rect.height >= minEdge
  }

  private static func evenFloor(_ value: CGFloat) -> CGFloat {
    let whole = Int(value)
    return CGFloat(whole - (whole % 2))
  }
}
