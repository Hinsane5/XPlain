/// A pen-changing command from a key or scroll (spec §4). Kept separate from the
/// event layer so the key→command mapping is pure and unit-tested; `InputRouter`
/// produces them, `AnnotationCanvas.apply` performs them.
enum PenCommand: Equatable {
  case setColor(PenColor)
  case toggleHighlighter
  case widen
  case narrow
}

/// A Draw-mode command from a keystroke (spec §4), beyond the pen changes.
/// Text-editing sub-mode keys (typing, Enter/Esc, Backspace) aren't here —
/// they're stateful and handled while a text draft is open.
enum DrawCommand: Equatable {
  case pen(PenCommand)  // color / highlighter / width
  case beginText  // t
  case whiteboard  // w
  case blackboard  // k
  case clear  // e
  case undo  // ⌘Z
  case redo  // ⌘⇧Z
}

/// Maps raw input (keys, scroll) to commands (spec §4). Pure and testable;
/// `AnnotationView` reads events and calls in. This owns the full key table.
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

  /// The full spec §4 key/modifier → `DrawCommand` mapping (M4.10). `command` is
  /// ⌘ held, `shift` is ⇧. Returns nil for anything not a draw command (⌘C/⌘S,
  /// unknown keys). Shape selection is separate — see `AnnotationCanvas.shape`.
  static func command(_ character: String, command: Bool, shift: Bool) -> DrawCommand? {
    if command {
      // Only ⌘Z / ⌘⇧Z are ours; ⌘C/⌘S and the rest fall through to nil.
      guard character.lowercased() == "z" else { return nil }
      return shift ? .redo : .undo
    }
    switch character {
    case "t": return .beginText
    case "w": return .whiteboard
    case "k": return .blackboard
    case "e": return .clear
    default: return penCommand(forKey: character).map(DrawCommand.pen)
    }
  }
}
