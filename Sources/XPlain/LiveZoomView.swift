import Cocoa

/// Renders the live capture feed magnified, following the cursor (LiveZoom,
/// spec §5 / M5.2). Layer-backed and updated per frame with implicit animations
/// disabled, so it tracks at the stream's frame rate. Uses the same
/// `ZoomRenderer.transform` as static Zoom to magnify about the cursor.
final class LiveZoomView: NSView {
  /// The magnification level (default 2×, spec §5 shares Zoom's range).
  var scale: CGFloat = ZoomRenderer.defaultScale

  private let imageLayer = CALayer()

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    wantsLayer = true
    layer?.backgroundColor = NSColor.black.cgColor
    imageLayer.contentsGravity = .resize
    imageLayer.frame = bounds
    layer?.addSublayer(imageLayer)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  /// Displays the next captured frame, magnified about the live cursor.
  func update(frame: CGImage) {
    let cursor = cursorInView()
    CATransaction.begin()
    CATransaction.setDisableActions(true)  // no implicit animation per frame
    imageLayer.contents = frame
    let base = NSRect(origin: .zero, size: bounds.size)
    imageLayer.frame = base.applying(ZoomRenderer.transform(scale: scale, about: cursor))
    CATransaction.commit()
  }

  /// The cursor in this view's (window) coordinate space — global mouse minus the
  /// window (display) origin. LiveZoom is click-through, so we read it globally
  /// rather than from mouse events.
  private func cursorInView() -> CGPoint {
    guard let window else { return .zero }
    let mouse = NSEvent.mouseLocation
    return CGPoint(x: mouse.x - window.frame.minX, y: mouse.y - window.frame.minY)
  }
}
