import CoreGraphics

/// The drawing model (docs/core.md): the committed `[Drawable]`, the current
/// pen, and the in-progress stroke. Pure logic with no view/AppKit dependency
/// so it's unit-tested directly; `AnnotationView` renders it and feeds it mouse
/// input. Shapes (M4.3), text (M4.5), boards (M4.6), and undo/redo (M4.7) extend
/// this.
final class AnnotationCanvas {
  /// Committed annotations, oldest first.
  private(set) var drawables: [Drawable] = []

  /// The active pen. Default red, medium width, per spec §4.
  var pen = Pen(color: .red, width: 3, isHighlighter: false)

  /// The kind of thing the current drag draws (spec §4). Chosen from the held
  /// modifiers at mouse-down (see `shape(shift:command:option:)`).
  enum Shape: Equatable {
    case freehand, line, rectangle, ellipse, arrow
  }

  /// Points of the freehand stroke currently being drawn (empty when not
  /// drawing freehand) — exposed so the view renders it live (M4.2).
  private(set) var inProgressStroke: [CGPoint] = []

  private var isDrawing = false
  private var gestureStart: CGPoint?
  private var lastPoint: CGPoint?
  private var gestureShape: Shape = .freehand

  /// The rubber-band shape preview for the current drag (line/rect/ellipse/
  /// arrow), or nil for freehand / no drag yet. Rendered live, committed on
  /// mouse-up (M4.3).
  var inProgressShape: Drawable? {
    guard isDrawing, gestureShape != .freehand,
      let start = gestureStart, let end = lastPoint, start != end
    else { return nil }
    return Self.drawable(shape: gestureShape, from: start, to: end, pen: pen)
  }

  /// Starts a stroke at `point` (left mouse down). `shape` is the modifier-
  /// chosen kind; `.freehand` traces the drag, the others rubber-band.
  func beginStroke(at point: CGPoint, shape: Shape = .freehand) {
    isDrawing = true
    gestureStart = point
    lastPoint = point
    gestureShape = shape
    inProgressStroke = shape == .freehand ? [point] : []
  }

  /// Extends the current stroke (left mouse drag). No-op if not drawing.
  func appendPoint(_ point: CGPoint) {
    guard isDrawing else { return }
    lastPoint = point
    if gestureShape == .freehand { inProgressStroke.append(point) }
  }

  /// Commits the current gesture (left mouse up). Freehand needs ≥2 points; a
  /// shape needs a non-empty drag (start ≠ end). Degenerate gestures are dropped.
  func endStroke() {
    defer {
      inProgressStroke = []
      isDrawing = false
      gestureStart = nil
      lastPoint = nil
      gestureShape = .freehand
    }
    guard isDrawing, let start = gestureStart, let end = lastPoint else { return }
    if gestureShape == .freehand {
      guard inProgressStroke.count > 1 else { return }
      drawables.append(.freehand(points: inProgressStroke, pen: pen))
    } else if start != end {
      drawables.append(Self.drawable(shape: gestureShape, from: start, to: end, pen: pen))
    }
  }

  // MARK: Shape geometry (pure — M4.3)

  /// The shape for the held modifiers (spec §4): Shift+⌘ = arrow, Shift = line,
  /// ⌘ = rectangle, ⌥ = ellipse, none = freehand. Shift+⌘ is checked first.
  static func shape(shift: Bool, command: Bool, option: Bool) -> Shape {
    if shift && command { return .arrow }
    if shift { return .line }
    if command { return .rectangle }
    if option { return .ellipse }
    return .freehand
  }

  /// Builds the `Drawable` for `shape` from a drag's `start`/`end`. Rect and
  /// ellipse normalize into a positive-size rect regardless of drag direction.
  static func drawable(shape: Shape, from start: CGPoint, to end: CGPoint, pen: Pen) -> Drawable {
    switch shape {
    case .freehand: return .freehand(points: [start, end], pen: pen)
    case .line: return .line(from: start, to: end, pen: pen)
    case .rectangle: return .rect(normalizedRect(start, end), pen: pen)
    case .ellipse: return .ellipse(normalizedRect(start, end), pen: pen)
    case .arrow: return .arrow(from: start, to: end, pen: pen)
    }
  }

  private static func normalizedRect(_ first: CGPoint, _ second: CGPoint) -> CGRect {
    CGRect(
      x: min(first.x, second.x),
      y: min(first.y, second.y),
      width: abs(second.x - first.x),
      height: abs(second.y - first.y)
    )
  }
}
