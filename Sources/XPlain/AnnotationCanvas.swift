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

  /// Points of the stroke currently being drawn (empty when not drawing) —
  /// exposed so the view can render it live before it's committed (M4.2).
  private(set) var inProgressStroke: [CGPoint] = []
  private var isDrawing = false

  /// Starts a freehand stroke at `point` (left mouse down).
  func beginStroke(at point: CGPoint) {
    inProgressStroke = [point]
    isDrawing = true
  }

  /// Extends the current stroke (left mouse drag). No-op if not drawing.
  func appendPoint(_ point: CGPoint) {
    guard isDrawing else { return }
    inProgressStroke.append(point)
  }

  /// Commits the current stroke as a freehand `Drawable` (left mouse up). A
  /// stroke with a single point (a click, no drag) is dropped, not committed.
  func endStroke() {
    defer {
      inProgressStroke = []
      isDrawing = false
    }
    guard isDrawing, inProgressStroke.count > 1 else { return }
    drawables.append(.freehand(points: inProgressStroke, pen: pen))
  }
}
