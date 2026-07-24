import Cocoa

/// A borderless window that covers exactly one display. It will host XPlain's
/// zoom/draw/live content; for M1.3 it shows an opaque test fill so we can
/// confirm it lands on the right display.
final class OverlayWindow: NSWindow {
  private static let escKeyCode: UInt16 = 53
  private static let upArrowKeyCode: UInt16 = 126
  private static let downArrowKeyCode: UInt16 = 125

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

  // The magnified image view, its zoom scale, and the last cursor position (in
  // window space), retained so mouse-move panning (M3.2) and scroll/arrow zoom
  // (M3.3) can re-anchor the frame. nil / 1 when not zoomed.
  private weak var zoomImageView: NSImageView?
  private var zoomScale: CGFloat = 1
  private var lastCursor: CGPoint = .zero

  /// The Draw-mode annotation view, when in Draw mode (M4.2). nil otherwise.
  private(set) weak var annotationView: AnnotationView?

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
    if event.modifierFlags.contains(.command) {
      switch event.charactersIgnoringModifiers {
      case "c":
        copyVisibleRegion()
        return
      case "s":
        saveVisibleRegion()
        return
      default: break
      }
    }
    switch event.keyCode {
    case Self.escKeyCode:
      onDismissRequested?()
    case Self.upArrowKeyCode where zoomScale != 1:
      zoomBy(steps: 1)
    case Self.downArrowKeyCode where zoomScale != 1:
      zoomBy(steps: -1)
    default:
      super.keyDown(with: event)
    }
  }

  /// Shows a live-magnification view (LiveZoom, M5.2) filling the overlay, fed
  /// by an `SCStream`. Returns the view so the caller can push frames into it.
  @discardableResult
  func showLiveZoom() -> LiveZoomView {
    zoomScale = 1
    acceptsMouseMovedEvents = false
    // M5.3: click-through — mouse events pass to the app underneath so LiveZoom
    // is a live magnifier you can keep working through (like ZoomIt's LiveZoom).
    // The view follows the cursor by reading its global position each frame, so
    // it doesn't need the mouse events it's giving up. Exit is the hotkey again
    // (see ModeController.toggle) since Esc / right-click now pass through too.
    ignoresMouseEvents = true
    let view = LiveZoomView(frame: NSRect(origin: .zero, size: frame.size))
    contentView = view
    return view
  }

  /// Shows the region-selection overlay for region recording (M5.6): a dimmed
  /// display you drag a rectangle on. Returns the view so the caller can hook
  /// its completion. Captures the mouse (not click-through) to gather the drag.
  @discardableResult
  func showRegionSelection() -> RegionSelectionView {
    zoomScale = 1
    acceptsMouseMovedEvents = false
    ignoresMouseEvents = false
    // Clear the window's blue test-fill so the selection's clear hole shows the
    // true desktop; the view draws its own dim backdrop.
    backgroundColor = .clear
    let view = RegionSelectionView(frame: NSRect(origin: .zero, size: frame.size))
    contentView = view
    makeFirstResponder(view)  // so Esc reaches the view to cancel
    return view
  }

  /// Draw-over-zoom (M4.9): snapshots whatever's currently shown (the magnified,
  /// panned zoom image) and hands it to the annotation canvas as the backdrop,
  /// so you annotate the *magnified* view rather than a fresh 1× capture.
  func beginDrawingOverCurrentContent() {
    guard let contentView,
      let rep = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds)
    else { return }
    contentView.cacheDisplay(in: contentView.bounds, to: rep)
    guard let snapshot = rep.cgImage else { return }
    showAnnotationCanvas(backdrop: snapshot)
  }

  /// Shows the Draw-mode annotation canvas over a frozen backdrop (M4.2): an
  /// `AnnotationView` filling the window, left-drag drawing freehand strokes.
  func showAnnotationCanvas(backdrop: CGImage) {
    zoomScale = 1
    acceptsMouseMovedEvents = true  // track hover to draw the pen dot (M4.4)
    let view = AnnotationView(frame: NSRect(origin: .zero, size: frame.size))
    view.backdrop = backdrop
    contentView = view
    annotationView = view
    makeFirstResponder(view)  // so the pen keys reach the view (M4.4)
  }

  /// The currently visible overlay content as an image — the "visible region"
  /// ⌘C / ⌘S export (M3.5). In Draw mode uses the annotation view's clean
  /// export (backdrop + annotations, no pen dot/caret — M4.8); otherwise
  /// snapshots the content view (the zoom case).
  func visibleRegionImage() -> NSImage? {
    if let annotationView {
      return annotationView.exportImage()
    }
    guard let contentView,
      let rep = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds)
    else { return nil }
    contentView.cacheDisplay(in: contentView.bounds, to: rep)
    let image = NSImage(size: contentView.bounds.size)
    image.addRepresentation(rep)
    return image
  }

  private func copyVisibleRegion() {
    guard let image = visibleRegionImage() else { return }
    SnapshotExporter.copy(image, to: .general)
  }

  private func saveVisibleRegion() {
    guard let image = visibleRegionImage() else { return }
    do {
      let url = try SnapshotExporter.savePNG(
        image,
        to: SnapshotExporter.defaultSaveDirectory,
        filename: SnapshotExporter.timestampedFilename()
      )
      NSLog("XPlain: saved \(url.path)")
    } catch {
      NSLog("XPlain: save failed - \(error)")
    }
  }

  override func scrollWheel(with event: NSEvent) {
    guard zoomScale != 1 else {
      super.scrollWheel(with: event)
      return
    }
    if event.scrollingDeltaY != 0 {
      lastCursor = event.locationInWindow
      zoomBy(steps: event.scrollingDeltaY > 0 ? 1 : -1)  // scroll up = zoom in
    }
  }

  override func rightMouseDown(with event: NSEvent) {
    onDismissRequested?()
  }

  /// Steps the zoom level (M3.3), keeping the point under the cursor fixed.
  /// Both scroll and ↑/↓ route here so they behave identically.
  func zoomBy(steps: Int) {
    guard zoomScale != 1 else { return }
    zoomScale = ZoomRenderer.zoomed(
      from: zoomScale,
      steps: steps,
      step: SettingsStore.shared.zoomStep
    )
    reanchorMagnifiedFrame()
  }

  private func reanchorMagnifiedFrame() {
    guard let zoomImageView else { return }
    let base = NSRect(origin: .zero, size: frame.size)
    zoomImageView.frame = base.applying(ZoomRenderer.transform(scale: zoomScale, about: lastCursor))
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
  ///   - animated: when true and magnified, the zoom-in animates from 1× to
  ///     `scale` (M3.4); false is a hard cut (the frame lands final immediately).
  func showImage(
    _ image: CGImage,
    magnifiedBy scale: CGFloat = 1,
    about cursor: CGPoint = .zero,
    animated: Bool = false
  ) {
    let container = ClippingView(frame: NSRect(origin: .zero, size: frame.size))

    let base = NSRect(origin: .zero, size: frame.size)
    let target = base.applying(ZoomRenderer.transform(scale: scale, about: cursor))
    let imageView = ZoomImageView(frame: target)
    imageView.image = NSImage(cgImage: image, size: frame.size)
    imageView.imageScaling = .scaleAxesIndependently
    container.addSubview(imageView)

    contentView = container
    zoomImageView = imageView
    zoomScale = scale
    lastCursor = cursor
    acceptsMouseMovedEvents = scale != 1  // pan only when magnified (M3.2)
    invalidateCursorRects(for: imageView)
    // Cursor rects only update on the next mouse move; set the red dot now so
    // it's shown the instant the overlay appears, not after the first move.
    Self.zoomCursor.set()

    // M3.4: animate from the 1× fill up to the magnified target. The frame is
    // already at target above (so a disabled/hard-cut lands correct); when
    // animating, start at 1× and let the animator drive it to target.
    let duration = ZoomRenderer.entryAnimationDuration(animated: animated)
    if duration > 0, scale != 1 {
      imageView.frame = base
      NSAnimationContext.runAnimationGroup { context in
        context.duration = duration
        imageView.animator().frame = target
      }
    }
  }

  /// M3.2: while magnified, moving the mouse re-anchors the frozen image on the
  /// live cursor, panning the view 1:1 so the content under the pointer tracks
  /// it. Uses the same `ZoomRenderer.transform` as the initial present.
  override func mouseMoved(with event: NSEvent) {
    guard zoomScale != 1 else {
      super.mouseMoved(with: event)
      return
    }
    lastCursor = event.locationInWindow
    reanchorMagnifiedFrame()
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
