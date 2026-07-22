import Cocoa

/// Shows and hides the single overlay window in response to mode changes. One
/// overlay exists at a time; switching between active modes (e.g. Zoom→Draw)
/// reuses it, and returning to idle tears it down.
final class OverlayController {
  private var window: OverlayWindow?

  /// Called when the on-screen overlay reports an Esc / right-click dismissal
  /// request (M1.5). Set this before calling `show`.
  var onDismissRequested: (() -> Void)?

  /// Whether an overlay is currently on screen.
  var isShowing: Bool { window != nil }

  /// Shows an overlay covering the given display frame, reusing the current
  /// window if one is already up (just repositioning it).
  func show(onDisplayFrame frame: NSRect) {
    if let window {
      window.setFrame(frame, display: true)
    } else {
      let overlay = OverlayWindow(displayFrame: frame)
      overlay.onDismissRequested = { [weak self] in self?.onDismissRequested?() }
      overlay.makeKeyAndOrderFront(nil)
      window = overlay
    }
  }

  /// Removes the overlay, if any.
  func hide() {
    window?.orderOut(nil)
    window = nil
  }
}

extension NSScreen {
  /// The frame of the display currently under the cursor, falling back to the
  /// main display. M1.6 replaces the selection logic with a tested pure function.
  static func frameUnderCursor() -> NSRect {
    let cursor = NSEvent.mouseLocation
    let match = screens.first { NSMouseInRect(cursor, $0.frame, false) }
    return (match ?? main ?? screens.first)?.frame ?? .zero
  }
}
