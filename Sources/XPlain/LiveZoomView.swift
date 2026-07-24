import Cocoa

/// Renders the live capture feed magnified, following the cursor (LiveZoom,
/// spec §5 / M5.2). Layer-backed and updated per frame with implicit animations
/// disabled, so it tracks at the stream's frame rate. Uses the same
/// `ZoomRenderer.transform` as static Zoom to magnify about the cursor.
final class LiveZoomView: NSView {
  /// The magnification level (default 2×, spec §5 shares Zoom's range).
  var scale: CGFloat = ZoomRenderer.defaultScale

  /// How the magnified region tracks the cursor (M5.4). Read from `SettingsStore`
  /// at show time; cursor-centered re-centers on the pointer every frame,
  /// edge-push holds still until the cursor nears the edge.
  var followMode: LiveZoomFollow.Mode = .cursorCentered

  private let imageLayer = CALayer()

  /// The last follow anchor, so edge-push can hold the view still within its
  /// dead zone across frames (M5.4). Seeded on the first frame.
  private var anchor: CGPoint?

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

  /// Displays the next captured frame, magnified about the follow anchor (M5.4:
  /// cursor-centered tracks the pointer; edge-push holds still until it nears
  /// the edge).
  func update(frame: CGImage) {
    let cursor = cursorInView()
    let next = LiveZoomFollow.anchor(
      mode: followMode,
      cursor: cursor,
      previous: anchor ?? cursor,  // seed edge-push on the cursor for frame one
      viewSize: bounds.size
    )
    anchor = next
    CATransaction.begin()
    CATransaction.setDisableActions(true)  // no implicit animation per frame
    imageLayer.contents = frame
    let base = NSRect(origin: .zero, size: bounds.size)
    imageLayer.frame = base.applying(ZoomRenderer.transform(scale: scale, about: next))
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
