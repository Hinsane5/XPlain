import Cocoa
import XCTest

@testable import XPlain

final class AnnotationExportTests: XCTestCase {
  func testExportCompositesAnnotationsOverTheBackdrop() throws {
    // A white board with a thick red freehand line across the vertical center.
    // The export must show the annotation, not just the blank board (M4.8).
    let view = AnnotationView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
    view.canvas.toggleWhiteboard()
    view.canvas.pen = Pen(color: .red, width: 12, isHighlighter: false)
    view.canvas.beginStroke(at: CGPoint(x: 0, y: 50))
    view.canvas.appendPoint(CGPoint(x: 200, y: 50))
    view.canvas.endStroke()

    let image = view.exportImage()
    let rep = try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(image.tiffRepresentation)))

    // Center pixel sits on the line → should be red (annotation composited in),
    // not white (the bare board).
    let center = try XCTUnwrap(rep.colorAt(x: rep.pixelsWide / 2, y: rep.pixelsHigh / 2))
    XCTAssertGreaterThan(center.redComponent, 0.5)
    XCTAssertLessThan(center.greenComponent, 0.5)
    XCTAssertLessThan(center.blueComponent, 0.5)

    // A corner is off the line → still the white board.
    let corner = try XCTUnwrap(rep.colorAt(x: 2, y: 2))
    XCTAssertGreaterThan(corner.redComponent, 0.9)
    XCTAssertGreaterThan(corner.greenComponent, 0.9)
    XCTAssertGreaterThan(corner.blueComponent, 0.9)
  }
}
