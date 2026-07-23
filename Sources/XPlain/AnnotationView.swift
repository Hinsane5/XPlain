import Cocoa

/// Renders an `AnnotationCanvas` over a frozen backdrop and feeds it mouse input
/// (Draw mode, spec §4). A non-flipped view (bottom-left origin) so its
/// coordinates match the capture/zoom space. Freehand only for M4.2; shapes,
/// text, and boards extend `draw` and the mouse handlers in later tasks.
final class AnnotationView: NSView {
  let canvas = AnnotationCanvas()

  /// The frozen screen (or magnified image) drawn under the annotations.
  var backdrop: CGImage?

  override var isFlipped: Bool { false }

  // Draw mode routes color/width/highlighter keys here; Esc / ⌘C / ⌘S fall
  // through to the window via the responder chain (M4.4).
  override var acceptsFirstResponder: Bool { true }

  // The pen preview is drawn by us (a dot at `pointer`) with the system cursor
  // hidden — cursor rects / cursorUpdate proved unreliable at keeping a custom
  // cursor showing while both hovering and drawing. This is fully in our control
  // and always matches the pen's color/size.
  private var pointer: CGPoint?
  private var didHideCursor = false

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if let window {
      pointer = convert(window.mouseLocationOutsideOfEventStream, from: nil)
      if !didHideCursor {
        NSCursor.hide()
        didHideCursor = true
      }
      needsDisplay = true
    } else {
      restoreCursor()
    }
  }

  deinit { restoreCursor() }

  private func restoreCursor() {
    if didHideCursor {
      NSCursor.unhide()
      didHideCursor = false
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    if let backdrop {
      NSImage(cgImage: backdrop, size: bounds.size).draw(in: bounds)
    }
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    for drawable in canvas.drawables {
      Self.render(drawable, in: context)
    }
    if canvas.inProgressStroke.count > 1 {
      Self.strokeFreehand(canvas.inProgressStroke, pen: canvas.pen, in: context)
    }
    if let preview = canvas.inProgressShape {
      Self.render(preview, in: context)
    }
    drawPenDot(in: context)
  }

  /// The pen preview dot at the pointer — pen color, sized to the brush.
  private func drawPenDot(in context: CGContext) {
    guard let pointer else { return }
    let pen = canvas.pen
    let effectiveWidth = pen.isHighlighter ? pen.width * 4 : pen.width
    let diameter = min(max(effectiveWidth, 6), 48)
    let alpha: CGFloat = pen.isHighlighter ? 0.5 : 1
    context.saveGState()
    context.setFillColor(pen.color.nsColor.withAlphaComponent(alpha).cgColor)
    context.fillEllipse(
      in: CGRect(
        x: pointer.x - diameter / 2,
        y: pointer.y - diameter / 2,
        width: diameter,
        height: diameter
      )
    )
    context.restoreGState()
  }

  override func mouseMoved(with event: NSEvent) {
    pointer = convert(event.locationInWindow, from: nil)
    needsDisplay = true
  }

  override func mouseDown(with event: NSEvent) {
    let modifiers = event.modifierFlags
    let shape = AnnotationCanvas.shape(
      shift: modifiers.contains(.shift),
      command: modifiers.contains(.command),
      option: modifiers.contains(.option)
    )
    pointer = convert(event.locationInWindow, from: nil)
    canvas.beginStroke(at: convert(event.locationInWindow, from: nil), shape: shape)
    needsDisplay = true
  }

  override func mouseDragged(with event: NSEvent) {
    pointer = convert(event.locationInWindow, from: nil)
    canvas.appendPoint(convert(event.locationInWindow, from: nil))
    needsDisplay = true
  }

  override func mouseUp(with event: NSEvent) {
    canvas.endStroke()
    needsDisplay = true
  }

  override func keyDown(with event: NSEvent) {
    // M4.4: pen keys (r/g/b/o/y/p, h, [ ]) mutate the pen; anything else (Esc,
    // ⌘C/⌘S) forwards up the responder chain to the window.
    if let command = Self.penCommand(for: event) {
      canvas.apply(command)
      needsDisplay = true  // redraws the dot in the new color/width
      return
    }
    super.keyDown(with: event)
  }

  private static func penCommand(for event: NSEvent) -> PenCommand? {
    guard !event.modifierFlags.contains(.command),
      let key = event.charactersIgnoringModifiers
    else { return nil }
    return InputRouter.penCommand(forKey: key)
  }

  override func scrollWheel(with event: NSEvent) {
    // M4.4: ⌥+scroll changes pen width (up = widen).
    guard event.modifierFlags.contains(.option), event.scrollingDeltaY != 0 else {
      super.scrollWheel(with: event)
      return
    }
    canvas.apply(event.scrollingDeltaY > 0 ? .widen : .narrow)
    needsDisplay = true  // redraws the dot at the new width
  }

  // MARK: Rendering

  private static func render(_ drawable: Drawable, in context: CGContext) {
    switch drawable {
    case .freehand(let points, let pen):
      strokeFreehand(points, pen: pen, in: context)
    case .line(let from, let to, let pen):
      apply(pen, to: context)
      context.saveGState()
      context.move(to: from)
      context.addLine(to: to)
      context.strokePath()
      context.restoreGState()
    case .rect(let rect, let pen):
      apply(pen, to: context)
      context.saveGState()
      context.stroke(rect)
      context.restoreGState()
    case .ellipse(let rect, let pen):
      apply(pen, to: context)
      context.saveGState()
      context.strokeEllipse(in: rect)
      context.restoreGState()
    case .arrow(let from, let to, let pen):
      strokeArrow(from: from, to: to, pen: pen, in: context)
    case .text:
      break  // M4.5
    }
  }

  private static func strokeArrow(
    from start: CGPoint,
    to end: CGPoint,
    pen: Pen,
    in context: CGContext
  ) {
    context.saveGState()
    apply(pen, to: context)
    // Shaft.
    context.move(to: start)
    context.addLine(to: end)
    // Two barbs at the tip, angled back along the shaft.
    let angle = atan2(end.y - start.y, end.x - start.x)
    let headLength = max(12, pen.width * 4)
    let spread = CGFloat.pi / 7
    for side in [angle + .pi - spread, angle + .pi + spread] {
      context.move(to: end)
      context.addLine(
        to: CGPoint(x: end.x + cos(side) * headLength, y: end.y + sin(side) * headLength)
      )
    }
    context.strokePath()
    context.restoreGState()
  }

  private static func strokeFreehand(_ points: [CGPoint], pen: Pen, in context: CGContext) {
    guard let first = points.first else { return }
    context.saveGState()
    apply(pen, to: context)
    context.move(to: first)
    for point in points.dropFirst() {
      context.addLine(to: point)
    }
    context.strokePath()
    context.restoreGState()
  }

  private static func apply(_ pen: Pen, to context: CGContext) {
    // The highlighter draws semi-transparent and wide (spec §4).
    let alpha: CGFloat = pen.isHighlighter ? 0.4 : 1
    let width = pen.isHighlighter ? pen.width * 4 : pen.width
    context.setStrokeColor(pen.color.nsColor.withAlphaComponent(alpha).cgColor)
    context.setLineWidth(width)
    context.setLineCap(.round)
    context.setLineJoin(.round)
  }
}

extension PenColor {
  /// The on-screen color for each named pen color (spec §4).
  var nsColor: NSColor {
    switch self {
    case .red: return .systemRed
    case .green: return .systemGreen
    case .blue: return .systemBlue
    case .orange: return .systemOrange
    case .yellow: return .systemYellow
    case .pink: return .systemPink
    }
  }
}
