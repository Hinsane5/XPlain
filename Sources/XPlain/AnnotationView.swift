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
  }

  override func mouseDown(with event: NSEvent) {
    canvas.beginStroke(at: convert(event.locationInWindow, from: nil))
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
    default:
      break  // shapes / text land in M4.3 / M4.5
    }
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
