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
}
