import Cocoa

/// A drag-to-select overlay for region recording (M5.6). Dims the whole display
/// and lets the user drag a clear rectangle; on mouse-up it reports the selected
/// rect (in view/display points, bottom-left origin), or `nil` if cancelled with
/// Esc or the drag was an empty click. The pure crop math lives in
/// `RecordingRegion`; this view just gathers the selection.
final class RegionSelectionView: NSView {
  private static let escKeyCode: UInt16 = 53

  /// Called once when the selection finishes: the chosen rect, or `nil` on
  /// cancel. `OverlayController.selectRegion` hides the overlay and forwards it.
  var onComplete: ((CGRect?) -> Void)?

  private var startPoint: CGPoint?
  private var currentRect: CGRect = .zero

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    wantsLayer = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override var acceptsFirstResponder: Bool { true }

  override func draw(_ dirtyRect: NSRect) {
    // Dim everything, punching a clear hole for the selection (even-odd fill).
    let path = NSBezierPath(rect: bounds)
    if currentRect != .zero {
      path.appendRect(currentRect)
    }
    path.windingRule = .evenOdd
    NSColor.black.withAlphaComponent(0.45).setFill()
    path.fill()

    if currentRect != .zero {
      NSColor.white.setStroke()
      let border = NSBezierPath(rect: currentRect)
      border.lineWidth = 1
      border.stroke()
    }
  }

  override func mouseDown(with event: NSEvent) {
    startPoint = convert(event.locationInWindow, from: nil)
    currentRect = .zero
    needsDisplay = true
  }

  override func mouseDragged(with event: NSEvent) {
    guard let startPoint else { return }
    let point = convert(event.locationInWindow, from: nil)
    currentRect = Self.rect(from: startPoint, to: point)
    needsDisplay = true
  }

  override func mouseUp(with event: NSEvent) {
    onComplete?(currentRect == .zero ? nil : currentRect)
  }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == Self.escKeyCode {
      onComplete?(nil)
    } else {
      super.keyDown(with: event)
    }
  }

  /// A normalized rect spanning two corner points (drag can go any direction).
  private static func rect(from start: CGPoint, to end: CGPoint) -> CGRect {
    CGRect(
      x: min(start.x, end.x),
      y: min(start.y, end.y),
      width: abs(start.x - end.x),
      height: abs(start.y - end.y)
    )
  }
}
