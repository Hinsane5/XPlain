import Cocoa

/// Draws `Drawable`s into a `CGContext` (spec §4). Split out of `AnnotationView`
/// so the view stays about input/state and the drawing lives in one place.
enum DrawableRenderer {
  static func render(_ drawable: Drawable, in context: CGContext) {
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
    case .text(let string, let point, let size, let color):
      write(string, at: point, size: size, color: color)
    }
  }

  static func write(_ string: String, at point: CGPoint, size: CGFloat, color: PenColor) {
    (string as NSString).draw(
      at: point,
      withAttributes: [
        .font: NSFont.systemFont(ofSize: size),
        .foregroundColor: color.nsColor,
      ]
    )
  }

  static func strokeFreehand(_ points: [CGPoint], pen: Pen, in context: CGContext) {
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

  private static func apply(_ pen: Pen, to context: CGContext) {
    // The highlighter draws semi-transparent and wide (spec §4); its opacity is
    // a live setting (M6.4).
    let alpha: CGFloat = pen.isHighlighter ? SettingsStore.shared.highlighterOpacity : 1
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
