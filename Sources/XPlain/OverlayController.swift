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

  /// Shows the overlay with the Screen Recording permission prompt (M2.2)
  /// instead of a mode's real content.
  func showPermissionPrompt(onDisplayFrame frame: NSRect) {
    show(onDisplayFrame: frame)
    window?.showPermissionPrompt()
  }

  /// Shows the overlay immediately (the M1.3 placeholder fill), then replaces
  /// it with the real captured desktop image once the async capture completes
  /// (M2.4). Falls back to the permission prompt if capture fails — e.g.
  /// permission was revoked after the preflight check in `AppDelegate` — so the
  /// user is never left looking at a stuck placeholder.
  func showCapturedSnapshot(of display: Display) {
    show(onDisplayFrame: display.frame)
    Task { [weak self] in
      do {
        let image = try await CaptureService.snapshot(
          of: display.displayID,
          pixelSize: display.pixelSize
        )
        self?.window?.showImage(image)
      } catch {
        NSLog("XPlain: capture failed - \(error)")
        self?.window?.showPermissionPrompt()
      }
    }
  }
}

extension NSScreen {
  /// The frame of the display currently under the cursor, falling back to the
  /// main display. The selection itself is `DisplayTargeting.frame`, a pure
  /// function unit-tested in isolation (M1.6); this just supplies live inputs.
  static func frameUnderCursor() -> NSRect {
    DisplayTargeting.frame(
      at: NSEvent.mouseLocation,
      in: screens.map(\.frame),
      fallback: main?.frame
    ) ?? .zero
  }

  /// The `CGDirectDisplayID` ScreenCaptureKit needs to capture this screen.
  var displayID: CGDirectDisplayID? {
    (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
  }

  /// The display currently under the cursor, as a full `Display` (frame +
  /// capture identity), falling back to the main display (M2.4). The
  /// selection itself is `DisplayTargeting.display`, unit-tested in isolation;
  /// this just supplies live inputs.
  static func displayUnderCursor() -> Display? {
    DisplayTargeting.display(
      at: NSEvent.mouseLocation,
      in: screens.compactMap(\.asDisplay),
      fallback: main?.asDisplay
    )
  }

  private var asDisplay: Display? {
    displayID.map { Display(frame: frame, displayID: $0, backingScaleFactor: backingScaleFactor) }
  }
}
