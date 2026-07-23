import CoreGraphics
import ScreenCaptureKit

/// Wraps ScreenCaptureKit still-image capture (M2.1). Requires Screen Recording
/// permission — callers should preflight via `CGPreflightScreenCaptureAccess()`
/// and route denial through the `PermissionPrompt` state (M2.2), never call this
/// blind.
enum CaptureService {
  enum CaptureError: Error {
    /// No shareable display matches the given `CGDirectDisplayID`.
    case noMatchingDisplay
  }

  /// Captures a still image of the given display's current contents, at that
  /// display's native pixel size.
  static func snapshot(of displayID: CGDirectDisplayID) async throws -> CGImage {
    let content = try await SCShareableContent.current
    guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
      throw CaptureError.noMatchingDisplay
    }

    let filter = SCContentFilter(display: display, excludingWindows: [])
    let config = SCStreamConfiguration()
    config.width = display.width
    config.height = display.height

    return try await SCScreenshotManager.captureImage(
      contentFilter: filter,
      configuration: config
    )
  }

  /// Converts a point between AppKit's bottom-left-origin screen space and
  /// CGImage/ScreenCaptureKit's top-left-origin space, for a display of the
  /// given height (M2.3). The same formula converts either direction —
  /// flipping twice returns the original point. Centralized here per
  /// docs/core.md's "Coordinate discipline": convert once, at the capture
  /// boundary, so the rest of the code works in one space.
  static func flipY(_ point: CGPoint, displayHeight: CGFloat) -> CGPoint {
    CGPoint(x: point.x, y: displayHeight - point.y)
  }

  /// Converts a rect the same way. Only the origin's Y moves — width, height,
  /// and X are unaffected by the flip.
  static func flipY(_ rect: CGRect, displayHeight: CGFloat) -> CGRect {
    CGRect(
      x: rect.origin.x,
      y: displayHeight - rect.origin.y - rect.height,
      width: rect.width,
      height: rect.height
    )
  }
}
