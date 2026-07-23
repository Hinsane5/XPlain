import Cocoa

/// A borderless window that covers exactly one display. It will host XPlain's
/// zoom/draw/live content; for M1.3 it shows an opaque test fill so we can
/// confirm it lands on the right display.
final class OverlayWindow: NSWindow {
  private static let escKeyCode: UInt16 = 53

  /// A red-dot pointer shown while a frozen snapshot is up, so it's obvious the
  /// overlay is active — otherwise the 1× capture is pixel-identical to the live
  /// desktop and there's no cue you've entered the mode (ZoomIt does the same).
  /// The real magnification lands in M3; this is the interim "you're in" cue.
  static let zoomCursor: NSCursor = {
    let diameter: CGFloat = 12
    let image = NSImage(size: NSSize(width: diameter, height: diameter))
    image.lockFocus()
    NSColor.systemRed.setFill()
    NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: diameter, height: diameter)).fill()
    image.unlockFocus()
    return NSCursor(image: image, hotSpot: NSPoint(x: diameter / 2, y: diameter / 2))
  }()

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

  /// Replaces the overlay's content with the permission prompt (M2.2): a
  /// centered message plus a button that deep-links to System Settings' Screen
  /// Recording pane. Shown instead of a mode's real content when capture
  /// permission is denied, so the user never sees a blank/frozen screen.
  func showPermissionPrompt() {
    let container = NSView(frame: NSRect(origin: .zero, size: frame.size))

    let label = NSTextField(wrappingLabelWithString: PermissionPromptContent.message)
    label.alignment = .center
    label.font = .systemFont(ofSize: 18)
    label.frame = NSRect(
      x: 40,
      y: frame.height / 2,
      width: frame.width - 80,
      height: 80
    )
    container.addSubview(label)

    let button = RightClickForwardingButton(
      title: PermissionPromptContent.buttonTitle,
      target: self,
      action: #selector(openSystemSettings)
    )
    button.frame = NSRect(
      x: frame.width / 2 - 100,
      y: frame.height / 2 - 60,
      width: 200,
      height: 32
    )
    container.addSubview(button)

    contentView = container
  }

  @objc private func openSystemSettings() {
    NSWorkspace.shared.open(PermissionPromptContent.systemSettingsURL)
  }

  /// Shows the captured desktop image magnified by `scale`, centered on
  /// `cursor` (M2.4 render + M3.1 zoom). `scale = 1` reproduces the M2.4 1×
  /// render (frame fills the window). The magnified image view is a subview of
  /// a clipping container so the part that overflows the display is cropped by
  /// the window; the container-fill keeps the red-dot cursor over the whole
  /// overlay.
  ///
  /// - Parameters:
  ///   - cursor: the zoom center in the window's (bottom-left origin) space —
  ///     `NSEvent.mouseLocation` minus the display origin. See
  ///     `OverlayController.showCapturedSnapshot`.
  func showImage(_ image: CGImage, magnifiedBy scale: CGFloat = 1, about cursor: CGPoint = .zero) {
    let container = ClippingView(frame: NSRect(origin: .zero, size: frame.size))

    let base = NSRect(origin: .zero, size: frame.size)
    let imageView = ZoomImageView(
      frame: base.applying(ZoomRenderer.transform(scale: scale, about: cursor))
    )
    imageView.image = NSImage(cgImage: image, size: frame.size)
    imageView.imageScaling = .scaleAxesIndependently
    container.addSubview(imageView)

    contentView = container
    invalidateCursorRects(for: imageView)
    // Cursor rects only update on the next mouse move; set the red dot now so
    // it's shown the instant the overlay appears, not after the first move.
    Self.zoomCursor.set()
  }
}

/// Clips its subviews to its own bounds so the magnified image view (which
/// extends past the display edges when zoomed) doesn't draw outside the overlay.
private final class ClippingView: NSView {
  override init(frame: NSRect) {
    super.init(frame: frame)
    clipsToBounds = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// The frozen-snapshot content view. Its only extra job over `NSImageView` is to
/// paint the red-dot `zoomCursor` over the whole overlay (see that cursor's note).
private final class ZoomImageView: NSImageView {
  override func resetCursorRects() {
    addCursorRect(bounds, cursor: OverlayWindow.zoomCursor)
  }
}

/// An `NSButton` that forwards right-clicks up the responder chain instead of
/// swallowing them (NSControl's default). Without this, right-clicking the
/// permission prompt's button would never reach `OverlayWindow.rightMouseDown`,
/// so it took a second right-click *outside* the button to dismiss the overlay.
private final class RightClickForwardingButton: NSButton {
  override func rightMouseDown(with event: NSEvent) {
    nextResponder?.rightMouseDown(with: event)
  }
}
