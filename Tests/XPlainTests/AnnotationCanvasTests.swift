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
}
