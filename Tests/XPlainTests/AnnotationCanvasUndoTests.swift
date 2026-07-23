import CoreGraphics
import XCTest

@testable import XPlain

final class AnnotationCanvasUndoTests: XCTestCase {
  // MARK: Undo / redo (M4.7)

  /// Commits one drawable of each type through the canvas gestures/text.
  private func canvasWithOneOfEachDrawable() -> AnnotationCanvas {
    let canvas = AnnotationCanvas()
    canvas.beginStroke(at: CGPoint(x: 0, y: 0))
    canvas.appendPoint(CGPoint(x: 1, y: 1))
    canvas.endStroke()  // freehand
    canvas.beginStroke(at: CGPoint(x: 0, y: 0), shape: .line)
    canvas.appendPoint(CGPoint(x: 10, y: 10))
    canvas.endStroke()  // line
    canvas.beginStroke(at: CGPoint(x: 0, y: 0), shape: .rectangle)
    canvas.appendPoint(CGPoint(x: 10, y: 5))
    canvas.endStroke()  // rect
    canvas.beginText(at: CGPoint(x: 3, y: 3))
    canvas.typeText("x")
    canvas.commitText()  // text
    return canvas
  }

  func testUndoRedoIsExactAcrossEveryDrawableType() {
    let canvas = canvasWithOneOfEachDrawable()
    let all = canvas.drawables
    XCTAssertEqual(all.count, 4)

    // Undo each in reverse order.
    for expectedCount in stride(from: 3, through: 0, by: -1) {
      canvas.undo()
      XCTAssertEqual(canvas.drawables.count, expectedCount)
    }
    XCTAssertTrue(canvas.drawables.isEmpty)

    // Redo restores them in the original order, exactly.
    for expectedCount in 1...4 {
      canvas.redo()
      XCTAssertEqual(canvas.drawables.count, expectedCount)
    }
    XCTAssertEqual(canvas.drawables, all)
  }

  func testUndoOnEmptyIsANoOp() {
    let canvas = AnnotationCanvas()
    canvas.undo()
    canvas.redo()
    XCTAssertTrue(canvas.drawables.isEmpty)
  }

  func testCommittingANewDrawableInvalidatesRedo() {
    let canvas = AnnotationCanvas()
    canvas.beginStroke(at: .zero)
    canvas.appendPoint(CGPoint(x: 1, y: 1))
    canvas.endStroke()
    canvas.undo()  // redo now has the stroke

    // A new stroke should drop the redo history (you can't redo the old one).
    canvas.beginStroke(at: CGPoint(x: 5, y: 5))
    canvas.appendPoint(CGPoint(x: 6, y: 6))
    canvas.endStroke()
    canvas.redo()

    XCTAssertEqual(canvas.drawables.count, 1)  // only the new stroke, redo did nothing
  }

  func testClearAllRemovesEverything() {
    let canvas = canvasWithOneOfEachDrawable()
    canvas.clearAll()
    XCTAssertTrue(canvas.drawables.isEmpty)
  }

  func testClearAllIsUndoable() {
    let canvas = canvasWithOneOfEachDrawable()
    let before = canvas.drawables

    canvas.clearAll()
    XCTAssertTrue(canvas.drawables.isEmpty)

    canvas.undo()  // undo the clear → everything comes back
    XCTAssertEqual(canvas.drawables, before)

    canvas.redo()  // redo the clear → empty again
    XCTAssertTrue(canvas.drawables.isEmpty)
  }

  func testClearOnEmptyCanvasIsANoOp() {
    let canvas = AnnotationCanvas()
    canvas.clearAll()
    canvas.undo()  // nothing was cleared, so nothing to undo
    XCTAssertTrue(canvas.drawables.isEmpty)
  }
}
