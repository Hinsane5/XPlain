import CoreGraphics
import XCTest

@testable import XPlain

final class DrawableTests: XCTestCase {
  private func roundTrip(_ drawable: Drawable) throws -> Drawable {
    let data = try JSONEncoder().encode(drawable)
    return try JSONDecoder().decode(Drawable.self, from: data)
  }

  private let pen = Pen(color: .red, width: 4, isHighlighter: false)

  func testPenRoundTrips() throws {
    let highlighter = Pen(color: .yellow, width: 20, isHighlighter: true)
    let data = try JSONEncoder().encode(highlighter)
    XCTAssertEqual(try JSONDecoder().decode(Pen.self, from: data), highlighter)
  }

  func testFreehandRoundTrips() throws {
    let drawable = Drawable.freehand(
      points: [CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 20)],
      pen: pen
    )
    XCTAssertEqual(try roundTrip(drawable), drawable)
  }

  func testLineRoundTrips() throws {
    let drawable = Drawable.line(from: CGPoint(x: 1, y: 2), to: CGPoint(x: 3, y: 4), pen: pen)
    XCTAssertEqual(try roundTrip(drawable), drawable)
  }

  func testRectRoundTrips() throws {
    let drawable = Drawable.rect(CGRect(x: 5, y: 6, width: 7, height: 8), pen: pen)
    XCTAssertEqual(try roundTrip(drawable), drawable)
  }

  func testEllipseRoundTrips() throws {
    let drawable = Drawable.ellipse(CGRect(x: 5, y: 6, width: 7, height: 8), pen: pen)
    XCTAssertEqual(try roundTrip(drawable), drawable)
  }

  func testArrowRoundTrips() throws {
    let drawable = Drawable.arrow(from: CGPoint(x: 1, y: 2), to: CGPoint(x: 30, y: 40), pen: pen)
    XCTAssertEqual(try roundTrip(drawable), drawable)
  }

  func testTextRoundTrips() throws {
    let drawable = Drawable.text("hello", at: CGPoint(x: 100, y: 200), size: 24, color: .blue)
    XCTAssertEqual(try roundTrip(drawable), drawable)
  }

  func testPenColorCoversTheSixSpecColors() {
    // spec §4: r red · g green · b blue · o orange · y yellow · p pink.
    XCTAssertEqual(
      Set(PenColor.allCases),
      [.red, .green, .blue, .orange, .yellow, .pink]
    )
  }
}
