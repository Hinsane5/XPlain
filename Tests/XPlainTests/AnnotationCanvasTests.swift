import CoreGraphics
import XCTest

@testable import XPlain

final class AnnotationCanvasTests: XCTestCase {
  func testFreehandStrokeCommitsAsAFreehandDrawable() {
    let canvas = AnnotationCanvas()
    canvas.pen = Pen(color: .green, width: 5, isHighlighter: false)

    canvas.beginStroke(at: CGPoint(x: 0, y: 0))
    canvas.appendPoint(CGPoint(x: 10, y: 10))
    canvas.appendPoint(CGPoint(x: 20, y: 5))
    canvas.endStroke()

    XCTAssertEqual(
      canvas.drawables,
      [
        .freehand(
          points: [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 10), CGPoint(x: 20, y: 5)],
          pen: Pen(color: .green, width: 5, isHighlighter: false)
        )
      ]
    )
  }

  func testInProgressStrokeIsExposedWhileDrawingThenCleared() {
    let canvas = AnnotationCanvas()
    canvas.beginStroke(at: CGPoint(x: 1, y: 1))
    canvas.appendPoint(CGPoint(x: 2, y: 2))

    XCTAssertEqual(canvas.inProgressStroke, [CGPoint(x: 1, y: 1), CGPoint(x: 2, y: 2)])
    XCTAssertTrue(canvas.drawables.isEmpty)  // not committed yet

    canvas.endStroke()
    XCTAssertTrue(canvas.inProgressStroke.isEmpty)  // cleared after commit
  }

  func testAppendWithoutBeginIsIgnored() {
    let canvas = AnnotationCanvas()
    canvas.appendPoint(CGPoint(x: 5, y: 5))
    canvas.endStroke()
    XCTAssertTrue(canvas.drawables.isEmpty)
  }

  func testEmptyStrokeIsNotCommitted() {
    // A click with no drag (begin immediately followed by end) shouldn't leave a
    // degenerate single-point drawable.
    let canvas = AnnotationCanvas()
    canvas.beginStroke(at: CGPoint(x: 3, y: 3))
    canvas.endStroke()
    XCTAssertTrue(canvas.drawables.isEmpty)
  }

  // MARK: Shapes (M4.3)

  func testModifierToShapeMapping() {
    // spec §4: none=freehand, Shift=line, ⌘=rect, ⌥=ellipse, Shift+⌘=arrow.
    typealias Shape = AnnotationCanvas.Shape
    XCTAssertEqual(AnnotationCanvas.shape(shift: false, command: false, option: false), .freehand)
    XCTAssertEqual(AnnotationCanvas.shape(shift: true, command: false, option: false), .line)
    XCTAssertEqual(AnnotationCanvas.shape(shift: false, command: true, option: false), .rectangle)
    XCTAssertEqual(AnnotationCanvas.shape(shift: false, command: false, option: true), .ellipse)
    XCTAssertEqual(AnnotationCanvas.shape(shift: true, command: true, option: false), .arrow)
  }

  func testShapeGeometryFromDragStartAndEnd() {
    let pen = Pen(color: .blue, width: 2, isHighlighter: false)
    let start = CGPoint(x: 10, y: 100)
    let end = CGPoint(x: 40, y: 60)

    XCTAssertEqual(
      AnnotationCanvas.drawable(shape: .line, from: start, to: end, pen: pen),
      .line(from: start, to: end, pen: pen)
    )
    XCTAssertEqual(
      AnnotationCanvas.drawable(shape: .arrow, from: start, to: end, pen: pen),
      .arrow(from: start, to: end, pen: pen)
    )
    // rect / ellipse normalize the drag into a positive-size rect regardless of
    // direction: here (10,60)–(40,100), 30×40.
    let normalized = CGRect(x: 10, y: 60, width: 30, height: 40)
    XCTAssertEqual(
      AnnotationCanvas.drawable(shape: .rectangle, from: start, to: end, pen: pen),
      .rect(normalized, pen: pen)
    )
    XCTAssertEqual(
      AnnotationCanvas.drawable(shape: .ellipse, from: start, to: end, pen: pen),
      .ellipse(normalized, pen: pen)
    )
  }

  func testDraggingAShapeCommitsThatShapeOnEnd() {
    let canvas = AnnotationCanvas()
    canvas.pen = Pen(color: .orange, width: 3, isHighlighter: false)

    canvas.beginStroke(at: CGPoint(x: 0, y: 0), shape: .rectangle)
    canvas.appendPoint(CGPoint(x: 50, y: 30))
    XCTAssertNotNil(canvas.inProgressShape)  // rubber-band preview available
    canvas.endStroke()

    XCTAssertEqual(
      canvas.drawables,
      [
        .rect(
          CGRect(x: 0, y: 0, width: 50, height: 30),
          pen: Pen(color: .orange, width: 3, isHighlighter: false)
        )
      ]
    )
    XCTAssertNil(canvas.inProgressShape)  // cleared after commit
  }

  func testShapeWithNoDragIsNotCommitted() {
    let canvas = AnnotationCanvas()
    canvas.beginStroke(at: CGPoint(x: 5, y: 5), shape: .ellipse)
    canvas.endStroke()  // no drag → start == end
    XCTAssertTrue(canvas.drawables.isEmpty)
  }

  // MARK: Pen commands (M4.4)

  func testSetColorCommandChangesThePenColor() {
    let canvas = AnnotationCanvas()
    canvas.apply(.setColor(.green))
    XCTAssertEqual(canvas.pen.color, .green)
  }

  func testToggleHighlighterFlipsTheFlag() {
    let canvas = AnnotationCanvas()
    XCTAssertFalse(canvas.pen.isHighlighter)
    canvas.apply(.toggleHighlighter)
    XCTAssertTrue(canvas.pen.isHighlighter)
    canvas.apply(.toggleHighlighter)
    XCTAssertFalse(canvas.pen.isHighlighter)
  }

  func testWidenAndNarrowAdjustWidthWithinBounds() {
    let canvas = AnnotationCanvas()
    let start = canvas.pen.width

    canvas.apply(.widen)
    XCTAssertGreaterThan(canvas.pen.width, start)
    canvas.apply(.narrow)
    XCTAssertEqual(canvas.pen.width, start, accuracy: 0.0001)

    // Never goes below the minimum, however many times you narrow.
    for _ in 0..<100 { canvas.apply(.narrow) }
    XCTAssertGreaterThanOrEqual(canvas.pen.width, AnnotationCanvas.minPenWidth)
    // …or above the maximum.
    for _ in 0..<1000 { canvas.apply(.widen) }
    XCTAssertLessThanOrEqual(canvas.pen.width, AnnotationCanvas.maxPenWidth)
  }

  // MARK: Text (M4.5)

  func testTypingBuildsTheDraftThenCommitsAsTextDrawable() {
    let canvas = AnnotationCanvas()
    canvas.pen.color = .blue

    canvas.beginText(at: CGPoint(x: 30, y: 40))
    XCTAssertTrue(canvas.isEditingText)
    canvas.typeText("Hi")
    canvas.typeText("!")
    XCTAssertEqual(canvas.textDraft?.string, "Hi!")

    canvas.commitText()
    XCTAssertFalse(canvas.isEditingText)
    XCTAssertEqual(
      canvas.drawables,
      [
        .text(
          "Hi!",
          at: CGPoint(x: 30, y: 40),
          size: AnnotationCanvas.defaultTextSize,
          color: .blue
        )
      ]
    )
  }

  func testBackspaceRemovesTheLastCharacter() {
    let canvas = AnnotationCanvas()
    canvas.beginText(at: .zero)
    canvas.typeText("abc")
    canvas.deleteBackwardText()
    XCTAssertEqual(canvas.textDraft?.string, "ab")
    canvas.deleteBackwardText()
    canvas.deleteBackwardText()
    canvas.deleteBackwardText()  // extra delete on empty is a no-op
    XCTAssertEqual(canvas.textDraft?.string, "")
  }

  func testEmptyTextIsNotCommitted() {
    let canvas = AnnotationCanvas()
    canvas.beginText(at: .zero)
    canvas.commitText()  // nothing typed
    XCTAssertTrue(canvas.drawables.isEmpty)
    XCTAssertFalse(canvas.isEditingText)
  }

  func testResizingTextClampsWithinBounds() {
    let canvas = AnnotationCanvas()
    canvas.beginText(at: .zero)
    let start = canvas.textDraft?.size

    canvas.resizeText(by: 1)
    XCTAssertGreaterThan(canvas.textDraft?.size ?? 0, start ?? 0)

    for _ in 0..<1000 { canvas.resizeText(by: 1) }
    XCTAssertLessThanOrEqual(canvas.textDraft?.size ?? 0, AnnotationCanvas.maxTextSize)
    for _ in 0..<1000 { canvas.resizeText(by: -1) }
    XCTAssertGreaterThanOrEqual(canvas.textDraft?.size ?? 0, AnnotationCanvas.minTextSize)
  }

  // MARK: Whiteboard / blackboard (M4.6)

  func testBoardStartsOnTheScreen() {
    XCTAssertEqual(AnnotationCanvas().board, .screen)
  }

  func testWhiteboardTogglesOnAndBackToScreen() {
    let canvas = AnnotationCanvas()
    canvas.toggleWhiteboard()
    XCTAssertEqual(canvas.board, .whiteboard)
    canvas.toggleWhiteboard()
    XCTAssertEqual(canvas.board, .screen)
  }

  func testBlackboardTogglesOnAndBackToScreen() {
    let canvas = AnnotationCanvas()
    canvas.toggleBlackboard()
    XCTAssertEqual(canvas.board, .blackboard)
    canvas.toggleBlackboard()
    XCTAssertEqual(canvas.board, .screen)
  }

  func testSwitchingDirectlyBetweenBoards() {
    let canvas = AnnotationCanvas()
    canvas.toggleWhiteboard()
    canvas.toggleBlackboard()  // white → black (not back to screen)
    XCTAssertEqual(canvas.board, .blackboard)
  }

  func testTogglingABoardKeepsExistingAnnotations() {
    let canvas = AnnotationCanvas()
    canvas.beginStroke(at: CGPoint(x: 0, y: 0))
    canvas.appendPoint(CGPoint(x: 5, y: 5))
    canvas.endStroke()
    let before = canvas.drawables

    canvas.toggleWhiteboard()
    canvas.toggleBlackboard()
    canvas.toggleBlackboard()

    XCTAssertEqual(canvas.drawables, before)  // annotations survive board swaps
  }

}
