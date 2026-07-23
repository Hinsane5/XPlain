/// A pen-changing command from a key or scroll (spec §4). Kept separate from the
/// event layer so the key→command mapping is pure and unit-tested; `InputRouter`
/// produces them, `AnnotationCanvas.apply` performs them.
enum PenCommand: Equatable {
  case setColor(PenColor)
  case toggleHighlighter
  case widen
  case narrow
}

/// Maps raw input (keys, scroll) to `PenCommand`s (spec §4). Pure and testable;
/// `AnnotationView` reads events and calls in. M4.10 extends this into the full
/// input mapping table.
enum InputRouter {
  /// The pen command for a single-character key, or nil if the key isn't a pen
  /// key: `r g b o y p` colors, `h` highlighter toggle, `]`/`[` width up/down.
  static func penCommand(forKey character: String) -> PenCommand? {
    switch character {
    case "r": return .setColor(.red)
    case "g": return .setColor(.green)
    case "b": return .setColor(.blue)
    case "o": return .setColor(.orange)
    case "y": return .setColor(.yellow)
    case "p": return .setColor(.pink)
    case "h": return .toggleHighlighter
    case "]": return .widen
    case "[": return .narrow
    default: return nil
    }
  }
}
