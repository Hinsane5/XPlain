import CoreGraphics

/// A pen color. The six named colors are the single-keypress choices from
/// spec §4 (`r g b o y p`); a closed enum keeps the model `Codable` and drives
/// the color-key mapping in `InputRouter` (M4.4).
enum PenColor: String, Codable, CaseIterable {
  case red, green, blue, orange, yellow, pink
}

/// The current drawing pen (spec §4): color, stroke width, and whether it's the
/// semi-transparent wide highlighter.
struct Pen: Equatable, Codable {
  var color: PenColor
  var width: CGFloat
  var isHighlighter: Bool
}

/// One annotation on the canvas — the in-memory drawing model from
/// docs/core.md. A value type, `Codable` so a board could be saved/restored
/// (backlog) and so undo/redo (M4.7) can snapshot it cheaply.
enum Drawable: Equatable, Codable {
  case freehand(points: [CGPoint], pen: Pen)
  case line(from: CGPoint, to: CGPoint, pen: Pen)
  case rect(CGRect, pen: Pen)
  case ellipse(CGRect, pen: Pen)
  case arrow(from: CGPoint, to: CGPoint, pen: Pen)
  case text(String, at: CGPoint, size: CGFloat, color: PenColor)
}
