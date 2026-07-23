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

    let button = NSButton(
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
}
