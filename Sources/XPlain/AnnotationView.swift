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

  // Text tool (M4.5): armed by `t`, placed by the next click, then typing.
  private var textArmed = false
  private static let returnKeyCode: UInt16 = 36
  private static let escapeKeyCode: UInt16 = 53
  private static let deleteKeyCode: UInt16 = 51

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
    switch canvas.board {
    case .screen:
      if let backdrop {
        NSImage(cgImage: backdrop, size: bounds.size).draw(in: bounds)
      }
    case .whiteboard:
      NSColor.white.setFill()
      bounds.fill()
    case .blackboard:
      NSColor.black.setFill()
      bounds.fill()
    }
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    for drawable in canvas.drawables {
      DrawableRenderer.render(drawable, in: context)
    }
    if canvas.inProgressStroke.count > 1 {
      DrawableRenderer.strokeFreehand(canvas.inProgressStroke, pen: canvas.pen, in: context)
    }
    if let preview = canvas.inProgressShape {
      DrawableRenderer.render(preview, in: context)
    }
    if let draft = canvas.textDraft {
      // Trailing caret while typing.
      DrawableRenderer.write(
        draft.string + "|",
        at: draft.location,
        size: draft.size,
        color: draft.color
      )
    } else if textArmed {
      drawTextCaret(in: context)  // show where/how big the text will land
    } else {
      drawPenDot(in: context)
    }
  }

  /// A vertical caret at the pointer, as tall as the text, so you can see the
  /// insertion point and font size before clicking to place text (M4.5).
  private func drawTextCaret(in context: CGContext) {
    guard let pointer else { return }
    let halfHeight = canvas.pendingTextSize / 2
    context.saveGState()
    context.setStrokeColor(canvas.pen.color.nsColor.cgColor)
    context.setLineWidth(2)
    // Centered on the pointer, so growing the size extends it up *and* down.
    context.move(to: CGPoint(x: pointer.x, y: pointer.y - halfHeight))
    context.addLine(to: CGPoint(x: pointer.x, y: pointer.y + halfHeight))
    context.strokePath()
    context.restoreGState()
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
    let point = convert(event.locationInWindow, from: nil)
    pointer = point

    if textArmed {
      canvas.beginText(at: point)  // place the caret (M4.5)
      textArmed = false
      needsDisplay = true
      return
    }
    if canvas.isEditingText {
      canvas.commitText()  // clicking away commits the current text
      needsDisplay = true
      return
    }

    let modifiers = event.modifierFlags
    let shape = AnnotationCanvas.shape(
      shift: modifiers.contains(.shift),
      command: modifiers.contains(.command),
      option: modifiers.contains(.option)
    )
    canvas.beginStroke(at: point, shape: shape)
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
    // M4.5: while typing, all keys go to the text (Enter/Esc commit).
    if canvas.isEditingText {
      handleTextKey(event)
      return
    }
    // `t` arms text placement for the next click (M4.5); `w`/`k` swap the board
    // (M4.6). All plain (no ⌘) single keys.
    if !event.modifierFlags.contains(.command) {
      switch event.charactersIgnoringModifiers {
      case "t":
        textArmed = true
        return
      case "w":
        canvas.toggleWhiteboard()
        needsDisplay = true
        return
      case "k":
        canvas.toggleBlackboard()
        needsDisplay = true
        return
      default:
        break
      }
    }
    // M4.4: pen keys (r/g/b/o/y/p, h, [ ]) mutate the pen; anything else (Esc,
    // ⌘C/⌘S) forwards up the responder chain to the window.
    if let command = Self.penCommand(for: event) {
      canvas.apply(command)
      needsDisplay = true  // redraws the dot in the new color/width
      return
    }
    super.keyDown(with: event)
  }

  private func handleTextKey(_ event: NSEvent) {
    switch event.keyCode {
    case Self.returnKeyCode, Self.escapeKeyCode:
      canvas.commitText()  // spec §4: Enter or Esc commits
    case Self.deleteKeyCode:
      canvas.deleteBackwardText()
    default:
      if let characters = event.characters, !characters.isEmpty {
        canvas.typeText(characters)
      }
    }
    needsDisplay = true
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
    if canvas.isEditingText || textArmed {
      canvas.resizeText(by: event.scrollingDeltaY > 0 ? 1 : -1)  // M4.5
    } else {
      canvas.apply(event.scrollingDeltaY > 0 ? .widen : .narrow)  // M4.4
    }
    needsDisplay = true
  }
}
