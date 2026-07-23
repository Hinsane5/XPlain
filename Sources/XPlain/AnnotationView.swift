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
  }

  override func mouseDown(with event: NSEvent) {
    let modifiers = event.modifierFlags
    let shape = AnnotationCanvas.shape(
      shift: modifiers.contains(.shift),
      command: modifiers.contains(.command),
      option: modifiers.contains(.option)
    )
    canvas.beginStroke(at: convert(event.locationInWindow, from: nil), shape: shape)
    needsDisplay = true
  }

  override func mouseDragged(with event: NSEvent) {
    canvas.appendPoint(convert(event.locationInWindow, from: nil))
    needsDisplay = true
  }

  override func mouseUp(with event: NSEvent) {
    canvas.endStroke()
    needsDisplay = true
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
    let alpha: CGFloat = pen.isHighlighter ? 0.4 : 1
    context.setStrokeColor(pen.color.nsColor.withAlphaComponent(alpha).cgColor)
    context.setLineWidth(pen.width)
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
