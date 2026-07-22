import Cocoa

/// A borderless window that covers exactly one display. It will host XPlain's
/// zoom/draw/live content; for M1.3 it shows an opaque test fill so we can
/// confirm it lands on the right display.
final class OverlayWindow: NSWindow {
  private static let escKeyCode: UInt16 = 53

  /// Called when Esc or a right-click asks to leave the active mode (M1.5). The
  /// window itself doesn't tear down — it just reports the request; the caller
  /// (see `AppDelegate`) routes it through `ModeController.exit()`.
  var onDismissRequested: (() -> Void)?

  /// - Parameter displayFrame: the target display's frame in global screen
  ///   coordinates (bottom-left origin). See `NSScreen.frameUnderCursor()`.
  init(displayFrame: NSRect) {
    super.init(
      contentRect: displayFrame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    isOpaque = false
    backgroundColor = NSColor.systemBlue.withAlphaComponent(0.35)  // M1.3 test fill
    hasShadow = false

    // M1.4: sit above the menu bar and follow the user onto full-screen apps and
    // every Space, per docs/core.md's overlay-window conventions.
    level = .mainMenu + 1
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
  }

  // Borderless windows can't become key by default, but the overlay needs key
  // status to receive Esc / mouse / scroll input.
  override var canBecomeKey: Bool { true }

  // Never let AppKit reposition a full-display overlay to keep a title bar
  // on-screen — there's no title bar, and the frame must match the display.
  override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
    frameRect
  }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == Self.escKeyCode {
      onDismissRequested?()
    } else {
      super.keyDown(with: event)
    }
  }

  override func rightMouseDown(with event: NSEvent) {
    onDismissRequested?()
  }
}
